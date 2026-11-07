--[[ ForeverHUD :: Config
     One dark panel, six sections, declarative controls. Every change is written
     to the active profile and applied live. ]]
local ADDON, ns = ...
local L = ns.L

local PANEL_WIDTH = 720
local PANEL_HEIGHT = 566
local NAV_WIDTH = 168
local CONTENT_WIDTH = PANEL_WIDTH - NAV_WIDTH - 40

local panel
local navButtons = {}
local sectionFrames = {}
local activeSection = "general"
local unitEditing = "player"

local SECTIONS = {
  { id = "general", label = function() return L.general end },
  { id = "units", label = function() return L.units end },
  { id = "castbars", label = function() return L.castbars end },
  { id = "auras", label = function() return L.auras end },
  { id = "actionbars", label = function() return L.actionbars end },
  { id = "profiles", label = function() return L.profiles end },
}

-- ---------------------------------------------------------------------------
-- widget factory
-- ---------------------------------------------------------------------------

local ROW = 32

local function NewRow(parent, y, height)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
  row:SetHeight(height or ROW)
  return row
end

local function RowLabel(row, text, width)
  local label = ns:CreateText(row, 12, ns.theme.text, "OUTLINE")
  label:SetPoint("LEFT", row, "LEFT", 0, 0)
  label:SetText(text)
  label:SetJustifyH("LEFT")
  if width then label:SetWidth(width) end
  return label
end

local function AddHeader(body, y, text)
  local label = ns:CreateText(body, 10, ns.theme.accent, "OUTLINE")
  label:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
  label:SetText(string.upper(text))
  label:SetJustifyH("LEFT")
  local line = body:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(ns.theme.border[1], ns.theme.border[2], ns.theme.border[3], 0.7)
  line:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -(y + 17))
  line:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -(y + 17))
  line:SetHeight(1)
  return y + 30
end

local function AddToggle(body, y, text, path)
  local row = NewRow(body, y)
  RowLabel(row, text)

  local check = CreateFrame("Button", nil, row, "BackdropTemplate")
  check:SetSize(20, 20)
  check:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  ns:ApplyBackdrop(check, { 0.04, 0.04, 0.05, 1 }, ns.theme.border)

  local tick = check:CreateTexture(nil, "ARTWORK")
  tick:SetPoint("TOPLEFT", check, "TOPLEFT", 3, -3)
  tick:SetPoint("BOTTOMRIGHT", check, "BOTTOMRIGHT", -3, 3)
  tick:SetColorTexture(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 1)
  check.tick = tick

  local function paint()
    if ns:Get(path) then
      tick:Show()
      check:SetBackdropBorderColor(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 1)
    else
      tick:Hide()
      check:SetBackdropBorderColor(ns.theme.border[1], ns.theme.border[2], ns.theme.border[3], 1)
    end
  end

  check:SetScript("OnClick", function()
    ns:Set(path, not ns:Get(path))
    paint()
    ns:ApplyAll()
  end)
  paint()
  return ROW
end

local function AddSlider(body, y, text, path, minValue, maxValue, step, formatter)
  local row = NewRow(body, y, 42)
  RowLabel(row, text)

  local valueText = ns:CreateText(row, 11, ns.theme.accent, "OUTLINE")
  valueText:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
  valueText:SetJustifyH("RIGHT")

  local slider = CreateFrame("Slider", nil, row)
  slider:SetOrientation("HORIZONTAL")
  slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -21)
  slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -21)
  slider:SetHeight(12)
  slider:SetMinMaxValues(minValue, maxValue)
  if slider.SetValueStep then slider:SetValueStep(step) end
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  if slider.SetThumbTexture then
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local thumb = slider:GetThumbTexture()
    if thumb and thumb.SetSize then thumb:SetSize(12, 22) end
  end

  local current = ns:Get(path, minValue)
  if type(current) ~= "number" then current = minValue end
  slider:SetValue(current)
  valueText:SetText(formatter and formatter(current) or tostring(current))

  slider:SetScript("OnValueChanged", function(_, value)
    local rounded = math.floor((value or minValue) / step + 0.5) * step
    valueText:SetText(formatter and formatter(rounded) or tostring(rounded))
  end)

  slider:SetScript("OnMouseUp", function(self)
    local value = self:GetValue()
    local rounded = math.floor((value or minValue) / step + 0.5) * step
    rounded = ns:Clamp(rounded, minValue, maxValue)
    ns:Set(path, rounded)
    ns:ApplyAll()
  end)
  return 42
end

local function AddChoice(body, y, text, path, options, onChange, currentValue)
  local row = NewRow(body, y)
  RowLabel(row, text)

  local button = CreateFrame("Button", nil, row, "BackdropTemplate")
  button:SetSize(210, 22)
  button:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  ns:ApplyBackdrop(button, ns.theme.row, ns.theme.border)

  local label = ns:CreateText(button, 11, ns.theme.text, "OUTLINE")
  label:SetPoint("CENTER", button, "CENTER", 0, 0)

  local index = 1
  local value = currentValue
  if value == nil and path then value = ns:Get(path) end
  for position, option in ipairs(options) do
    if option.value == value then index = position end
  end
  label:SetText(options[index] and options[index].label or "")
  button:SetScript("OnEnter", function() button:SetBackdropBorderColor(ns.theme.borderHi[1], ns.theme.borderHi[2], ns.theme.borderHi[3], 1) end)
  button:SetScript("OnLeave", function() button:SetBackdropBorderColor(ns.theme.border[1], ns.theme.border[2], ns.theme.border[3], 1) end)
  button:SetScript("OnClick", function()
    index = (index % #options) + 1
    if path then ns:Set(path, options[index].value) end
    label:SetText(options[index].label)
    if onChange then onChange(options[index].value) end
    ns:ApplyAll()
  end)
  return ROW
end

local function AddButton(body, y, text, onClick, width)
  local row = NewRow(body, y, 30)
  local button = CreateFrame("Button", nil, row, "BackdropTemplate")
  button:SetSize(width or 150, 24)
  button:SetPoint("LEFT", row, "LEFT", 0, 0)
  ns:ApplyBackdrop(button, ns.theme.row, ns.theme.border)
  local label = ns:CreateText(button, 11, ns.theme.text, "OUTLINE")
  label:SetPoint("CENTER", button, "CENTER", 0, 0)
  label:SetText(text)
  button:SetScript("OnEnter", function() button:SetBackdropBorderColor(ns.theme.borderHi[1], ns.theme.borderHi[2], ns.theme.borderHi[3], 1) end)
  button:SetScript("OnLeave", function() button:SetBackdropBorderColor(ns.theme.border[1], ns.theme.border[2], ns.theme.border[3], 1) end)
  button:SetScript("OnClick", onClick)
  return 30, button
end

local function AddEdit(body, y, text, width, onEnter, defaultText)
  local row = NewRow(body, y, 30)
  RowLabel(row, text)
  local edit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
  edit:SetSize(width or 220, 24)
  edit:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  ns:ApplyBackdrop(edit, { 0.035, 0.035, 0.045, 1 }, ns.theme.border)
  if edit.SetFont then edit:SetFont(ns.font, 11, "OUTLINE") end
  edit:SetTextInsets(6, 6, 0, 0)
  edit:SetAutoFocus(false)
  if edit.SetMaxLetters then edit:SetMaxLetters(60000) end
  edit:SetText(defaultText or "")
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  edit:SetScript("OnEnterPressed", function(self)
    if onEnter then onEnter(self:GetText() or "") end
    self:ClearFocus()
  end)
  return 30, edit
end

local function NewSectionBody(parent)
  local body = CreateFrame("Frame", nil, parent)
  body:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  body:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  body:SetHeight(10)
  return body
end

-- ---------------------------------------------------------------------------
-- sections
-- ---------------------------------------------------------------------------

local function BuildGeneral(parent)
  local body = NewSectionBody(parent)
  local y = 4
  y = y + AddSlider(body, y, L.scale, "general.scale", 0.6, 1.6, 0.05, function(value) return string.format("%.2fx", value) end)
  y = y + AddToggle(body, y, L.locked, "general.locked")
  y = y + AddToggle(body, y, L.combatFade, "general.combatFade")
  y = y + AddToggle(body, y, L.hideBlizzard, "general.hideBlizzard")
  y = y + AddToggle(body, y, L.loginMessage, "general.loginMessage")
  y = y + AddChoice(body, y, L.language, "general.language", {
    { value = "auto", label = L.languageAuto },
    { value = "es", label = L.spanish },
    { value = "en", label = L.english },
  }, function()
    ns:Print(L.needsReload)
  end)
  y = y + AddHeader(body, y + 6, L.about)
  local info = ns:CreateText(body, 11, ns.theme.muted, "OUTLINE")
  info:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
  info:SetWidth(CONTENT_WIDTH)
  info:SetJustifyH("LEFT")
  info:SetText("ForeverHUD " .. ns.version .. "  ·  Interface 16001  ·  MIT\n" .. "github.com/smouj/forever-hud")
  return body
end

local function BuildUnits(parent)
  local body = NewSectionBody(parent)
  local y = 4
  local storedUnit = ns:Get("ui.unitEditing", "player")
  if storedUnit == "player" or storedUnit == "target" or storedUnit == "focus" or storedUnit == "pet" or storedUnit == "targettarget" then
    unitEditing = storedUnit
  end
  y = y + AddChoice(body, y, L.unitToEdit, nil, {
    { value = "player", label = L.player },
    { value = "target", label = L.target },
    { value = "focus", label = L.focus },
    { value = "pet", label = L.pet },
    { value = "targettarget", label = L.targettarget },
  }, function(value)
    unitEditing = value
    ns:Set("ui.unitEditing", value)
    ns.ConfigAPI.Rebuild("units")
  end, unitEditing)

  local prefix = "units." .. unitEditing .. "."
  y = y + AddToggle(body, y, L.enabled, prefix .. "enabled")
  y = y + AddSlider(body, y, L.width, prefix .. "width", 120, 420, 2, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.height, prefix .. "height", 20, 90, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddChoice(body, y, L.healthText, prefix .. "healthText", {
    { value = "both", label = L.both },
    { value = "value", label = L.value },
    { value = "percent", label = L.percent },
    { value = "none", label = L.none },
  })
  y = y + AddToggle(body, y, L.classColors, prefix .. "classColors")
  y = y + AddToggle(body, y, L.portrait, prefix .. "portrait")
  y = y + AddToggle(body, y, L.showName, prefix .. "showName")
  y = y + AddToggle(body, y, L.showLevel, prefix .. "showLevel")
  y = y + AddToggle(body, y, L.tooltip, prefix .. "tooltip")
  return body
end

local function BuildCastbars(parent)
  local body = NewSectionBody(parent)
  local y = 4
  y = y + AddToggle(body, y, L.enabled, "castbars.enabled")
  y = y + AddToggle(body, y, L.playerCast, "castbars.playerEnabled")
  y = y + AddToggle(body, y, L.targetCast, "castbars.targetEnabled")
  y = y + AddSlider(body, y, L.width, "castbars.width", 140, 420, 2, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.height, "castbars.height", 12, 40, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddToggle(body, y, L.showIcon, "castbars.showIcon")
  y = y + AddToggle(body, y, L.showTime, "castbars.showTime")
  y = y + AddToggle(body, y, L.interruptHint, "castbars.interruptHint")
  return body
end

local function BuildAuras(parent)
  local body = NewSectionBody(parent)
  local y = 4
  y = y + AddToggle(body, y, L.enabled, "auras.enabled")
  y = y + AddSlider(body, y, L.auraSize, "auras.size", 16, 56, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.perRow, "auras.perRow", 4, 16, 1, function(value) return ns:Round(value) end)
  y = y + AddSlider(body, y, L.spacing, "auras.spacing", 0, 12, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.maxAuras, "auras.maxAuras", 4, 24, 1, function(value) return ns:Round(value) end)
  y = y + AddToggle(body, y, L.buffs, "auras.buffs")
  y = y + AddToggle(body, y, L.debuffs, "auras.debuffs")
  y = y + AddToggle(body, y, L.targetDebuffs, "auras.targetDebuffs")
  y = y + AddToggle(body, y, L.permanent, "auras.permanent")
  return body
end

local function BuildActionBars(parent)
  local body = NewSectionBody(parent)
  local y = 4
  y = y + AddToggle(body, y, L.enabled, "actionbars.enabled")
  y = y + AddSlider(body, y, L.rows, "actionbars.rows", 1, 3, 1, function(value) return ns:Round(value) end)
  y = y + AddSlider(body, y, L.buttonsPerRow, "actionbars.buttonsPerRow", 4, 12, 1, function(value) return ns:Round(value) end)
  y = y + AddSlider(body, y, L.buttonSize, "actionbars.buttonSize", 22, 56, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.spacing, "actionbars.spacing", 0, 12, 1, function(value) return ns:Round(value) .. " px" end)
  y = y + AddSlider(body, y, L.alpha, "actionbars.alpha", 0.2, 1, 0.05, function(value) return string.format("%d%%", ns:Round(value * 100)) end)
  y = y + AddToggle(body, y, L.showKeybinds, "actionbars.showKeybinds")
  y = y + AddToggle(body, y, L.showCounts, "actionbars.showCounts")
  y = y + AddToggle(body, y, L.barBackground, "actionbars.background")
  return body
end

local function BuildProfiles(parent)
  local body = NewSectionBody(parent)
  local y = 4

  local names = ns:ProfileNames()
  local options = {}
  for _, name in ipairs(names) do
    options[#options + 1] = { value = name, label = name }
  end
  if #options == 0 then options[1] = { value = "Default", label = "Default" } end

  y = y + AddChoice(body, y, L.activeProfile, nil, options, function(value)
    local ok = ns:SetProfile(value)
    if ok then
      ns:Print(string.format(L.profileSwitched, value))
      panel.subtitle:SetText("v" .. ns.version .. "  ·  " .. ns:ProfileName())
      ns.ConfigAPI.Rebuild("profiles")
    end
  end, ns:ProfileName())

  local rowHeight
  local newEdit
  rowHeight, newEdit = AddEdit(body, y, L.profileName, 220, function(text)
    local name = (text or ""):match("^%s*(.-)%s*$")
    if name == "" then ns:Print(L.invalidName) return end
    local ok, reason = ns:NewProfile(name)
    if not ok then
      ns:Print(reason == "invalid" and L.invalidName or L.profileMissing)
      return
    end
    ns:SetProfile(name)
    ns:Print(string.format(L.profileCreated, name))
    newEdit:SetText("")
    ns.ConfigAPI.Rebuild("profiles")
  end)
  y = y + rowHeight
  y = y + select(1, AddButton(body, y, L.newProfile, function()
    local text = newEdit:GetText() or ""
    local name = text:match("^%s*(.-)%s*$")
    if name == "" then
      ns:Print(L.invalidName)
      return
    end
    local ok = ns:NewProfile(name)
    if not ok then ns:Print(L.profileMissing) return end
    ns:SetProfile(name)
    ns:Print(string.format(L.profileCreated, name))
    newEdit:SetText("")
    ns.ConfigAPI.Rebuild("profiles")
  end, 150))

  local copyName = ns:ProfileName() .. " copy"
  local copyIndex = 1
  while ns.db.profiles[copyName] do
    copyIndex = copyIndex + 1
    copyName = ns:ProfileName() .. " copy " .. copyIndex
  end
  y = y + select(1, AddButton(body, y, L.copyProfile, function()
    local ok, reason = ns:CopyProfile(ns:ProfileName(), copyName)
    if not ok then ns:Print(reason == "exists" and L.invalidName or L.profileMissing) return end
    ns:SetProfile(copyName)
    ns:Print(string.format(L.profileCopied, ns:ProfileName(), copyName))
    ns.ConfigAPI.Rebuild("profiles")
  end, 150))

  local deletable = {}
  for _, name in ipairs(names) do
    if name ~= ns:ProfileName() then deletable[#deletable + 1] = { value = name, label = name } end
  end
  if #deletable == 0 then deletable[1] = { value = "", label = L.none } end
  local deleteChoice = deletable[1].value
  local deleteRow = AddChoice(body, y, L.deleteProfile, nil, deletable, function(value)
    deleteChoice = value
  end, deleteChoice)

  y = y + select(1, AddButton(body, y, L.deleteProfile, function()
    if deleteChoice == "" then
      ns:Print(L.profileInUse)
      return
    end
    if StaticPopup_Show then
      StaticPopup_Show("FOREVERHUD_DELETE_PROFILE", deleteChoice, nil, deleteChoice)
    else
      if ns:DeleteProfile(deleteChoice) then
        ns:Print(string.format(L.profileDeleted, deleteChoice))
        ns.ConfigAPI.Rebuild("profiles")
      end
    end
  end, 150))

  y = y + select(1, AddButton(body, y, L.resetProfile, function()
    ns:ResetProfile()
    ns:Print(string.format(L.profileReset, ns:ProfileName()))
    ns.ConfigAPI.Rebuild("profiles")
  end, 150))

  y = y + AddHeader(body, y + 6, L.exportProfile)
  local exportEdit
  rowHeight, exportEdit = AddEdit(body, y, L.exportProfile, 330, nil, "")
  y = y + rowHeight
  ns.ConfigAPI.exportEdit = exportEdit

  y = y + select(1, AddButton(body, y, L.exportProfile, function()
    local text = ns:Serialize()
    if ns.ConfigAPI.exportEdit then
      ns.ConfigAPI.exportEdit:SetText(text)
      ns.ConfigAPI.exportEdit:SetFocus()
      ns.ConfigAPI.exportEdit:HighlightText()
    end
    ns:Print(L.exported)
  end, 150))

  local importEdit
  rowHeight, importEdit = AddEdit(body, y, L.importProfile, 330, function(text)
    local profile = ns:Deserialize(text)
    if not profile then ns:Print(L.importFailed) return end
    local name = "Import " .. date("%Y%m%d-%H%M")
    local index = 1
    while ns.db.profiles[name] do
      index = index + 1
      name = "Import " .. date("%Y%m%d-%H%M") .. " " .. index
    end
    ns.db.profiles[name] = profile
    ns:SetProfile(name)
    ns:Print(string.format(L.imported, name))
    ns.ConfigAPI.Rebuild("profiles")
  end)
  y = y + rowHeight
  y = y + select(1, AddButton(body, y, L.importProfile, function()
    local profile = ns:Deserialize(importEdit:GetText() or "")
    if not profile then ns:Print(L.importFailed) return end
    local name = "Import " .. date("%Y%m%d-%H%M")
    local index = 1
    while ns.db.profiles[name] do
      index = index + 1
      name = "Import " .. date("%Y%m%d-%H%M") .. " " .. index
    end
    ns.db.profiles[name] = profile
    ns:SetProfile(name)
    ns:Print(string.format(L.imported, name))
    ns.ConfigAPI.Rebuild("profiles")
  end, 150))

  y = y + select(1, AddButton(body, y, L.reloadUI, function()
    if ReloadUI then ReloadUI() end
  end, 150))

  return body
end

local BUILDERS = {
  general = BuildGeneral,
  units = BuildUnits,
  castbars = BuildCastbars,
  auras = BuildAuras,
  actionbars = BuildActionBars,
  profiles = BuildProfiles,
}

-- ---------------------------------------------------------------------------
-- panel chrome
-- ---------------------------------------------------------------------------

local function SelectSection(id)
  activeSection = id
  for key, frame in pairs(sectionFrames) do
    if key == id then frame:Show() else frame:Hide() end
  end
  for key, button in pairs(navButtons) do
    if key == id then
      button.selected:Show()
      button.label:SetTextColor(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 1)
    else
      button.selected:Hide()
      button.label:SetTextColor(ns.theme.muted[1], ns.theme.muted[2], ns.theme.muted[3], 1)
    end
  end
  ns.ConfigAPI.Rebuild(id)
end

function ns.ConfigAPI_Rebuild(id)
  id = id or activeSection
  if not panel then return end
  local builder = BUILDERS[id]
  if not builder then return end
  local old = sectionFrames[id]
  if old then
    old:Hide()
    old:ClearAllPoints()
    old:SetParent(nil)
  end
  local holder = CreateFrame("Frame", nil, panel.content)
  holder:SetAllPoints(panel.content)
  local body = builder(holder)
  holder.body = body
  sectionFrames[id] = holder
  if id == activeSection then holder:Show() else holder:Hide() end
end

local function CreatePanel()
  panel = CreateFrame("Frame", "ForeverHUDConfigPanel", UIParent, "BackdropTemplate")
  panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG")
  panel:SetToplevel(true)
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  ns:ApplyBackdrop(panel, ns.theme.panel, ns.theme.borderHi)
  panel:Hide()

  local title = ns:CreateText(panel, 18, ns.theme.accent, "OUTLINE")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -16)
  title:SetText("ForeverHUD")
  panel.title = title

  local subtitle = ns:CreateText(panel, 10, ns.theme.muted, "OUTLINE")
  subtitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -40)
  subtitle:SetText("v" .. ns.version .. "  ·  " .. ns:ProfileName())
  panel.subtitle = subtitle

  local close = CreateFrame("Button", nil, panel, "BackdropTemplate")
  close:SetSize(22, 22)
  close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -12)
  ns:ApplyBackdrop(close, ns.theme.row, ns.theme.border)
  local closeText = ns:CreateText(close, 14, ns.theme.muted, "OUTLINE")
  closeText:SetPoint("CENTER", close, "CENTER", 0, 0)
  closeText:SetText("x")
  close:SetScript("OnClick", function() panel:Hide() end)

  local nav = CreateFrame("Frame", nil, panel)
  nav:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -64)
  nav:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 14)
  nav:SetWidth(NAV_WIDTH)

  local divider = panel:CreateTexture(nil, "ARTWORK")
  divider:SetColorTexture(ns.theme.border[1], ns.theme.border[2], ns.theme.border[3], 0.8)
  divider:SetPoint("TOPLEFT", nav, "TOPRIGHT", 12, 0)
  divider:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 12, 0)
  divider:SetWidth(1)

  panel.content = CreateFrame("Frame", nil, panel)
  panel.content:SetPoint("TOPLEFT", divider, "TOPLEFT", 18, 0)
  panel.content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)

  for index, section in ipairs(SECTIONS) do
    local button = CreateFrame("Button", nil, nav, "BackdropTemplate")
    button:SetPoint("TOPLEFT", nav, "TOPLEFT", 0, -((index - 1) * 34))
    button:SetPoint("TOPRIGHT", nav, "TOPRIGHT", 0, -((index - 1) * 34))
    button:SetHeight(30)
    button:SetScript("OnClick", function() SelectSection(section.id) end)
    button:SetScript("OnEnter", function() button:SetBackdropColor(ns.theme.row[1], ns.theme.row[2], ns.theme.row[3], 0.9) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(0, 0, 0, 0) end)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    button:SetBackdropColor(0, 0, 0, 0)

    local selected = button:CreateTexture(nil, "OVERLAY")
    selected:SetColorTexture(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 1)
    selected:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    selected:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    selected:SetWidth(2)
    selected:Hide()
    button.selected = selected

    local label = ns:CreateText(button, 12, ns.theme.muted, "OUTLINE")
    label:SetPoint("LEFT", button, "LEFT", 12, 0)
    label:SetText(section.label())
    button.label = label

    navButtons[section.id] = button
  end

  table.insert(UISpecialFrames, "ForeverHUDConfigPanel")
end

local function Open(section)
  if not panel then CreatePanel() end
  if ns.db == nil then ns:InitDB() end
  panel.subtitle:SetText("v" .. ns.version .. "  ·  " .. ns:ProfileName())
  SelectSection(section or activeSection or "general")
  panel:Show()
  panel:Raise()
end

StaticPopupDialogs["FOREVERHUD_DELETE_PROFILE"] = {
  text = L.deleteConfirm,
  button1 = L.accept,
  button2 = L.cancel,
  OnAccept = function(_, data)
    if not data then return end
    if ns:DeleteProfile(data) then
      ns:Print(string.format(L.profileDeleted, data))
      if panel and panel:IsShown() then ns.ConfigAPI.Rebuild("profiles") end
    else
      ns:Print(L.profileInUse)
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

ns.ConfigAPI = {
  Open = Open,
  Rebuild = function(id) ns.ConfigAPI_Rebuild(id) end,
  ShowExport = function(text)
    Open("profiles")
    if ns.ConfigAPI.exportEdit then
      ns.ConfigAPI.exportEdit:SetText(text)
      ns.ConfigAPI.exportEdit:SetFocus()
      ns.ConfigAPI.exportEdit:HighlightText()
    end
  end,
}

