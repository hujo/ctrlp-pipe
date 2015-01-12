scriptencoding utf-8
function! ctrlp#pipe#expr#excute(expr, mode) abort "{{{
  for [k, v] in ctrlp#pipe#expr#items() | let {k} = v | unlet! k | unlet! v | endfor
  try
    execute a:expr
  catch /./
    cal ctrlp#pipe#log([v:exception, a:expr])
    return 0
  endtry
  return 1
endfunction "}}}
function! ctrlp#pipe#expr#eval(...) abort "{{{
  for [k, v] in ctrlp#pipe#expr#items() | let {k} = v | unlet! k | unlet! v | endfor
  try
    return eval(a:1)
  catch /./
    return ctrlp#pipe#log([v:exception, a:1])
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
