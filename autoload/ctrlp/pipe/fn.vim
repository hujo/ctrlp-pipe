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
function! ctrlp#pipe#fn#fillSp(itemList, label, ...) abort "{{{
  let [o, k] = [deepcopy(a:itemList), a:label]
  for i in range(len(o))
    if len(o[i]) > k
      let o[i][k] = substitute(get(o[i], k, ''), '\v^\s+|\s+$', '', 'g')
    endif
  endfor
  let ls = map(copy(o),
  \     (exists('*strdisplaywidth')
  \       ? 'strdisplaywidth' : 'strlen')
  \     . '(get(v:val, k, ''''))')
  let mx = max(ls)
  for i in range(len(o))
    if len(o[i]) > k
      let o[i][k] = o[i][k] . repeat(' ', mx - ls[i])
    endif
  endfor
  return !a:0 ? o : map(range(a:0), 'ctrlp#pipe#fn#fillSp(o, a:000[v:key])')[-1]
endfunction "}}}
function! ctrlp#pipe#fn#flatArr(arr) abort "{{{
  let ret = []
  for val in a:arr
    if     type(val) is type([]) | call extend(ret, ctrlp#pipe#fn#flatArr(val))
    elseif type(val) is type({}) | call extend(ret, ctrlp#pipe#fn#flatArr(values(val)))
    else                         | call add(ret, val)
    endif
    unlet! val
  endfor
  return ret
endfunction "}}}
function! ctrlp#pipe#fn#exeOrder(...) abort "{{{
  for cmd in ctrlp#pipe#fn#flatArr(deepcopy(a:000))
    if !ctrlp#pipe#expr#excute(cmd) | return 0 | endif
  endfor
  return 1
endfunction "}}}
function! ctrlp#pipe#fn#evalLcd(lcd, expr) abort "{{{
  if !isdirectory(a:lcd) | throw a:lcd . ' is not directory' | endif
  let cwd = getcwd()
  lcd `=a:lcd`
  let ret = ctrlp#pipe#expr#eval(a:expr)
  lcd `=cwd`
  return ret
endfunction "}}}
function! ctrlp#pipe#fn#getTail(...) abort "{{{
  let tail = ctrlp#call('s:tail')
  return tail[stridx(tail, '+') + 1 :]
endfunction "}}}
function! ctrlp#pipe#fn#exeTail(...) abort "{{{
  let tail = ctrlp#pipe#fn#getTail()
  let exprs = ctrlp#pipe#fn#flatArr(deepcopy(a:000))
  let ret = empty(exprs) ? '' : remove(exprs, -1)
  if ctrlp#pipe#fn#exeOrder(exprs) && tail !=# ''
    cal ctrlp#pipe#expr#excute(tail)
  endif
  return ret
endfunction "}}}
function! ctrlp#pipe#fn#exeTailLcd(lcd, ...) abort "{{{
  if !isdirectory(a:lcd) | throw a:lcd . ' is not directory' | endif
  let exprs = ctrlp#pipe#fn#flatArr(deepcopy(a:000))
  if empty(exprs) | call add(exprs, '') | endif
  let cwd = getcwd()
  lcd `=a:lcd`
  let ret = ctrlp#pipe#fn#exeTail(exprs)
  lcd `=cwd`
  return ret
endfunction "}}}
