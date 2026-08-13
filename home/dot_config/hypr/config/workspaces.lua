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

hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, layout = "scrolling", default_name = "coding"})
hl.workspace_rule({ workspace = "2", monitor = MONITOR1, persistent = true, layout = "scrolling"})
hl.workspace_rule({ workspace = "3", monitor = MONITOR1, persistent = true, layout = "scrolling" })
hl.workspace_rule({ workspace = "4", monitor = MONITOR2, default = true, persistent = true, default_name = "coding-reference", layout = "scrolling"})
hl.workspace_rule({ workspace = "5", monitor = MONITOR2, persistent = true, layout = "scrolling" })

hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR, decorate = false })
hl.workspace_rule({ workspace = "special:communication", monitor = MONITOR2, layout = "lua:grid" })

-- Dwindle has no per-workspace split ratio, so the two-column workspaces are
-- sized from events instead: the listed window is squeezed to `fraction` of the
-- usable width and dwindle hands the remainder to its neighbour.
local columns = {
    [1] = { class = "com.mitchellh.ghostty", side = "left", fraction = 2 / 9 },
    [4] = { class = "todoist", side = "right", fraction = 2 / 9 },
}

local function arrangeColumns()
    for id, spec in pairs(columns) do
        local windows = hl.get_windows({ workspace = id, floating = false, mapped = true })
        if #windows == 2 then
            local target, other = windows[1], windows[2]
            if other.class == spec.class then
                target, other = other, target
            end

            -- Matching y means a plain left/right split, the only case worth touching.
            if target.class == spec.class and target.at.y == other.at.y then
                local wantLeft = spec.side == "left"
                if (target.at.x < other.at.x) ~= wantLeft then
                    hl.dispatch(hl.dsp.window.move({ direction = wantLeft and "l" or "r", window = target }))
                end

                -- The delta moves the shared border rightwards, so it inverts on the right column.
                local delta = math.floor((target.size.x + other.size.x) * spec.fraction) - target.size.x
                hl.dispatch(hl.dsp.window.resize({
                    x = wantLeft and delta or -delta,
                    y = 0,
                    relative = true,
                    window = target,
                }))
            end
        end
    end
end

-- Deferred because the layout has not placed the window yet when the event fires.
local function scheduleArrange()
    hl.timer(arrangeColumns, { timeout = 100, type = "oneshot" })
end

hl.on("window.open", scheduleArrange)
hl.on("window.move_to_workspace", scheduleArrange)
hl.on("window.close", scheduleArrange)
