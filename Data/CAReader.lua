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
-- GetTalentsByClass con withMasteries=true y =false devuelven conjuntos distintos
-- (cada modo omite algunos nodos que el otro sí trae). Confirmado in-game: solo
-- la UNIÓN de ambos cubre todos los talentos aprendidos. Mergeamos deduplicando
-- por ID.
function R.classTree(className, slot)
  local api = CA()
  if not (api and type(api.GetTalentsByClass) == "function" and className) then return {} end
  local seen, out = {}, {}
  local function absorb(withMasteries)
    local ok, entries = pcall(api.GetTalentsByClass, className, slot, withMasteries)
    if ok and type(entries) == "table" then
      for _, e in ipairs(entries) do
        if e.ID and not seen[e.ID] then
          seen[e.ID] = true
          out[#out + 1] = e
        end
      end
    end
  end
  absorb(false)
  absorb(true)
  return out
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

-- Build del PROPIO personaje ("player") para comparar. Intenta GetInspectedBuild
-- primero; si viene vacío (puede no aplicar a uno mismo), cae a consultar el
-- rango real de cada nodo con UnitTalentRankByID("player", ...), que sí devuelve
-- rango para el jugador local. Devuelve { [id] = { rank, maxRank } }.
function R.playerBuild(slot, rawTree)
  local viaInspect = R.unitBuild("player", slot)
  local n = 0
  for _ in pairs(viaInspect) do n = n + 1 end
  if n > 0 then return viaInspect end

  local api = CA()
  local out = {}
  if api and type(api.UnitTalentRankByID) == "function" and type(rawTree) == "table" then
    for _, node in ipairs(rawTree) do
      local id = node.ID
      if id then
        local ok, rank, maxRank = pcall(api.UnitTalentRankByID, "player", id, slot)
        if ok and type(rank) == "number" and rank > 0 then
          out[id] = { rank = rank, maxRank = maxRank }
        end
      end
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
