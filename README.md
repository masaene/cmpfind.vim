# cmpfind.vim

## install
    cp ./autoload/bsw.vim /usr/share/vim/vim8.x/autoload
    cp ./plugin/bsw.vim /usr/share/vim/vim8.x/plugin
    
## usage
ctrl-h:call 'CmpFind' command and wait input a part of filename.
1. press return key, if input string can specify filename.<br>
execute ':edit <filename>'
2. press tab key, if input string can not specify filename.<br>
will complete filename.
  
## example
file structure
    abc1.txt
    abc2.txt
    dir1
    -abc3.txt
    dir2
    -abc4.txt

input a part of filename.

    :CmpFind abc

press <TAB> key.
  
    abc1.txt abc2.txt abc3.txt abc4.txt
    :CmpFind abc1.txt

input a part of filname.

    :CmpFind 3

press <CR> key.
  
    :edit abc3.txt -> change buffer.
