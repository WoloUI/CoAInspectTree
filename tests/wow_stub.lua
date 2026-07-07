-- Stubs mínimos de la API WoW para correr los módulos bajo lua5.1.
-- Cada test puede sobrescribir estos globales antes de cargar el módulo.
_G.CoAInspectTree = _G.CoAInspectTree or {}

-- Registro no-op de frames/eventos usado por Init.lua al cargarse.
if not _G.CreateFrame then
  function _G.CreateFrame()
    local f = {}
    function f.RegisterEvent() end
    function f.SetScript() end
    function f.UnregisterEvent() end
    return f
  end
end
_G.DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME or { AddMessage = function() end }

-- Helper de aserción compartido por los tests.
local T = { passed = 0, failed = 0 }
function T.eq(a, b, msg)
  if a ~= b then
    T.failed = T.failed + 1
    print("  FAIL: " .. (msg or "") .. " (esperado " .. tostring(b) .. ", fue " .. tostring(a) .. ")")
  else
    T.passed = T.passed + 1
  end
end
function T.truthy(v, msg)
  if not v then
    T.failed = T.failed + 1
    print("  FAIL: " .. (msg or "") .. " (esperaba valor verdadero)")
  else
    T.passed = T.passed + 1
  end
end
function T.done()
  print(string.format("  %d passed, %d failed", T.passed, T.failed))
  return T.failed == 0
end
return T
