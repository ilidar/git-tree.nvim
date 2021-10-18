local M = {}

function M.center_string(width, str)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

function M.create_window_buffer_pair(width, height, row, col)
	local border_window_options = {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
        border = {"╔", "═" ,"╗", "║", "╝", "═", "╚", "║"}
	}
	local border_buf = vim.api.nvim_create_buf(false, true)
	local border_window = vim.api.nvim_open_win(border_buf, true, border_window_options)
	return border_window, border_buf
end

return M
