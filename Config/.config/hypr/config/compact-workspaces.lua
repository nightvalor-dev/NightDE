-- Keep workspaces gap-free.
-- When a workspace is left empty (you close its last window or move it away),
-- every window on a higher-numbered workspace shifts down to fill the gap:
--   1 [kitty]  2 [code]  3 [brave]   -- close code ->   1 [kitty]  2 [brave]
-- Special (scratchpad) workspaces are left alone.

local busy = false

local function compact()
    if busy then return end
    busy = true

    local ok, err = pcall(function()
        -- Numbered workspaces that still have windows, in order
        local used = {}
        for _, ws in ipairs(hl.get_workspaces()) do
            if not ws.special and ws.id and ws.id >= 1 and ws.windows > 0 then
                table.insert(used, ws.id)
            end
        end
        table.sort(used)

        local active = hl.get_active_workspace()
        local active_id = active and active.id
        local follow_to = nil

        -- used[1] -> 1, used[2] -> 2, ...
        for target, id in ipairs(used) do
            if id ~= target then
                for _, w in ipairs(hl.get_windows()) do
                    if w.workspace and w.workspace.id == id then
                        hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = w }))
                    end
                end
                if id == active_id then follow_to = target end
            end
        end

        -- If the workspace you were looking at moved, follow it
        if follow_to then
            hl.dispatch(hl.dsp.focus({ workspace = follow_to }))
        end
    end)

    busy = false
    if not ok then print("compact-workspaces: " .. tostring(err)) end
end

-- Run shortly after the event, once Hyprland has finished updating its state
local function later()
    hl.timer(compact, { timeout = 120, type = "oneshot" })
end

hl.on("window.close", later)
hl.on("window.move_to_workspace", later)
