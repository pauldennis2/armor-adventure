-- Moshine quest: train-direction data collection.
--
-- Detects whether trains on the Moshine surface are circling clockwise (deosil)
-- or counterclockwise (widdershins).
--
-- Sampling strategy: on_tick_3 fires 20x/sec. A new history point is only
-- recorded when the train's front_stock has moved >= MIN_SAMPLE_DISTANCE tiles
-- from the last recorded position. This makes the history angular-position-based
-- rather than time-based, so it stays valid across a wide speed range.
--
-- With MIN_SAMPLE_DISTANCE=10 on a 15-tile-radius loop (~94 tile circumference),
-- each sample step is ~38 degrees of arc. HISTORY_SIZE=8 covers ~266 degrees,
-- giving a stable circumcenter and a cross-sum with consistent sign.
--
-- Detection:
--   cross_sum: sum of 2D cross-products across all consecutive triplets in history.
--              Straight segments contribute ~0; corners accumulate a sign that
--              reflects rotation direction (positive = CW = deosil, Y-down coords).
--   fit_circle: circumscribed circle through h[1], h[4], h[8] gives loop center
--               and radius. Used to check that the data-processor is INSIDE the
--               loop (distance from center < radius * INSIDE_FACTOR).
--
-- Known limitation: if the train laps the loop within MIN_SAMPLE_DISTANCE tiles
-- of travel (i.e. circumference < MIN_SAMPLE_DISTANCE), the fit degenerates.
-- This won't happen on any reasonable Factorio loop.

local M = {}

local SURFACE_NAME        = "moshine"
local PROCESSOR_NAME      = "data-processor"
local SPEED_MIN           = 2.0    -- tiles/tick (~432 kph); ignore slow trains
local MIN_SAMPLE_DISTANCE = 10     -- tiles; min travel before recording a new sample
local HISTORY_SIZE        = 8      -- position samples kept per train
local CROSS_THRESHOLD     = 0.5    -- minimum |cross sum| to commit to a direction
local MIN_RADIUS          = 8      -- fitted circle must be at least this many tiles
local INSIDE_FACTOR       = 0.6    -- data-proc must be within this fraction of radius from center
local DEOSIL_TOKEN        = "deosil-scan-token"
local WIDDERSHINS_TOKEN   = "widdershins-scan-token"

-- Iterate slots rather than get_item_count so any quality of magnet qualifies.
local function train_has_magnet(train)
    for _, wagon in ipairs(train.cargo_wagons) do
        local inv = wagon.get_inventory(defines.inventory.cargo_wagon)
        if inv then
            for i = 1, #inv do
                local stack = inv[i]
                if stack.valid_for_read and stack.name == "magnet" then return true end
            end
        end
    end
    return false
end

-- Sum cross-products across all consecutive triplets in the position history.
-- Straight segments contribute ~0; corners accumulate a consistent-sign value.
-- In Factorio (Y increases downward): positive total = clockwise = deosil.
local function cross_sum(h)
    local total = 0
    for i = 1, #h - 2 do
        local ax = h[i+1].x - h[i].x
        local ay = h[i+1].y - h[i].y
        local bx = h[i+2].x - h[i+1].x
        local by = h[i+2].y - h[i+1].y
        total = total + (ax * by - ay * bx)
    end
    return total
end

-- Fit the unique circumscribed circle to three points.
-- Returns cx, cy, radius, or nil if the points are (near-)collinear.
local function fit_circle(p1, p2, p3)
    local ax, ay = p1.x, p1.y
    local bx, by = p2.x, p2.y
    local cx, cy = p3.x, p3.y
    local D = 2 * (ax*(by-cy) + bx*(cy-ay) + cx*(ay-by))
    if math.abs(D) < 1e-4 then return nil end
    local a2 = ax*ax + ay*ay
    local b2 = bx*bx + by*by
    local c2 = cx*cx + cy*cy
    local ux = (a2*(by-cy) + b2*(cy-ay) + c2*(ay-by)) / D
    local uy = (a2*(cx-bx) + b2*(ax-cx) + c2*(bx-ax)) / D
    local r  = math.sqrt((ax-ux)^2 + (ay-uy)^2)
    return ux, uy, r
end

-- Insert token into any data-processor inside the fitted loop that has the
-- matching recipe active and does not already hold a token.
-- Returns number of processors found inside the loop.
local function grant_token(surface, cx, cy, radius, token_name, recipe_name)
    local procs = surface.find_entities_filtered{
        name     = PROCESSOR_NAME,
        position = {x = cx, y = cy},
        radius   = radius * INSIDE_FACTOR,
    }
    for _, proc in ipairs(procs) do
        local recipe = proc.get_recipe()
        if recipe and recipe.name == recipe_name then
            local inv = proc.get_inventory(defines.inventory.assembling_machine_input)
            if inv and not inv.find_item_stack(token_name) then
                inv.insert{name = token_name, count = 1}
            end
        end
    end
    return #procs
end

function M.on_tick_3()
    local surface = game.surfaces[SURFACE_NAME]
    if not surface then return end

    storage.moshine_train_positions = storage.moshine_train_positions or {}
    local history = storage.moshine_train_positions
    local seen        = {}

    local locos     = surface.find_entities_filtered{type = "locomotive"}
    local processed = {}
    for _, loco in ipairs(locos) do
        local train = loco.train
        if not train.valid             then goto continue end
        if processed[train.id]         then goto continue end
        processed[train.id] = true
        if math.abs(train.speed) < SPEED_MIN then goto continue end

        seen[train.id] = true

        -- Distance-adaptive sampling: only record a new point when the train has
        -- moved MIN_SAMPLE_DISTANCE tiles from the last recorded position. This
        -- keeps history entries spaced in arc-length rather than wall-clock time.
        local pos = train.front_stock.position
        local h   = history[train.id] or {}
        if #h > 0 then
            local last = h[#h]
            local dx   = pos.x - last.x
            local dy   = pos.y - last.y
            if dx*dx + dy*dy < MIN_SAMPLE_DISTANCE * MIN_SAMPLE_DISTANCE then
                goto continue
            end
        end
        h[#h + 1] = {x = pos.x, y = pos.y}
        if #h > HISTORY_SIZE then table.remove(h, 1) end
        history[train.id] = h

        if #h < HISTORY_SIZE          then goto continue end
        if not train_has_magnet(train) then goto continue end

        local cross = cross_sum(h)

        if math.abs(cross) <= CROSS_THRESHOLD then goto continue end

        local cx, cy, radius = fit_circle(h[1], h[4], h[8])
        if not cx or radius < MIN_RADIUS then goto continue end

        local token, recipe
        if cross > 0 then
            token, recipe = DEOSIL_TOKEN,      "deosil-motion-data"
        else
            token, recipe = WIDDERSHINS_TOKEN, "widdershins-motion-data"
        end

        grant_token(surface, cx, cy, radius, token, recipe)

        ::continue::
    end

    for id in pairs(history) do
        if not seen[id] then
            history[id] = nil
        end
    end
end

return M
