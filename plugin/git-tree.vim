if exists('g:loaded_git_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link GitTreeHeader      Number
hi def link GitTreeSubHeader   Identifier

command! GitTree lua require'git-tree'.git_tree()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_git_tree = 1
