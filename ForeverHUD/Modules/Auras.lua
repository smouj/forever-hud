--[[ ForeverHUD :: Auras
     Buffs and debuffs with icon, stacks and cooldown sweep. ]]
local ADDON, ns = ...
local L = ns.L

local groups = {}
local module = { groups = groups }

local DEBUFF_COLORS = {
  Magic = { 0.20, 0.60, 1.00 },
  Curse = { 0.60, 0.00, 1.00 },
  Disease = { 0.60, 0.40, 0.00 },
  Poison = { 0.00, 0.65, 0.00 },
  Bleed = { 0.85, 0.15, 0.15 },
}

local function GetTime_()
  return (GetTime and GetTime()) or 0
end

local function PackAura(data)
  if not data then return nil end
  return {
    name = data.name,
    icon = data.icon,
    count = data.applications or data.count or 0,
    duration = data.duration or 0,
    expirationTime = data.expirationTime or 0,
    dispelName = data.dispelName,
    spellId = data.spellId,
  }
end

local function ReadAura(unit, index, filter)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    return PackAura(C_UnitAuras.GetAuraDataByIndex(unit, index, filter))
  end
  if not UnitAura then return nil end
  local name, icon, count, dispelName, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, filter)
  if not name then return nil end
  return {
    name = name, icon = icon, count = count or 0,
    duration = duration or 0, expirationTime = expirationTime or 0,
    dispelName = dispelName, spellId = spellId,
  }
end

local function Collect(group, limit, showPermanent)
  local list = {}
  if ns.preview.active then
    local source = ns.preview.auras[group.key] or {}
    local start = ns.preview.auras.start or GetTime_()
    for index = 1, math.min(#source, limit) do
      local aura = source[index]
      list[#list + 1] = {
        name = aura.name, icon = aura.icon, count = aura.count or 0,
        duration = aura.duration or 0,
        expirationTime = (aura.expirationTime and aura.expirationTime > 0) and aura.expirationTime or (start + (aura.duration or 0)),
        dispelName = aura.dispelName,
      }
    end
    return list
  end

  if not UnitExists or not UnitExists(group.unit) then return list end

  local function accept(aura)
    if not aura or not aura.name then return false end
    if not showPermanent and (aura.duration or 0) == 0 then return false end
    return true
  end

  if AuraUtil and AuraUtil.ForEachAura then
    local ok = pcall(AuraUtil.ForEachAura, group.unit, group.filter, nil, function(aura)
      local packed = PackAura(aura)
      if accept(packed) then
        list[#list + 1] = packed
      end
      return #list >= limit
    end, true)
    if ok then return list end
  end

  for index = 1, limit + 8 do
    local aura = ReadAura(group.unit, index, group.filter)
    if not aura then break end
    if accept(aura) then list[#list + 1] = aura end
    if #list >= limit then break end
  end
  return list
end

local function SortAuras(list)
  table.sort(list, function(a, b)
    local da, db = a.duration or 0, b.duration or 0
    if (da == 0) ~= (db == 0) then return db == 0 end
    if da == 0 then return (a.name or "") < (b.name or "") end
    return (a.expirationTime or 0) < (b.expirationTime or 0)
  end)
end

local function CreateAuraButton(group)
  local button = CreateFrame("Frame", nil, group, "BackdropTemplate")
  button:SetSize(32, 32)
  ns:ApplyBackdrop(button, { 0.02, 0.02, 0.03, 0.85 }, ns.theme.border)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
  icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  button.icon = icon

  local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
  cooldown:SetAllPoints(icon)
  cooldown:SetDrawEdge(false)
  cooldown:SetHideCountdownNumbers(true)
  button.cooldown = cooldown

  local count = ns:CreateText(button, 11, ns.theme.text, "OUTLINE")
  count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
  count:SetJustifyH("RIGHT")
  button.count = count

  button:Hide()
  return button
end

local function CreateGroup(key, unit, filter, positionPrefix)
  local group = CreateFrame("Frame", "ForeverHUD_Auras_" .. key, UIParent)
  group.key = key
  group.unit = unit
  group.filter = filter
  group.positionPrefix = positionPrefix
  group.buttons = {}
  group.displayed = 0
  for index = 1, 24 do
    group.buttons[index] = CreateAuraButton(group)
  end
  return group
end

local function ApplyGroup(group, cfg, positionPrefix)
  local scale = ns:Get("general.scale", 1)
  group:SetScale(scale ~= 1 and scale or 1)
  local size = cfg.size or 32
  local spacing = cfg.spacing or 4
  local perRow = math.max(1, cfg.perRow or 10)

  for index, button in ipairs(group.buttons) do
    button:SetSize(size, size)
    button:ClearAllPoints()
    local column = (index - 1) % perRow
    local row = math.floor((index - 1) / perRow)
    button:SetPoint("TOPLEFT", group, "TOPLEFT", column * (size + spacing), -row * (size + spacing))
  end

  local limit = ns:Clamp(cfg.maxAuras or 24, 1, #group.buttons)
  local rows = math.ceil(limit / perRow)
  group:SetSize(perRow * size + (perRow - 1) * spacing, rows * size + (rows - 1) * spacing)

  local point = cfg[positionPrefix .. "Point"] or "CENTER"
  local x = cfg[positionPrefix .. "X"] or 0
  local y = cfg[positionPrefix .. "Y"] or 0
  group:ClearAllPoints()
  group:SetPoint(point, UIParent, point, x, y)

  ns:MakeMovable(group, "auras", positionPrefix)
  ns:RegisterMovable(group)
  group:EnableMouse(not ns:Get("general.locked", true))
end

local function RefreshGroup(group)
  local cfg = ns:Get("auras")
  if not cfg or not cfg.enabled then
    group:Hide()
    return
  end
  local enabled = true
  if group.key == "playerBuffs" then enabled = cfg.buffs
  elseif group.key == "playerDebuffs" then enabled = cfg.debuffs
  elseif group.key == "targetDebuffs" then enabled = cfg.targetDebuffs end

  if not enabled then
    group:Hide()
    return
  end

  local limit = ns:Clamp(cfg.maxAuras or 24, 1, #group.buttons)
  local list = Collect(group, limit, cfg.permanent)
  SortAuras(list)

  for index, button in ipairs(group.buttons) do
    local aura = list[index]
    if aura then
      button.icon:SetTexture(aura.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      if (aura.count or 0) > 1 then
        button.count:SetText(tostring(aura.count))
      else
        button.count:SetText("")
      end
      local color = DEBUFF_COLORS[aura.dispelName or ""] or ns.theme.border
      button:SetBackdropBorderColor(color[1], color[2], color[3], 1)
      if (aura.duration or 0) > 0 and (aura.expirationTime or 0) > 0 then
        local start = aura.expirationTime - aura.duration
        button.cooldown:SetCooldown(start, aura.duration)
        button.cooldown:Show()
      else
        button.cooldown:Clear()
        button.cooldown:Hide()
      end
      button:Show()
    else
      button:Hide()
    end
  end
  group.displayed = #list
  if #list > 0 then group:Show() else group:Hide() end
end

function module:Initialize()
  groups.playerBuffs = CreateGroup("playerBuffs", "player", "HELPFUL", "buff")
  groups.playerDebuffs = CreateGroup("playerDebuffs", "player", "HARMFUL", "debuff")
  groups.targetDebuffs = CreateGroup("targetDebuffs", "target", "HARMFUL", "target")
end

function module:Apply()
  local cfg = ns:Get("auras")
  if not cfg then return end
  ApplyGroup(groups.playerBuffs, cfg, "buff")
  ApplyGroup(groups.playerDebuffs, cfg, "debuff")
  ApplyGroup(groups.targetDebuffs, cfg, "target")
  module:Refresh()
end

function module:Refresh()
  if groups.playerBuffs then RefreshGroup(groups.playerBuffs) end
  if groups.playerDebuffs then RefreshGroup(groups.playerDebuffs) end
  if groups.targetDebuffs then RefreshGroup(groups.targetDebuffs) end
end

ns:RegisterModule("auras", module)

ns:On("UNIT_AURA", function(_, unit)
  if unit == "player" then
    if groups.playerBuffs then RefreshGroup(groups.playerBuffs) end
    if groups.playerDebuffs then RefreshGroup(groups.playerDebuffs) end
  elseif unit == "target" then
    if groups.targetDebuffs then RefreshGroup(groups.targetDebuffs) end
  end
end)

ns:On("PLAYER_TARGET_CHANGED", function()
  if groups.targetDebuffs then RefreshGroup(groups.targetDebuffs) end
end)

ns:On("PLAYER_ENTERING_WORLD", function() module:Refresh() end)
