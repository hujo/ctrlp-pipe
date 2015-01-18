scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

if get(g:, 'loaded_ctrlp_pipe', 0)
  let &cpoptions = s:save_cpo
  unlet! s:save_cpo
  finish
endif
let g:loaded_ctrlp_pipe = 1


function! s:toP(val, ...) abort "{{{
  let t = type(a:val)
  if type('') == t | return a:0 ? string(a:val) : a:val | endif
  if type(10) == t | return a:val | endif
  if type({}) == t ||
  \  type([]) == t | return s:toP(string(a:val)) | endif
  return string(a:val)
endfunction "}}}
function! s:toT(expr) abort "{{{
  let t = type(a:expr)
  if     t == type('') | return split(a:expr, '\v\r\n|\n|\r')
  elseif t == type([]) | return map(copy(a:expr), 's:toP(v:val)')
  elseif t == type({}) | return values(map(copy(a:expr), 'string(v:key) . '': '' . s:toP(v:val, 1)'))
  endif
  return []
endfunction "}}}
function! s:getExt() abort "{{{
  if !exists('s:Ext')
    let s:Ext = {}
  endif
  return s:Ext
endfunction "}}}
function! s:resetExt() abort "{{{
  for k in keys(s:getExt())
    cal remove(s:Ext, k)
  endfor
  return extend(s:Ext, extend(copy(s:pipe_core), s:pipe_opt))
endfunction "}}}
function! s:doExp(str) abort "{{{
  call ctrlp#pipe#_selection(a:str)
  let acts = []
  for [k, v] in s:ACTION
    if k ==# ctrlp#pipe#_mode() || k ==# '-'
      call add(acts, v)
    endif
  endfor
  return ctrlp#pipe#fn#exeOrder(acts)
endfunction "}}}
function! s:parseCmdLine(line) abort "{{{
  " Todo:
  " regexp:
  "  case of separator in the string
  "      '\v"([^\"]|\\.)*"'
  "      '\v''(''''|[^''])*'''
  "
  " return: [input, body, pats]
  "   input --> body --- pats
  "     pats = [[mode, expr], [mode, expr]]
endfunction "}}}
function! s:trashBuf() abort "{{{
  let cbnr = bufnr('$')
  for bnr in range(1, cbnr - 1)
    if getbufvar(bnr, 'ctrlp_pipe_buffer') is 1
      exe bnr . 'bwipeout!'
    endif
  endfor
endfunction "}}}


function! ctrlp#pipe#_selection(...) abort "{{{
  let ret = get(s:, 'SELECTION', [''])
  if a:0 | call add(ret, a:1) | endif
  return ret
endfunction "}}}
function! ctrlp#pipe#_target(...) abort "{{{
  return get(s:, 'TARGET', [''])
endfunction "}}}
function! ctrlp#pipe#_command(...) abort "{{{
  let cmd = get(s:, 'COMMAND', '')
  return cmd ==# '' ? '' : 'CtrlPipe! ' . cmd
endfunction "}}}
function! ctrlp#pipe#_mode(...) abort "{{{
  return s:MODE
endfunction "}}}


function! ctrlp#pipe#log(...) abort "{{{
  if a:0 == 1
    call add(s:LOG, [
    \  s:toP(a:1)
    \, s:toP(get(s:, 'SELECTION', ''))
    \, s:toP(get(s:, 'COMMAND', ''))
    \])
    return a:1
  elseif a:0 && a:[a:0]
    call ctrlp#pipe#log(values(deepcopy(a:))[:-2])
    return a:[a:[a:0]]
  endif
  return deepcopy(s:LOG)
endfunction "}}}
function! ctrlp#pipe#opt(targ, ...) abort "{{{
  cal ctrlp#pipe#reset(get(a:000, 1, 0))
  let Ext = s:getExt()
  let [trg, t] = [deepcopy(a:targ), type(a:targ)]
  if t is type('')
    if a:0 == 0 | return deepcopy(get(Ext, trg, '')) | endif
    let Ext[trg] = deepcopy(a:1)
  elseif t is type({})
    call extend(Ext, trg, get(a:000, 0, 'force'))
  endif
endfunction "}}}
function! ctrlp#pipe#reset(...) abort "{{{
  if a:0 && a:1 is 0 | return | endif
  call s:resetExt()
  let s:SELECTION = []
  let s:TARGET  = []
  let s:ACTION  = []
  let s:MODE    = ''
  let s:COMMAND = ''
  let s:SAVEPMT = {}
endfunction "}}}
function! ctrlp#pipe#savePmt(...) abort "{{{
  let s:SAVEPMT.prompt = ctrlp#getvar('s:prompt')
  let lnum = 0
  if has_key(s:SAVEPMT, 'jump_lnum')
    let lnum = remove(s:SAVEPMT, 'jump_lnum')
  endif
  if lnum && ctrlp#getvar('s:nolim')
    while getchar(0) | endwhile
    cal feedkeys(lnum . 'G', 'n')
  endif
  return a:0 ? a:1 : ''
endfunction "}}}
function! ctrlp#pipe#id(...) abort "{{{
  return s:ID
endfunction "}}}
function! ctrlp#pipe#init(...) abort "{{{
  let b:ctrlp_pipe_buffer = 1
  if !empty(s:SAVEPMT)
    call extend(ctrlp#getvar('s:'), s:SAVEPMT)
  endif
  return reverse(copy(s:TARGET))
endfunction "}}}
function! ctrlp#pipe#read(line, is_reset) abort "{{{
  if a:is_reset | cal ctrlp#pipe#reset() | endif
  let line = substitute(a:line, '\v(\r|\n)$', '', 'g')
  let s:COMMAND = line
  " Todo:
  "  See: s:parseCmdLine()
  " let [input, s:TARGET, s:ACTION] = s:parseCmdLine(line)
  " {{{
  let pats = []
  if match(line, '\V\s\+-->\s\+') != -1
    let tmp = split(line, '\V\s\+-->\s\+')
    let input = remove(tmp, 0)
    let body = join(tmp, '')
    unlet! tmp
  else
    let [input, body] = ['', line]
  endif
  let tmp = split(body, '\v\s+--\ze-\s+|\s+--\ze[thev]{1,3}\s+')
  let body = remove(tmp, 0)
  for t in tmp
    for i in range(stridx(t, ' '))
      call add(pats, [t[i], substitute(t, '\v^(-|[thev]{1,3})\s+', '', 'g')])
    endfor
  endfor
  unlet! tmp
  " }}}
  if empty(s:SELECTION)
    let s:SELECTION = [input]
  endif
  " {{{
  let [s:TARGET, s:ACTION] = [s:toT(ctrlp#pipe#expr#eval(body)), pats]
  " }}}
  return s:ID
endfunction "}}}
function! ctrlp#pipe#exit(...) abort "{{{
  let mdata = get(ctrlp#getvar('s:'), 'mdata', [])
  if get(mdata, 1, 0) is s:ID | call remove(mdata, 0, -1) | endif
  call s:trashBuf()
endfunction "}}}
function! ctrlp#pipe#accept(mode, str) abort "{{{
  let s:SAVEPMT.jump_lnum = line('.')
  let s:MODE = a:mode
  call ctrlp#exit()
  call s:doExp(a:str)
  call ctrlp#pipe#exit()
endfunction "}}}

if !exists('s:ID') " {{{
  let s:pipe_core =  {
  \ 'init'  : 'ctrlp#pipe#init()',
  \ 'accept': 'ctrlp#pipe#accept',
  \ 'exit'  : 'ctrlp#pipe#exit()',
  \ 'sname' : 'pipe',
  \}
  let s:pipe_opt = {
  \ 'lname' : 'pipe',
  \ 'nolim' : 1,
  \ 'type'  : 'path',
  \ 'opmul' : 0
  \}

  cal ctrlp#pipe#reset()
  call add(g:ctrlp_ext_vars, s:getExt())
  let [s:IDX, s:ID, s:LOG] = [len(g:ctrlp_ext_vars) - 1, g:ctrlp_builtins + len(g:ctrlp_ext_vars), []]

endif "}}}

let &cpoptions = s:save_cpo
unlet! s:save_cpo
