## ctrlp-pipe
### Usage
```vim
:CtrlPipe A --- B
```

The A will be evaluated in the `eval()`. Evaluated value is output to CtrlP.  
The B will be evaluated in the `execute`. B will be evaluated after selection by ctrlp.

------------------------------------------------------------------------------

#### ---
A and B are separated by `---`.

<dl>
  <dt>---</dt>
  <dd>It will run in any mode.</dd>
  <dt>--e</dt>
  <dd>It will run in mode the case of <code>e</code></dd>
  <dt>--h</dt>
  <dd>It will run in mode the case of <code>h</code></dd>
  <dt>--t</dt>
  <dd>It will run in mode the case of <code>t</code></dd>
  <dt>--v</dt>
  <dd>It will run in mode the case of <code>v</code></dd>
</dl>

------------------------------------------------------------------------------

#### C, S, T and _
Variable `C`, `S`, `T` and `_` can be used in the A and B.

<dl>
  <dt>C</dt>
  <dd>C, it is the value of CtrlPipe that became the start of the loop.</dd>
  <dt>S</dt>
  <dd><b>S</b> is an array to store the string that is selected in ctrlp.</dd>
  <dt>T</dt>
  <dd><b>T</b> is an array that is output to ctrlp.</dd>
  <dt><b>_</b></dt>
  <dd>
    <b>_</b> is dictionary that is utilities.<br>
    Default value of <b>_</b>. this have only the function <code>redir()</code>.<br>
    If <code>ctrlp_pipe_module</code> is the dictionary, <b>_</b> &lt;-- <code>ctrlp_pipe_module</code>.
  </dd>
</dl>

------------------------------------------------------------------------------

#### -->

`-->` is describe in front of the `A`.

``` vim
:CtrlPipe String --> A --- B
```

This is `String` is evaluated as a string.
do not need to be enclosed in quotes.

If `S` is empty value of `S` will be `["String"]`.

------------------------------------------------------------------------------
### Introduction

First try using this command.
```vim
:CtrlPipe v: --- echo S
```

Can get a mode 'a:mode'
```vim
:CtrlPipe ['A'] --- echo a:mode
```

Different output for each mode.
```vim
:CtrlPipe ['C-t', 'C-x', 'C-v', 'CR'] --t echo 't' --h echo 'h' --v echo 'v' --e echo 'e' --- echo S[-1]
```

Repeat the command
```vim
:CtrlPipe ['Repeat'] --- exe C
```

Set the initial value of `S`
```vim
:CtrlPipe InitValue --> S --- exe C
```

Using the C and then configure the loop.
`<C-t>` Check the scope.
```vim
:CtrlPipe START --> S --- exe C --t echo l:
```

Behaves like ctrlp-line.
```vim
:CtrlPipe map(getline(0, '$'), '(v:key+1).":\t".v:val') --- exe 'normal!' split(S[-1], ':')[0] . 'ggzvzz'
```

------------------------------------------------------------------------------
### Example
```vim
" Example:
" Select and open the file from v:oldfiles
" can get a mode 'a:mode'
:CtrlPipe filter(copy(v:oldfiles), 'filereadable(expand(v:val))') --- call ctrlp#acceptfile(a:mode, S[-1])

" Example:
"   reg query browse (windows)
"     <CR>  -> next
"     <C-t> -> back
:CtrlPipe HKLM --> S[-1] . system(printf('reg query "%s"', S[-1])) --t call remove(S, -2, -1) --- exe C
```

------------------------------------------------------------------------------
### Use it as launcher.

```vim
nmap <leader><C-p> <Plug>(ctrlp-pipe)
```

For more information, please read the [plugin/pipe.vim](https://github.com/hujo/ctrlp-pipe/blob/master/plugin/ctrlp/pipe.vim)
