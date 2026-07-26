-- Corre todos los tests headless. Uso: cd al addon y `lua5.1 tests/run_all.lua`
local files = {
  "tests/test_log.lua",
  "tests/test_treemodel.lua",
  "tests/test_careader.lua",
  "tests/test_inspecthook.lua",
}
local allOk = true
for _, f in ipairs(files) do
  local chunk = loadfile(f)
  if not chunk then
    print("SKIP (no existe): " .. f)
  else
    -- Aislar el estado global entre tests recargando el namespace.
    _G.CoAInspectTree = {}
    local ok = chunk()
    if ok == false then allOk = false end
  end
end
print(allOk and "ALL OK" or "SOME FAILED")
os.exit(allOk and 0 or 1)
