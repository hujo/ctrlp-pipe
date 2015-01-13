scriptencoding utf-8

let s:SFILE = glob(expand('<sfile>:p:h:h:h:h') . '/plugin/ctrlp/pipe.vim')
let s:SOUCES = { s:SFILE : { 'ftime': 0 } } "{{{
"   'filepath' : {
"     'ftime': num,
"     'cmds': {
"       NAME : {
"         'name'    : str,
"         'value'   : str,
"         'comment' : str
"       }
"     }
" }, ...}
"}}}

function! s:cCout(line) abort "{{{
  let expr = matchstr(a:line, '\v^\@\zs.+\ze\@')
  if expr !=# ''
    try
      sandbox let f = eval(expr)
    catch /./
      return ctrlp#pipe#log('STARTUP[E:cCout]', '"' . a:line, v:exception, a:line, 2)
    endtry
    let line = f ? strpart(a:line, len(expr) + 2) : '"' . a:line
    let line = substitute(line, '\v^\s+', '', 'g')
    return line
  endif
  return a:line
endfunction "}}}
function! s:isComment(line) abort "{{{
  return a:line[0] =~# '\v["]'
endfunction "}}}
function! s:getComment(line) "{{{
  return matchstr(a:line, '\v"\s*\zs.+')
endfunction "}}}
function! s:newCmd(line) abort "{{{
  let before = matchstr(a:line, '\v:.+\|')
  return {
  \ 'name' : matchstr(a:line, '\v^[^\t :]+'),
  \ 'value': before ==# '' ? ':CtrlPipe ' : before . 'CtrlPipe ',
  \ 'comment': ''
  \}
endfunction "}}}
function! s:extCmd(cmdict, line) abort "{{{
  let line = substitute(a:line, '\v^\s+', '', 'g')
  return s:isComment(line)
  \   ? {'comment': join([get(a:cmdict, 'comment'), s:getComment(line)])}
  \   : {'value': join([get(a:cmdict, 'value'), line]) }
endfunction "}}}
function! s:getFiniPos(lines) "{{{
  let lines = a:lines
  for idx in range(len(lines))
    if lines[idx] =~# '\v^fini%[sh]$'
      return idx
    endif
  endfor
  return -1
endfunction "}}}
function! s:buildCmds(filepath) abort "{{{
  let is_comment = 0
  let [list, lines] = [[], readfile(a:filepath)]
  let [idx, length] = [s:getFiniPos(lines), len(lines) - 1]
  while idx < length
    let idx += 1
    let line = lines[idx]
    if line[0] !~# '\v[\t ]' && line !~# '\v^\s*$'
      let is_comment = s:isComment(line)
      if !s:isComment(line)
        let cline = s:cCout(line)
        let is_comment = s:isComment(cline)
        " Line is composed 'CC' only. It affects the next line
        if cline ==# '' | continue | endif
        if cline ==# '"' . line
          if idx < length
            let lines[idx + 1] = '"' . lines[idx + 1]
          endif
          continue
        endif
        if !is_comment
          call add(list, s:newCmd(cline))
        endif
      endif
    elseif !is_comment && line =~# '\v^\s+'
      call extend(list[-1], s:extCmd(list[-1], line))
    endif
  endwhile
  " Convert the List to Dict
  let ret = {}
  for cmd in list | let ret[cmd.name] = cmd | endfor
  return ret
endfunction "}}}
function! s:getCmds(filepath, ...) abort "{{{
  let file = a:filepath
  if !filereadable(file) | return [] | endif
  let ftime = getftime(file)
  let cache = get(
  \ (!has_key(s:SOUCES, file)
  \   ? extend(s:SOUCES, {file : {'ftime': 0 }}) : s:SOUCES ),
  \ file )
  return get(
  \ (cache.ftime < ftime
  \   ? extend(cache,
  \     {'ftime': ftime, 'cmds': extend(a:0 ? a:1 : {}, s:buildCmds(file))})
  \   : cache ),
  \ 'cmds' )
endfunction "}}}
function! s:getCmdWithName(cmdname) abort "{{{
  let file = get(g:, 'ctrlp_pipe_file', '')
  let cmds = has_key(s:SOUCES, file)
  \        ? get(s:SOUCES[file], 'cmds', {}) : {}
  let cmd = copy(get(cmds, a:cmdname, {}))
  if !empty(cmd)
    let [bef, aft] = split(cmd.value, '\v^.+\zsCtrlPipe\ze')
    let lname = 'CtrlPipe[' . a:cmdname . ']'
    let extopt = printf('cal ctrlp#pipe#opt(''lname'', ''%s'', ''not reset'') | CtrlPipe', lname)
    let cmd.value = bef . extopt . aft
  endif
  return cmd
endfunction "}}}
function! s:readLine() abort "{{{
  let file = fnamemodify(expand(get(g:, 'ctrlp_pipe_file', s:SFILE)), ':p')
  let cmds = {}
  if file !=# s:SFILE && get(g:, 'ctrlp_pipe_file_extend', 0)
    let cmds = s:getCmds(s:SFILE, cmds)
  endif
  let g:ctrlp_pipe_file = file
  return map(
  \   ctrlp#pipe#fn#fillSp(values(s:getCmds(file, cmds)), 'name'),
  \   'v:val.name . "\t" . v:val.comment'
  \)
endfunction "}}}
function! s:L2C(cmdline) "{{{
  return get(s:getCmdWithName(split(a:cmdline)[0]), 'value', '')
endfunction "}}}

function! ctrlp#pipe#mapping#register() "{{{
  if maparg('<plug>(ctrlp-pipe)') ==# ''
    nnoremap <silent><plug>(ctrlp-pipe)
    \   :<c-u>call ctrlp#pipe#opt({'type': 'tabs', 'lname': 'CtrlPipe'})
    \     <bar>CtrlPipe reverse(sort(<sid>readLine()))
    \     --- call ctrlp#pipe#exit(1) <bar> exe <sid>L2C(S[-1])<cr>
  endif
endfunction "}}}

function! ctrlp#pipe#mapping#getCmd(name) "{{{
  call s:readLine()
  return get(s:getCmdWithName(a:name), 'value', '')
endfunction "}}}

function! ctrlp#pipe#mapping#getCmdNS() "{{{
  if empty(s:getCmdWithName(a:name)) | call s:readLine() | endif
  " Todo:
  "return deepcopy()
endfunction "}}}
