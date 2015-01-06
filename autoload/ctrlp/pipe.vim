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
function! s:doExp(mode, str) abort "{{{
  call ctrlp#pipe#_selection(a:str)
  for [k, v] in s:ACTION
    if k ==# a:mode || k ==# '-'
      call ctrlp#pipe#expr#excute(v, a:mode)
    endif
  endfor
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
function! s:getWithType(dict, key, B, ...) abort "{{{
  let val = get(a:dict, a:key, a:B)
  return !a:0 ? type(val) is type(a:B) ? val : a:B
  \           : type(val) isnot type(a:B) ? val : a:B
endfunction "}}}

if !exists('s:ID') " INIT {{{
  let s:pipe_core =  {
  \ 'init'  : 'ctrlp#pipe#init()',
  \ 'accept': 'ctrlp#pipe#accept',
  \ 'exit'  : 'ctrlp#pipe#exit()',
  \ 'sname' : 'pipe',
  \}
  let s:pipe_opt = map({
  \ 'lname' : 'pipe',
  \ 'nolim' : 1,
  \ 'type'  : 'path',
  \}, 's:getWithType(g:, ''ctrlp_pipe_default_'' . v:key, v:val)')

  call add(g:ctrlp_ext_vars, extend(copy(s:pipe_core), s:pipe_opt))

  let [s:IDX, s:ID] = [len(g:ctrlp_ext_vars) - 1, g:ctrlp_builtins + len(g:ctrlp_ext_vars)]
  let [s:LOG, s:TARGET, s:ACTION, s:RETRY, s:COMMAND, s:SAVEOPT] = [[], [], [], 0, '', '']

endif "}}}

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
  return cmd ==# '' ? ''
  \ : printf('cal ctrlp#pipe#opt(%s) |', s:SAVEOPT) . 'CtrlPipe ' . cmd
endfunction "}}}
function! ctrlp#pipe#log(...) abort "{{{
  if a:0 == 1
    call add(s:LOG, {
    \ 'A': s:toP(a:1),
    \ 'C': s:toP(get(s:, 'COMMAND')),
    \ 'S': s:toP(get(s:, 'SELECTION')),
    \ 'T': s:toP(get(s:, 'TARGET'))
    \})
    return a:1
  elseif a:0 && a:[a:0]
    call add(s:LOG, { 'A' : deepcopy(a:) })
    return a:[a:[a:0]]
  endif
  return deepcopy(s:LOG)
endfunction "}}}
function! ctrlp#pipe#init(...) abort "{{{
  let b:ctrlp_clear_cache_on_exit = 1
  return reverse(copy(s:TARGET))
endfunction "}}}
function! ctrlp#pipe#exit(...) abort "{{{
  if a:0 && a:1 is 1
    let [s:RETRY, s:TARGET] = [0, []]
  endif
  if s:RETRY is 0
    let g:ctrlp_ext_vars[s:IDX] = extend(copy(s:pipe_core), s:pipe_opt)
  endif
  " ctrlp#call() ?
  let mdata = get(ctrlp#getvar('s:'), 'mdata', [])
  if get(mdata, 1, 0) is s:ID | call remove(mdata, 0, -1) | endif
endfunction "}}}
function! ctrlp#pipe#opt(keyOrDict, ...) abort "{{{
  let Ext = g:ctrlp_ext_vars[s:IDX]
  let [trg, t] = [deepcopy(a:keyOrDict), type(a:keyOrDict)]
  if t is type('')
    if !a:0 | return deepcopy(get(Ext, trg, '')) | endif
    let Ext[trg] = s:getWithType(Ext, trg, a:1, 'isnot')
    return a:1
  elseif t is type({})
    call map(trg, 'ctrlp#pipe#opt(v:key, v:val)')
    return get(a:000, 0, '')
  elseif t is 0
    return filter(deepcopy(Ext), '!has_key(s:pipe_core, v:key)')
  endif
  return ''
endfunction "}}}
function! ctrlp#pipe#accept(mode, str) abort "{{{
  let s:RETRY = 0 | call ctrlp#exit()
  let s:RETRY = 1 | call s:doExp(a:mode, a:str)
  let s:RETRY = 0 | call ctrlp#pipe#exit()
endfunction "}}}
function! ctrlp#pipe#read(line) abort "{{{
  let line = substitute(a:line, '\v(\r|\n)$', '', 'g')
  if !s:RETRY
    let [s:COMMAND, s:SAVEOPT] = [line, string(ctrlp#pipe#opt(0))]
  endif
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
  let tmp = split(body, '\v\s+--\ze[thev-]\s+')
  let body = remove(tmp, 0)
  for t in tmp
    call add(pats, [t[0], substitute(strpart(t, 1), '\v^\s+', '', 'g')])
  endfor
  unlet! tmp
  " }}}
  if !s:RETRY || !exists('s:SELECTION') || empty(s:SELECTION)
    let s:SELECTION = [input]
  endif
  " {{{
  let [s:TARGET, s:ACTION] = [s:toT(ctrlp#pipe#expr#eval(body)), pats]
  " }}}
  return s:ID
endfunction "}}}

let &cpoptions = s:save_cpo
unlet! s:save_cpo
