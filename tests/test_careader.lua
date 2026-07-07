local T = dofile("tests/wow_stub.lua")

-- Mock de la API del cliente ANTES de cargar el módulo.
_G.UnitClass = function(unit) return "Guardian", "GUARDIAN" end
_G.CharacterAdvancementUtil = {
  GetClassDBCByFile = function(file) return file == "GUARDIAN" and "Guardian" or nil end,
}
_G.C_CharacterAdvancement = {
  GetTalentsByClass = function(className, slot, withMasteries)
    if className == "Guardian" then
      return { { ID = 31319, Name = "With Honor" }, { ID = 30056, Name = "Iron Guardian" } }
    end
    return {}
  end,
  GetInspectedBuild = function(unit, slot)
    -- slot 2 aprende ambos; slot 1 solo el primero.
    if slot == 2 then
      return { { EntryId = 31319, Rank = 1, Locked = 0 }, { EntryId = 30056, Rank = 2, Locked = 0 } }
    end
    return { { EntryId = 31319, Rank = 1, Locked = 0 } }
  end,
  UnitTalentRankByID = function(unit, id, slot)
    local maxByer = { [31319] = 1, [30056] = 3, [99999] = 5 }
    if id == 99999 then return 0, maxByer[id] end  -- nodo no aprendido
    local rank = (slot == 2 and id == 30056) and 2 or 1
    return rank, maxByer[id]
  end,
  GetInspectInfo = function(unit) return 2, { 1, 2 } end,
}

dofile("Data/CAReader.lua")
local CIT = _G.CoAInspectTree
local R = CIT.CAReader

print("test_careader:")
T.eq(R.className("target"), "Guardian", "resuelve className DBC")

local tree = R.classTree("Guardian", 2)
T.eq(#tree, 2, "classTree devuelve la lista de nodos")

local build = R.unitBuild("target", 2)
T.eq(build[31319].rank, 1, "unitBuild rank del nodo 31319")
T.eq(build[30056].rank, 2, "unitBuild rank del nodo 30056 en slot 2")
T.eq(build[30056].maxRank, 3, "unitBuild maxRank via UnitTalentRankByID")

local active, unlocked = R.inspectInfo("target")
T.eq(active, 2, "inspectInfo activeSpec")
T.eq(#unlocked, 2, "inspectInfo unlockedSpecs")

-- buildFromTree: marca CADA nodo del árbol consultando UnitTalentRankByID,
-- así el marcado es completo aunque EntryId de GetInspectedBuild no coincida.
local rawTree = {
  { ID = 31319 }, { ID = 30056 }, { ID = 99999 },
}
local bft = R.buildFromTree("target", 2, rawTree)
T.eq(bft[31319].rank, 1, "buildFromTree rank de 31319")
T.eq(bft[30056].rank, 2, "buildFromTree rank de 30056 en slot 2")
T.eq(bft[30056].maxRank, 3, "buildFromTree maxRank de 30056")
T.eq(bft[99999], nil, "buildFromTree excluye nodo con rank 0")

-- Robustez: si la API tira error, devuelve valores seguros.
_G.C_CharacterAdvancement.GetTalentsByClass = function() error("boom") end
T.eq(#R.classTree("Guardian", 2), 0, "classTree devuelve {} si la API falla")
return T.done()
