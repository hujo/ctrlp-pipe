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
  let [pmt, lazy] = [join(ctrlp#getvar('s:prompt'), ''), &lazyredraw]
  if a:0 && !type(a:1) | let pmt .= a:1 | endif
  let templ = 'set lazyredraw | cal feedkeys(''%s'') | let &lazyredraw = %d'
  return pmt ==# '' ? '' : printf(templ, pmt, lazy)
endfunction "}}}
function! ctrlp#pipe#fn#fillSp(itemList, label) "{{{
  let [o, k] = [a:itemList, a:label]
  let ls = map(copy(o),
  \     (exists('*strdisplaywidth')
  \       ? 'strdisplaywidth' : 'strlen')
  \     . '(v:val[k])')
  let [mx, o] = [max(ls), deepcopy(o)]
  for i in range(len(o))
    let o[i][k] = o[i][k] . repeat(' ', mx - ls[i])
  endfor
  return o
endfunction "}}}
