-- Parses Factorio energy strings like "240kW", "20kJ", or bare numbers.
local function parse_energy(val)
  if type(val) == "number" then return val end
  if type(val) ~= "string" then return 0 end
  if val == "infinite" then return math.huge end
  local num = tonumber(val:match("^([%d%.]+)")) or 0
  local prefix = val:match("^[%d%.]+([kMGTP]?)")
  local mult = {k=1e3, K=1e3, M=1e6, G=1e9, T=1e12, P=1e15}
  return num * (mult[prefix] or 1)
end

-- Poll all energy-shield-equipment prototypes (excluding our own) for the best stats.
local best_hp    = 0
local best_regen = 0  -- HP/second

for name, eq in pairs(data.raw["energy-shield-equipment"] or {}) do
  if name ~= "regenerative-plating" then
    best_hp = math.max(best_hp, eq.max_shield_value or 0)

    local cost = parse_energy(eq.energy_per_shield or 0)
    local flow = (eq.energy_source and parse_energy(eq.energy_source.input_flow_limit or 0)) or 0
    if cost > 0 and flow > 0 and flow ~= math.huge then
      best_regen = math.max(best_regen, flow / cost)
    end
  end
end

-- Fallback to vanilla mk1 baseline (50 HP, 240kW/20kJ = 12 HP/sec)
if best_hp    == 0 then best_hp    = 50 end
if best_regen == 0 then best_regen = 12 end

local REGEN_SECONDS = 900

local our_hp    = math.floor(best_hp * 10)
local our_regen = math.max(1, math.ceil(our_hp / REGEN_SECONDS))

-- Minimum-cost energy source: 1J per HP, buffer just large enough to fill the shield,
-- flow limit set to exactly what the target regen rate requires.
local regen = data.raw["energy-shield-equipment"]["regenerative-plating"]
if regen then
  regen.max_shield_value = our_hp
  regen.energy_per_shield = "1J"
  regen.energy_source = {
    type = "electric",
    buffer_capacity = our_hp .. "J",
    input_flow_limit = our_regen .. "W",
    usage_priority = "secondary-input",
  }
end
