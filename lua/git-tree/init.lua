local api = vim.api
local main_buffer, main_window
local position = 0

local function center(str)
	local width = api.nvim_win_get_width(0)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

local function create_border_table(width, height)
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

local function create_window_buffer_pair(width, height, row, col)
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

local function open_window()
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

	local _, border_buf = create_window_buffer_pair(
		border_window_width,
		border_window_height,
		border_window_row,
		border_window_col
	)

	local border_lines = create_border_table(border_window_width, border_window_height)
	vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

	main_window, main_buffer = create_window_buffer_pair(
		main_window_width,
		main_window_height,
		main_window_row,
		main_window_col
	)

	vim.api.nvim_buf_set_option(main_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(main_buffer, "filetype", "git_tree")
	vim.api.nvim_win_set_option(main_window, "cursorline", true)

	api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)
	api.nvim_buf_set_lines(main_buffer, 0, -1, false, { center("What have i done?"), "", "" })
	api.nvim_buf_add_highlight(main_buffer, -1, "GitTreeHeader", 0, 0, -1)
end

local function update_view()
	-- we will use vim systemlist function which run shell
	-- command and return result as list
	local result = vim.fn.systemlist("git diff-tree --no-commit-id --name-only -r HEAD")

	-- with small indentation results will look better
	for k, v in pairs(result) do
		result[k] = "  " .. result[k]
	end

	api.nvim_buf_set_lines(main_buffer, 0, -1, false, result)
end

local function update_view(direction)
	api.nvim_buf_set_option(main_buffer, "modifiable", true)

	position = position + direction
	if position < 0 then
		position = 0
	end

	local result = vim.fn.systemlist("git diff-tree --no-commit-id --name-only -r  HEAD~" .. position)
	for k, v in pairs(result) do
		result[k] = "  " .. result[k]
	end

	api.nvim_buf_set_lines(main_buffer, 0, -1, false, {
		center("What have i done?"),
		center("HEAD~" .. position),
		"",
	})
	api.nvim_buf_set_lines(main_buffer, 3, -1, false, result)
	api.nvim_buf_add_highlight(main_buffer, -1, "GitTreeHeader", 0, 0, -1)
	api.nvim_buf_add_highlight(main_buffer, -1, "GitTreeSubHeader", 1, 0, -1)
	api.nvim_buf_set_option(main_buffer, "modifiable", false)
end

local function set_mappings()
	local mappings = {
		["["] = "update_view(-1)",
		["]"] = "update_view(1)",
		["<cr>"] = "open_file()",
		h = "update_view(-1)",
		l = "update_view(1)",
		q = "close_window()",
		k = "move_cursor()",
	}

	for k, v in pairs(mappings) do
		api.nvim_buf_set_keymap(main_buffer, "n", k, ':lua require"git-tree".' .. v .. "<cr>", {
			nowait = true,
			noremap = true,
			silent = true,
		})
	end

	local other_chars = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"i",
		"n",
		"o",
		"p",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
	}
	for k, v in ipairs(other_chars) do
		api.nvim_buf_set_keymap(main_buffer, "n", v, "", { nowait = true, noremap = true, silent = true })
		api.nvim_buf_set_keymap(main_buffer, "n", v:upper(), "", { nowait = true, noremap = true, silent = true })
		api.nvim_buf_set_keymap(
			main_buffer,
			"n",
			"<c-" .. v .. ">",
			"",
			{ nowait = true, noremap = true, silent = true }
		)
	end
end

local function close_window()
	api.nvim_win_close(main_window, true)
end

-- Our file list start at line 4, so we can prevent reaching above it
-- from bottm the end of the buffer will limit movment
local function move_cursor()
	local new_pos = math.max(4, api.nvim_win_get_cursor(main_window)[1] - 1)
	api.nvim_win_set_cursor(main_window, { new_pos, 0 })
end

-- Open file under cursor
local function open_file()
	local str = api.nvim_get_current_line()
	close_window()
	api.nvim_command("edit " .. str)
end

local function git_tree()
	position = 0 -- if you want to preserve last displayed state just omit this line
	open_window()
	set_mappings()
	update_view(0)
	api.nvim_win_set_cursor(main_window, { 4, 0 }) -- set cursor on first list entry
end

return {
	git_tree = git_tree,
	update_view = update_view,
	open_file = open_file,
	move_cursor = move_cursor,
	close_window = close_window,
}
