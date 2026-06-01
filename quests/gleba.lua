-- Quest: Gleba (Mind Control, Harvester, Personal Tesla Turret, Demolisher Heart)

local gleba = {}

local HARVESTER_RANGE  = 10
local HP_PER_PART      = 1000
local HEART_DROP_RANGE = 75

local DART_QUALITY_MULTIPLIER = {
    normal    = 1,
    uncommon  = 2,
    rare      = 3,
    epic      = 4,
    legendary = 5,
}

local TESLA_PRIMARY_DAMAGE = {
    normal    = 25,
    uncommon  = 75,
    rare      = 150,
    epic      = 225,
    legendary = 400,
}
local TESLA_CHAIN_DAMAGE = {
    normal    = 2,
    uncommon  = 5,
    rare      = 15,
    epic      = 25,
    legendary = 75,
}

local function get_tesla_player_and_quality(event)
    local function check(player)
        if not (player and player.character and player.character.valid) then return end
        local inv = player.get_inventory(defines.inventory.character_armor)
        if not inv then return end
        local item = inv[1]
        if not (item and item.valid_for_read and item.grid) then return end
        for _, eq in ipairs(item.grid.equipment) do
            if eq.name == "personal-tesla-turret" then return player, eq.quality.name end
        end
    end
    local p, q
    if event.cause and event.cause.valid and event.cause.type == "character" then
        p, q = check(event.cause.player)
        if p then return p, q end
    end
    if event.source_entity and event.source_entity.valid and event.source_entity.type == "character" then
        p, q = check(event.source_entity.player)
        if p then return p, q end
    end
    for _, player in pairs(game.connected_players) do
        p, q = check(player)
        if p then return p, q end
    end
end

function gleba.on_script_trigger_effect(event)
    local id = event.effect_id

    if id == "mind-control-hit" then
        local target = event.target_entity
        if not target or not target.valid then return end
        if target.surface.name ~= "gleba" then return end
        if target.type ~= "unit" and target.type ~= "spider-unit" then return end
        if target.force.name ~= "enemy" then return end
        target.force = "neutral"
        if target.commandable then
            target.commandable.set_command{type = defines.command.wander, distraction = defines.distraction.none}
        end
        storage.mind_controlled = storage.mind_controlled or {}
        storage.mind_controlled[target.unit_number] = target
        local q_name = event.source_entity and event.source_entity.valid
                       and event.source_entity.quality and event.source_entity.quality.name
                       or "normal"
        storage.mc_quality = storage.mc_quality or {}
        storage.mc_quality[target.unit_number] = DART_QUALITY_MULTIPLIER[q_name] or 1
        rendering.draw_text{
            text          = "★ Mind Controlled",
            surface       = target.surface,
            target        = target,
            target_offset = {0, -2.5},
            color         = {r = 0.7, g = 0.2, b = 1.0},
            scale         = 1.2,
            alignment     = "center",
        }

    elseif id == "personal-tesla-turret-hit" or id == "personal-tesla-turret-chain-hit" then
        local target = event.target_entity
        if not (target and target.valid) then return end
        local player, quality = get_tesla_player_and_quality(event)
        if not player then return end
        quality = quality or "normal"
        local dmg_table = (id == "personal-tesla-turret-hit") and TESLA_PRIMARY_DAMAGE or TESLA_CHAIN_DAMAGE
        target.damage(dmg_table[quality] or dmg_table.normal, player.force, "electric", player.character)
    end
end

function gleba.register_harvester(entity)
    storage.harvesters   = storage.harvesters   or {}
    storage.harvester_hp = storage.harvester_hp or {}
    local uid = entity.unit_number
    storage.harvesters[uid]   = entity
    storage.harvester_hp[uid] = storage.harvester_hp[uid] or 0
    entity.set_recipe("pentapod-tissue-samples-from-biomass")
end

function gleba.unregister_harvester(entity)
    if not storage.harvesters then return end
    local uid = entity.unit_number
    storage.harvesters[uid] = nil
    if storage.harvester_hp then storage.harvester_hp[uid] = nil end
end

-- Scans all surfaces for placed harvesters and registers any that aren't tracked.
-- Called on configuration-changed to recover harvesters placed while scripts were inactive.
function gleba.rescan_harvesters()
    storage.harvesters   = storage.harvesters   or {}
    storage.harvester_hp = storage.harvester_hp or {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{name = "harvester"}) do
            if entity.valid and not storage.harvesters[entity.unit_number] then
                gleba.register_harvester(entity)
            end
        end
    end
end

function gleba.on_tick_59()
    local mc = storage.mind_controlled

    -- Harvest pass: consume nearby mind-controlled units.
    local harvesters = storage.harvesters
    if harvesters and mc then
        for h_uid, harvester in pairs(harvesters) do
            if not harvester.valid then
                harvesters[h_uid] = nil
                if storage.harvester_hp then storage.harvester_hp[h_uid] = nil end
            elseif harvester.status == defines.entity_status.no_power
                or harvester.status == defines.entity_status.low_power then
                -- unpowered: skip
            else
                local hx, hy = harvester.position.x, harvester.position.y
                local r2     = HARVESTER_RANGE * HARVESTER_RANGE
                for m_uid, mc_entity in pairs(mc) do
                    if mc_entity.valid and mc_entity.surface == harvester.surface then
                        local dx = mc_entity.position.x - hx
                        local dy = mc_entity.position.y - hy
                        if dx*dx + dy*dy <= r2 then
                            local hp  = mc_entity.health
                            local mul = storage.mc_quality and storage.mc_quality[m_uid] or 1
                            mc_entity.die()
                            mc[m_uid] = nil
                            if storage.mc_quality then storage.mc_quality[m_uid] = nil end
                            storage.harvester_hp[h_uid] = (storage.harvester_hp[h_uid] or 0) + hp * mul
                            local biomass = math.floor(storage.harvester_hp[h_uid] / HP_PER_PART)
                            if biomass > 0 then
                                storage.harvester_hp[h_uid] = storage.harvester_hp[h_uid] % HP_PER_PART
                                local inv = harvester.get_inventory(defines.inventory.assembling_machine_input)
                                if inv then inv.insert({name = "enemy-biomass", count = biomass}) end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Follow pass: refresh movement commands toward nearest player.
    if mc then
        for uid, entity in pairs(mc) do
            if not entity.valid then
                mc[uid] = nil
                if storage.mc_quality then storage.mc_quality[uid] = nil end
            else
                local nearest, dist2 = nil, math.huge
                for _, player in pairs(game.players) do
                    if player.character and player.surface == entity.surface then
                        local dx = player.position.x - entity.position.x
                        local dy = player.position.y - entity.position.y
                        local d  = dx*dx + dy*dy
                        if d < dist2 then dist2 = d; nearest = player end
                    end
                end
                if nearest and dist2 > 16 and entity.commandable then
                    entity.commandable.set_command{
                        type        = defines.command.go_to_location,
                        destination = nearest.position,
                        distraction = defines.distraction.none,
                    }
                end
            end
        end
    end
end

function gleba.on_entity_died(event)
    local ent = event.entity

    if ent.name == "harvester" then
        gleba.unregister_harvester(ent)

    elseif ent.name == "big-demolisher" then
        local nearby = ent.surface.find_entities_filtered({
            type     = "character",
            position = ent.position,
            radius   = HEART_DROP_RANGE,
        })
        if #nearby == 0 then return end
        local remains_pos = ent.surface.find_non_colliding_position("big-demolisher-remains", ent.position, 5, 0.5) or ent.position
        local remains = ent.surface.create_entity({name = "big-demolisher-remains", position = remains_pos, force = "neutral"})
        if remains and remains.valid then
            rendering.draw_text{
                text          = "★ Extract the heart",
                surface       = ent.surface,
                target        = remains,
                target_offset = {0, -3},
                color         = {r = 1, g = 0.6, b = 0, a = 1},
                scale         = 1.5,
                alignment     = "center",
                time_to_live  = 3600,
            }
        end
        game.print("[color=yellow]Big Demolisher slain! Mine its remains to extract the Demolisher Heart.[/color]")
    end
end

return gleba
