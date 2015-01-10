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
function! ctrlp#pipe#fn#savePmt(...) "{{{
  return join(ctrlp#getvar('s:prompt'), '')
endfunction "}}}
function! ctrlp#pipe#fn#fillSp(itemList, label, ...) "{{{
  let [o, k] = [deepcopy(a:itemList), a:label]
  for i in range(len(o))
    let o[i][k] = substitute(get(o[i], k, ''), '\v^\s+|\s+$', '', 'g')
  endfor
  let ls = map(copy(o),
  \     (exists('*strdisplaywidth')
  \       ? 'strdisplaywidth' : 'strlen')
  \     . '(get(v:val, k, ''''))')
  let mx = max(ls)
  for i in range(len(o))
    let o[i][k] = o[i][k] . repeat(' ', mx - ls[i])
  endfor
  return !a:0 ? o : map(range(a:0), 'ctrlp#pipe#fn#fillSp(o, a:000[v:key])')[-1]
endfunction "}}}
