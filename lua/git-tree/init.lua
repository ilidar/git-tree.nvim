local function git_hist()
	vim.cmd(":split | terminal")
	local command = ':call jobsend(b:terminal_job_id, "gh -30\\n")'
	vim.cmd(command)
end

return {
	git_hist = git_hist,
}
