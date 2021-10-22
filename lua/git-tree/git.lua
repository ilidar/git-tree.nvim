local M = {}

function M.get_commit_hash_range(str)
	local idx = string.find(str, "-")
	if not idx then
		return -1, -1
	end
	return idx - 9, idx - 2
end

return M
