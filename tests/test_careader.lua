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
    -- En unidades inspeccionadas el rank llega como nil; solo el maxRank (2º
    -- valor) es fiable. El rank real proviene de GetInspectedBuild.Rank.
    local maxByer = { [31319] = 1, [30056] = 3 }
    return nil, maxByer[id]
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

-- Con rank nil de UnitTalentRankByID, unitBuild conserva el Rank de
-- GetInspectedBuild (regresión de marcado que hay que evitar).
local b1 = R.unitBuild("target", 1)
T.eq(b1[31319].rank, 1, "unitBuild slot1 conserva Rank de GetInspectedBuild")

-- playerBuild: usa GetInspectedBuild si trae datos (para tu propio personaje).
local pb = R.playerBuild(2, { { ID = 31319 }, { ID = 30056 } })
T.eq(pb[31319].rank, 1, "playerBuild via GetInspectedBuild")
T.eq(pb[30056].rank, 2, "playerBuild rank de 30056")

-- ...y cae a UnitTalentRankByID(player) si GetInspectedBuild viene vacío.
_G.C_CharacterAdvancement.GetInspectedBuild = function() return {} end
_G.C_CharacterAdvancement.UnitTalentRankByID = function(u, id, slot)
  if id == 31319 then return 2, 4 end
  return 0, 1
end
local pb2 = R.playerBuild(2, { { ID = 31319 }, { ID = 30056 } })
T.eq(pb2[31319].rank, 2, "playerBuild fallback usa rank real del player")
T.eq(pb2[30056], nil, "playerBuild fallback excluye rank 0")

-- classTree une withMasteries=false y =true (cada modo omite nodos distintos).
_G.C_CharacterAdvancement.GetTalentsByClass = function(cn, slot, withM)
  if withM then
    return { { ID = 30056, Name = "B" }, { ID = 999, Name = "C" } }
  else
    return { { ID = 31319, Name = "A" }, { ID = 30056, Name = "B" } }
  end
end
local merged = R.classTree("Guardian", 2)
T.eq(#merged, 3, "classTree une ambos modos sin duplicar (A,B,C)")

-- Robustez: si la API tira error, devuelve valores seguros.
_G.C_CharacterAdvancement.GetTalentsByClass = function() error("boom") end
T.eq(#R.classTree("Guardian", 2), 0, "classTree devuelve {} si la API falla")
return T.done()
