local T = dofile("tests/wow_stub.lua")

-- CreateFrame que soporta OnUpdate/eventos como no-ops (InspectHook crea watchers
-- al cargarse). Devuelve un frame con los métodos que usan los módulos.
_G.CreateFrame = function()
  local f = {}
  function f.RegisterEvent() end
  function f.UnregisterEvent() end
  function f.SetScript() end
  function f.SetPoint() end
  function f.ClearAllPoints() end
  return f
end

-- Contadores de visibilidad del panel: el bug es que Show() se llama sin inspect.
local shows, hides = 0, 0
_G.UnitName = function() return "Someone" end
_G.UnitExists = function() return true end
_G.UnitIsPlayer = function() return true end

dofile("Core/Log.lua")
dofile("Core/Init.lua")
local CIT = _G.CoAInspectTree
CIT.enabled = true

-- Stubs de las dependencias de renderFor (no probamos el render real, solo el
-- gating de visibilidad).
CIT.CAReader = {
  className = function() return "Guardian" end,
  classTree = function() return { { ID = 1, Tab = "Class" } } end,
  unitBuild = function() return {} end,
  playerBuild = function() return {} end,
  inspectInfo = function() return 1, { 1 } end,
}
CIT.TreeModel = { build = function() return {} end }
CIT.TreePanel = {
  Get = function() return { title = { SetText = function() end } } end,
  Show = function() shows = shows + 1 end,
  Hide = function() hides = hides + 1 end,
  AttachTo = function() end,
  SetSpecs = function() end,
  SetCompare = function() end,
  Render = function() end,
}

dofile("UI/InspectHook.lua")

local handler = CIT.on["INSPECT_CHARACTER_ADVANCEMENT_RESULT"][1]

print("test_inspecthook:")

-- Sin inspect frame abierto (combate: llega data de talentos del target por un
-- auto-inspect de otro addon). El panel NO debe abrirse.
_G.InspectFrame = nil
_G.InspectPaperDollFrame = nil
shows, hides = 0, 0
handler()
T.eq(shows, 0, "no abre el panel cuando no hay inspect frame visible")

-- Con inspect frame abierto: el panel sí debe mostrarse.
_G.InspectFrame = { IsVisible = function() return true end }
shows, hides = 0, 0
handler()
T.truthy(shows > 0, "muestra el panel cuando el inspect está abierto")

return T.done()
