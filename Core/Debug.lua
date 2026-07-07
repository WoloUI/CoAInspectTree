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

-- /coait          -> resumen por tab
-- /coait class    -> nodos del tab Class con posiciones
_G.SLASH_COAIT1 = "/coait"
_G.SlashCmdList = _G.SlashCmdList or {}
_G.SlashCmdList["COAIT"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "class" then
    CIT.safe(CIT.Debug.dumpClass)
  else
    CIT.safe(CIT.Debug.dumpTarget)
  end
end
