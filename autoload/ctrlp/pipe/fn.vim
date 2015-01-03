scriptencoding utf-8
function! ctrlp#pipe#fn#_redir(...) abort "{{{
  call ctrlp#pipe#redir#s()
  redir => ret
  try
    silent exe a:1
  finally
    redir END
    call ctrlp#pipe#redir#e()
  endtry
  return exists('ret') ? ret : ''
endfunction "}}}
function! ctrlp#pipe#fn#redir(expr, ...) abort "{{{
  let ret = ctrlp#pipe#fn#_redir(a:expr)
  return a:0 && a:1 is 1 ? split(ret, '\v\r\n|\n|\r') : ret
endfunction "}}}
