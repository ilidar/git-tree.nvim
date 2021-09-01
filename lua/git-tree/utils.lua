local utils = {}

function utils.center_string(width, str)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

function utils.create_border_table(width, height)
	if width <= 2 or height <= 2 then
		return nil, nil
	end
	local border_lines = { "╔" .. string.rep("═", width - 2) .. "╗" }
	local middle_line = "║" .. string.rep(" ", width - 2) .. "║"
	for i = 2, height - 1 do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, "╚" .. string.rep("═", width - 2) .. "╝")
	return border_lines
end

function utils.create_window_buffer_pair(width, height, row, col)
	local border_window_options = {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
	}
	local border_buf = vim.api.nvim_create_buf(false, true)
	local border_window = vim.api.nvim_open_win(border_buf, true, border_window_options)
	return border_window, border_buf
end

return utils
