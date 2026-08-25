-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Add your workspace rules here. Increment the workspace number as you go. Do not have duplicate workspaces.

-- 1 and 4 are the defaults for their monitors, so both come up together at login.
hl.layout.register("grid", {
    recalculate = function(ctx)
        local columns = math.ceil(math.sqrt(#ctx.targets))
        for index, target in ipairs(ctx.targets) do
            target:place(ctx:grid_cell(index, columns))
        end
    end,
})

-- Monitor 1
hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, default_name = "coding", layout = "scrolling", layout_opts = { orientation = "right" } })
hl.workspace_rule({ workspace = "2", monitor = MONITOR1, persistent = true, layout = "scrolling", layout_opts = { orientation = "right" } })
hl.workspace_rule({ workspace = "3", monitor = MONITOR1, persistent = true, layout = "scrolling", layout_opts = { orientation = "right" } })

-- Monitor 2
hl.workspace_rule({ workspace = "4", monitor = MONITOR2, default = true, persistent = true, default_name = "coding-reference", layout = "scrolling"})
hl.workspace_rule({ workspace = "5", monitor = MONITOR2, persistent = true, layout = "scrolling" })

-- Special Workspaces
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR, decorate = false, layout = "monocle" })
hl.workspace_rule({ workspace = "special:communication", monitor = MONITOR2, layout = "lua:grid" })
