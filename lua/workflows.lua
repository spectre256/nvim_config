local map = vim.keymap.set

local Workflows = {}

Workflows.defaults = {
    path = nil,
    data = {
        global = {},   -- Keyed by [input]
        repos = {},    -- Keyed by [repo][input]
        branches = {}, -- Keyed by [repo][branch][input]
    },
}

function Workflows.defaults:open(path)
    self.path = path

    local handle = io.open(path, "r")
    if not handle then return true end

    local raw = handle:read("*a")
    handle:close()
    if raw == "" then return true end

    local ok, data = pcall(vim.json.decode, raw)
    if not ok then
        return false, string.format("Failed to decode %s: %s", path, data)
    end
    self.data = data
    return true
end

function Workflows.defaults:get(repo, branch, input)
    local global_value = self.data.global[input]
    local repo_value = self.data.repos[repo] and self.data.repos[repo][input]
    local branch_value = self.data.branches[repo]
        and self.data.branches[repo][branch]
        and self.data.branches[repo][branch][input]

    return branch_value or repo_value or global_value
end

-- TODO: Global/repo values go stale
function Workflows.defaults:set(repo, branch, input, value)
    self.data.global[input] = self.data.global[input] or value

    self.data.repos[repo] = self.data.repos[repo] or {}
    self.data.repos[repo][input] = self.data.repos[repo][input] or value

    self.data.branches[repo] = self.data.branches[repo] or {}
    self.data.branches[repo][branch] = self.data.branches[repo][branch] or {}
    self.data.branches[repo][branch][input] = value
end

function Workflows.defaults:save()
    if not self.path then return false, "File not open" end

    local handle = io.open(self.path, "w")
    if not handle then
        return false, string.format("Failed to open file %s", self.path)
    end
    handle:write(vim.json.encode(self.data))
    handle:close()
    return true
end

local function runCmd(cmd, ...)
    local res = vim.system({ "bash", "-c", cmd:format(...) }):wait()
    return res.stdout and res.stdout:gsub("\n$", "")
end

local function runJsonCmd(cmd, ...)
    local raw = runCmd(cmd, ...)
    return raw and raw ~= "" and vim.json.decode(raw)
end

function Workflows.run(workflow)
    if not workflow then return end

    local repo = runCmd("git config --get remote.origin.url || git rev-parse --show-toplevel")
    local branch = runCmd("git branch --show-current")
    local inputs = runJsonCmd("gh workflow view '%s' --yaml | yq '.on.workflow_dispatch.inputs'", workflow.name) or {}

    local inputs_arg = vim.iter(pairs(inputs))
        :map(function(name, opts)
            local default = Workflows.defaults:get(repo, branch, name);
            local value = coroutine.wrap(vim.ui.input)({
                default = default or opts.default,
                prompt = string.format("Enter the %s: ", (opts.description or name):lower()),
                scope = "buffer",
            }, function(v) coroutine.yield(v) end)

            if not value then coroutine.yield() end
            Workflows.defaults:set(repo, branch, name, value)
            return name, value
        end)
        :map(function(name, value)
            return string.format(" -f '%s='\"%s\"", name, value)
        end)
        :join("")

    local ok, err = Workflows.defaults:save()
    if not ok then error(err) end

    local cmd = string.format("gh workflow run '%s' --ref %s%s", workflow.name, branch, inputs_arg)
    vim.system({ "bash", "-c", cmd })
end

function Workflows.select()
    local workflows = runJsonCmd("gh workflow list --json id,name,state")
    if not workflows then return end

    local padding = vim.iter(workflows)
        :map(function(workflow) return #workflow.name end)
        :fold(0, function(acc, len) return math.max(acc, len) end)
    local format = string.format("%%-%ds  %%s  %%s", padding)

    local path = vim.fn.stdpath("state") .. "/gh_workflow_defaults.json"
    local ok, err = Workflows.defaults:open(path)
    if not ok then error(err) end

    vim.ui.select(workflows, {
        prompt = "Select workflow:",
        format_item = function(item)
            return string.format(format, item.name, item.state, item.id)
        end,
    }, coroutine.wrap(Workflows.run))
end

function Workflows.setup()
    map("n", "<Leader>gw", Workflows.select)
end

return Workflows
