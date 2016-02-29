
let s:save_cpo = &cpoptions
set cpoptions&vim

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
  let access_token = inputsecret('esa access token for '.g:esa_team.':')
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
