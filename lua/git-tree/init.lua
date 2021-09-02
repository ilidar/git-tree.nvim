local api = vim.api
local main_buffer, main_window
local border_buffer, border_window
local utils = require("git-tree.utils")
local previous_cursor_position = -1
local M = {}

function M.set_mappings()
	local mappings = {
		h = "git_tree_on_diff_exit()",
		j = "move_cursor_down_with_limits()",
		k = "move_cursor_up_with_limits()",
		l = "show_git_diff()",
		q = "close_window()",
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
	assert(main_window == nil, "Main window should not exist")
	assert(border_window == nil, "Border window should not exist")

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

	border_window, border_buffer = utils.create_window_buffer_pair(
		border_window_width,
		border_window_height,
		border_window_row,
		border_window_col
	)

	local border_lines = utils.create_border_table(border_window_width, border_window_height)
	vim.api.nvim_buf_set_lines(border_buffer, 0, -1, false, border_lines)

	main_window, main_buffer = utils.create_window_buffer_pair(
		main_window_width,
		main_window_height,
		main_window_row,
		main_window_col
	)

	vim.api.nvim_buf_set_option(main_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(main_buffer, "filetype", "git_tree")
	vim.api.nvim_buf_set_option(main_buffer, "swapfile", false)
	vim.api.nvim_buf_set_option(border_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(border_buffer, "filetype", "git_tree")
	vim.api.nvim_buf_set_option(border_buffer, "swapfile", false)

	vim.api.nvim_win_set_option(main_window, "cursorline", true)
end

function M.close_window()
	api.nvim_win_close(main_window, true)
	api.nvim_win_close(border_window, true)

	main_window = nil
	border_window = nil
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

function M.move_cursor_up_with_limits()
	local new_pos = math.max(4, api.nvim_win_get_cursor(main_window)[1] - 1)
	api.nvim_win_set_cursor(main_window, { new_pos, 0 })
	previous_cursor_position = new_pos
end

function M.move_cursor_down_with_limits()
    local main_buffer_lines_count = api.nvim_buf_line_count(main_buffer)
	local new_pos = math.min(main_buffer_lines_count, api.nvim_win_get_cursor(main_window)[1] + 1)
	api.nvim_win_set_cursor(main_window, { new_pos, 0 })
	previous_cursor_position = new_pos
end

function M.show_git_diff()
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

function M.git_tree_on_resized()
	if main_window then
		M.close_window()
		M.open_window()
		M.refresh_git_log_buffer()
		M.set_mappings()
	end
end

function M.git_tree_on_diff_exit()
	M.refresh_git_log_buffer()
	api.nvim_win_set_cursor(main_window, { previous_cursor_position, 0 })
end

function M.git_tree()
	M.open_window()
	M.set_mappings()
	M.refresh_git_log_buffer()
	api.nvim_win_set_cursor(main_window, { 4, 0 }) -- set cursor on first list entry
end

return M
