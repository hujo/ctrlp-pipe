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

command! -bang -complete=expression -nargs=* CtrlPipe call ctrlp#init(ctrlp#pipe#read(<q-args>, <bang>1))
"Todo:
"command! -complete=customlist, -nargs=? CtrlPipeDispatch

if get(g:, 'ctrlp_pipe_mapping_disable', 0)
  let &cpoptions = s:save_cpo
  unlet! s:save_cpo
  finish
endif

call ctrlp#pipe#mapping#register()

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
" The default value of "type" is "path", so change it to "line"
Line/jump :cal ctrlp#pipe#opt({'type': 'line'}) |
  " [ehtv] normal ggzvzz
  " [tail] exe
  sort(map(getline(0,'$'),'v:val."\t:".(v:key+1)'), 'i')
    --- exe 'norm!' matchstr(S[-1],'\v\d+$') . 'ggzvzz' | exe ctrlp#pipe#savePmt(ctrlp#pipe#fn#exeTail(C))

" The default value of "opmul" is 0, so change it to 1
File/old :cal ctrlp#pipe#opt({'opmul': 1}) |
  " [ehtv] acceptfile
  " [opmul][tail]
  reverse(filter(copy(v:oldfiles),'filereadable(expand(v:val))'))
    --- cal ctrlp#pipe#savePmt() | cal ctrlp#acceptfile(a:mode,S[-1]) | exe C

" if has('win32') --> enable
@has('win32')@
Sys/reg/query
  " [ehv] down [t] up
  " (reg query %s)
  ( len(S) < 2 ? extend( S, ['HKLM', 'HKCU'] ) :
      filter( [S[-1]]
            + split(system(printf('reg query "%s"',S[-1])), '\v\r\n|\n|\r'),
        'v:val !~# ''\v^\s*$'''
      )
  )
    --- if S[-1] ==# S[-2] | call remove(S, -1) | endif
    --t call remove(S, -2, -1) --- exe C

File/Filer
  " %{fnamemodify(get(ctrlp#pipe#_selection(), -1, '.'), ':p:h')}
  " DIR [[t] lcd exe tail [h] lcd exe tail lcd - [ehtv] move directory]
  " FILE [ehtv] acceptfile
  ./ --> extend(reverse(map(
          glob( S[-1] . '*', 0, 1 )
          , 'fnamemodify(v:val, '':t'') . (isdirectory(v:val) ? expand(''/'') : '''')'
         )), ['..', '.'])
    --- cal add(S, fnamemodify(join(remove(S, -2 , -1), ''), ':p'))
      | if isdirectory(S[-1])
      |   if a:mode ==# 't' | lcd `=S[-1]` | cal ctrlp#pipe#fn#exeTail() | en
      |   if a:mode ==# 'h' | cal ctrlp#pipe#fn#exeTailLcd(S[-1]) | en
      |   if a:mode ==# 'e' | cal ctrlp#pipe#fn#exeTail() | en
      |   exe C
      | elseif filereadable(S[-1])
      |   cal ctrlp#acceptfile(a:mode, S[-1])
      |   if a:mode !=# 'e' | exe ctrlp#pipe#savePmt(C) | en
      | endif

Vim/redir :call ctrlp#pipe#opt({'type': 'line'}) |
  " [t] sort
  " (Please input command!)
  ctrlp#pipe#fn#redir(insert(S, input('input command: ','','command'), 0)[0])
  --t cal ctrlp#pipe#savePmt()
    | exe 'CtrlPipe! sort(' . string(T) . ')'

Vim/color :cal ctrlp#pipe#opt({'type': 'tabs'}) |
  " [e] change colorscheme
  " [t] toggle background
  " [hv] acceptfile
  map( ctrlp#pipe#fn#fillSp(
        map( globpath( &rtp, 'colors/*.vim', 0, 1 )
      , '[fnamemodify(v:val, '':t:r''), v:val]' )
    , 0 )
  ,'join(v:val, "\t")' )
    --t let &bg = &bg[0] ==# 'l' ? 'dark' : 'light'
    --e exe 'colo' split(S[-1])[0]
    --et exe ctrlp#pipe#savePmt(C)
    --hv cal ctrlp#acceptfile(a:mode, split(S[-1], '\v[\t]')[-1])

Git/grep :call ctrlp#pipe#opt({'type': 'line'}) |
  " [ehtv] acceptfile
  " (git grep -n -e input toplevel)
    map(split(system(printf(
        'git grep --full-name -n -e %s %s'
       , map([join(map(split(input('GitGrep: ')), 'shellescape(v:val)'), ' ')], 'v:val ==# '''' ? ''.'' : v:val')[0]
       , shellescape(insert(S, matchstr(system('git rev-parse --show-toplevel'), '\v\f+') . '/', 0)[0])
    )), '\v\r\n|\r|\n'), 'join(insert(split(v:val, ''\v^\S+:\d+\zs:''), "\t", 1), "")')
  --- cal ctrlp#pipe#savePmt()
    | let fline = split(split(S[-1])[0], '\v^\S+\zs:\ze\d+')
    | cal ctrlp#acceptfile(a:mode, S[0] . fline[0], fline[-1])
    | exe join([split(C, '\vCtrlPip' . 'e\zs\s')[0], S[0] . ' -->', 'T', '--- ' . split(C, '\s--' . '-\zs\s')[-1]])

Git/log/diff :cal ctrlp#pipe#opt({'type': 'line'}) |
  " [ehtv] open git diff buffer
  reverse(split(iconv(system('git log --pretty=format:"%h %s %ad" --date=relative'), 'utf-8', &enc), '\v\r\n|\n|\r'))
    --e if '' !=# expand('%') | new | else | %delete _ | endif
    --t tabnew --v vnew --h new
    --- call setline(1, systemlist(printf('git diff %s', split(S[-1])[0])))
      | setl buftype=nofile bufhidden=hide noswapfile nobuflisted
      | setf diff

Git/file/ls :cal ctrlp#pipe#opt({'opmul': 1}) |
  " [ehtv] acceptfile
  " [opmul]
  system('git ls-files') --- cal ctrlp#acceptfile(a:mode,S[-1])

Vim/cmd :cal ctrlp#pipe#opt({'type': 'tabs'}) |
  " [htv] acceptfile > search()
  " [e] :Comd
  reverse(sort(map(ctrlp#pipe#fn#fillSp(map (
    split(join(_.redir('verbose com', 1)[1:], "\n"), '\v\s*Last set from \f+\zs\n')
  , '[
        matchstr(v:val, ''\v\C!?\s*\zs[A-Z][A-Za-z0-9]*'')
      , matchstr(v:val, ''\v\f+$'')
    ]'
  ), 0), 'join(v:val, "\t")')))
    --htv let S[-1] = map(split(S[-1], "\t"), 'substitute(v:val, ''\v^\s+|\s+$'', '''', ''g'')')
      | cal ctrlp#acceptfile(a:mode, S[-1][1], '')
      | cal search(printf('\v\Ccom%[mand]!?.+(<%s>|(\n\s*\\.+)+<%s>)', S[-1][0], S[-1][0]), 'cW')
    --htv exe ctrlp#pipe#savePmt(C)
    --e cal feedkeys(':' . matchstr(S[-1], '\v\w+') . ' ', 'n')

Hist/cmd :cal ctrlp#pipe#opt({'type': 'line'}) |
  ctrlp#pipe#fn#redir('his :',1)[1:-1]
  " [e] feedkeys [h] execute [t] histdel
    --- cal add(S,str2nr(matchstr(S[-1], '\v\d+')))
    --e cal feedkeys(':' . histget(':',S[-1]), 'nt')
    --h exe histget(':', S[-1])
    --t cal ctrlp#pipe#savePmt() | cal histdel(':',S[-1]) | exe C

Hist/search :cal ctrlp#pipe#opt({'type': 'line'}) |
  " [e] feedkeys [t] histdel
  ctrlp#pipe#fn#redir('his /',1)[1:-1]
    --- call add(S,str2nr(matchstr(S[-1], '\v\d+')))
    --e cal feedkeys('/' . histget('search', S[-1]), 'nt')
    --t cal ctrlp#pipe#savePmt() | cal histdel('/',S[-1]) | exe C
