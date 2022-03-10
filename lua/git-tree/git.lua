local M = {}

function M.get_commit_hash_range(str)
    local idx = string.find(str, "-")
    if not idx then
        return -1, -1
    end
    return idx - 9, idx - 2
end

function M.get_commit_time_range(str)
    local idx = string.find(str, "-")
    if not idx then
        return -1, -1
    end
    local a = string.find(str, "(", idx + 3, true)
    local b = string.find(str, ")", a + 1)
    if not a or not b then
        return -1, -1
    end
    return a - 1, b
end

function M.get_commit_author_range(str)
    local a = string.find(str, "<", 1, true)
    local b = string.find(str, ">", 1, true)
    if not a or not b then
        return -1, -1
    end
    return a - 1, b
end

function M.get_commit_branch_range(str)
    local a = string.find(str, "(", 1, true)
    local b = string.find(str, ")", 1, true)
    if not a or not b then
        return -1, -1
    end
    local x = string.find(str, "(", b + 1, true)
    if not x then
        return -1, -1
    end
    local y = string.find(str, ")", x + 1, true)
    if not y then
        return -1, -1
    end
    return a - 1, b
end

function M.get_log_lines()
    local git_log_results = vim.fn.systemlist(
        "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all --tags"
    )
    for k, _ in pairs(git_log_results) do
        git_log_results[k] = " " .. git_log_results[k]
    end
    return git_log_results
end

return M
