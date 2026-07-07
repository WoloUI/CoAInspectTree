local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end

CIT.enabled = false

-- Frame despachador de eventos. Los módulos registran callbacks en CIT.on[EVENT].
CIT.on = CIT.on or {}
local dispatcher = CreateFrame("Frame")
dispatcher:RegisterEvent("PLAYER_LOGIN")
dispatcher:SetScript("OnEvent", function(_, event, ...)
  local handlers = CIT.on[event]
  if handlers then
    for i = 1, #handlers do CIT.safe(handlers[i], ...) end
  end
end)
CIT.dispatcher = dispatcher

-- Registra un handler para un evento y asegura que el frame lo escuche.
function CIT.RegisterEvent(event, handler)
  CIT.on[event] = CIT.on[event] or {}
  table.insert(CIT.on[event], handler)
  dispatcher:RegisterEvent(event)
end

-- Al login: detectar si el realm soporta CoA.
CIT.RegisterEvent("PLAYER_LOGIN", function()
  CIT.enabled = (_G.C_CharacterAdvancement ~= nil)
  if CIT.enabled then
    CIT.Log("activo (Character Advancement detectado).")
  end
end)
