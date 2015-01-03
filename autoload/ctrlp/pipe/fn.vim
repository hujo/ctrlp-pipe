scriptencoding utf-8
function! ctrlp#pipe#fn#_redir(...) abort "{{{
  let ret = ''
  redir => ret
  try
    silent exe a:1
  finally
    redir END
    return ret
  endtry
endfunction "}}}
function! ctrlp#pipe#fn#redir(expr, ...) abort "{{{
  call ctrlp#pipe#redir#s()
  let ret = ctrlp#pipe#fn#_redir(a:expr)
  call ctrlp#pipe#redir#e()
  return a:0 && a:1 is 1 ? split(ret, '\v\r\n|\n|\r') : ret
endfunction "}}}
