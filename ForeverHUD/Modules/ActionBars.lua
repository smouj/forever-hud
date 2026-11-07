--[[ ForeverHUD :: Action bars
     Secure action buttons. Attributes are only written out of combat, and no
     button is ever clicked or driven by the addon itself. ]]
local ADDON, ns = ...
local L = ns.L

local bars = {}
local buttons = {}
local module = { bars = bars, buttons = buttons }
local BAR_POINTS = { "CENTER", "CENTER", "CENTER" }
local ROW_BINDINGS = {
  { "ACTIONBUTTON", 1 },
  { "MULTIACTIONBAR1BUTTON", 1 },
  { "MULTIACTIONBAR2BUTTON", 1 },
}
local ROW_SLOTS = { 1, 61, 49 }

local function InCombat()
  return InCombatLockdown and InCombatLockdown()
end

local function ActionTexture(slot)
  if C_ActionBar and C_ActionBar.GetActionTexture then
    return C_ActionBar.GetActionTexture(slot)
  end
  if GetActionTexture then return GetActionTexture(slot) end
  return nil
end

local function ActionCooldown(slot)
  if C_ActionBar and C_ActionBar.GetActionCooldown then
    return C_ActionBar.GetActionCooldown(slot)
  end
  if GetActionCooldown then return GetActionCooldown(slot) end
  return 0, 0, 0
end

local function HasAction_(slot)
  if C_ActionBar and C_ActionBar.HasAction then return C_ActionBar.HasAction(slot) end
  if HasAction then return HasAction(slot) end
  return false
end

local function ActionCount(slot)
  if GetActionCount then return GetActionCount(slot) or 0 end
  return 0
end

local function CreateButton(index, parent)
  local button = CreateFrame("CheckButton", "ForeverHUD_ActionButton" .. index, parent, "SecureActionButtonTemplate,BackdropTemplate")
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("type", "action")
  button:SetSize(36, 36)

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(button)
  background:SetColorTexture(0.02, 0.02, 0.03, 0.72)
  button.background = background

  ns:ApplyBackdrop(button, { 0.02, 0.02, 0.03, 0.72 }, ns.theme.border)

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

  local count = ns:CreateText(button, 12, ns.theme.text, "OUTLINE")
  count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
  count:SetJustifyH("RIGHT")
  button.count = count

  local keybind = ns:CreateText(button, 9, ns.theme.muted, "OUTLINE")
  keybind:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -2)
  keybind:SetJustifyH("LEFT")
  button.keybind = keybind

  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

  button.slot = nil
  return button
end

local function UpdateButton(button, showCounts, showKeybinds)
  local slot = button.slot
  if not slot then
    button:Hide()
    return
  end

  local texture = ActionTexture(slot)
  if texture and HasAction_(slot) then
    button.icon:SetTexture(texture)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetDesaturated(false)
    button.icon:SetVertexColor(1, 1, 1, 1)
    button.icon:Show()
  else
    button.icon:SetTexture(nil)
    button.icon:Hide()
  end

  if showCounts then
    local countValue = ActionCount(slot)
    if countValue and countValue > 1 then
      button.count:SetText(tostring(countValue))
    else
      button.count:SetText("")
    end
  else
    button.count:SetText("")
  end

  if showKeybinds then
    local binding = button.binding
    local key = binding and GetBindingKey and GetBindingKey(binding)
    if key then
      local text = key
      if GetBindingText then text = GetBindingText(key, "KEY_", true) end
      button.keybind:SetText(text)
      button.keybind:Show()
    else
      button.keybind:SetText("")
    end
  else
    button.keybind:SetText("")
  end

  -- usable / range feedback
  local usable = true
  if IsUsableAction then
    usable = IsUsableAction(slot)
  end
  if not usable then
    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(0.45, 0.45, 0.85, 1)
  else
    button.icon:SetDesaturated(false)
    local inRange = nil
    if IsActionInRange then inRange = IsActionInRange(slot) end
    if inRange == false or inRange == 0 then
      button.icon:SetVertexColor(0.85, 0.25, 0.20, 1)
    else
      button.icon:SetVertexColor(1, 1, 1, 1)
    end
  end
end

local function UpdateCooldown(button)
  if not button.slot then return end
  local start, duration, enable = ActionCooldown(button.slot)
  if start and duration and duration > 0 and enable ~= 0 then
    button.cooldown:SetCooldown(start, duration)
    button.cooldown:Show()
  else
    button.cooldown:Clear()
    button.cooldown:Hide()
  end
end

local function UpdateAll()
  local cfg = ns:Get("actionbars")
  if not cfg then return end
  for _, button in ipairs(buttons) do
    UpdateButton(button, cfg.showCounts, cfg.showKeybinds)
    UpdateCooldown(button)
  end
end

function module:Apply()
  if InCombat() then
    ns:RunOutOfCombat(function() module:Apply() end)
    return
  end
  local cfg = ns:Get("actionbars")
  if not cfg then return end
  local bar = bars.main
  if not cfg.enabled then
    bar:Hide()
    return
  end

  local size = ns:Clamp(cfg.buttonSize or 36, 18, 64)
  local spacing = ns:Clamp(cfg.spacing or 4, 0, 20)
  local perRow = ns:Clamp(cfg.buttonsPerRow or 12, 1, 12)
  local rows = ns:Clamp(cfg.rows or 2, 1, 3)
  local padding = 6

  local width = perRow * size + (perRow - 1) * spacing + padding * 2
  local height = rows * size + (rows - 1) * spacing + padding * 2

  local scale = ns:Get("general.scale", 1)
  bar:SetScale(scale ~= 1 and scale or 1)
  bar:SetSize(width, height)
  bar:ClearAllPoints()
  bar:SetPoint(cfg.point or BAR_POINTS[1], UIParent, cfg.point or BAR_POINTS[1], cfg.x or 0, cfg.y or 0)
  bar:SetAlpha(ns:Clamp(cfg.alpha or 1, 0.15, 1))
  bar:Show()

  if cfg.background then
    if not bar.__backdropApplied then
      ns:ApplyBackdrop(bar)
      bar.__backdropApplied = true
    end
    bar:SetBackdropColor(ns.theme.bg[1], ns.theme.bg[2], ns.theme.bg[3], 0.85)
  elseif bar.__backdropApplied then
    bar:SetBackdrop(nil)
    bar.__backdropApplied = false
  end

  local index = 0
  for row = 1, rows do
    for column = 1, perRow do
      index = index + 1
      local button = buttons[index]
      if button then
        local slot = ROW_SLOTS[row] + column - 1
        local bindingBase = ROW_BINDINGS[row]
        local binding = nil
        if bindingBase and column <= 12 then
          binding = bindingBase[1] .. column
        end
        button.slot = slot
        button.binding = binding
        button:SetAttribute("action", slot)
        button:SetSize(size, size)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", bar, "TOPLEFT", padding + (column - 1) * (size + spacing), -(padding + (row - 1) * (size + spacing)))
        button:Show()
      end
    end
  end

  for position = index + 1, #buttons do
    buttons[position].slot = nil
    buttons[position]:Hide()
  end

  ns:MakeMovable(bar, "actionbars")
  ns:RegisterMovable(bar)
  bar:EnableMouse(not ns:Get("general.locked", true))

  if ns.preview.active then
    module:PreviewFill()
  else
    UpdateAll()
  end
end

function module:PreviewFill()
  local demo = {
    "Interface\\Icons\\Spell_Holy_HolyBolt",
    "Interface\\Icons\\Spell_Holy_FlashHeal",
    "Interface\\Icons\\Spell_Holy_PowerWordShield",
    "Interface\\Icons\\Spell_Holy_Renew",
    "Interface\\Icons\\Spell_Holy_DispelMagic",
    "Interface\\Icons\\Spell_Holy_Heal",
    "Interface\\Icons\\Spell_Holy_SealOfWisdom",
    "Interface\\Icons\\Spell_Holy_SealOfMight",
    "Interface\\Icons\\Spell_Holy_LayOnHands",
    "Interface\\Icons\\Spell_Holy_DivineShield",
    "Interface\\Icons\\Spell_Holy_Excorcism_02",
    "Interface\\Icons\\Spell_Holy_BlessingOfStrength",
    "Interface\\Icons\\Spell_Fire_Fireball02",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    "Interface\\Icons\\Spell_Arcane_Arcane01",
  }
  local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" }
  local cfg = ns:Get("actionbars")
  local perRow = ns:Clamp(cfg.buttonsPerRow or 12, 1, 12)
  for index, button in ipairs(buttons) do
    if button:IsShown() then
      local column = ((index - 1) % perRow) + 1
      button.icon:SetTexture(demo[index] or "Interface\\Icons\\INV_Misc_QuestionMark")
      button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      button.icon:Show()
      button.icon:SetDesaturated(false)
      button.icon:SetVertexColor(1, 1, 1, 1)
      button.count:SetText(index % 5 == 0 and "3" or "")
      button.keybind:SetText(cfg.showKeybinds and (keys[column] or "") or "")
      button.cooldown:Clear()
      button.cooldown:Hide()
    end
  end
end

function module:Refresh()
  if ns.preview.active then
    module:PreviewFill()
  else
    UpdateAll()
  end
end

function module:Initialize()
  local bar = CreateFrame("Frame", "ForeverHUD_ActionBar", UIParent, "BackdropTemplate")
  bar:SetSize(476, 88)
  bar:SetFrameStrata("MEDIUM")
  ns:ApplyBackdrop(bar)
  bar.__backdropApplied = true
  bars.main = bar

  for index = 1, 36 do
    buttons[index] = CreateButton(index, bar)
    buttons[index]:Hide()
  end
end

ns:RegisterModule("actionbars", module)

ns:On("ACTIONBAR_SLOT_CHANGED", function() UpdateAll() end)
ns:On("ACTIONBAR_UPDATE_COOLDOWN", function()
  for _, button in ipairs(buttons) do UpdateCooldown(button) end
end)
ns:On("ACTIONBAR_UPDATE_STATE", function() UpdateAll() end)
ns:On("ACTIONBAR_UPDATE_USABLE", function() UpdateAll() end)
ns:On("UPDATE_BINDINGS", function() UpdateAll() end)
ns:On("PLAYER_ENTERING_WORLD", function() UpdateAll() end)
ns:On("TICK", function(_, elapsed)
  module.cooldownAccum = (module.cooldownAccum or 0) + (elapsed or 0)
  if module.cooldownAccum < 0.5 then return end
  module.cooldownAccum = 0
  for _, button in ipairs(buttons) do
    if button.slot then UpdateCooldown(button) end
  end
end)
