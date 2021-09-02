local api = vim.api
local main_buffer, main_window
local utils = require("git-tree.utils")
local M = {}

local function set_mappings()
	local mappings = {
		["<cr>"] = "open_file()",
		h = "update_view()",
		l = "update_view()",
		q = "close_window()",
		k = "move_cursor_up_with_limits()",
	}

	for k, v in pairs(mappings) do
		api.nvim_buf_set_keymap(main_buffer, "n", k, ':lua require"git-tree".' .. v .. "<cr>", {
			nowait = true,
			noremap = true,
			silent = true,
		})
	end
end

function M.open_window()
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local main_window_height = math.ceil(height * 0.8 - 4)
	local main_window_width = math.ceil(width * 0.8)
	local main_window_row = math.ceil((height - main_window_height) / 2 - 1)
	local main_window_col = math.ceil((width - main_window_width) / 2)

	local border_window_height = main_window_height + 2
	local border_window_width = main_window_width + 2
	local border_window_row = main_window_row - 1
	local border_window_col = main_window_col - 1

	local _, border_buf = utils.create_window_buffer_pair(
		border_window_width,
		border_window_height,
		border_window_row,
		border_window_col
	)

	local border_lines = utils.create_border_table(border_window_width, border_window_height)
	vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

	main_window, main_buffer = utils.create_window_buffer_pair(
		main_window_width,
		main_window_height,
		main_window_row,
		main_window_col
	)

	vim.api.nvim_buf_set_option(main_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(main_buffer, "filetype", "git_tree")
	vim.api.nvim_win_set_option(main_window, "cursorline", true)

	api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)
end

function M.refresh_git_log_buffer()
	local git_log_results = vim.fn.systemlist(
		"git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all --tags"
	)
	for k, v in pairs(git_log_results) do
		git_log_results[k] = " " .. git_log_results[k]
	end

	api.nvim_buf_set_option(main_buffer, "modifiable", true)
	api.nvim_buf_set_lines(main_buffer, 0, -1, false, {
		utils.center_string(api.nvim_win_get_width(0), "Git Tree"),
		utils.center_string(api.nvim_win_get_width(0), "v0.0.1"),
		"",
		"   Local changes",
	})
	api.nvim_buf_set_lines(main_buffer, 4, -1, false, git_log_results)
	api.nvim_buf_add_highlight(main_buffer, -1, "GitTreeHeader", 0, 0, -1)
	api.nvim_buf_add_highlight(main_buffer, -1, "GitTreeSubHeader", 1, 0, -1)
	api.nvim_buf_set_option(main_buffer, "modifiable", false)
end

function M.close_window()
	api.nvim_win_close(main_window, true)
end

function M.move_cursor_up_with_limits()
	local new_pos = math.max(4, api.nvim_win_get_cursor(main_window)[1] - 1)
	api.nvim_win_set_cursor(main_window, { new_pos, 0 })
end

function M.open_file()
	local str = api.nvim_get_current_line()
	local git_diff_results
	-- TODO: i know it's shit, but lets keep it for now
	if str == "   Local changes" then
		git_diff_results = vim.fn.systemlist("git diff")
	else
		local index_of_star = string.find(str, "*")
		local commit_hash_str = string.sub(str, index_of_star + 2, index_of_star + 8)
		git_diff_results = vim.fn.systemlist("git diff " .. commit_hash_str .. "~1")
	end
	api.nvim_buf_set_option(main_buffer, "modifiable", true)
	api.nvim_buf_set_option(main_buffer, "filetype", "diff")
	api.nvim_buf_set_lines(main_buffer, 0, -1, false, git_diff_results)
	api.nvim_buf_set_option(main_buffer, "modifiable", false)
end

function M.git_tree()
	M.open_window()
	set_mappings()
	M.refresh_git_log_buffer()
	api.nvim_win_set_cursor(main_window, { 4, 0 }) -- set cursor on first list entry
end

return M
