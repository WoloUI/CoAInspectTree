local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.Debug = {}

-- Resumen por tab del target inspeccionado: total de nodos y cuántos aprendidos.
function CIT.Debug.dumpTarget()
  local u = "target"
  local cn = CIT.CAReader.className(u)
  if not cn then CIT.Log("debug: no CoA class on target (inspect a player first)."); return end
  local active = CIT.CAReader.inspectInfo(u) or 1
  local tree = CIT.CAReader.classTree(cn, active)
  if #tree == 0 then CIT.Log("debug: empty tree (data not loaded yet?)."); return end

  local byId, total, order = {}, {}, {}
  for _, n in ipairs(tree) do
    byId[n.ID] = n.Tab
    if total[n.Tab] == nil then total[n.Tab] = 0; order[#order + 1] = n.Tab end
    total[n.Tab] = total[n.Tab] + 1
  end

  local build = CIT.CAReader.unitBuild(u, active)
  local learned, totalLearned = {}, 0
  for id in pairs(build) do
    local tb = byId[id]
    if tb then learned[tb] = (learned[tb] or 0) + 1 end
    totalLearned = totalLearned + 1
  end

  CIT.Log("class=" .. tostring(cn) .. " slot=" .. tostring(active)
    .. " nodes=" .. #tree .. " learned=" .. totalLearned)
  for _, tb in ipairs(order) do
    CIT.Log("  TAB " .. tb .. " total=" .. total[tb] .. " learned=" .. (learned[tb] or 0))
  end
end

-- Lista los nodos del tab "Class" con posición y marca de aprendido.
function CIT.Debug.dumpClass()
  local u = "target"
  local cn = CIT.CAReader.className(u)
  if not cn then CIT.Log("debug: no CoA class on target."); return end
  local active = CIT.CAReader.inspectInfo(u) or 1
  local tree = CIT.CAReader.classTree(cn, active)
  local build = CIT.CAReader.unitBuild(u, active)
  local n = 0
  for _, node in ipairs(tree) do
    if node.Tab == "Class" then
      n = n + 1
      local mark = build[node.ID] and "*" or "-"
      CIT.Log(mark .. " " .. node.ID .. " " .. (node.Name or "?")
        .. " x=" .. tostring(node.PositionX) .. " y=" .. tostring(node.PositionY))
    end
  end
  CIT.Log("Class nodes: " .. n)
end

-- Lista las funciones disponibles en las tablas de la API CoA, para descubrir
-- de dónde sacar el árbol de clase real.
function CIT.Debug.dumpAPI()
  local function dumpTbl(name, t)
    if type(t) ~= "table" then CIT.Log(name .. " = nil"); return end
    local names = {}
    for k, v in pairs(t) do
      if type(v) == "function" then names[#names + 1] = k end
    end
    table.sort(names)
    CIT.Log(name .. " (" .. #names .. " funcs):")
    local line = ""
    for _, n in ipairs(names) do
      if #line + #n + 2 > 90 then CIT.Log("  " .. line); line = "" end
      line = (line == "") and n or (line .. ", " .. n)
    end
    if line ~= "" then CIT.Log("  " .. line) end
  end
  dumpTbl("C_CharacterAdvancement", _G.C_CharacterAdvancement)
  dumpTbl("CharacterAdvancementUtil", _G.CharacterAdvancementUtil)
end

-- Muestra los EntryId aprendidos que NO aparecen en el árbol de GetTalentsByClass
-- (los que "faltan"), para identificar de qué árbol vienen.
function CIT.Debug.dumpMissing()
  local u = "target"
  local cn = CIT.CAReader.className(u)
  if not cn then CIT.Log("debug: no class."); return end
  local active = CIT.CAReader.inspectInfo(u) or 1
  local tree = CIT.CAReader.classTree(cn, active)
  local inTree = {}
  for _, n in ipairs(tree) do inTree[n.ID] = true end
  local build = CIT.CAReader.unitBuild(u, active)
  local miss = {}
  for id in pairs(build) do if not inTree[id] then miss[#miss + 1] = id end end
  CIT.Log("learned NOT in tree: " .. #miss)
  if #miss > 0 then
    CIT.Log(table.concat(miss, ",", 1, math.min(#miss, 25)))
  end
end

-- /coait          -> resumen por tab
-- /coait class    -> nodos del tab Class con posiciones
-- /coait api      -> funciones de la API CoA
-- /coait miss     -> aprendidos que no están en el árbol
_G.SLASH_COAIT1 = "/coait"
_G.SlashCmdList = _G.SlashCmdList or {}
_G.SlashCmdList["COAIT"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "class" then
    CIT.safe(CIT.Debug.dumpClass)
  elseif msg == "api" then
    CIT.safe(CIT.Debug.dumpAPI)
  elseif msg == "miss" then
    CIT.safe(CIT.Debug.dumpMissing)
  else
    CIT.safe(CIT.Debug.dumpTarget)
  end
end
