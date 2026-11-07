--[[ ForeverHUD :: headless test suite
     lua tests/run_tests.lua
     Loads the addon against tests/wow_mock.lua and exercises the real code. ]]
package.path = "./tests/?.lua;" .. package.path
local Mock = dofile("tests/wow_mock.lua")

local ADDON = "ForeverHUD"
local ns = {}
local FILES = {
  "Locales.lua",
  "Core.lua",
  "Config.lua",
  "Modules/UnitFrames.lua",
  "Modules/CastBars.lua",
  "Modules/Auras.lua",
  "Modules/ActionBars.lua",
}

local function loadAddon()
  for _, file in ipairs(FILES) do
    local chunk, err = loadfile("ForeverHUD/" .. file)
    if not chunk then error("cannot load " .. file .. ": " .. tostring(err)) end
    local ok, runErr = pcall(chunk, ADDON, ns)
    if not ok then error("error in " .. file .. ": " .. tostring(runErr)) end
  end
end

loadAddon()
Mock.Fire("ADDON_LOADED", ADDON)
Mock.Fire("PLAYER_LOGIN")

local passed, failed = 0, {}
local current = "?"

local function test(name, fn)
  current = name
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    io.write("ok " .. passed .. " - " .. name .. "\n")
  else
    table.insert(failed, name .. " :: " .. tostring(err))
    io.write("not ok - " .. name .. "\n")
  end
end

local function assertEqual(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
  end
end

local function assertTruthy(value, label)
  if not value then error((label or "value") .. " is not truthy", 2) end
end

local function assertContains(haystack, needle, label)
  haystack = tostring(haystack or "")
  if not haystack:find(needle, 1, true) then
    error(string.format("%s: %q does not contain %q", label or "text", haystack, needle), 2)
  end
end

local function readFile(path)
  local file = assert(io.open(path, "rb"))
  local content = file:read("*a")
  file:close()
  return content
end

-- ---------------------------------------------------------------------------
test("el TOC declara Interface 16001 y todos sus ficheros", function()
  local toc = readFile("ForeverHUD/ForeverHUD.toc")
  assertContains(toc, "## Interface: 16001", "Interface")
  assertContains(toc, "## SavedVariables: ForeverHUDDB", "SavedVariables")
  for line in toc:gmatch("[^\r\n]+") do
    if line ~= "" and not line:match("^##") then
      local path = "ForeverHUD/" .. line:gsub("\\", "/")
      local file = io.open(path, "rb")
      assertTruthy(file, "missing file " .. path)
      file:close()
    end
  end
end)

test("la base de datos arranca con el perfil Default", function()
  assertTruthy(ns.db, "ns.db")
  assertTruthy(ns.db.profiles["Default"], "Default profile")
  assertEqual(ns:ProfileName(), "Default", "active profile")
  assertEqual(ns:Get("units.player.width"), 286, "default width")
  assertEqual(ns:Get("castbars.height"), 20, "castbar height")
end)

test("mensaje de bienvenida en el chat", function()
  assertContains(Mock.ChatText(), "ForeverHUD " .. ns.version, "chat")
end)

test("marcos de unidad con datos reales", function()
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  assertTruthy(frame and frame:IsShown(), "player frame shown")
  assertEqual(frame.name:GetText(), "Aelric", "player name")
  assertEqual(frame.health:GetValue(), 8000, "player health")
  assertContains(frame.healthText:GetText(), "80%", "health text")
  local target = ns:GetModule("unitframes"):GetFrame("target")
  assertTruthy(target:IsShown(), "target frame shown")
  assertContains(target.level:GetText(), "Jefe", "boss classification")
end)

test("un objetivo inexistente oculta el marco", function()
  Mock.units.target.exists = false
  Mock.Fire("PLAYER_TARGET_CHANGED")
  local frame = ns:GetModule("unitframes"):GetFrame("target")
  assertEqual(frame:IsShown(), false, "target hidden")
  Mock.units.target.exists = true
  Mock.Fire("PLAYER_TARGET_CHANGED")
  assertTruthy(frame:IsShown(), "target visible again")
end)

test("UNIT_HEALTH actualiza el texto de vida", function()
  Mock.units.player.health = 4000
  Mock.Fire("UNIT_HEALTH", "player")
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  assertContains(frame.healthText:GetText(), "40%", "health text")
  Mock.units.player.health = 8000
  Mock.Fire("UNIT_HEALTH", "player")
end)

test("los ajustes se aplican en vivo", function()
  ns:Set("units.player.width", 320)
  ns:ApplyAll()
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  assertEqual(frame:GetWidth(), 320, "frame width")
  ns:Set("units.player.width", 286)
  ns:ApplyAll()
end)

test("la escala global se propaga a los marcos", function()
  ns:Set("general.scale", 1.2)
  ns:ApplyAll()
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  assertEqual(frame:GetScale(), 1.2, "scale")
  ns:Set("general.scale", 1)
  ns:ApplyAll()
end)

test("texto de vida en porcentaje", function()
  ns:Set("units.player.healthText", "percent")
  ns:ApplyAll()
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  assertEqual(frame.healthText:GetText(), "80%", "percent text")
  ns:Set("units.player.healthText", "both")
  ns:ApplyAll()
end)

test("desbloquear y arrastrar guarda la posición", function()
  ns:HandleCommand("unlock")
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", -120, -210)
  frame:GetScript("OnDragStop")(frame)
  assertEqual(ns:Get("units.player.x"), -120, "saved x")
  assertEqual(ns:Get("units.player.y"), -210, "saved y")
  assertEqual(ns:Get("units.player.point"), "CENTER", "saved point")
  ns:HandleCommand("lock")
end)

test("bloqueado no se puede mover", function()
  ns:Set("general.locked", true)
  local frame = ns:GetModule("unitframes"):GetFrame("player")
  frame.moving = false
  frame:GetScript("OnDragStart")(frame)
  assertEqual(frame.moving, false, "did not start moving")
  ns:Set("general.locked", false)
  frame:GetScript("OnDragStart")(frame)
  assertEqual(frame.moving, true, "started moving")
  ns:Set("general.locked", true)
end)

test("auras del jugador: iconos, orden y stacks", function()
  local auras = ns:GetModule("auras")
  local group = auras.groups.playerBuffs
  assertTruthy(group:IsShown(), "buffs shown")
  assertEqual(group.displayed, 2, "two buffs")
  assertEqual(group.buttons[1].count:GetText(), "2", "first aura stacks")
  assertEqual(group.buttons[1].icon:GetTexture(), "Interface\\Icons\\Spell_Holy_PowerWordShield", "sorted by expiry")
end)

test("debufs del objetivo con color de dispel", function()
  local group = ns:GetModule("auras").groups.targetDebuffs
  assertTruthy(group:IsShown(), "debuffs shown")
  assertEqual(group.displayed, 1, "one debuff")
  local color = group.buttons[1].backdropBorderColor
  assertEqual(color[1], 0.2, "magic red")
  assertEqual(color[3], 1.0, "magic blue")
end)

test("las auras permanentes se filtran cuando se pide", function()
  table.insert(Mock.auras["target|HARMFUL"], { name = "Permanente", icon = "Interface\\Icons\\INV_Misc_Rune_01", applications = 0, duration = 0, expirationTime = 0 })
  ns:Set("auras.permanent", false)
  ns:ApplyAll()
  local group = ns:GetModule("auras").groups.targetDebuffs
  assertEqual(group.displayed, 1, "permanent hidden")
  ns:Set("auras.permanent", true)
  ns:ApplyAll()
  assertEqual(group.displayed, 2, "permanent visible")
  table.remove(Mock.auras["target|HARMFUL"])
  ns:ApplyAll()
end)

test("castbar del jugador sigue el lanzamiento", function()
  Mock.time = 1000
  Mock.casts.player = {
    name = "Bola de fuego", icon = "Interface\\Icons\\Spell_Fire_Fireball02",
    startTime = 999000, endTime = 1001000, notInterruptible = false,
  }
  Mock.Fire("UNIT_SPELLCAST_START", "player")
  local bars = ns:GetModule("castbars").bars
  assertTruthy(bars.player:IsShown(), "castbar shown")
  assertContains(bars.player.text:GetText(), "Bola de fuego", "spell name")
  bars.player:GetScript("OnUpdate")(bars.player, 0.1)
  local value = bars.player.bar:GetValue()
  assertTruthy(value > 0.4 and value < 0.6, "progress around 0.5, got " .. tostring(value))
end)

test("castbar del objetivo avisa de interrumpible", function()
  Mock.casts.target = {
    name = "Descarga de sombra", icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    startTime = 999500, endTime = 1001500, notInterruptible = false,
  }
  Mock.Fire("UNIT_SPELLCAST_START", "target")
  local bar = ns:GetModule("castbars").bars.target
  assertTruthy(bar:IsShown(), "target castbar shown")
  assertContains(bar.text:GetText(), "interrumpible", "hint")
  Mock.casts.target = nil
  Mock.Fire("UNIT_SPELLCAST_STOP", "target")
  assertEqual(bar:IsShown(), false, "hidden after stop")
end)

test("la castbar se oculta al terminar el lanzamiento", function()
  Mock.casts.player = nil
  Mock.Fire("UNIT_SPELLCAST_STOP", "player")
  assertEqual(ns:GetModule("castbars").bars.player:IsShown(), false, "hidden")
end)

test("barras de acción: atributos y filas", function()
  local module = ns:GetModule("actionbars")
  local buttons = module.buttons
  assertEqual(buttons[1]:GetAttribute("action"), 1, "slot 1")
  assertEqual(buttons[12]:GetAttribute("action"), 12, "slot 12")
  assertEqual(buttons[13]:GetAttribute("action"), 61, "second row starts at 61")
  assertEqual(buttons[13]:IsShown(), true, "row 2 shown")
  assertEqual(buttons[25]:IsShown(), false, "row 3 hidden")
end)

test("el tamaño de los botones se aplica", function()
  ns:Set("actionbars.buttonSize", 40)
  ns:ApplyAll()
  local buttons = ns:GetModule("actionbars").buttons
  assertEqual(buttons[1]:GetWidth(), 40, "button width")
  ns:Set("actionbars.buttonSize", 36)
  ns:ApplyAll()
end)

test("en combate los cambios de barra se posponen", function()
  ns:Set("actionbars.buttonSize", 40)
  ns:ApplyAll()
  Mock.inCombat = true
  ns:Set("actionbars.buttonSize", 30)
  ns:ApplyAll()
  local buttons = ns:GetModule("actionbars").buttons
  assertEqual(buttons[1]:GetWidth(), 40, "unchanged while in combat")
  Mock.inCombat = false
  Mock.Fire("PLAYER_REGEN_ENABLED")
  assertEqual(buttons[1]:GetWidth(), 30, "applied after combat")
  ns:Set("actionbars.buttonSize", 36)
  ns:ApplyAll()
end)

test("el modo vista previa pinta datos simulados", function()
  Mock.units.target.exists = false
  Mock.Fire("PLAYER_TARGET_CHANGED")
  ns:HandleCommand("preview")
  assertEqual(ns.preview.active, true, "preview on")
  local frames = ns:GetModule("unitframes").frames
  assertTruthy(frames.target:IsShown(), "mock target shown")
  assertContains(frames.target.name:GetText(), "Foso", "mock target name")
  assertTruthy(ns:GetModule("actionbars").buttons[1].icon:IsShown(), "demo icon")
  ns:HandleCommand("preview")
  assertEqual(ns.preview.active, false, "preview off")
  assertEqual(frames.target:IsShown(), false, "target hidden again")
  Mock.units.target.exists = true
  Mock.Fire("PLAYER_TARGET_CHANGED")
end)

test("perfiles: crear, cambiar y borrar", function()
  assertTruthy(ns:NewProfile("PvP"), "created")
  assertTruthy(ns:SetProfile("PvP"), "switched")
  ns:Set("units.player.width", 320)
  assertTruthy(ns:SetProfile("Default"), "back to default")
  assertEqual(ns:Get("units.player.width"), 286, "default untouched")
  assertTruthy(ns:SetProfile("PvP"), "switch again")
  assertEqual(ns:Get("units.player.width"), 320, "pv profile kept")
  local ok, reason = ns:DeleteProfile("PvP")
  assertEqual(ok, false, "cannot delete active")
  assertEqual(reason, "active", "reason")
  assertTruthy(ns:SetProfile("Default"), "switch back")
  assertTruthy(ns:DeleteProfile("PvP"), "deleted")
  assertEqual(ns.db.profiles["PvP"], nil, "gone")
end)

test("exportar e importar un perfil", function()
  ns:Set("units.player.width", 300)
  local text = ns:Serialize()
  local profile = ns:Deserialize(text)
  assertTruthy(profile, "deserialized")
  assertEqual(profile.units.player.width, 300, "width roundtrip")
  assertEqual(ns:Deserialize("no es una tabla"), nil, "rejects garbage")
  local defaults = ns:Deserialize("{}")
  assertTruthy(defaults, "empty table falls back to defaults")
  assertEqual(defaults.units.player.width, 286, "default width filled")
  ns:Set("units.player.width", 286)
end)

test("reset del perfil activo", function()
  ns:Set("units.player.width", 410)
  assertTruthy(ns:ResetProfile(), "reset")
  assertEqual(ns:Get("units.player.width"), 286, "factory width")
end)

test("los disenos reconfiguran el HUD de golpe", function()
  assertTruthy(ns:ApplyPreset("minimo"), "minimal applied")
  assertEqual(ns:Get("units.focus.enabled"), false, "focus off")
  assertEqual(ns:Get("auras.enabled"), false, "auras off")
  assertEqual(ns:Get("actionbars.rows"), 1, "one action row")
  assertEqual(ns:GetModule("unitframes").frames.focus:IsShown(), false, "focus frame hidden")

  assertTruthy(ns:ApplyPreset("compacto"), "compact applied")
  assertEqual(ns:Get("general.scale"), 0.9, "compact scale")
  assertEqual(ns:Get("units.player.width"), 240, "compact width")

  assertTruthy(ns:ApplyPreset("clasico"), "classic applied")
  assertEqual(ns:Get("units.player.width"), 286, "classic width")
  assertEqual(ns:Get("auras.enabled"), true, "auras back on")
  assertEqual(ns:Get("actionbars.rows"), 2, "two action rows")
end)

test("el color de acento recolorea el HUD", function()
  ns:Set("general.accent", "oro")
  ns:ApplyAll()
  assertEqual(ns.theme.accent[1], 0.851, "gold accent")
  ns:Set("general.accent", "acero")
  ns:ApplyAll()
  assertEqual(ns.theme.accent[1], 0.804, "steel accent")
end)

test("comandos de chat: version y ayuda", function()
  Mock.ClearChat()
  ns:HandleCommand("version")
  assertContains(Mock.ChatText(), "ForeverHUD " .. ns.version, "version")
  Mock.ClearChat()
  ns:HandleCommand("ayuda")
  assertContains(Mock.ChatText(), "Comandos", "help")
end)

test("la configuración abre el panel y reconstruye secciones", function()
  Mock.ClearChat()
  ns:HandleCommand("")
  local panel = Mock.named["ForeverHUDConfigPanel"]
  assertTruthy(panel, "panel created")
  assertTruthy(panel:IsShown(), "panel shown")
  ns.ConfigAPI.Rebuild("units")
  ns.ConfigAPI.Rebuild("profiles")
  assertTruthy(#panel.content.children > 0, "content built")
end)

test("unidades desactivadas se ocultan", function()
  ns:Set("units.focus.enabled", false)
  ns:ApplyAll()
  assertEqual(ns:GetModule("unitframes").frames.focus:IsShown(), false, "focus hidden")
  ns:Set("units.focus.enabled", true)
  ns:ApplyAll()
end)

test("apagar las auras oculta los grupos", function()
  ns:Set("auras.enabled", false)
  ns:ApplyAll()
  assertEqual(ns:GetModule("auras").groups.playerBuffs:IsShown(), false, "hidden")
  ns:Set("auras.enabled", true)
  ns:ApplyAll()
  assertTruthy(ns:GetModule("auras").groups.playerBuffs:IsShown(), "back")
end)

test("el límite de auras se respeta", function()
  ns:Set("auras.maxAuras", 1)
  ns:ApplyAll()
  assertEqual(ns:GetModule("auras").groups.playerBuffs.displayed, 1, "one aura")
  ns:Set("auras.maxAuras", 24)
  ns:ApplyAll()
end)

test("sin errores de módulos", function()
  local first
  for name, err in pairs(ns.errors) do
    first = name .. ": " .. tostring(err)
    break
  end
  assertEqual(first, nil, "module errors")
end)

-- ---------------------------------------------------------------------------
local total = passed + #failed
io.write(string.format("\n%d/%d tests passed\n", passed, total))
if #failed > 0 then
  io.write("\nfailures:\n")
  for _, failure in ipairs(failed) do io.write("  - " .. failure .. "\n") end
  os.exit(1)
end
os.exit(0)
