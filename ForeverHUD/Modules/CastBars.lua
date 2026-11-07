--[[ ForeverHUD :: Cast bars
     Player and target cast/channel bars driven by UNIT_SPELLCAST_* events. ]]
local ADDON, ns = ...
local L = ns.L

local bars = {}
local module = { bars = bars }

local function GetTime_()
  return (GetTime and GetTime()) or 0
end

local function ReadCast(unit)
  if ns.preview.active then
    if unit ~= "player" then return nil end
    local demo = ns.preview.cast
    local now = GetTime_()
    local elapsed = now - (ns.preview.started or now)
    if elapsed > demo.duration then
      ns.preview.started = now
      elapsed = 0
    end
    return demo.name, demo.icon, now - elapsed, now - elapsed + demo.duration, not demo.interruptible, demo.channel
  end

  if not UnitExists or not UnitExists(unit) then return nil end

  if UnitCastingInfo then
    local name, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    if name then
      return name, texture, (startTime or 0) / 1000, (endTime or 0) / 1000, notInterruptible, false
    end
  end

  if UnitChannelInfo then
    local name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
    if name then
      return name, texture, (startTime or 0) / 1000, (endTime or 0) / 1000, notInterruptible, true
    end
  end
  return nil
end

local function StopBar(frame)
  frame.casting = false
  if frame.spark then frame.spark:Hide() end
  frame:Hide()
end

local function StartBar(frame, name, icon, startTime, endTime, notInterruptible, channel)
  local duration = endTime - startTime
  if duration <= 0 then
    StopBar(frame)
    return
  end
  frame.casting = true
  frame.duration = duration
  frame.startedAt = startTime
  frame.channel = channel and true or false
  frame.notInterruptible = notInterruptible and true or false
  frame.spellName = name or ""

  local cfg = ns:Get("castbars")
  local hint = ""
  if cfg.interruptHint and frame.unit == "target" and not notInterruptible then
    hint = "  |cff4ec46b" .. (ns:LocaleCode() == "esES" and "interrumpible" or "interruptible") .. "|r"
  end
  frame.text:SetText(name .. hint)
  if icon and cfg.showIcon then
    frame.icon:SetTexture(icon)
    frame.icon:Show()
  else
    frame.icon:Hide()
  end
  frame:Show()
end

local function Refresh(frame)
  local cfg = ns:Get("castbars")
  local enabled = cfg.enabled
  if frame.unit == "player" then enabled = enabled and cfg.playerEnabled
  elseif frame.unit == "target" then enabled = enabled and cfg.targetEnabled end
  if not enabled then
    StopBar(frame)
    return
  end
  local name, icon, startTime, endTime, notInterruptible, channel = ReadCast(frame.unit)
  if not name then
    StopBar(frame)
    return
  end
  if frame.casting and frame.spellName == name and math.abs((frame.startedAt or 0) - startTime) < 0.05 then
    frame.duration = endTime - startTime
    frame.notInterruptible = notInterruptible and true or false
    return
  end
  StartBar(frame, name, icon, startTime, endTime, notInterruptible, channel)
end

local function CreateCastBar(unit)
  local frame = CreateFrame("Frame", "ForeverHUD_Cast_" .. unit, UIParent, "BackdropTemplate")
  frame:SetSize(280, 20)
  frame:SetFrameStrata("MEDIUM")
  ns:ApplyBackdrop(frame, ns.theme.bg, ns.theme.borderHi)
  frame.unit = unit
  frame.casting = false

  local bar = ns:CreateBar(frame, 280, 18)
  bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  frame.bar = bar

  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  icon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  icon:SetWidth(18)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:Hide()
  frame.icon = icon

  local text = ns:CreateText(frame, 11, ns.theme.text, "OUTLINE")
  text:SetPoint("LEFT", frame, "LEFT", 7, 0)
  text:SetJustifyH("LEFT")
  frame.text = text

  local time = ns:CreateText(frame, 11, ns.theme.accent, "OUTLINE")
  time:SetPoint("RIGHT", frame, "RIGHT", -7, 0)
  time:SetJustifyH("RIGHT")
  frame.timeText = time

  local spark = frame:CreateTexture(nil, "OVERLAY", nil, 7)
  spark:SetTexture(ns.path .. "Media\\spark")
  spark:SetBlendMode("ADD")
  spark:SetSize(14, 26)
  spark:Hide()
  frame.spark = spark

  frame:SetScript("OnUpdate", function(self, elapsed)
    if not self.casting then return end
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.03 then return end
    self.elapsed = 0
    local now = GetTime_()
    local duration = self.duration or 0
    local remaining = math.max(0, (self.startedAt + duration) - now)
    local progress = duration > 0 and math.min(1, math.max(0, (now - self.startedAt) / duration)) or 0
    self.bar:SetMinMaxValues(0, 1)
    self.bar:SetValue(progress)
    if ns:Get("castbars.showTime", true) then
      self.timeText:SetText(string.format("%.1f", remaining))
    else
      self.timeText:SetText("")
    end
    if self.spark then
      local width = (self:GetWidth() or 280) - 4
      self.spark:ClearAllPoints()
      self.spark:SetPoint("CENTER", self.bar, "LEFT", progress * width, 0)
      self.spark:Show()
    end
    if progress >= 1 then
      if ns.preview.active then
        ns.preview.started = now
      else
        self.casting = false
      end
    end
  end)

  return frame
end

local function ApplyBar(frame, cfg, prefix)
  local scale = ns:Get("general.scale", 1)
  frame:SetScale(scale ~= 1 and scale or 1)
  frame:SetSize(cfg.width, cfg.height)
  frame.bar:ClearAllPoints()
  frame.bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  frame.bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

  if cfg.showIcon then
    local size = math.max(10, cfg.height - 2)
    frame.icon:SetSize(size, size)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if frame.casting then frame.icon:Show() end
  else
    frame.icon:Hide()
  end

  frame.text:SetFont(ns.font, math.max(9, math.floor(cfg.height * 0.55)), "OUTLINE")
  frame.timeText:SetFont(ns.font, math.max(9, math.floor(cfg.height * 0.55)), "OUTLINE")
  frame.timeText:SetTextColor(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 1)

  ns:ApplyBackdrop(frame, ns.theme.bg, ns.theme.borderHi)
  ns:AddCornerAccents(frame)
  ns:UpdateAccents(frame)
  frame.bar:SetStatusBarTexture(ns:BarTexture())
  if frame.unit == "player" then
    local accent = ns.theme.accent
    frame.bar:SetStatusBarColor(accent[1] * 0.92, accent[2] * 0.92, accent[3] * 0.92, 1)
  else
    frame.bar:SetStatusBarColor(0.66, 0.26, 0.22, 1)
  end
  if frame.spark then
    frame.spark:SetSize(math.max(12, math.floor(cfg.height * 0.9)), cfg.height + 8)
    frame.spark:SetVertexColor(ns.theme.accent[1], ns.theme.accent[2], ns.theme.accent[3], 0.9)
  end

  local position = {
    point = cfg[prefix .. "Point"] or "CENTER",
    x = cfg[prefix .. "X"] or 0,
    y = cfg[prefix .. "Y"] or 0,
  }
  frame:ClearAllPoints()
  frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)

  ns:MakeMovable(frame, "castbars", prefix)
  ns:RegisterMovable(frame)
  frame:EnableMouse(not ns:Get("general.locked", true))
end

function module:Initialize()
  bars.player = CreateCastBar("player")
  bars.target = CreateCastBar("target")
end

function module:Apply()
  local cfg = ns:Get("castbars")
  if not cfg then return end
  ApplyBar(bars.player, cfg, "player")
  ApplyBar(bars.target, cfg, "target")
  module:Refresh()
end

function module:Refresh()
  if bars.player then Refresh(bars.player) end
  if bars.target then Refresh(bars.target) end
end

ns:RegisterModule("castbars", module)

for _, event in ipairs({
  "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
  "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
  "UNIT_SPELLCAST_CHANNEL_STOP",
  "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE",
  "UNIT_SPELLCAST_EMPOWER_STOP",
}) do
  ns:On(event, function(_, unit)
    local frame = bars[unit]
    if frame then
      local ok, err = pcall(Refresh, frame)
      if not ok then ns.errors["castbars." .. unit] = tostring(err) end
    end
  end)
end

ns:On("PLAYER_TARGET_CHANGED", function() if bars.target then Refresh(bars.target) end end)
ns:On("PLAYER_ENTERING_WORLD", function() module:Refresh() end)
ns:On("TICK", function(_, elapsed)
  if not ns.preview.active then return end
  if bars.player then Refresh(bars.player) end
end)
