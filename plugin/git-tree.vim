if exists('g:loaded_git_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link GitTreeLocalChanges      Number
hi def link GitTreeCommitHash        Identifier

command! GitTree lua require'git-tree'.git_tree()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_git_tree = 1


augroup GitTree
    autocmd!
    autocmd VimResized * :lua require("git-tree").git_tree_on_resized()
augroup END
