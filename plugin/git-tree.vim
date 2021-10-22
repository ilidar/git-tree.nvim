if exists('g:loaded_git_tree') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link GitTreeLocalChanges Number
hi def link GitTreeCommitHash Identifier
hi def link GitTreeCommitTime Constant
hi def link GitTreeCommitAuthor String

command! GitTree lua require'git-tree'.git_tree()
command! GitTreeToggle lua require'git-tree'.git_tree_toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_git_tree = 1


augroup GitTree
    autocmd!
    autocmd VimResized * :lua require("git-tree").git_tree_on_resize()
augroup END
