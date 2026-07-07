local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.CAReader = {}
local R = CIT.CAReader

local function CA()  return _G.C_CharacterAdvancement end
local function CAU() return _G.CharacterAdvancementUtil end

-- className DBC de la unidad (p.ej. "Guardian"), o nil.
function R.className(unit)
  local _, classFile = UnitClass(unit)
  local u = CAU()
  if not (u and type(u.GetClassDBCByFile) == "function") then return nil end
  local ok, name = pcall(u.GetClassDBCByFile, classFile)
  if ok then return name end
  return nil
end

-- Árbol completo de la clase (lista de nodos crudos). {} si falla.
function R.classTree(className, slot)
  local api = CA()
  if not (api and type(api.GetTalentsByClass) == "function" and className) then return {} end
  local ok, entries = pcall(api.GetTalentsByClass, className, slot, true)
  if ok and type(entries) == "table" then return entries end
  return {}
end

-- Build aprendida del unit en esa spec: { [EntryId] = { rank, maxRank } }.
function R.unitBuild(unit, slot)
  local api = CA()
  local out = {}
  if not (api and type(api.GetInspectedBuild) == "function") then return out end
  local ok, entries = pcall(api.GetInspectedBuild, unit, slot)
  if not (ok and type(entries) == "table") then return out end
  for _, e in ipairs(entries) do
    if e.EntryId then
      local rank, maxRank = e.Rank, nil
      if type(api.UnitTalentRankByID) == "function" then
        local rok, r, m = pcall(api.UnitTalentRankByID, unit, e.EntryId, slot)
        if rok then
          if type(r) == "number" then rank = r end
          maxRank = m
        end
      end
      out[e.EntryId] = { rank = rank, maxRank = maxRank }
    end
  end
  return out
end

-- (activeSpec, unlockedSpecs) del unit inspeccionado.
function R.inspectInfo(unit)
  local api = CA()
  if not (api and type(api.GetInspectInfo) == "function") then return nil, nil end
  local ok, active, unlocked = pcall(api.GetInspectInfo, unit)
  if ok then return active, unlocked end
  return nil, nil
end
