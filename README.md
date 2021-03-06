## ctrlp-pipe
### Usage
```vim
:CtrlPipe A --- B
```

The A will be evaluated in the `eval()`. Evaluated value is output to CtrlP.  
The B will be evaluated in the `execute`. B will be evaluated after selection by CtrlP.

------------------------------------------------------------------------------

#### ` --- `
A and B are separated by ` --- `.

* ` --- `  will run in any mode.
* ` --e `  will run in mode the case of `e`
* ` --h `  will run in mode the case of `h`
* ` --t `  will run in mode the case of `t`
* ` --v `  will run in mode the case of `v`

------------------------------------------------------------------------------

#### `C`  `S`  `T` and `_`
Variable `C`, `S`, `T` and `_` can be used in the A and B.

  * `C` is the value of CtrlPipe that became the start of the loop.
  * `S` is an array to store the string that is selected in ctrlp.
  * `T` is an array that is output to ctrlp.
  * `_` is dictionary that is utilities. Default value of `_`. this have only the function `redir()`.  
    If *g:ctrlp_pipe_module* is the dictionary, `_ <-- g:ctrlp_pipe_module`.

------------------------------------------------------------------------------

#### ` --> `

` --> ` is describe in front of the `A`.

    :CtrlPipe String --> A --- B

String is evaluated as a string. do not need to be enclosed in quotes.

`S` is initialized with `['String']`.  
Also, if `S` has become empty, S will be `['String']`.  
The initial value of the `S` of case you did not describe the String is `['']`.

------------------------------------------------------------------------------
### Introduction

First try using this command.

    :CtrlPipe v: --- echo S

Can get a mode `a:mode`

    :CtrlPipe ['A'] --- echo a:mode


Different output for each mode.

    :CtrlPipe ['C-t', 'C-x', 'C-v', 'CR'] --t echo 't' --h echo 'h' --v echo 'v' --e echo 'e' --- echo S[-1]


Repeat the command

    :CtrlPipe ['Repeat'] --- exe C

Set the initial value of `S`

    :CtrlPipe InitValue --> S --- exe C

Using the `C` then configure the loop. `<C-t>` Check the scope.

    :CtrlPipe START --> S --- exe C --t echo l:


Behaves like ctrlp-line.

    :CtrlPipe sort(map(getline(0,'$'),'v:val."\t:".(v:key+1)')) --- exe ctrlp#pipe#savePmt() | exe 'norm!' matchstr(S[-1],'\v\d+$') . 'ggzvzz' | exe C

------------------------------------------------------------------------------
### Use it as launcher.

```vim
nmap <leader><C-p> <Plug>(ctrlp-pipe)
```

For more information, please read the [plugin/pipe.vim](./plugin/ctrlp/pipe.vim)
