-- Panglia quest: nuking a speed zone destroys the hidden beacons and yields
-- essence-of-speed nodes after the blast settles.

local HAS_PANGLIA = script.active_mods["panglia_planet"] ~= nil

local M = {}

local SPAWN_DELAY = 300  -- ticks; nodes appear after blast settles (~5 s)

function M.on_script_trigger_effect(event)
    if not HAS_PANGLIA then return end
    if event.effect_id ~= "armor_adventure_nuke_on_panglia" then return end

    local surface = game.surfaces[event.surface_index]
    if not surface or surface.name ~= "panglia" then return end

    -- target_position is the rocket impact point; source_position may be the launcher.
    local pos = event.target_position or event.source_position
    if not pos then return end

    -- Load all beacons on the surface into a grid keyed by rounded tile position.
    -- Panglia places beacons at 1-tile intervals, so rounding to nearest integer works.
    local all_beacons = surface.find_entities_filtered{name = "panglia_hidden_beacon"}
    if #all_beacons == 0 then return end

    local grid = {}
    for _, beacon in pairs(all_beacons) do
        local gx = math.floor(beacon.position.x + 0.5)
        local gy = math.floor(beacon.position.y + 0.5)
        if not grid[gx] then grid[gx] = {} end
        grid[gx][gy] = beacon
    end

    -- Find the beacon nearest to the impact point.
    local nearest, nearest_d2 = nil, math.huge
    for gx, col in pairs(grid) do
        for gy, beacon in pairs(col) do
            local dx, dy = gx - pos.x, gy - pos.y
            local d2 = dx * dx + dy * dy
            if d2 < nearest_d2 then nearest_d2, nearest = d2, beacon end
        end
    end
    if not nearest then return end

    -- BFS flood-fill: collect the entire contiguous zone touching the impact point.
    -- 8-directional adjacency; beacons 1 tile apart are in the same zone.
    local queue = {nearest}
    local found = {}
    local sx = math.floor(nearest.position.x + 0.5)
    local sy = math.floor(nearest.position.y + 0.5)
    found[sx .. "," .. sy] = true

    local head = 1
    while head <= #queue do
        local curr = queue[head]; head = head + 1
        if curr.valid then
            local cx = math.floor(curr.position.x + 0.5)
            local cy = math.floor(curr.position.y + 0.5)
            for dx = -1, 1 do
                local nx = cx + dx
                if grid[nx] then
                    for dy = -1, 1 do
                        if dx ~= 0 or dy ~= 0 then
                            local ny = cy + dy
                            local key = nx .. "," .. ny
                            if not found[key] and grid[nx][ny] then
                                found[key] = true
                                table.insert(queue, grid[nx][ny])
                            end
                        end
                    end
                end
            end
        end
    end

    -- Destroy all beacons in the zone (no loot — we spawn essence nodes instead).
    local positions = {}
    for _, beacon in pairs(queue) do
        if beacon.valid then
            table.insert(positions, {x = beacon.position.x, y = beacon.position.y})
            beacon.destroy()
        end
    end

    if #positions == 0 then return end

    storage.panglia_pending_essence = storage.panglia_pending_essence or {}
    table.insert(storage.panglia_pending_essence, {
        surface_index = surface.index,
        positions     = positions,
        spawn_tick    = game.tick + SPAWN_DELAY,
    })
end

function M.on_tick_59()
    if not HAS_PANGLIA then return end
    local pending = storage.panglia_pending_essence
    if not pending or #pending == 0 then return end

    local tick = game.tick
    for i = #pending, 1, -1 do
        local entry = pending[i]
        if tick >= entry.spawn_tick then
            local surface = game.surfaces[entry.surface_index]
            if surface then
                for j, bpos in ipairs(entry.positions) do
                    surface.set_tiles({{name = "panglia-volcanic-ash-dark", position = bpos}})
                    if j % 200 == 1 then
                        surface.create_entity{
                            name     = "panglia-essence-node",
                            position = bpos,
                            force    = "neutral",
                        }
                    end
                end
            end
            table.remove(pending, i)
        end
    end
end

return M
