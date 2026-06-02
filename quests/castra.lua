-- Quest: SIMULAC Commander (Castra)
-- Killing enemy data-collector bases earns quality-scaled points (2-7).
-- Warnings fire at LOW_WARN_THRESHOLD and WARN_THRESHOLD; commander spawns at KILL_THRESHOLD.
-- Meter drains DRAIN_PER_MIN points per minute while no commander is active.

local castra = {}

local KILL_THRESHOLD      = 30
local WARN_THRESHOLD      = 20
local LOW_WARN_THRESHOLD  = 10
local DRAIN_PER_MIN       = 2
local QUALITY_POINTS      = {normal=2, uncommon=3, rare=4, epic=5, legendary=7}
local QUALITY_ORDER   = {"legendary", "epic", "rare", "uncommon", "normal"}
local COMMANDER_NAME  = "simulac-commander"
local SMF_NAME        = "simulac-mobile-fortress"
local SMF_MIN_RANGE   = 20   -- tiles; SMF stops closing when this close to the player
local SMF_SPEED       = 0.104 -- tiles per tick (~tank speed with rocket fuel, +30%)
local SPAWN_DIST      = 90  -- tiles; off-screen at normal zoom

local function best_tap_quality(player)
    local inv = player.get_main_inventory()
    if not inv then return nil end
    for _, q in ipairs(QUALITY_ORDER) do
        if inv.find_item_stack({name = "simulac-data-tap", quality = q}) then
            return q
        end
    end
    return nil
end

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

    local tap_quality = best_tap_quality(near_player)
    if tap_quality then
        near_player.remove_item({name = "simulac-data-tap", quality = tap_quality, count = 1})
        storage.simulac_commander_quality = tap_quality
    end

    local commander = surface.create_entity({
        name     = COMMANDER_NAME,
        position = pos,
        force    = "enemy",
        quality  = tap_quality or "normal",
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

local function spawn_smf(near_player)
    local surface = near_player.surface
    local angle   = math.random() * 2 * math.pi
    local base    = {
        x = near_player.position.x + math.cos(angle) * SPAWN_DIST,
        y = near_player.position.y + math.sin(angle) * SPAWN_DIST,
    }
    local pos = surface.find_non_colliding_position(SMF_NAME, base, 30, 1)
    if not pos then pos = base end

    local smf = surface.create_entity({
        name     = SMF_NAME,
        position = pos,
        force    = "enemy",
    })
    if smf and smf.valid then
        storage.simulac_mobile_fortress = smf
        local fuel_inv = smf.get_fuel_inventory()
        if fuel_inv then fuel_inv.insert({name = "rocket-fuel", count = 20}) end
        smf.color = {r = 0.05, g = 0.55, b = 1.0, a = 1}
        if smf.grid then
            smf.grid.put({name = "fusion-reactor-equipment",    position = {0, 0}})
            smf.grid.put({name = "energy-shield-mk2-equipment", position = {4, 0}})
            smf.grid.put({name = "personal-combat-roboport",    position = {4, 2}})
        end
        game.forces["player"].print("[SMF] Simulac Mobile Fortress has deployed at " .. pos.x .. ", " .. pos.y)
    else
        game.forces["player"].print("[SMF] ERROR: create_entity returned nil — spawn failed.")
    end
end

-- Laser attack: called every 20 ticks (~3x/sec) for responsive acquisition.
function castra.on_tick_laser()
    local cmd = storage.simulac_commander
    if cmd and cmd.valid then
        local nearby = cmd.surface.find_entities_filtered({
            type     = "character",
            position = cmd.position,
            radius   = 22,
        })
        for _, char in ipairs(nearby) do
            if char.valid and char.force.name ~= "enemy" then
                char.damage(200, "enemy", "laser", cmd)
                cmd.surface.create_entity({
                    name     = "laser-beam",
                    position = cmd.position,
                    source   = cmd,
                    target   = char,
                    duration = 25,
                    force    = "enemy",
                })
            end
        end
    end

end

function castra.on_tick_59()
    local cmd = storage.simulac_commander
    if cmd and cmd.valid then
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

    -- SMF: fire cannon at nearest player within 50 tiles (~once per second).
    local smf = storage.simulac_mobile_fortress
    if smf and smf.valid then
        local nearest, dist2 = nil, math.huge
        for _, player in pairs(game.players) do
            if player.character and player.character.valid
               and player.surface == smf.surface then
                local dx = player.position.x - smf.position.x
                local dy = player.position.y - smf.position.y
                local d  = dx*dx + dy*dy
                if d < dist2 then dist2 = d; nearest = player end
            end
        end
        if nearest and dist2 < 50*50 then
            local dist = math.sqrt(dist2)
            local dx   = nearest.position.x - smf.position.x
            local dy   = nearest.position.y - smf.position.y
            local shell_pos = {
                x = smf.position.x + dx / dist * 5,
                y = smf.position.y + dy / dist * 5,
            }
            smf.surface.create_entity({
                name     = "simulac-mobile-fortress-shell",
                position = shell_pos,
                target   = nearest.character,
                speed    = 0.25,
                force    = "enemy",
            })
        end
    end
end

-- Movement: called every tick for smooth teleportation. Negligible UPS — single
-- entity lookup with immediate return when no SMF is active.
function castra.on_tick_smf()
    local smf = storage.simulac_mobile_fortress
    if not smf or not smf.valid then return end

    local nearest, dist2 = nil, math.huge
    for _, player in pairs(game.players) do
        if player.character and player.character.valid
           and player.surface == smf.surface then
            local dx = player.position.x - smf.position.x
            local dy = player.position.y - smf.position.y
            local d  = dx*dx + dy*dy
            if d < dist2 then dist2 = d; nearest = player end
        end
    end
    if not nearest then return end

    local dx = nearest.position.x - smf.position.x
    local dy = nearest.position.y - smf.position.y
    smf.orientation = (math.atan2(dx, -dy) / (2 * math.pi)) % 1
    if dist2 > SMF_MIN_RANGE * SMF_MIN_RANGE then
        local dist  = math.sqrt(dist2)
        local ratio = math.min(SMF_SPEED / dist, 1)
        smf.teleport({smf.position.x + dx * ratio, smf.position.y + dy * ratio})
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

        local inv = cause.player and cause.player.get_main_inventory()
        local has_tap = false
        if inv then
            for i = 1, #inv do
                local stack = inv[i]
                if stack.valid_for_read and stack.name == "simulac-data-tap" then
                    has_tap = true; break
                end
            end
        end
        if not has_tap then return end

        local quality   = ent.quality and ent.quality.name or "normal"
        local pts       = QUALITY_POINTS[quality] or 1
        local old_meter = storage.simulac_awaken_meter or 0
        local new_meter = old_meter + pts
        storage.simulac_awaken_meter = new_meter
        game.forces["player"].print(
            "Killed a " .. quality .. " base, +" .. pts .. " castra points, you now have " .. new_meter)

        if old_meter < LOW_WARN_THRESHOLD and new_meter >= LOW_WARN_THRESHOLD then
            game.forces["player"].print({"armor-adventure.simulac-warning-low"})
        end
        if old_meter < WARN_THRESHOLD and new_meter >= WARN_THRESHOLD then
            game.forces["player"].print({"armor-adventure.simulac-warning"})
        end

        if new_meter >= KILL_THRESHOLD then
            storage.simulac_awaken_meter = 0
            game.forces["player"].print("Castra meter reset to 0 (commander + SMF spawned).")
            local trigger_player = (cause.valid and cause.type == "character") and cause.player
                                or find_player_on_castra(ent.position)
            if trigger_player then
                spawn_commander(trigger_player)
                -- spawn_smf(trigger_player)  -- SMF design in progress, not yet functional
            end
        end

    elseif name == SMF_NAME then
        storage.simulac_mobile_fortress = nil
        game.forces["player"].print("[SMF] Simulac Mobile Fortress destroyed.")

    elseif name == COMMANDER_NAME then
        storage.simulac_commander = nil
        local surf         = ent.surface
        local pos          = ent.position
        local tap_quality  = storage.simulac_commander_quality
        storage.simulac_commander_quality = nil
        if tap_quality then
            storage.simulac_pending_core_quality = tap_quality
        end
        local place_pos = surf.find_non_colliding_position("simulac-core-remains", pos, 10, 0.5) or pos
        surf.create_entity({
            name    = "simulac-core-remains",
            position = place_pos,
            force   = "neutral",
            quality = tap_quality or "normal",
        })
        rendering.draw_text{
            text          = "★ Mine the SIMULAC Remains",
            surface       = surf,
            target        = place_pos,
            target_offset = {0, -2.5},
            color         = {r = 1, g = 0.8, b = 0, a = 1},
            scale         = 1.5,
            alignment     = "center",
            time_to_live  = 600,
        }
    end
end

return castra
