--[[ ForeverHUD :: Unit frames
     Player, target, focus, pet and target-of-target. Display only: ForeverHUD
     never intercepts clicks and never drives the secure unit API. ]]
local ADDON, ns = ...
local L = ns.L

local UNITS = { "player", "target", "focus", "pet", "targettarget" }
local frames = {}
local module = { frames = frames }

local POWER_COLORS = {
  [0]  = { 0.00, 0.32, 0.78 },
  [1]  = { 0.78, 0.10, 0.10 },
  [2]  = { 0.95, 0.55, 0.10 },
  [3]  = { 0.85, 0.80, 0.10 },
  [4]  = { 0.10, 0.60, 0.90 },
  [6]  = { 0.55, 0.35, 0.85 },
  [8]  = { 0.00, 0.65, 0.70 },
  [11] = { 0.55, 0.85, 0.15 },
  [13] = { 0.80, 0.20, 0.80 },
}

local CLASSIFICATION = {
  elite = "Elite",
  rareelite = "Raro +",
  rare = "Raro",
  worldboss = "Jefe",
  minus = "Debil",
  trivial = "Trivial",
}

local function classColor(classFile)
  local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
  if color then return color.r, color.g, color.b end
  return nil
end

local function reactionColor(unit, info)
  if info and info.dead then return 0.38, 0.38, 0.38 end
  if info and info.friendly ~= nil then
    if info.friendly then return 0.20, 0.58, 0.31 end
    return 0.72, 0.17, 0.15
  end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then return 0.38, 0.38, 0.38 end
  if UnitCanAttack and UnitCanAttack("player", unit) then return 0.72, 0.17, 0.15 end
  if UnitIsFriend and UnitIsFriend("player", unit) then return 0.20, 0.58, 0.31 end
  return 0.78, 0.64, 0.22
end

local function powerColor(powerType)
  local color = (PowerBarColor and PowerBarColor[powerType]) or POWER_COLORS[powerType]
  if color then
    if color.r then return color.r, color.g, color.b end
    return color[1], color[2], color[3]
  end
  return 0.20, 0.40, 0.83
end

-- Reads from the live API, or from the preview fixture when preview mode is on.
local function UnitInfo(unit)
  if ns.preview.active then
    local demo = ns.preview.units[unit]
    if not demo then return nil end
    return {
      name = demo.name,
      level = demo.level,
      classFile = demo.classFile,
      health = demo.health,
      maxHealth = demo.maxHealth,
      power = demo.power,
      maxPower = demo.maxPower,
      powerType = demo.powerType,
      friendly = demo.friendly,
      dead = false,
      classification = nil,
      connected = true,
    }
  end
  if not UnitExists or not UnitExists(unit) then return nil end
  local name = UnitName(unit)
  if not name or name == "" then return nil end
  local maxHealth = UnitHealthMax(unit) or 0
  local health = UnitHealth(unit) or 0
  local powerType = 0
  if UnitPowerType then powerType = UnitPowerType(unit) end
  local classFile
  if UnitClass then classFile = select(2, UnitClass(unit)) end
  local classification = "normal"
  if UnitClassification then classification = UnitClassification(unit) end
  return {
    name = name,
    level = UnitLevel and UnitLevel(unit) or 0,
    classFile = classFile,
    health = health,
    maxHealth = maxHealth > 0 and maxHealth or 1,
    power = UnitPower and UnitPower(unit) or 0,
    maxPower = UnitPowerMax and UnitPowerMax(unit) or 0,
    powerType = powerType,
    friendly = not (UnitCanAttack and UnitCanAttack("player", unit)),
    dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) or false,
    classification = classification,
    connected = (UnitIsConnected and UnitIsConnected(unit)) ~= false,
    isPlayer = UnitIsPlayer and UnitIsPlayer(unit) or false,
  }
end

local function healthString(health, maxHealth, style)
  if style == "none" then return "" end
  local percent = maxHealth > 0 and math.floor((health / maxHealth) * 100 + 0.5) or 0
  if style == "percent" then return string.format("%d%%", percent) end
  if style == "value" then return ns:Short(health) end
  return string.format("%d%%  |cff9c9486%s / %s|r", percent, ns:Short(health), ns:Short(maxHealth))
end

local function CreateUnitFrame(unit)
  local frame = CreateFrame("Frame", "ForeverHUD_Unit_" .. unit, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("MEDIUM")
  frame:SetSize(280, 46)
  ns:ApplyBackdrop(frame)

  local health = ns:CreateBar(frame, 280, 34)
  health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  frame.health = health

  local power = ns:CreateBar(frame, 280, 7)
  power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  frame.power = power

  local portrait = frame:CreateTexture(nil, "ARTWORK")
  portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  portrait:SetSize(44, 44)
  portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  frame.portrait = portrait

  local portraitEdges = {}
  local function edge(pointA, pointB, width, height)
    local texture = frame:CreateTexture(nil, "OVERLAY", nil, 6)
    texture:SetPoint(pointA, portrait)
    texture:SetPoint(pointB, portrait)
    if width then texture:SetWidth(width) end
    if height then texture:SetHeight(height) end
    portraitEdges[#portraitEdges + 1] = texture
  end
  edge("TOPLEFT", "TOPRIGHT", nil, 1)
  edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
  edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
  edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
  frame.portraitEdges = portraitEdges

  local name = ns:CreateText(frame, 12, ns.theme.text, "OUTLINE")
  name:SetPoint("TOPLEFT", health, "TOPLEFT", 7, -3)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  if name.SetNonSpaceWrap then name:SetNonSpaceWrap(false) end
  if name.SetMaxLines then name:SetMaxLines(1) end
  frame.name = name

  local level = ns:CreateText(frame, 9, ns.theme.muted, "OUTLINE")
  level:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 7, 3)
  level:SetJustifyH("LEFT")
  frame.level = level

  local healthText = ns:CreateText(frame, 10, ns.theme.text, "OUTLINE")
  healthText:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -7, 3)
  healthText:SetJustifyH("RIGHT")
  frame.healthText = healthText

  local marker = frame:CreateTexture(nil, "OVERLAY")
  marker:SetSize(16, 16)
  marker:SetPoint("TOPLEFT", frame, "TOPLEFT", -7, 7)
  marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  marker:Hide()
  frame.marker = marker

  local dead = ns:CreateText(frame, 12, ns.theme.danger, "OUTLINE")
  dead:SetPoint("CENTER", health, "CENTER", 0, 0)
  dead:SetText("")
  dead:Hide()
  frame.deadText = dead

  frame:SetAlpha(1)
  return frame
end

local function ApplyFrame(unit, frame, cfg)
  local scale = ns:Get("general.scale", 1)
  if scale ~= 1 then frame:SetScale(scale) else frame:SetScale(1) end
  frame:SetSize(cfg.width, cfg.height)

  local padding = 1
  local portraitSize = 0
  if cfg.portrait then portraitSize = cfg.height - 2 end

  local powerHeight = math.max(5, math.floor(cfg.height * 0.15))
  local healthHeight = math.max(8, cfg.height - (padding * 2) - powerHeight - 1)

  frame.health:ClearAllPoints()
  frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", padding + portraitSize + (portraitSize > 0 and 3 or 0), -padding)
  frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -padding)
  frame.health:SetHeight(healthHeight)

  frame.power:ClearAllPoints()
  frame.power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding + portraitSize + (portraitSize > 0 and 3 or 0), padding)
  frame.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
  frame.power:SetHeight(powerHeight)

  if cfg.portrait then
    frame.portrait:Show()
    frame.portrait:SetSize(portraitSize, portraitSize)
    local edgeColor = ns.theme.accent2
    for index = 1, #frame.portraitEdges do
      local texture = frame.portraitEdges[index]
      texture:SetColorTexture(edgeColor[1], edgeColor[2], edgeColor[3], 0.9)
      texture:Show()
    end
  else
    frame.portrait:Hide()
    for index = 1, #frame.portraitEdges do frame.portraitEdges[index]:Hide() end
  end

  frame.name:SetShown(cfg.showName and true or false)
  frame.level:SetShown(cfg.showLevel and true or false)
  frame.healthText:SetShown(cfg.healthText ~= "none")

  local barWidth = cfg.width - (padding * 2) - portraitSize - (portraitSize > 0 and 3 or 0)
  frame.name:SetWidth(math.max(40, barWidth - 14))

  frame.name:SetFont(ns.font, math.max(10, math.floor(cfg.height * 0.27)), "OUTLINE")
  frame.healthText:SetFont(ns.font, math.max(8, math.floor(cfg.height * 0.21)), "OUTLINE")
  frame.level:SetFont(ns.font, math.max(8, math.floor(cfg.height * 0.19)), "OUTLINE")

  ns:ApplyBackdrop(frame)
  ns:AddCornerAccents(frame)
  ns:UpdateAccents(frame)
  frame.health:SetStatusBarTexture(ns:BarTexture())
  frame.power:SetStatusBarTexture(ns:BarTexture())

  ns:ApplyPosition(frame, cfg, "", "CENTER")
  frame:EnableMouse((cfg.tooltip == true) or (not ns:Get("general.locked", true)))

  if cfg.tooltip then
    frame:SetScript("OnEnter", function(self)
      if not GameTooltip or not GameTooltip.SetUnit then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetUnit(unit)
      GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)
  else
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
  end
end

local function UpdateFrame(unit, frame)
  local cfg = ns:Get("units." .. unit)
  if not cfg then return end
  local info = UnitInfo(unit)
  local visible = cfg.enabled and info ~= nil
  if ns.preview.active then
    visible = cfg.enabled and (ns.preview.units[unit] ~= nil)
  end

  if not visible then
    frame:Hide()
    return
  end
  frame:Show()

  local health = frame.health
  local maxHealth = math.max(1, info.maxHealth or 1)
  health:SetMinMaxValues(0, maxHealth)
  health:SetValue(info.health or 0)

  local r, g, b
  local useClass = cfg.classColors and info.classFile
  if useClass then r, g, b = classColor(info.classFile) end
  if not r then r, g, b = reactionColor(unit, info) end
  health:SetStatusBarColor(r, g, b, 1)

  frame.healthText:SetText(healthString(info.health or 0, maxHealth, cfg.healthText))
  frame.power:SetMinMaxValues(0, math.max(1, info.maxPower or 1))
  frame.power:SetValue(info.power or 0)
  local pr, pg, pb = powerColor(info.powerType or 0)
  frame.power:SetStatusBarColor(pr, pg, pb, 1)

  frame.name:SetText(info.name or "")
  frame.name:SetTextColor(r, g, b, 1)

  local level = info.level or 0
  local levelText = level > 0 and tostring(level) or "??"
  local classification = CLASSIFICATION[info.classification or "normal"]
  if classification then levelText = levelText .. " · " .. classification end
  frame.level:SetText(levelText)
  frame.level:SetTextColor(ns.theme.muted[1], ns.theme.muted[2], ns.theme.muted[3], 0.95)

  if cfg.portrait and not ns.preview.active then
    if SetPortraitTexture then
      SetPortraitTexture(frame.portrait, unit)
    end
  elseif cfg.portrait then
    frame.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  local markerIndex = (not ns.preview.active) and GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
  if markerIndex then
    SetRaidTargetIconTexture(frame.marker, markerIndex)
    frame.marker:Show()
  else
    frame.marker:Hide()
  end

  if info.dead then
    frame.deadText:SetText("MUERTO")
    frame.deadText:Show()
    frame:SetAlpha(0.72)
  else
    frame.deadText:Hide()
  end

  if not info.connected then
    frame:SetAlpha(0.55)
  end

  if cfg.showName and (info.name or "") == "" then frame.name:Hide() end
end

function module:Initialize()
  for _, unit in ipairs(UNITS) do
    local frame = CreateUnitFrame(unit)
    frames[unit] = frame
    ns:MakeMovable(frame, "units." .. unit)
    ns:RegisterMovable(frame)
  end
end

function module:Apply()
  local locked = ns:Get("general.locked", true)
  for _, unit in ipairs(UNITS) do
    local frame = frames[unit]
    local cfg = ns:Get("units." .. unit)
    if frame and cfg then
      ApplyFrame(unit, frame, cfg)
      if not cfg.enabled then frame:Hide() end
      frame:EnableMouse(not locked or cfg.tooltip == true)
    end
  end
  module:Refresh()

  if ns:Get("general.hideBlizzard", false) then
    if PlayerFrame then PlayerFrame:Hide() end
    if TargetFrame then TargetFrame:Hide() end
  elseif ns.initialized then
    if PlayerFrame then PlayerFrame:Show() end
    if TargetFrame then TargetFrame:Show() end
  end
end

function module:Refresh()
  for _, unit in ipairs(UNITS) do
    local frame = frames[unit]
    if frame then
      local ok, err = pcall(UpdateFrame, unit, frame)
      if not ok then ns.errors["unitframes." .. unit] = tostring(err) end
    end
  end
end

function module:GetFrame(unit)
  return frames[unit]
end

ns:RegisterModule("unitframes", module)

-- ---------------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------------
local function RefreshUnit(unit)
  local frame = frames[unit]
  if frame then module:Refresh() end
end

for _, event in ipairs({
  "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH",
  "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
  "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS",
}) do
  ns:On(event, function(_, unit)
    if unit and frames[unit] then
      local ok, err = pcall(UpdateFrame, unit, frames[unit])
      if not ok then ns.errors["unitframes." .. unit] = tostring(err) end
    end
  end)
end

ns:On("PLAYER_TARGET_CHANGED", function()
  RefreshUnit("target")
  RefreshUnit("targettarget")
end)

ns:On("PLAYER_FOCUS_CHANGED", function()
  RefreshUnit("focus")
end)

ns:On("UNIT_PET", function(_, unit)
  if unit == "player" then RefreshUnit("pet") end
end)

ns:On("PLAYER_ENTERING_WORLD", function()
  module:Refresh()
end)

ns:On("PLAYER_REGEN_DISABLED", function()
  if not ns:Get("general.combatFade", true) then return end
  for _, unit in ipairs(UNITS) do
    local frame = frames[unit]
    if frame and frame:IsShown() then ns:FadeTo(frame, 1, 0.15) end
  end
end)

ns:On("PLAYER_REGEN_ENABLED", function()
  if not ns:Get("general.combatFade", true) then return end
  local alpha = ns:Get("units.player.enabled") and 0.55 or 0.55
  for _, unit in ipairs(UNITS) do
    local frame = frames[unit]
    if frame and frame:IsShown() then ns:FadeTo(frame, alpha, 0.35) end
  end
end)

ns:On("APPLY", function()
  if ns.preview.active then return end
  if ns:Get("general.combatFade", true) and not (InCombatLockdown and InCombatLockdown()) then
    for _, unit in ipairs(UNITS) do
      local frame = frames[unit]
      if frame and frame:IsShown() then frame:SetAlpha(0.55) end
    end
  elseif not ns:Get("general.combatFade", true) then
    for _, unit in ipairs(UNITS) do
      local frame = frames[unit]
      if frame then frame:SetAlpha(1) end
    end
  end
end)
