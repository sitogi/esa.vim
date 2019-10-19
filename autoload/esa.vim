"=============================================================================
" File: esa.vim
" Author: Masato Yamamoto <jajkeqos@gmail.com>
" Last Change: 01-Mar-2016.
" Version: 0.1
" WebPage: http://github.com/upamune/esa.vim
" License: BSD

let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:esa_disabled') && g:esa_disabled == 1
  function! esa#Esa(...) abort
  endfunction
  finish
endif

if !executable('curl')
  echohl ErrorMsg | echomsg 'Esa: require ''curl'' command' | echohl None
  finish
endif

if globpath(&rtp, 'autoload/webapi/http.vim') ==# ''
  echohl ErrorMsg | echomsg 'Esa: require ''webapi'', install https://github.com/mattn/webapi-vim' | echohl None
  finish
else
  call webapi#json#true()
endif

let s:esa_token_file = expand(get(g:, 'esa_token_file', '~/.esa-vim'))
let s:system = function(get(g:, 'webapi#system_function', 'system'))

if !exists('g:esa_team')
  let g:esa_team = $ESA_TEAM
endif

if !exists('g:esa_api_url')
  let g:esa_api_url = 'https://api.esa.io/v1/teams/'
endif
if g:esa_api_url !~# '/$'
  let g:esa_api_url .= '/'
endif

function! s:shellwords(str) abort
  let words = split(a:str, '\%(\([^ \t\''"]\+\)\|''\([^\'']*\)''\|"\(\%([^\"\\]\|\\.\)*\)"\)\zs\s*\ze')
  let words = map(words, 'substitute(v:val, ''\\\([\\ ]\)'', ''\1'', "g")')
  let words = map(words, 'matchstr(v:val, ''^\%\("\zs\(.*\)\ze"\|''''\zs\(.*\)\ze''''\|.*\)$'')')
  return words
endfunction

function! s:get_current_filename(no) abort
  let filename = expand('%:t')
  return filename
endfunction

function! s:get_browser_command() abort
  let esa_browser_command = get(g:, 'esa_browser_command', '')
  if esa_browser_command ==# ''
    if has('win32') || has('win64')
      let esa_browser_command = '!start rundll32 url.dll,FileProtocolHandler %URL%'
    elseif has('mac') || has('macunix') || has('gui_macvim') || system('uname') =~? '^darwin'
      let esa_browser_command = 'open %URL%'
    elseif executable('xdg-open')
      let esa_browser_command = 'xdg-open %URL%'
    elseif executable('firefox')
      let esa_browser_command = 'firefox %URL% &'
    else
      let esa_browser_command = ''
    endif
  endif
  return esa_browser_command
endfunction

function! s:open_browser(url) abort
  let cmd = s:get_browser_command()
  if len(cmd) == 0
    redraw
    echohl WarningMsg
    echo 'It seems that you don''t have general web browser. Open URL below.'
    echohl None
    echo a:url
    return
  endif
  let quote = &shellxquote == '"' ?  "'" : '"'
  if cmd =~# '^!'
    let cmd = substitute(cmd, '%URL%', '\=quote.a:url.quote', 'g')
    let g:hoge = cmd
    silent! exec cmd
  elseif cmd =~# '^:[A-Z]'
    let cmd = substitute(cmd, '%URL%', '\=a:url', 'g')
    exec cmd
  else
    let cmd = substitute(cmd, '%URL%', '\=quote.a:url.quote', 'g')
    call system(cmd)
  endif
endfunction

function! s:EsaGetAuthHeader() abort
  let auth = ''
  if filereadable(s:esa_token_file)
    let str = join(readfile(s:esa_token_file), '')
    if type(str) == 1
      let auth = str
    endif
  endif
  if len(auth) > 0
    return auth
  endif

  redraw
  echohl WarningMsg
  echo 'esa.vim require an access token for esa. These settings are stored in "~/.esa-vim". If you want to revoke, do "rm ~/.esa-vim".'
  echohl None
  let access_token = input('esa access token for '.g:esa_team.':')
  if len(access_token) == 0
    let v:errmsg = 'Canceled'
    return ''
  endif
  call writefile([access_token], s:esa_token_file)
  if !(has('win32') || has('win64'))
    call system('chmod go= '.s:esa_token_file)
  endif
  return access_token
endfunction

function! esa#Esa(count, bang, line1, line2, ...) abort
  redraw
  let bufname = bufname('%')
  let wip = 0
  let clipboard = 0
  let openbrowser = 0
  let public = 0
  let path = ''
  if strlen(g:esa_team) == 0
    echohl ErrorMsg | echomsg 'You have not configured a esa access token.' | echohl None
    return
  endif

  " Load content
  let args = (a:0 > 0) ? s:shellwords(a:1) : []
  if get(args, 0) =~# '^\(-e\|--edit\)$\C'
      let postId = get(args, 1)
      if len(postId) > 0
        call s:EsaLoad(postId)
      endif
      return
  endif

  " Post content
  for arg in args
    if arg =~# '^\(-h\|--help\)$\C'
      help :Esa
      return
    elseif arg =~# '^\(-e\|--edit\)$\C'
    elseif arg =~# '^\(-b\|--browser\)$\C'
      let openbrowser = 1
    elseif arg =~# '^\(-w\|--wip\)$\C'
      let wip = 1
    elseif arg =~# '^\(-c\|--clipboard\)$\C'
      let clipboard = 1
    elseif arg =~# '^\(-p\|--public\)$\C'
      let public = 1
    elseif len(arg) > 0
      let path = arg
    endif
  endfor
  unlet args

  let content = join(getline(a:line1, a:line2), "\n")
  let url = s:EsaPost(content, path, wip, public)
  if type(url) == 1 && len(url) > 0
    if openbrowser == 1
      call s:open_browser(url)
    endif
    if clipboard == 1
      if exists('g:esa_clip_command')
        call system(g:esa_clip_command, url)
      elseif has('clipboard')
        let @+ = url
      else
        let @" = url
      endif
    endif
  endif
  return 1
endfunction

function! s:EsaPost(content, path, wip, public) abort
  let post = {"post" : {"name" : "", "body_md" : a:content, "category" : "" }}
  let filename = s:get_current_filename(1)
  let category = ''
  let name = ''
  let pos = strridx(a:path, '/')

  if len(a:path) == 0
    let name = s:get_current_filename(1)
  elseif pos == -1
    let name = a:path
  else
    let category = a:path[:(pos-1)]
    let name = a:path[(pos+1):]
  endif
  let post.post['name'] = name
  let post.post['category'] = category

  if a:wip == 0
    let post.post['wip'] = function('webapi#json#false')
  else
    let post.post['wip'] = function('webapi#json#true')
  endif

  let header = {"Content-Type": "application/json"}
  let auth = s:EsaGetAuthHeader()
  if len(auth) == 0
    redraw
    echohl ErrorMsg | echomsg v:errmsg | echohl None
    return
  endif
  let header['Authorization'] = 'Bearer '.auth

  redraw | echon 'Posting it to esa... '
  let res = webapi#http#post(g:esa_api_url.g:esa_team.'/posts', webapi#json#encode(post), header)
  if res.status =~# '^2'
    let obj = webapi#json#decode(res.content)
    let loc = obj['url']

    if a:public == 1
      let loc = s:EsaPublicPost(obj['number'])
    endif

    redraw | echomsg 'Done: '.loc
  else
    let loc = ''
    echohl ErrorMsg | echomsg 'Post failed: '. res.status | echohl None
  endif
  return loc
endfunction

function! s:EsaPublicPost(number) abort
  let loc = ''
  let header = {"Content-Type": "application/json"}
  let auth = s:EsaGetAuthHeader()
  if len(auth) == 0
    redraw
    echohl ErrorMsg | echomsg v:errmsg | echohl None
    return
  endif
  let header['Authorization'] = 'Bearer '.auth
  let res = webapi#http#post(g:esa_api_url.g:esa_team.'/posts/'.a:number.'/sharing', webapi#json#encode({}), header)
  if res.status =~# '^2'
    let obj = webapi#json#decode(res.content)
    let loc = obj['html']
  else
    let loc = ''
    echohl ErrorMsg | echomsg 'Get Sharing URL failed: '.res.status | echohl None
  endif
  return loc
endfunction

function! s:EsaLoad(id) abort
  let header = {"Content-Type": "application/json"}
  let auth = s:EsaGetAuthHeader()
  if len(auth) == 0
    redraw
    echohl ErrorMsg | echomsg v:errmsg | echohl None
    return
  endif
  let header['Authorization'] = 'Bearer '.auth
  let url = g:esa_api_url.g:esa_team.'/posts/' . a:id
  let res = webapi#http#get(url, webapi#json#encode({}), header)
  if res.status =~# '^2'
    let obj = webapi#json#decode(res.content)
    " バッファに展開したときに改行が一つ多く挿入されるため削除 (Vim のバッファでは \r も一つの改行としてみなされる？)
    let mdStr = substitute(obj['body_md'], '\r\n', '\n', 'g')
    call s:InsertContent(mdStr)

    " ロードしたバッファで ID とカテゴリを保持しておき、上書き保存に使用する
    let b:postId = obj['number']
    let b:category = obj['category']

    echon "Load succeeded." . " PostID: " . b:postId . ", Category: " . b:category
  else
    echohl ErrorMsg | echomsg 'Loading post failed: '.res.status | echohl None
  endif
endfunction

function! s:InsertContent(contentStr) abort
    " TODO watch current setting
    setlocal nosmartindent
    execute ":normal a" . a:contentStr
    setlocal smartindent

    " 最終行に不要な区切り文字が挿入されるため空行にしておく
    execute ":normal dd"
    call append(line("$"), "")
    execute ":normal G"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
