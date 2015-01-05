scriptencoding utf-8

" Description: {{{1
"
"   This plugin is a plugin to extend the easy 'ctrlp'.
"   Insert the various things to 'ctrlp'.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variable:
"
" *g:ctrlp_pipe_disable*
"   please set the 0 to 'ctrlp_pipe_disable' if you want disable this plug.
"
" *g:ctrlp_pipe_mapping_disable*
"   please set the 0 to 'ctrlp_pipe_mapping_disable' if you do not want plug mapping.
"
" *g:ctrlp_pipe_file*
"   set the file to read. The default is this file.
"   Please refer to the sample of this file to reference how to write files.
"
" *g:ctrlp_pipe_file_extend*
"   if you set 1 in this variable. extend 'ctrlp_pipe_file' with sample in this file.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Command:
"   CtrlPipe
"     See: ../../README.md
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mapping:
" This file set mapping
"   nnoremap <silent><Plug>(ctrlp-pipe)
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Usage:
"   nmap <leader><C-p> <Plug>(ctrlp-pipe)
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Todo:
"   * opmul : OpenMulti
"       use b:ctrlp_* ???
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" Vimscript {{{1
let s:save_cpo = &cpoptions
let &cpoptions = s:save_cpo

if get(g:, 'ctrlp_pipe_disable', 0)
  let &cpoptions = s:save_cpo
  unlet! s:save_cpo
  finish
endif

command! -complete=expression -nargs=* CtrlPipe call ctrlp#init(ctrlp#pipe#read(<q-args>))

if get(g:, 'ctrlp_pipe_mapping_disable', 0)
  let &cpoptions = s:save_cpo
  unlet! s:save_cpo
  finish
endif

let s:SFILE = expand('<sfile>:p')
" s:FILES {{{
" s:FILES = {
"   FILEPATH : {
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
let s:FILES = { s:SFILE : { 'ftime': 0 } }
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
  \ (!has_key(s:FILES, file)
  \   ? extend(s:FILES, {file : {'ftime': 0 }}) : s:FILES ),
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
  let cmds = has_key(s:FILES, file)
  \        ? get(s:FILES[file], 'cmds', {}) : {}
  return get(cmds, a:cmdname, {})
endfunction "}}}
function! s:readLine() abort "{{{
  let file = fnamemodify(expand(get(g:, 'ctrlp_pipe_file', s:SFILE)), ':p')
  let cmds = {}
  if file !=# s:SFILE && get(g:, 'ctrlp_pipe_file_extend', 0)
    let cmds = s:getCmds(s:SFILE, cmds)
  endif
  let cmds = s:getCmds(file, cmds)
  let g:ctrlp_pipe_file = file
  return map( values(cmds), 'v:val.name . "\t" . v:val.comment' )
endfunction "}}}
function! s:L2C(cmdline) "{{{
  return get(s:getCmdWithName(split(a:cmdline)[0]), 'value', '') . "\n"
endfunction "}}}

nnoremap <silent><plug>(ctrlp-pipe)
\   :<c-u>call ctrlp#pipe#opt({'type': 'tabs'})
\     <bar>CtrlPipe sort(<sid>readLine())
\     --- call ctrlp#pipe#exit(1) <bar> exe <sid>L2C(S[-1])<cr>

let &cpoptions = s:save_cpo
unlet! s:save_cpo
finish


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Example: {{{1
"
"  Subsequent lines of rows that only written 'finish' will be loaded.
"  It is read from the beginning of the file if the row is not found.
"  It may be useful when it is set to the file name extension 'vim'.
"
">
"NAME :{before1} | {before2} | {beforeN...} |
"  BODY
"    BODY
"    BODY ....
"<
"
" * NAME should not indent
"     * Please use only 'A-Za-z0-9_/\' characters to NAME.
"     * If you use the other characters, It may not work, suddenly.
"
" * {before} is the command to be executed before the command.
"     * Please put the ':' at the beginning of the line.
"     * Please put the '|' at the end of the line.
"     Please write if necessary.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CommentOut:
" This is comment. commented out by placing the first '"' of the line.
  commentout
    commentout
    "This is comment.
  Up to the line, which is not indented, up to the line that has not been commented out

" CC: Conditional Commentout
" '@expr@NAME' if expr is fasle comment out NAME

@0@This is Commentout

@0@
This is Commentout

@1!=1@Commentout
    This is Commentout

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" Sample: {{{2
" The default value of "type" is "path", so change it to "tabe"
line/jump :cal ctrlp#pipe#opt({'type': 'tabe'}) |
  sort(map(getline(0,'$'),'substitute(v:val, ''\t'', '' '', ''g'')."\t".(v:key+1)'))
    --- exe 'norm' matchstr(S[-1],'\v\d+$').'ggzvzz'

" The default value of "opmul" is 0, so change it to 1
file/old :cal ctrlp#pipe#opt({'opmul': 1}) |
  " [ehtv] ctrlp#acceptfile
  " 'opmul': true
  reverse(filter(copy(v:oldfiles),'filereadable(expand(v:val))'))
    --- call ctrlp#acceptfile(a:mode,S[-1])

" if has('win32') --> enable
@has('win32')@
sys/win/reg/query :cal ctrlp#pipe#opt({'type': 'file'}) |
  " (reg query %s) [t] UP [ehv] DOWN
  HKLM --> filter( [S[-1]]
               + split(system(printf('reg query "%s"',S[-1])), "\n"),
             'v:val !~# ''\v^\s*$'''
           )
    --- if S[-1] ==# S[-2] | call remove(S, -1) | endif
    --t call remove(S, -2, -1) --- exe C

Filer
  " [t] lcd (dir)
  " [ehtv] ctrlp#acceptfile
  ./ --> extend(map(glob(S[-1].'*',0,1),
          'fnamemodify(v:val,'':t'') . (isdirectory(v:val) ? ''/'' : '''')'
         ), ['..', '.'])
    --- exe isdirectory(get(add(S,fnamemodify(S[-2].S[-1],':p')),-1))
              ? get({'t': 'lcd ' . S[-1]}, a:mode, C )
            : ctrlp#acceptfile(a:mode,S[-1])

Redir :call ctrlp#pipe#opt({'type': 'line'}) |
  " Please input command!
  _.redir(insert(S, input('input command: ','','command'), 0)[0])

Git/grep/e :call ctrlp#pipe#opt({'type': 'tab'}) |
  " git grep -n -E shellescape(input()) --- [ehtv] ctrlp#acceptfile
  map( split( system( printf( 'git grep -n -E %s',
            map( [input('GitGrep: ')], 'v:val ==# '''' ? '''' : shellescape(v:val)' )[0] ) ), "\n" ),
      'join(reverse(split(v:val, ''\v^\f+:\d+\zs:'')), "\t")' )
  --- call call( 'ctrlp#acceptfile',
        [a:mode] + split( split( S[-1] )[-1], '\v:\ze\d+$' ) )

Git/log/diff :cal ctrlp#pipe#opt({'type': 'line'}) |
  " [ehtv] open git diff buffer
  reverse(systemlist('git log --pretty=format:"%h %s %ad" --date=relative'))
    --e if '' !=# expand('%') | new | else | %delete _ | endif
    --t tabnew --v vnew --h new
    --- call setline(1, systemlist(printf('git diff %s', split(S[-1])[0])))
      | setl buftype=nofile bufhidden=hide noswapfile nobuflisted
      | setf diff

Git/file/ls :cal ctrlp#pipe#opt({'opmul': 1}) |
  " [ehtv] ctrlp#acceptfile
  " 'opmul': true
  system('git ls-files') --- call ctrlp#acceptfile(a:mode,S[-1])

hist/cmd :cal ctrlp#pipe#opt({'type': 'line'}) |
  _.redir('his :',1)[1:-2]
  " [e] execute [h] histdel
    --- cal add(S,str2nr(split(S[-1])[0]))
    --h cal histdel(':',S[-1]) | exe C
    --e exe histget(':',S[-1])

hist/search :cal ctrlp#pipe#opt({'type': 'line'}) |
  " [e] /select value [h] histdel
  _.redir('his /',1)[1:-2]
    --- call add(S,str2nr(split(S[-1])[0]))
    --e cal feedkeys('/' . histget('search', S[-1]), 't')
    --h cal histdel('/', S[-1]) | exe C

Log :cal ctrlp#pipe#opt({'type': 'line', }) |
  " Viewing the error log.
  (len(S) < 2 ? ctrlp#pipe#log() : get(ctrlp#pipe#log(), S[-1], []))
  --- if len(S) > 2 | call remove(S, -1)
             | else | let S[-1] = split(S[-1])[0] | endif
  --t call remove(S, -1)
  --- exe C


" Test: {{{2
@get(g:, 'ctrlp_pipe_debug', 0)@
TEST_S
  Test S --> S --- exe C

@get(g:, 'ctrlp_pipe_debug', 0)@
TEST_T
  extend(T, S) --- exe C

@get(g:, 'ctrlp_pipe_debug', 0)@
TEST_ST
  A --> extend(extend(T, S), T) --t echo S --e exe C
