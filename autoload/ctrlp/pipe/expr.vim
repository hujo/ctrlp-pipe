scriptencoding utf-8
function! ctrlp#pipe#expr#excute(expr) abort "{{{
  let a:mode = ctrlp#pipe#_mode()
  for [k, v] in ctrlp#pipe#expr#items() | let {k} = v | unlet! k | unlet! v | endfor
  try
    execute a:expr
  catch /./
    cal ctrlp#pipe#expr#cleanScope(
    \     ctrlp#pipe#log([v:exception, a:expr]))
    return 0
  endtry
  return 1
endfunction "}}}
function! ctrlp#pipe#expr#eval(...) abort "{{{
  let a:mode = ctrlp#pipe#_mode()
  for [k, v] in ctrlp#pipe#expr#items() | let {k} = v | unlet! k | unlet! v | endfor
  try
    return ctrlp#pipe#expr#cleanScope(eval(a:1))
  catch /./
    return ctrlp#pipe#expr#cleanScope(
    \       ctrlp#pipe#log([v:exception, a:1]))
  endtry
endfunction "}}}
function! ctrlp#pipe#expr#items() abort "{{{
  let ret = {}
  let ret._ = {'redir': function('ctrlp#pipe#fn#redir')}
  if type(get(g:, 'ctrlp_pipe_module', 0)) is type({})
    call extend(ret._, g:ctrlp_pipe_module)
  endif
  let ret.S = ctrlp#pipe#_selection()
  let ret.T = ctrlp#pipe#_target()
  let ret.C = ctrlp#pipe#_command()
  return items(ret)
endfunction "}}}
function! ctrlp#pipe#expr#cleanScope(...) "{{{
  for k in keys(s:)
    cal remove(s:, k)
    unlet! s:{k}
  endfor
  return get(a:000, -1, '')
endfunction "}}}
function! ctrlp#pipe#expr#extendScope(dict) "{{{
  cal extend(s:, deepcopy(a:dict))
endfunction "}}}
