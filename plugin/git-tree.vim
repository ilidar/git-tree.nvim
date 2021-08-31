if exists('g:loaded_git_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link WhidHeader      Number
hi def link WhidSubHeader   Identifier

command! GitTree lua require'git-tree'.whid()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_git_tree = 1
