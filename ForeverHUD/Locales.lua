--[[ ForeverHUD :: Locales
     Two languages, resolved at read time so /reload switches cleanly. ]]
local ADDON, ns = ...

local esES = {
  -- sections
  general = "General",
  units = "Unidades",
  castbars = "Lanzamientos",
  auras = "Auras",
  actionbars = "Barras de accion",
  profiles = "Perfiles",
  about = "Acerca de",

  -- general
  scale = "Escala de la interfaz",
  locked = "Bloquear posiciones",
  combatFade = "Atenuar fuera de combate",
  hideBlizzard = "Ocultar marcos de Blizzard",
  language = "Idioma",
  languageAuto = "Automatico",
  loginMessage = "Mensaje al iniciar",
  auto = "Automatico",
  spanish = "Espanol",
  english = "Ingles",
  always = "Siempre",
  never = "Nunca",
  on = "Si",
  off = "No",

  -- units
  unitToEdit = "Unidad a editar",
  player = "Jugador",
  target = "Objetivo",
  focus = "Foco",
  pet = "Mascota",
  targettarget = "Objetivo del objetivo",
  enabled = "Activado",
  width = "Anchura",
  height = "Altura",
  healthText = "Texto de vida",
  value = "Valor",
  percent = "Porcentaje",
  both = "Valor y porcentaje",
  none = "Ninguno",
  classColors = "Colores de clase",
  portrait = "Retrato",
  showName = "Mostrar nombre",
  showLevel = "Mostrar nivel",
  tooltip = "Tooltip al pasar el raton",

  -- castbars
  playerCast = "Barra del jugador",
  targetCast = "Barra del objetivo",
  showIcon = "Mostrar icono",
  showTime = "Mostrar tiempo restante",
  interruptHint = "Aviso de hechizo interrumpible",

  -- auras
  auraSize = "Tamano de icono",
  perRow = "Iconos por fila",
  spacing = "Espaciado",
  buffs = "Buffs del jugador",
  debuffs = "Debuffs del jugador",
  targetDebuffs = "Debuffs del objetivo",
  permanent = "Mostrar auras permanentes",
  maxAuras = "Maximo de auras",

  -- action bars
  rows = "Filas",
  buttonsPerRow = "Botones por fila",
  buttonSize = "Tamano de boton",
  alpha = "Opacidad",
  showKeybinds = "Mostrar atajos",
  showCounts = "Mostrar cargas y contadores",
  barBackground = "Fondo de la barra",

  -- profiles
  activeProfile = "Perfil activo",
  newProfile = "Nuevo",
  copyProfile = "Copiar",
  deleteProfile = "Eliminar",
  deleteConfirm = "Eliminar el perfil \"%s\"? Esta accion no se puede deshacer.",
  resetProfile = "Restablecer perfil",
  exportProfile = "Exportar",
  importProfile = "Importar",
  reloadUI = "Recargar interfaz",
  profileName = "Nombre del perfil",
  accept = "Aceptar",
  cancel = "Cancelar",
  close = "Cerrar",
  apply = "Aplicar",
  reset = "Restablecer",
  resetAll = "Restablecer todo el HUD",

  -- chat
  loaded = "ForeverHUD %s cargado. Escribe /fh para abrir la configuracion.",
  loadedPreview = "Vista previa activa: /fh preview para salir.",
  configOpened = "Configuracion abierta.",
  lockOn = "Posiciones bloqueadas.",
  lockOff = "Posiciones desbloqueadas: arrastra los marcos y escribe /fh lock al terminar.",
  previewOn = "Vista previa activada con datos simulados.",
  previewOff = "Vista previa desactivada.",
  profileCreated = "Perfil \"%s\" creado y activo.",
  profileCopied = "Perfil \"%s\" copiado a \"%s\".",
  profileDeleted = "Perfil \"%s\" eliminado.",
  profileMissing = "Ese perfil no existe.",
  profileInUse = "No puedes eliminar el perfil activo.",
  profileReset = "Perfil \"%s\" restablecido.",
  profileSwitched = "Perfil activo: %s.",
  exported = "Perfil exportado. Copia la cadena desde el campo de texto.",
  imported = "Perfil importado como \"%s\".",
  importFailed = "Cadena de perfil invalida.",
  invalidName = "Nombre de perfil invalido.",
  resetDone = "HUD restablecido a los valores de fabrica.",
  moduleError = "El modulo %s fallo y se ha desactivado: %s",
  helpHeader = "Comandos de ForeverHUD:",
  helpConfig = "/fh - abre la configuracion",
  helpLock = "/fh lock | unlock - bloquea o libera los marcos",
  helpPreview = "/fh preview - datos simulados sin combate",
  helpProfile = "/fh profile <nombre> - cambia de perfil",
  helpReset = "/fh reset - restablece el perfil activo",
  helpExport = "/fh export - exporta el perfil activo",
  helpImport = "/fh import <cadena> - importa un perfil",
  helpVersion = "/fh version - version instalada",
  noProfile = "No hay perfiles guardados.",
  needsReload = "El cambio de idioma se aplica tras /reload.",
  unitFramesMissing = "El modulo de unidades esta desactivado.",
}

local enUS = {
  general = "General",
  units = "Units",
  castbars = "Cast bars",
  auras = "Auras",
  actionbars = "Action bars",
  profiles = "Profiles",
  about = "About",

  scale = "Interface scale",
  locked = "Lock positions",
  combatFade = "Fade out of combat",
  hideBlizzard = "Hide Blizzard unit frames",
  language = "Language",
  languageAuto = "Automatic",
  loginMessage = "Login message",
  auto = "Automatic",
  spanish = "Spanish",
  english = "English",
  always = "Always",
  never = "Never",
  on = "On",
  off = "Off",

  unitToEdit = "Unit to edit",
  player = "Player",
  target = "Target",
  focus = "Focus",
  pet = "Pet",
  targettarget = "Target of target",
  enabled = "Enabled",
  width = "Width",
  height = "Height",
  healthText = "Health text",
  value = "Value",
  percent = "Percent",
  both = "Value and percent",
  none = "None",
  classColors = "Class colors",
  portrait = "Portrait",
  showName = "Show name",
  showLevel = "Show level",
  tooltip = "Mouseover tooltip",

  playerCast = "Player cast bar",
  targetCast = "Target cast bar",
  showIcon = "Show icon",
  showTime = "Show remaining time",
  interruptHint = "Interruptible hint",

  auraSize = "Icon size",
  perRow = "Icons per row",
  spacing = "Spacing",
  buffs = "Player buffs",
  debuffs = "Player debuffs",
  targetDebuffs = "Target debuffs",
  permanent = "Show permanent auras",
  maxAuras = "Maximum auras",

  rows = "Rows",
  buttonsPerRow = "Buttons per row",
  buttonSize = "Button size",
  alpha = "Opacity",
  showKeybinds = "Show keybinds",
  showCounts = "Show charges and counts",
  barBackground = "Bar background",

  activeProfile = "Active profile",
  newProfile = "New",
  copyProfile = "Copy",
  deleteProfile = "Delete",
  deleteConfirm = "Delete the profile \"%s\"? This cannot be undone.",
  resetProfile = "Reset profile",
  exportProfile = "Export",
  importProfile = "Import",
  reloadUI = "Reload interface",
  profileName = "Profile name",
  accept = "Accept",
  cancel = "Cancel",
  close = "Close",
  apply = "Apply",
  reset = "Reset",
  resetAll = "Reset the whole HUD",

  loaded = "ForeverHUD %s loaded. Type /fh to open settings.",
  loadedPreview = "Preview active: /fh preview to exit.",
  configOpened = "Settings opened.",
  lockOn = "Positions locked.",
  lockOff = "Positions unlocked: drag the frames, then type /fh lock.",
  previewOn = "Preview enabled with simulated data.",
  previewOff = "Preview disabled.",
  profileCreated = "Profile \"%s\" created and active.",
  profileCopied = "Profile \"%s\" copied to \"%s\".",
  profileDeleted = "Profile \"%s\" deleted.",
  profileMissing = "That profile does not exist.",
  profileInUse = "You cannot delete the active profile.",
  profileReset = "Profile \"%s\" reset.",
  profileSwitched = "Active profile: %s.",
  exported = "Profile exported. Copy the string from the text field.",
  imported = "Profile imported as \"%s\".",
  importFailed = "Invalid profile string.",
  invalidName = "Invalid profile name.",
  resetDone = "HUD reset to factory values.",
  moduleError = "Module %s failed and was disabled: %s",
  helpHeader = "ForeverHUD commands:",
  helpConfig = "/fh - open settings",
  helpLock = "/fh lock | unlock - lock or free the frames",
  helpPreview = "/fh preview - simulated data without combat",
  helpProfile = "/fh profile <name> - switch profile",
  helpReset = "/fh reset - reset the active profile",
  helpExport = "/fh export - export the active profile",
  helpImport = "/fh import <string> - import a profile",
  helpVersion = "/fh version - installed version",
  noProfile = "No saved profiles.",
  needsReload = "The language change applies after /reload.",
  unitFramesMissing = "The unit frames module is disabled.",
}

ns.strings = { esES = esES, enUS = enUS }

local function resolveLanguage()
  local setting = "auto"
  if ns.db and ns:Get("general.language") then
    setting = ns:Get("general.language")
  end
  if setting == "es" then return "esES" end
  if setting == "en" then return "enUS" end
  local locale = (GetLocale and GetLocale()) or "enUS"
  if ns.strings[locale] then return locale end
  return "enUS"
end

ns.L = setmetatable({}, {
  __index = function(_, key)
    local set = ns.strings[resolveLanguage()] or ns.strings.enUS
    local value = set[key]
    if value == nil then value = ns.strings.enUS[key] end
    if value == nil then return tostring(key) end
    return value
  end,
})

function ns:LocaleCode()
  return resolveLanguage()
end
