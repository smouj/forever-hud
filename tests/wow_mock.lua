--[[ Headless World of Warcraft API mock for ForeverHUD.
     Only implements what the addon actually touches, so a missing API fails
     loudly instead of being silently ignored. ]]
local Mock = {
  frames = {},
  named = {},
  chat = {},
  handlers = {},   -- event -> { frame = script }
  time = 1000,
  inCombat = false,
  units = {},
  auras = {},
  casts = {},
  actions = {},
  bindings = {},
  popupShown = nil,
}

local Widget = {}
Widget.__index = Widget

local function newWidget(kind, name, parent, template)
  local widget = setmetatable({
    kind = kind,
    name = name,
    parent = parent,
    template = template,
    points = {},
    width = 0,
    height = 0,
    shown = true,
    alpha = 1,
    scale = 1,
    strata = "MEDIUM",
    level = 1,
    scripts = {},
    attributes = {},
    children = {},
    text = "",
    value = 0,
    minValue = 0,
    maxValue = 1,
    checked = false,
  }, Widget)
  if parent and parent.children then table.insert(parent.children, widget) end
  table.insert(Mock.frames, widget)
  if name then Mock.named[name] = widget end
  return widget
end

function Widget:GetName() return self.name end
function Widget:GetParent() return self.parent end
function Widget:SetParent(parent)
  self.parent = parent
  if parent and parent.children then table.insert(parent.children, self) end
  if not parent then self.shown = false end
end
function Widget:GetChildren() return self.children end
function Widget:SetPoint(point, a, b, c, d)
  local relativeTo, relativePoint, x, y
  if type(a) == "number" then
    relativeTo, relativePoint, x, y = nil, point, a, b
  else
    relativeTo, relativePoint, x, y = a, b or point, c or 0, d or 0
  end
  table.insert(self.points, { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x, y = y })
end
function Widget:GetPoint(index)
  local point = self.points[index or 1]
  if not point then return nil end
  return point.point, point.relativeTo, point.relativePoint, point.x, point.y
end
function Widget:ClearAllPoints() self.points = {} end
function Widget:SetAllPoints() self.points = {} end
function Widget:SetSize(width, height) self.width, self.height = width, height end
function Widget:SetWidth(width) self.width = width end
function Widget:SetHeight(height) self.height = height end
function Widget:GetWidth() return self.width end
function Widget:GetHeight() return self.height end
function Widget:SetScale(scale) self.scale = scale end
function Widget:GetScale() return self.scale end
function Widget:SetAlpha(alpha) self.alpha = alpha end
function Widget:GetAlpha() return self.alpha end
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:SetShown(shown) self.shown = shown and true or false end
function Widget:IsShown() return self.shown end
function Widget:IsVisible() return self.shown end
function Widget:SetScript(script, fn) self.scripts[script] = fn end
function Widget:GetScript(script) return self.scripts[script] end
function Widget:HookScript(script, fn)
  local previous = self.scripts[script]
  self.scripts[script] = function(...)
    if previous then previous(...) end
    fn(...)
  end
end
function Widget:RegisterEvent(event)
  Mock.handlers[event] = Mock.handlers[event] or {}
  for _, entry in ipairs(Mock.handlers[event]) do
    if entry.widget == self then return end
  end
  table.insert(Mock.handlers[event], { widget = self })
end
function Widget:UnregisterEvent(event)
  local list = Mock.handlers[event]
  if not list then return end
  for index = #list, 1, -1 do
    if list[index].widget == self then table.remove(list, index) end
  end
end
function Widget:RegisterForDrag() end
function Widget:RegisterForClicks() end
function Widget:SetMovable(movable) self.movable = movable end
function Widget:IsMovable() return self.movable end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:EnableMouse(mouse) self.mouse = mouse end
function Widget:SetClampedToScreen() end
function Widget:SetFrameStrata(strata) self.strata = strata end
function Widget:GetFrameStrata() return self.strata end
function Widget:SetFrameLevel(level) self.level = level end
function Widget:GetFrameLevel() return self.level end
function Widget:SetToplevel() end
function Widget:Raise() end
function Widget:SetID(id) self.id = id end
function Widget:GetID() return self.id end
function Widget:SetUserPlaced() end
function Widget:SetHitRectInsets() end
function Widget:SetBackdrop(backdrop) self.backdrop = backdrop end
function Widget:SetBackdropColor(r, g, b, a) self.backdropColor = { r, g, b, a } end
function Widget:SetBackdropBorderColor(r, g, b, a) self.backdropBorderColor = { r, g, b, a } end
function Widget:SetStatusBarTexture(texture) self.statusBarTexture = texture end
function Widget:GetStatusBarTexture()
  self.statusBarTextureObject = self.statusBarTextureObject or newWidget("Texture", nil, self)
  return self.statusBarTextureObject
end
function Widget:SetStatusBarColor(r, g, b, a) self.statusBarColor = { r, g, b, a } end
function Widget:SetMinMaxValues(minValue, maxValue) self.minValue, self.maxValue = minValue, maxValue end
function Widget:GetMinMaxValues() return self.minValue, self.maxValue end
function Widget:SetValue(value)
  self.value = value
  local handler = self.scripts.OnValueChanged
  if handler then handler(self, value) end
end
function Widget:GetValue() return self.value end
function Widget:SetReverseFill(reverse) self.reverseFill = reverse end
function Widget:SetOrientation(orientation) self.orientation = orientation end
function Widget:SetValueStep(step) self.valueStep = step end
function Widget:SetObeyStepOnDrag() end
function Widget:SetThumbTexture(texture)
  self.thumb = newWidget("Texture", nil, self)
  self.thumb.texture = texture
end
function Widget:GetThumbTexture() return self.thumb end
function Widget:CreateTexture(name, layer)
  return newWidget("Texture", name, self)
end
function Widget:CreateFontString(name, layer)
  return newWidget("FontString", name, self)
end
function Widget:CreateFrame(frameType, name)
  return newWidget(frameType or "Frame", name, self)
end
function Widget:SetTexture(texture) self.texture = texture end
function Widget:GetTexture() return self.texture end
function Widget:SetColorTexture(r, g, b, a) self.colorTexture = { r, g, b, a } end
function Widget:SetVertexColor(r, g, b, a) self.vertexColor = { r, g, b, a } end
function Widget:GetVertexColor()
  local c = self.vertexColor or { 1, 1, 1, 1 }
  return c[1], c[2], c[3], c[4]
end
function Widget:SetDesaturated(desaturated) self.desaturated = desaturated end
function Widget:SetTexCoord(...) self.texCoord = { ... } end
function Widget:SetBlendMode(mode) self.blendMode = mode end
function Widget:SetDrawLayer(layer, subLevel) self.drawLayer = layer end
function Widget:SetDrawEdge() end
function Widget:SetHideCountdownNumbers() end
function Widget:SetCooldown(start, duration)
  self.cooldownStart, self.cooldownDuration = start, duration
end
function Widget:Clear() self.cooldownStart, self.cooldownDuration = nil, nil end
function Widget:SetText(text) self.text = tostring(text or "") end
function Widget:GetText() return self.text end
function Widget:SetFont(font, size, flags) self.font, self.fontSize, self.fontFlags = font, size, flags end
function Widget:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
function Widget:SetJustifyH(justify) self.justifyH = justify end
function Widget:SetJustifyV(justify) self.justifyV = justify end
function Widget:SetShadowColor(...) self.shadowColor = { ... } end
function Widget:SetShadowOffset(x, y) self.shadowOffset = { x, y } end
function Widget:SetWordWrap(wrap) self.wordWrap = wrap end
function Widget:SetMaxLines(lines) self.maxLines = lines end
function Widget:SetNonSpaceWrap(wrap) self.nonSpaceWrap = wrap end
function Widget:SetSpacing(spacing) self.spacing = spacing end
function Widget:SetAutoFocus(auto) self.autoFocus = auto end
function Widget:SetTextInsets(...) self.textInsets = { ... } end
function Widget:SetMaxLetters(letters) self.maxLetters = letters end
function Widget:SetFocus() self.focused = true end
function Widget:ClearFocus() self.focused = false end
function Widget:HasFocus() return self.focused end
function Widget:HighlightText() self.highlighted = true end
function Widget:SetChecked(checked) self.checked = checked end
function Widget:GetChecked() return self.checked end
function Widget:SetNormalTexture(texture) self.normalTexture = texture end
function Widget:SetHighlightTexture(texture) self.highlightTexture = texture end
function Widget:SetPushedTexture(texture) self.pushedTexture = texture end
function Widget:SetAttribute(key, value) self.attributes[key] = value end
function Widget:GetAttribute(key) return self.attributes[key] end
function Widget:SetAlpha_(alpha) self.alpha = alpha end

-- ---------------------------------------------------------------------------
-- global API
-- ---------------------------------------------------------------------------

local function unit(name)
  local data = Mock.units[name]
  if data and data.exists == false then return nil end
  return data
end

function Mock.Install()
  UIParent = newWidget("Frame", "UIParent")
  UIParent.width, UIParent.height = 1920, 1080

  CreateFrame = function(frameType, name, parent, template)
    return newWidget(frameType, name, parent, template)
  end

  SlashCmdList = {}
  UISpecialFrames = {}
  StaticPopupDialogs = {}

  DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, message)
      table.insert(Mock.chat, message)
    end,
  }
  ChatFrame1 = DEFAULT_CHAT_FRAME

  GameTooltip = {
    SetOwner = function() end,
    SetUnit = function(self, value) self.unit = value end,
    AddLine = function() end,
    ClearLines = function() end,
    SetText = function() end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
  }

  StaticPopup_Show = function(dialog, arg1, arg2, data)
    Mock.popupShown = { dialog = dialog, arg1 = arg1, data = data }
  end

  RAID_CLASS_COLORS = {
    PALADIN = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
  }

  PowerBarColor = {
    [0] = { r = 0.00, g = 0.32, b = 0.78 },
    [1] = { r = 0.78, g = 0.10, b = 0.10 },
    [2] = { r = 0.95, g = 0.55, b = 0.10 },
  }

  DebuffTypeColor = {
    Magic = { r = 0.20, g = 0.60, b = 1.00 },
    Curse = { r = 0.60, g = 0.00, b = 1.00 },
  }

  GetLocale = function() return "esES" end
  GetTime = function() return Mock.time end
  GetRealmName = function() return "TestRealm" end
  InCombatLockdown = function() return Mock.inCombat end
  ReloadUI = function() Mock.reloaded = true end
  date = os.date

  UnitExists = function(name) return unit(name) ~= nil end
  UnitName = function(name)
    local data = unit(name)
    return data and data.name or nil
  end
  UnitClass = function(name)
    local data = unit(name)
    if not data then return nil end
    return data.className or data.classFile, data.classFile, data.classID
  end
  UnitLevel = function(name)
    local data = unit(name)
    return data and data.level or 0
  end
  UnitHealth = function(name)
    local data = unit(name)
    return data and data.health or 0
  end
  UnitHealthMax = function(name)
    local data = unit(name)
    return data and data.maxHealth or 100
  end
  UnitPower = function(name, powerType)
    local data = unit(name)
    if not data then return 0 end
    if data.powers and powerType then return data.powers[powerType] or 0 end
    return data.power or 0
  end
  UnitPowerMax = function(name, powerType)
    local data = unit(name)
    if not data then return 0 end
    if data.powerMax and powerType then return data.powerMax[powerType] or 0 end
    return data.maxPower or 0
  end
  UnitPowerType = function(name)
    local data = unit(name)
    return data and data.powerType or 0
  end
  UnitClassification = function(name)
    local data = unit(name)
    return data and data.classification or "normal"
  end
  UnitIsDeadOrGhost = function(name)
    local data = unit(name)
    return data and data.dead or false
  end
  UnitCanAttack = function(_, name)
    local data = unit(name)
    return data and (not data.friendly) or false
  end
  UnitIsFriend = function(_, name)
    local data = unit(name)
    return data and data.friendly or false
  end
  UnitIsPlayer = function(name)
    local data = unit(name)
    return data and data.classFile ~= nil
  end
  UnitIsConnected = function(name)
    local data = unit(name)
    return data and data.connected ~= false
  end
  GetRaidTargetIndex = function(name)
    local data = unit(name)
    return data and data.raidMarker or nil
  end
  SetRaidTargetIconTexture = function(texture, index)
    texture.raidIndex = index
  end
  SetPortraitTexture = function(texture, name)
    texture.portraitUnit = name
  end

  UnitCastingInfo = function(name)
    local cast = Mock.casts[name]
    if not cast or cast.channel then return nil end
    return cast.name, cast.text, cast.icon, cast.startTime, cast.endTime, false, 1, cast.notInterruptible, cast.spellId
  end
  UnitChannelInfo = function(name)
    local cast = Mock.casts[name]
    if not cast or not cast.channel then return nil end
    return cast.name, cast.text, cast.icon, cast.startTime, cast.endTime, false, cast.notInterruptible, cast.spellId
  end

  C_UnitAuras = {
    GetAuraDataByIndex = function(name, index, filter)
      local list = Mock.auras[name .. "|" .. filter]
      if not list then return nil end
      return list[index]
    end,
  }
  AuraUtil = {
    ForEachAura = function(name, filter, maxCount, callback)
      local list = Mock.auras[name .. "|" .. filter] or {}
      for _, aura in ipairs(list) do
        if callback(aura) then return end
      end
    end,
  }
  UnitAura = function(name, index, filter)
    local list = Mock.auras[name .. "|" .. filter]
    local aura = list and list[index]
    if not aura then return nil end
    return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, nil, nil, nil, aura.spellId
  end

  GetActionTexture = function(slot) return Mock.actions[slot] or nil end
  HasAction = function(slot) return Mock.actions[slot] ~= nil end
  GetActionCooldown = function(slot) return 0, 0, 1 end
  GetActionCount = function(slot) return 0 end
  IsUsableAction = function() return true end
  IsActionInRange = function() return 1 end
  GetBindingKey = function(binding) return Mock.bindings[binding] end
  GetBindingText = function(key) return key end
end

function Mock.Fire(event, ...)
  local list = Mock.handlers[event]
  if not list then return end
  for _, entry in ipairs(list) do
    local script = entry.widget.scripts.OnEvent
    if script then
      local ok, err = pcall(script, entry.widget, event, ...)
      if not ok then
        error("event " .. event .. " failed: " .. tostring(err), 0)
      end
    end
  end
end

function Mock.ChatText()
  return table.concat(Mock.chat, "\n")
end

function Mock.ClearChat()
  Mock.chat = {}
end

function Mock.ResetUnits()
  Mock.units = {
    player = {
      exists = true, name = "Aelric", classFile = "PALADIN", className = "Paladin", classID = 2,
      level = 60, health = 8000, maxHealth = 10000, power = 4000, maxPower = 5000,
      powerType = 0, friendly = true, connected = true,
    },
    target = {
      exists = true, name = "Senor del Foso", classFile = "WARRIOR", className = "Warrior", classID = 1,
      level = -1, health = 150000, maxHealth = 300000, power = 0, maxPower = 0,
      powerType = 1, friendly = false, connected = true, classification = "worldboss",
    },
  }
  Mock.auras = {
    ["player|HELPFUL"] = {
      { name = "Bendicion", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", applications = 0, duration = 900, expirationTime = Mock.time + 900 },
      { name = "Escudo", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", applications = 2, duration = 12, expirationTime = Mock.time + 12 },
    },
    ["player|HARMFUL"] = {},
    ["target|HARMFUL"] = {
      { name = "Fuego", icon = "Interface\\Icons\\Spell_Fire_Immolation", applications = 0, duration = 8, expirationTime = Mock.time + 8, dispelName = "Magic" },
    },
  }
  Mock.casts = {}
  Mock.actions = {}
  for slot = 1, 12 do Mock.actions[slot] = "Interface\\Icons\\INV_Misc_QuestionMark" end
  for slot = 61, 72 do Mock.actions[slot] = "Interface\\Icons\\INV_Misc_QuestionMark" end
  Mock.bindings = {}
  for index = 1, 12 do Mock.bindings["ACTIONBUTTON" .. index] = tostring(index) end
end

Mock.ResetUnits()
Mock.Install()

return Mock
