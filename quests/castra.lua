-- Quest: SIMULAC Commander (Castra)
-- Killing enemy data-collector bases earns quality-scaled points (1-5).
-- Warning fires at WARN_THRESHOLD; commander spawns at KILL_THRESHOLD.
-- Meter drains DRAIN_PER_MIN points per minute while no commander is active.

local castra = {}

local KILL_THRESHOLD  = 50
local WARN_THRESHOLD  = 30
local DRAIN_PER_MIN   = 2
local QUALITY_POINTS  = {normal=1, uncommon=2, rare=3, epic=4, legendary=5}
local COMMANDER_NAME  = "simulac-commander"
local SPAWN_DIST      = 90  -- tiles; off-screen at normal zoom

local function find_player_on_castra(near_position)
    local best, best_d2 = nil, math.huge
    for _, player in pairs(game.players) do
        if player.character and player.character.valid
           and player.surface.name == "castra" then
            local dx = player.position.x - near_position.x
            local dy = player.position.y - near_position.y
            local d2 = dx*dx + dy*dy
            if d2 < best_d2 then best_d2 = d2; best = player end
        end
    end
    return best
end

local function spawn_commander(near_player)
    local surface = near_player.surface
    local angle   = math.random() * 2 * math.pi
    local base    = {
        x = near_player.position.x + math.cos(angle) * SPAWN_DIST,
        y = near_player.position.y + math.sin(angle) * SPAWN_DIST,
    }
    local pos = surface.find_non_colliding_position(COMMANDER_NAME, base, 20, 1)
    if not pos then pos = base end

    local commander = surface.create_entity({
        name     = COMMANDER_NAME,
        position = pos,
        force    = "enemy",
    })
    if commander and commander.valid then
        storage.simulac_commander = commander
        if commander.commandable then
            commander.commandable.set_command({
                type        = defines.command.go_to_location,
                destination = near_player.position,
                distraction = defines.distraction.by_anything,
            })
        end
    end
    game.forces["player"].print({"armor-adventure.simulac-commander-spawned"})
end

function castra.on_tick_60()
    local cmd = storage.simulac_commander
    if not cmd or not cmd.valid then return end

    -- Undodgeable laser pulse: damages any non-enemy character within 15 tiles.
    local nearby = cmd.surface.find_entities_filtered({
        type     = "character",
        position = cmd.position,
        radius   = 15,
    })
    for _, char in ipairs(nearby) do
        if char.valid and char.force.name ~= "enemy" then
            char.damage(200, "enemy", "laser", cmd)
            rendering.draw_line{
                color        = {r = 0.2, g = 0.9, b = 1.0, a = 0.85},
                width        = 4,
                from         = cmd.position,
                to           = char.position,
                surface      = cmd.surface,
                time_to_live = 20,
            }
        end
    end

    -- Refresh pursuit toward nearest player on same surface.
    if cmd.commandable then
        local nearest, dist2 = nil, math.huge
        for _, player in pairs(game.players) do
            if player.character and player.character.valid
               and player.surface == cmd.surface then
                local dx = player.position.x - cmd.position.x
                local dy = player.position.y - cmd.position.y
                local d  = dx*dx + dy*dy
                if d < dist2 then dist2 = d; nearest = player end
            end
        end
        if nearest then
            cmd.commandable.set_command{
                type        = defines.command.go_to_location,
                destination = nearest.position,
                distraction = defines.distraction.by_anything,
            }
        end
    end
end

function castra.on_tick_3600()
    local meter = storage.simulac_awaken_meter or 0
    if meter <= 0 then return end
    local drained = math.min(meter, DRAIN_PER_MIN)
    storage.simulac_awaken_meter = meter - drained
    game.forces["player"].print(
        "Castra meter drain: -" .. drained .. " points, now at " .. storage.simulac_awaken_meter)
end

function castra.on_entity_died(event)
    local ent  = event.entity
    local name = ent.name

    if name == "data-collector" then
        if ent.surface.name ~= "castra" then return end
        if ent.force.name  ~= "enemy"   then return end
        local cause = event.cause
        if not (cause and cause.valid and cause.type == "character") then return end
        if cause.surface.name ~= "castra" then return end

        local quality   = ent.quality and ent.quality.name or "normal"
        local pts       = QUALITY_POINTS[quality] or 1
        local old_meter = storage.simulac_awaken_meter or 0
        local new_meter = old_meter + pts
        storage.simulac_awaken_meter = new_meter
        game.forces["player"].print(
            "Killed a " .. quality .. " base, +" .. pts .. " castra points, you now have " .. new_meter)

        if old_meter < WARN_THRESHOLD and new_meter >= WARN_THRESHOLD then
            game.forces["player"].print({"armor-adventure.simulac-warning"})
        end

        if new_meter >= KILL_THRESHOLD then
            storage.simulac_awaken_meter = 0
            game.forces["player"].print("Castra meter reset to 0 (commander spawned).")
            local trigger_player = (cause.valid and cause.type == "character") and cause.player
                                or find_player_on_castra(ent.position)
            if trigger_player then spawn_commander(trigger_player) end
        end

    elseif name == COMMANDER_NAME then
        storage.simulac_commander = nil
        local surf      = ent.surface
        local pos       = ent.position
        local place_pos = surf.find_non_colliding_position("steel-chest", pos, 5, 0.5) or pos
        local chest     = surf.create_entity({name = "steel-chest", position = place_pos, force = "neutral"})
        if chest and chest.valid then
            chest.get_inventory(defines.inventory.chest).insert({name = "unrefined-simulac-core", count = 1})
            rendering.draw_text{
                text          = "★ SIMULAC Core",
                surface       = surf,
                target        = place_pos,
                target_offset = {0, -2.5},
                color         = {r = 1, g = 0.8, b = 0, a = 1},
                scale         = 1.5,
                alignment     = "center",
                time_to_live  = 600,
            }
        else
            surf.spill_item_stack{
                position      = pos,
                stack         = {name = "unrefined-simulac-core", count = 1},
                enable_looted = true,
            }
        end
    end
end

return castra
