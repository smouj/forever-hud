--[[ ForeverHUD :: Core
     Namespace, database, profiles, event bus, module loader, slash commands. ]]
local ADDON, ns = ...

ns.ADDON = ADDON
ns.version = "1.0.0"
ns.path = "Interface\\AddOns\\" .. ADDON .. "\\"

ns.modules = {}
ns.moduleOrder = {}
ns.handlers = {}
ns.errors = {}
ns.preview = { active = false, units = {}, auras = {} }

ns.theme = {
  bg       = { 0.043, 0.047, 0.063, 0.94 },
  bgSolid  = { 0.059, 0.063, 0.082, 1.00 },
  panel    = { 0.082, 0.086, 0.110, 0.97 },
  row      = { 0.110, 0.114, 0.141, 1.00 },
  border   = { 0.290, 0.239, 0.161, 1.00 },
  borderHi = { 0.545, 0.420, 0.220, 1.00 },
  accent   = { 0.851, 0.678, 0.322, 1.00 },
  accent2  = { 0.584, 0.396, 0.184, 1.00 },
  text     = { 0.937, 0.918, 0.867, 1.00 },
  muted    = { 0.596, 0.580, 0.541, 1.00 },
  danger   = { 0.851, 0.243, 0.220, 1.00 },
  ok       = { 0.373, 0.780, 0.443, 1.00 },
  shadow   = { 0.000, 0.000, 0.000, 0.85 },
}

ns.font = (STANDARD_TEXT_FONT) or "Fonts\\FRIZQT__.TTF"

-- ---------------------------------------------------------------------------
-- small utilities
-- ---------------------------------------------------------------------------

function ns:Print(message)
  local frame = DEFAULT_CHAT_FRAME or ChatFrame1
  if not frame then return end
  if frame.AddMessage then
    frame:AddMessage("|cffd9ad52ForeverHUD|r: " .. tostring(message))
  end
end

function ns:Warn(message)
  local frame = DEFAULT_CHAT_FRAME or ChatFrame1
  if not frame then return end
  if frame.AddMessage then
    frame:AddMessage("|cffd9ad52ForeverHUD|r |cffff5555error|r: " .. tostring(message))
  end
end

function ns:SetColor(object, color, alpha)
  if not object or not color then return end
  object:SetVertexColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

function ns:SetTextureColor(texture, color, alpha)
  if not texture or not color then return end
  texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
end

function ns:Copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for k, v in pairs(value) do out[k] = ns:Copy(v) end
  return out
end

function ns:Short(value)
  value = tonumber(value) or 0
  if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
  if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
  if value >= 1e4 then return string.format("%.0fK", value / 1e3) end
  return tostring(math.floor(value + 0.5))
end

function ns:Round(value)
  return math.floor((tonumber(value) or 0) + 0.5)
end

function ns:Clamp(value, minValue, maxValue)
  value = tonumber(value) or minValue
  if value < minValue then return minValue end
  if value > maxValue then return maxValue end
  return value
end

-- ---------------------------------------------------------------------------
-- frames and widgets
-- ---------------------------------------------------------------------------

function ns:ApplyBackdrop(frame, background, border)
  if not frame or not frame.SetBackdrop then return end
  local bg = background or ns.theme.bg
  local bd = border or ns.theme.border
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
  frame:SetBackdropBorderColor(bd[1], bd[2], bd[3], bd[4] or 1)
end

function ns:CreatePanel(name, parent, width, height)
  local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
  frame:SetSize(width, height)
  ns:ApplyBackdrop(frame)
  return frame
end

function ns:CreateBar(parent, width, height, reverse)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetSize(width, height)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar:SetStatusBarColor(0.35, 0.62, 0.35, 1)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(1)
  if reverse and bar.SetReverseFill then
    bar:SetReverseFill(true)
  end
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(bar)
  background:SetColorTexture(0.02, 0.02, 0.03, 0.72)
  bar.background = background
  local shine = bar:CreateTexture(nil, "OVERLAY", nil, 2)
  shine:SetTexture("Interface\\Buttons\\WHITE8X8")
  shine:SetColorTexture(1, 1, 1, 0.06)
  shine:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
  shine:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
  shine:SetHeight(1)
  return bar
end

function ns:CreateText(parent, size, color, flags)
  local text = parent:CreateFontString(nil, "OVERLAY")
  if text.SetFont then
    text:SetFont(ns.font, size or 11, flags or "OUTLINE")
  end
  local c = color or ns.theme.text
  if text.SetTextColor then
    text:SetTextColor(c[1], c[2], c[3], c[4] or 1)
  end
  text:SetShadowColor(ns.theme.shadow[1], ns.theme.shadow[2], ns.theme.shadow[3], 0.9)
  text:SetShadowOffset(1, -1)
  return text
end

function ns:FadeTo(frame, targetAlpha, duration)
  if not frame or not frame.SetAlpha then return end
  duration = duration or 0.22
  if not frame.__fadeState then
    frame.__fadeState = { running = false }
  end
  local state = frame.__fadeState
  state.from = frame:GetAlpha() or 1
  state.to = targetAlpha
  state.elapsed = 0
  state.duration = duration
  if state.running then return end
  state.running = true
  frame:SetScript("OnUpdate", function(self, elapsed)
    local s = self.__fadeState
    s.elapsed = s.elapsed + elapsed
    local progress = s.duration > 0 and math.min(1, s.elapsed / s.duration) or 1
    self:SetAlpha(s.from + (s.to - s.from) * progress)
    if progress >= 1 then
      s.running = false
      self:SetScript("OnUpdate", nil)
    end
  end)
end

-- ---------------------------------------------------------------------------
-- defaults
-- ---------------------------------------------------------------------------

local function unitDefaults(point, x, y, width, height)
  return {
    enabled = true,
    point = point,
    x = x,
    y = y,
    width = width,
    height = height,
    healthText = "both",
    classColors = true,
    portrait = false,
    showName = true,
    showLevel = true,
    tooltip = false,
  }
end

function ns:DefaultProfile()
  return {
    general = {
      scale = 1.0,
      locked = true,
      combatFade = true,
      hideBlizzard = false,
      language = "auto",
      loginMessage = true,
    },
    units = {
      player       = unitDefaults("CENTER", 0, -176, 286, 46),
      target       = unitDefaults("CENTER", 0, 182, 286, 46),
      focus        = unitDefaults("CENTER", -430, 182, 190, 38),
      pet          = unitDefaults("CENTER", 380, -300, 160, 32),
      targettarget = unitDefaults("CENTER", 0, 238, 132, 22),
    },
    castbars = {
      enabled = true,
      playerEnabled = true,
      targetEnabled = true,
      width = 286,
      height = 20,
      playerPoint = "CENTER",
      playerX = 0,
      playerY = -222,
      targetPoint = "CENTER",
      targetX = 0,
      targetY = 222,
      showIcon = true,
      showTime = true,
      interruptHint = true,
    },
    auras = {
      enabled = true,
      size = 32,
      perRow = 10,
      spacing = 4,
      maxAuras = 24,
      buffs = true,
      debuffs = true,
      targetDebuffs = true,
      permanent = true,
      buffPoint = "CENTER",
      buffX = 0,
      buffY = -120,
      debuffPoint = "CENTER",
      debuffX = 0,
      debuffY = -268,
      targetPoint = "CENTER",
      targetX = 0,
      targetY = 132,
    },
    actionbars = {
      enabled = true,
      rows = 2,
      buttonsPerRow = 12,
      buttonSize = 36,
      spacing = 4,
      alpha = 1.0,
      showKeybinds = true,
      showCounts = true,
      background = true,
      point = "CENTER",
      x = 0,
      y = -342,
    },
    version = 1,
  }
end

-- ---------------------------------------------------------------------------
-- database and profiles
-- ---------------------------------------------------------------------------

local function mergeDefaults(target, source)
  for key, value in pairs(source) do
    if type(value) == "table" then
      if type(target[key]) ~= "table" then target[key] = {} end
      mergeDefaults(target[key], value)
    elseif target[key] == nil then
      target[key] = value
    end
  end
end

function ns:CharacterKey()
  local name = (UnitName and UnitName("player")) or "Unknown"
  local realm = (GetRealmName and GetRealmName()) or "Realm"
  return name .. " - " .. realm
end

function ns:InitDB()
  if type(ForeverHUDDB) ~= "table" then ForeverHUDDB = {} end
  local db = ForeverHUDDB
  if type(db.version) ~= "number" then db.version = 1 end
  if type(db.profiles) ~= "table" then db.profiles = {} end
  if type(db.charProfiles) ~= "table" then db.charProfiles = {} end

  local defaults = ns:DefaultProfile()
  if next(db.profiles) == nil then
    db.profiles["Default"] = defaults
  end
  for _, profile in pairs(db.profiles) do
    mergeDefaults(profile, ns:DefaultProfile())
  end

  local key = ns:CharacterKey()
  local name = db.charProfiles[key]
  if not name or not db.profiles[name] then
    name = "Default"
    db.charProfiles[key] = name
  end
  ns.db = db
end

function ns:Profile()
  if not ns.db then return nil end
  local name = ns.db.charProfiles[ns:CharacterKey()]
  return ns.db.profiles[name]
end

function ns:ProfileName()
  if not ns.db then return "Default" end
  return ns.db.charProfiles[ns:CharacterKey()] or "Default"
end

function ns:ProfileNames()
  local names = {}
  if not ns.db then return names end
  for name in pairs(ns.db.profiles) do names[#names + 1] = name end
  table.sort(names)
  return names
end

local function validProfileName(name)
  return type(name) == "string" and #name >= 1 and #name <= 32 and name:find("^[%w _%-%.]+$") ~= nil
end

function ns:SetProfile(name)
  if not ns.db or type(name) ~= "string" then return false, "missing" end
  if not ns.db.profiles[name] then return false, "missing" end
  ns.db.charProfiles[ns:CharacterKey()] = name
  ns:ApplyAll()
  ns:RefreshAll()
  return true, name
end

function ns:NewProfile(name, copyFrom)
  if not ns.db then return false end
  if not validProfileName(name) then return false, "invalid" end
  if ns.db.profiles[name] then return false, "exists" end
  local source
  if copyFrom and ns.db.profiles[copyFrom] then
    source = ns:Copy(ns.db.profiles[copyFrom])
  else
    source = ns:DefaultProfile()
    mergeDefaults(source, ns:Profile() or {})
  end
  ns.db.profiles[name] = source
  return true
end

function ns:CopyProfile(from, to)
  if not ns.db or not ns.db.profiles[from] or not validProfileName(to) then return false, "invalid" end
  if ns.db.profiles[to] then return false, "exists" end
  ns.db.profiles[to] = ns:Copy(ns.db.profiles[from])
  return true
end

function ns:DeleteProfile(name)
  if not ns.db then return false, "missing" end
  if not ns.db.profiles[name] then return false, "missing" end
  if name == ns:ProfileName() then return false, "active" end
  ns.db.profiles[name] = nil
  return true
end

function ns:ResetProfile(name)
  if not ns.db then return false end
  name = name or ns:ProfileName()
  if not ns.db.profiles[name] then return false end
  ns.db.profiles[name] = ns:DefaultProfile()
  if name == ns:ProfileName() then
    ns:ApplyAll()
    ns:RefreshAll()
  end
  return true
end

-- dot separated access into the active profile
local function walk(root, path, create)
  local node = root
  for key in string.gmatch(path, "[^%.]+") do
    if type(node) ~= "table" then return nil end
    if node[key] == nil then
      if not create then return nil end
      node[key] = {}
    end
    node = node[key]
  end
  return node
end

function ns:Get(path, fallback)
  local profile = ns:Profile()
  if not profile then return fallback end
  local value = walk(profile, path, false)
  if value == nil then return fallback end
  return value
end

function ns:Set(path, value)
  local profile = ns:Profile()
  if not profile then return false end
  local parentPath, leaf = string.match(path, "^(.*)%.([^%.]+)$")
  local node
  if parentPath then
    node = walk(profile, parentPath, true)
  else
    node = profile
    leaf = path
  end
  if type(node) ~= "table" or not leaf then return false end
  node[leaf] = value
  return true
end

-- ---------------------------------------------------------------------------
-- serialization for profile export / import
-- ---------------------------------------------------------------------------

local function serializeValue(value, depth)
  local kind = type(value)
  if kind == "table" then
    if depth > 8 then return "{}" end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b)
      if ta == tb and (ta == "string" or ta == "number") then return a < b end
      return ta < tb
    end)
    local parts = {}
    for _, key in ipairs(keys) do
      local encodedKey
      if type(key) == "string" and key:find("^[%a_][%w_]*$") then
        encodedKey = key
      else
        encodedKey = "[" .. serializeValue(key, depth + 1) .. "]"
      end
      parts[#parts + 1] = encodedKey .. "=" .. serializeValue(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif kind == "string" then
    return string.format("%q", value)
  elseif kind == "number" then
    if value ~= value or value == math.huge or value == -math.huge then return "0" end
    return string.format("%.4f", value):gsub("%.?0+$", "")
  elseif kind == "boolean" then
    return tostring(value)
  end
  return "nil"
end

function ns:Serialize(profile)
  return serializeValue(profile or ns:Profile() or {}, 0)
end

function ns:Deserialize(text)
  if type(text) ~= "string" or #text < 2 or #text > 60000 then return nil end
  local loader = loadstring or load
  local chunk = loader("return " .. text)
  if not chunk then return nil end
  local ok, value = pcall(chunk)
  if not ok or type(value) ~= "table" then return nil end
  if type(value) ~= "table" then return nil end
  mergeDefaults(value, ns:DefaultProfile())
  return value
end

-- ---------------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local SYNTHETIC_EVENTS = { TICK = true, APPLY = true, REFRESH = true, INIT = true }

function ns:On(event, handler)
  if not ns.handlers[event] then ns.handlers[event] = {} end
  table.insert(ns.handlers[event], handler)
  if not SYNTHETIC_EVENTS[event] then
    eventFrame:RegisterEvent(event)
  end
  return handler
end

ns.RegisterEvent = ns.On

function ns:Fire(event, ...)
  local list = ns.handlers[event]
  if not list then return end
  for index = 1, #list do
    local handler = list[index]
    local ok, err = pcall(handler, event, ...)
    if not ok then
      ns:Warn(string.format("handler %s: %s", tostring(event), tostring(err)))
    end
  end
end

local outOfCombatQueue = {}

function ns:RunOutOfCombat(fn)
  if not InCombatLockdown or not InCombatLockdown() then
    local ok, err = pcall(fn)
    if not ok then ns:Warn(tostring(err)) end
    return true
  end
  table.insert(outOfCombatQueue, fn)
  return false
end

local function flushOutOfCombat()
  local queue = outOfCombatQueue
  outOfCombatQueue = {}
  for _, fn in ipairs(queue) do
    local ok, err = pcall(fn)
    if not ok then ns:Warn(tostring(err)) end
  end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName == ADDON then ns:InitDB() end
  elseif event == "PLAYER_LOGIN" then
    ns:Initialize()
  elseif event == "PLAYER_REGEN_ENABLED" then
    flushOutOfCombat()
  end
  ns:Fire(event, ...)
end)

-- shared ticker: modules subscribe to TICK instead of each running OnUpdate
local ticker = CreateFrame("Frame")
ticker:Show()
local tickAccumulator = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
  tickAccumulator = tickAccumulator + elapsed
  if tickAccumulator < 0.05 then return end
  local step = tickAccumulator
  tickAccumulator = 0
  ns:Fire("TICK", step)
end)

-- ---------------------------------------------------------------------------
-- modules
-- ---------------------------------------------------------------------------

function ns:RegisterModule(name, module)
  if ns.modules[name] then return end
  ns.modules[name] = module
  ns.moduleOrder[#ns.moduleOrder + 1] = name
  module.name = name
end

function ns:GetModule(name)
  return ns.modules[name]
end

function ns:SafeCall(name, method, ...)
  local module = ns.modules[name]
  if not module or not module[method] then return end
  local ok, err = pcall(module[method], module, ...)
  if not ok then
    ns.errors[name] = tostring(err)
    if not module.__reported then
      module.__reported = true
      ns:Warn(string.format(ns.L.moduleError, name, tostring(err)))
    end
  end
  return ok
end

function ns:Initialize()
  if ns.initialized then return end
  if not ns.db then ns:InitDB() end
  ns.initialized = true

  for _, name in ipairs(ns.moduleOrder) do
    ns:SafeCall(name, "Initialize")
  end
  ns:ApplyAll()
  ns:RefreshAll()
  ns:Fire("INIT")

  if ns:Get("general.loginMessage") and not ns.preview.active then
    ns:Print(string.format(ns.L.loaded, ns.version))
  end
end

function ns:ApplyAll()
  for _, name in ipairs(ns.moduleOrder) do
    ns:SafeCall(name, "Apply")
  end
  ns:UpdateMouseState()
  ns:Fire("APPLY")
end

function ns:RefreshAll()
  for _, name in ipairs(ns.moduleOrder) do
    ns:SafeCall(name, "Refresh")
  end
  ns:Fire("REFRESH")
end

-- ---------------------------------------------------------------------------
-- placement helpers
-- ---------------------------------------------------------------------------

function ns:ApplyPosition(frame, cfg, prefix, defaultPoint)
  if not frame or not cfg then return end
  prefix = prefix or ""
  local point = cfg[prefix .. "point"] or defaultPoint or "CENTER"
  local x = cfg[prefix .. "x"] or 0
  local y = cfg[prefix .. "y"] or 0
  frame:ClearAllPoints()
  frame:SetPoint(point, UIParent, point, x, y)
end

function ns:MakeMovable(frame, path, prefix)
  if not frame or not frame.SetMovable then return end
  prefix = prefix or ""
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  if frame.RegisterForDrag then frame:RegisterForDrag("LeftButton") end
  frame:SetScript("OnDragStart", function(self)
    if ns:Get("general.locked") then return end
    if InCombatLockdown and InCombatLockdown() then return end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint(1)
    if not point then return end
    local cfg = ns:Get(path)
    if type(cfg) ~= "table" then return end
    ns:Set(path .. "." .. prefix .. "point", point)
    ns:Set(path .. "." .. prefix .. "x", ns:Round(x))
    ns:Set(path .. "." .. prefix .. "y", ns:Round(y))
  end)
  frame:EnableMouse(not ns:Get("general.locked"))
end

function ns:UpdateMouseState()
  local locked = ns:Get("general.locked", true)
  local list = ns.movableFrames or {}
  for index = 1, #list do
    local frame = list[index]
    if frame.EnableMouse then frame:EnableMouse(not locked) end
  end
end

function ns:RegisterMovable(frame)
  ns.movableFrames = ns.movableFrames or {}
  for index = 1, #ns.movableFrames do
    if ns.movableFrames[index] == frame then return end
  end
  ns.movableFrames[#ns.movableFrames + 1] = frame
end

-- ---------------------------------------------------------------------------
-- preview mode
-- ---------------------------------------------------------------------------

local function demoUnit(name, level, classFile, health, maxHealth, power, maxPower, powerType, friendly)
  return {
    name = name, level = level, classFile = classFile,
    health = health, maxHealth = maxHealth,
    power = power, maxPower = maxPower, powerType = powerType,
    friendly = friendly,
  }
end

function ns:BuildPreviewData()
  local units = ns.preview.units
  units.player = demoUnit("Aelric", 60, "PALADIN", 8120, 10000, 4200, 5400, 0, true)
  units.target = demoUnit("Senor del Foso", -1, nil, 184000, 300000, 0, 0, 0, false)
  units.focus = demoUnit("Sanadora Vex", 60, "PRIEST", 6400, 7800, 5100, 6000, 0, false)
  units.pet = demoUnit("Lobo espectral", 60, "HUNTER", 3200, 4200, 0, 0, 0, true)
  units.targettarget = demoUnit("Aelric", 60, "PALADIN", 8120, 10000, 4200, 5400, 0, true)

  ns.preview.auras.playerBuffs = {
    { name = "Bendicion de reyes", icon = "Interface\\Icons\\Spell_Magic_MageArmor", count = 0, duration = 900, expirationTime = 0, dispelName = nil },
    { name = "Poder divino", icon = "Interface\\Icons\\Spell_Holy_DivineSpirit", count = 1, duration = 600, expirationTime = 0, dispelName = nil },
    { name = "Escudo sagrado", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", count = 0, duration = 12, expirationTime = 0, dispelName = nil },
  }
  ns.preview.auras.playerDebuffs = {
    { name = "Sangrado", icon = "Interface\\Icons\\Ability_Creature_Cursed_02", count = 3, duration = 15, expirationTime = 0, dispelName = "Bleed" },
  }
  ns.preview.auras.targetDebuffs = {
    { name = "Fuego", icon = "Interface\\Icons\\Spell_Fire_Immolation", count = 0, duration = 8, expirationTime = 0, dispelName = "Magic" },
    { name = "Heridas", icon = "Interface\\Icons\\Ability_Creature_Poison_02", count = 5, duration = 20, expirationTime = 0, dispelName = "Poison" },
    { name = "Maldicion", icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", count = 0, duration = 30, expirationTime = 0, dispelName = "Curse" },
  }
  ns.preview.auras.start = GetTime and GetTime() or 0
  ns.preview.cast = {
    name = "Bola de fuego", icon = "Interface\\Icons\\Spell_Fire_Fireball02",
    startTime = (GetTime and GetTime() or 0), duration = 2.4, interruptible = true, channel = false,
  }
  ns.preview.started = GetTime and GetTime() or 0
end

function ns:StartPreview()
  if ns.preview.active then return end
  ns:BuildPreviewData()
  ns.preview.active = true
  ns:ApplyAll()
  ns:RefreshAll()
  ns:Print(ns.L.previewOn)
end

function ns:StopPreview()
  if not ns.preview.active then return end
  ns.preview.active = false
  ns:ApplyAll()
  ns:RefreshAll()
  ns:Print(ns.L.previewOff)
end

function ns:TogglePreview()
  if ns.preview.active then ns:StopPreview() else ns:StartPreview() end
end

-- ---------------------------------------------------------------------------
-- slash commands
-- ---------------------------------------------------------------------------

function ns:OpenConfig(section)
  if ns.ConfigAPI and ns.ConfigAPI.Open then
    ns.ConfigAPI.Open(section)
  else
    ns:Print(ns.L.configOpened)
  end
end

function ns:PrintHelp()
  ns:Print(ns.L.helpHeader)
  ns:Print(ns.L.helpConfig)
  ns:Print(ns.L.helpLock)
  ns:Print(ns.L.helpPreview)
  ns:Print(ns.L.helpProfile)
  ns:Print(ns.L.helpReset)
  ns:Print(ns.L.helpExport)
  ns:Print(ns.L.helpImport)
  ns:Print(ns.L.helpVersion)
end

function ns:HandleCommand(message)
  message = tostring(message or "")
  local command, rest = string.match(message, "^%s*(%S*)%s*(.-)%s*$")
  command = string.lower(command or "")

  if command == "" or command == "config" or command == "options" or command == "opciones" then
    ns:OpenConfig()
  elseif command == "lock" or command == "bloquear" then
    ns:Set("general.locked", true)
    ns:UpdateMouseState()
    ns:Print(ns.L.lockOn)
  elseif command == "unlock" or command == "move" or command == "desbloquear" then
    ns:Set("general.locked", false)
    ns:UpdateMouseState()
    ns:Print(ns.L.lockOff)
  elseif command == "preview" then
    ns:TogglePreview()
  elseif command == "profile" or command == "perfil" then
    if rest == "" then
      ns:Print(string.format("%s: %s", ns.L.activeProfile, ns:ProfileName()))
    else
      local ok, reason = ns:SetProfile(rest)
      if ok then
        ns:Print(string.format(ns.L.profileSwitched, rest))
      else
        ns:Print(reason == "active" and ns.L.profileInUse or ns.L.profileMissing)
      end
    end
  elseif command == "profiles" then
    local names = ns:ProfileNames()
    if #names == 0 then ns:Print(ns.L.noProfile) end
    for _, name in ipairs(names) do
      local mark = name == ns:ProfileName() and "|cffd9ad52*|r " or "  "
      ns:Print(mark .. name)
    end
  elseif command == "reset" then
    ns:ResetProfile()
    ns:Print(ns.L.resetDone)
  elseif command == "export" then
    local text = ns:Serialize()
    if ns.ConfigAPI and ns.ConfigAPI.ShowExport then
      ns.ConfigAPI.ShowExport(text)
    else
      ns:Print(text)
    end
    ns:Print(ns.L.exported)
  elseif command == "import" then
    local profile = ns:Deserialize(rest)
    if not profile then
      ns:Print(ns.L.importFailed)
      return
    end
    local name = "Import " .. date("%Y%m%d-%H%M")
    local index = 1
    while ns.db.profiles[name] do
      index = index + 1
      name = "Import " .. date("%Y%m%d-%H%M") .. " " .. index
    end
    ns.db.profiles[name] = profile
    ns:SetProfile(name)
    ns:Print(string.format(ns.L.imported, name))
  elseif command == "version" then
    ns:Print(("ForeverHUD %s | Interface 16001"):format(ns.version))
  else
    ns:PrintHelp()
  end
end

SLASH_FOREVERHUD1 = "/fh"
SLASH_FOREVERHUD2 = "/foreverhud"
SlashCmdList["FOREVERHUD"] = function(message)
  ns:HandleCommand(message)
end
