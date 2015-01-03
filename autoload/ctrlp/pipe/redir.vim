scriptencoding utf-8
function! ctrlp#pipe#redir#s() abort
  let [s:list, &list] = [&list, 0]
endfunction
function! ctrlp#pipe#redir#e() abort
  let &list = s:list
endfunction
