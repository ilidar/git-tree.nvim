local api = vim.api
local log_window_buffer, log_window
local diff_window_buffer, diff_window
local utils = require("git-tree.utils")
local previous_cursor_position = -1
local M = {}

function M.set_mappings()
	-- TODO: create event functions
	local mappings = {
		h = "git_tree_on_diff_exit()",
		j = "move_cursor_down_with_limits()",
		k = "move_cursor_up_with_limits()",
		l = "show_git_diff()",
		q = "close_window()",
	}

	for k, v in pairs(mappings) do
		api.nvim_buf_set_keymap(log_window_buffer, "n", k, ':lua require"git-tree".' .. v .. "<cr>", {
			nowait = true,
			noremap = true,
			silent = true,
		})
	end
end

-- TODO: refactor
function M.open_window()
	assert(log_window == nil, "Main window should not exist")

	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local h = math.ceil(height * 0.8 - 4)
	local w = math.ceil(width * 0.8)
	local r = math.ceil((height - h) / 2 - 1)
	local c = math.ceil((width - w) / 2)

	local log_window_height = math.floor(h / 2)
	local log_window_width = w
	local log_window_row = r
	local log_window_col = c

	local diff_window_height = math.floor(h / 2)
	local diff_window_width = w
	local diff_window_row = r + log_window_height + 2
	local diff_window_col = c

	diff_window, diff_window_buffer = utils.create_window_buffer_pair(
		diff_window_width,
		diff_window_height,
		diff_window_row,
		diff_window_col
	)

	log_window, log_window_buffer = utils.create_window_buffer_pair(
		log_window_width,
		log_window_height,
		log_window_row,
		log_window_col
	)

	vim.api.nvim_buf_set_option(log_window_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(log_window_buffer, "filetype", "git_tree")
	vim.api.nvim_buf_set_option(log_window_buffer, "swapfile", false)

	vim.api.nvim_buf_set_option(diff_window_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(diff_window_buffer, "filetype", "git_tree")
	vim.api.nvim_buf_set_option(diff_window_buffer, "swapfile", false)

	vim.api.nvim_win_set_option(log_window, "cursorline", true)
end

function M.close_window()
	api.nvim_win_close(log_window, true)
	api.nvim_win_close(diff_window, true)

	log_window = nil
	diff_window = nil
end

function M.refresh_git_log(buffer)
	local git_log_results = vim.fn.systemlist(
		"git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all --tags"
	)
	for k, v in pairs(git_log_results) do
		git_log_results[k] = " " .. git_log_results[k]
	end

	api.nvim_buf_set_option(buffer, "modifiable", true)
	api.nvim_buf_set_lines(buffer, 0, -1, false, {
		"   Local changes",
	})
	api.nvim_buf_set_lines(buffer, 4, -1, false, git_log_results)
	api.nvim_buf_add_highlight(buffer, -1, "GitTreeLocalChanges", 0, 0, -1)
	for k, v in pairs(git_log_results) do
		local commit_hash_from, commit_hash_to = M.get_commit_hash_range(v)
		if commit_hash_from ~= -1 then
			api.nvim_buf_add_highlight(buffer, -1, "GitTreeCommitHash", k, commit_hash_from, commit_hash_to)
		end
	end
	api.nvim_buf_set_option(buffer, "modifiable", false)
end

function M.move_cursor_up_with_limits()
	local new_pos = math.max(1, api.nvim_win_get_cursor(log_window)[1] - 1)
	api.nvim_win_set_cursor(log_window, { new_pos, 0 })
	previous_cursor_position = new_pos

	M.show_git_diff_inline()
end

function M.move_cursor_down_with_limits()
	local main_buffer_lines_count = api.nvim_buf_line_count(log_window_buffer)
	local new_pos = math.min(main_buffer_lines_count, api.nvim_win_get_cursor(log_window)[1] + 1)
	api.nvim_win_set_cursor(log_window, { new_pos, 0 })
	previous_cursor_position = new_pos

	M.show_git_diff_inline()
end

function M.get_commit_hash_range(str)
	local index_of_star = string.find(str, "*")
	if not index_of_star then
		return -1, -1
	end
	return index_of_star + 1, index_of_star + 8
end

function M.show_git_diff()
	local str = api.nvim_get_current_line()
	local git_diff_results
	local commit_hash_from, commit_hash_to = M.get_commit_hash_range(str)
	if commit_hash_from ~= -1 then
		local commit_hash_str = string.sub(str, commit_hash_from, commit_hash_to)
		git_diff_results = vim.fn.systemlist("git diff " .. commit_hash_str .. "~1")
	else
		git_diff_results = vim.fn.systemlist("git diff")
	end
	api.nvim_buf_set_option(log_window_buffer, "modifiable", true)
	api.nvim_buf_set_option(log_window_buffer, "filetype", "diff")
	api.nvim_buf_set_lines(log_window_buffer, 0, -1, false, git_diff_results)
	api.nvim_buf_set_option(log_window_buffer, "modifiable", false)
end

function M.show_git_diff_inline()
	local str = api.nvim_get_current_line()
	local git_diff_results
	local commit_hash_from, commit_hash_to = M.get_commit_hash_range(str)
	if commit_hash_from ~= -1 then
		local commit_hash_str = string.sub(str, commit_hash_from, commit_hash_to)
		git_diff_results = vim.fn.systemlist("git diff " .. commit_hash_str .. "~1")
	else
		git_diff_results = vim.fn.systemlist("git diff")
	end
	api.nvim_buf_set_option(diff_window_buffer, "modifiable", true)
	api.nvim_buf_set_option(diff_window_buffer, "filetype", "diff")
	api.nvim_buf_set_lines(diff_window_buffer, 0, -1, false, git_diff_results)
	api.nvim_buf_set_option(diff_window_buffer, "modifiable", false)
end

function M.git_tree_on_resized()
	if log_window then
		M.close_window()
		M.open_window()
		M.refresh_git_log(log_window_buffer)
		M.set_mappings()
	end
end

function M.git_tree_on_diff_exit()
	M.refresh_git_log(log_window_buffer)
	api.nvim_win_set_cursor(log_window, { previous_cursor_position, 0 })
end

function M.git_tree()
	M.open_window()
	M.set_mappings()
	M.refresh_git_log(log_window_buffer)
	api.nvim_win_set_cursor(log_window, { 1, 0 }) -- set cursor on first list entry
end

function M.git_tree_toggle()
	if log_window then
		M.close_window()
	else
		M.git_tree()
	end
end

return M
