local T = dofile("tests/wow_stub.lua")
dofile("Core/Log.lua")
local CIT = _G.CoAInspectTree

print("test_log:")
-- safe atrapa errores y devuelve ok=false
local ok = CIT.safe(function() error("boom") end)
T.eq(ok, false, "safe atrapa error -> ok=false")
-- safe devuelve ok=true y el resultado en caso normal
local ok2, res = CIT.safe(function() return 42 end)
T.eq(ok2, true, "safe ok=true en caso normal")
T.eq(res, 42, "safe devuelve el resultado")
return T.done()
