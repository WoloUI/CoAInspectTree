local T = dofile("tests/wow_stub.lua")
dofile("Data/TreeModel.lua")
local CIT = _G.CoAInspectTree
local fx = dofile("tests/fixtures/guardian.lua")

print("test_treemodel:")
local model = CIT.TreeModel.build(fx.tree, fx.build)

-- Conserva todos los nodos, indexados por ID.
local count = 0
for _ in pairs(model.nodes) do count = count + 1 end
T.eq(count, 5, "conserva los 5 nodos")
T.eq(model.nodes[31319].name, "With Honor", "mapea Name -> name")
T.eq(model.nodes[31319].x, 6, "mapea PositionX -> x")
T.eq(model.nodes[31169].nodeType, "SpendSquare", "mapea NodeType")

-- Estado aprendido desde buildMap.
T.eq(model.nodes[31319].known, true, "nodo en build -> known")
T.eq(model.nodes[31319].rank, 1, "rank desde build")
T.eq(model.nodes[30056].maxRank, 3, "maxRank desde build")
T.eq(model.nodes[1719].known, false, "nodo fuera de build -> not known")
T.eq(model.nodes[1719].rank, 0, "rank 0 si no aprendido")

-- Tabs únicas, en orden de primera aparición.
T.eq(model.tabs[1], "Protection", "primer tab")
T.eq(model.tabs[2], "Class", "segundo tab")
T.eq(#model.tabs, 2, "dos tabs distintos")

-- Aristas: solo entre nodos presentes en el set (6712/11060 no existen -> se omiten).
local function hasEdge(a, b)
  for _, e in ipairs(model.edges) do
    if e.from == a and e.to == b then return true end
  end
  return false
end
T.truthy(hasEdge(31319, 30056), "arista With Honor -> Iron Guardian")
T.truthy(hasEdge(30056, 31169), "arista Iron Guardian -> Heavy Blow")
T.eq(hasEdge(1719, 6712), false, "no crea arista a nodo inexistente")

-- bounds: límites de grilla por Tab y overall (para auto-fit del panel).
local b = CIT.TreeModel.bounds(model)
T.eq(b.maxX, 6, "bounds.maxX overall")
T.eq(#b.tabs, 2, "bounds tiene una entrada por Tab")
T.eq(b.tabs[1].name, "Protection", "bounds tab[1] name")
T.eq(b.tabs[1].minX, 2, "bounds Protection minX")
T.eq(b.tabs[1].maxX, 6, "bounds Protection maxX")
T.eq(b.tabs[1].minY, 0, "bounds Protection minY")
T.eq(b.tabs[1].maxY, 4, "bounds Protection maxY")
T.eq(b.tabs[2].name, "Class", "bounds tab[2] name")
T.eq(b.tabs[2].minX, 4, "bounds Class minX")
T.eq(b.tabs[2].maxY, 1, "bounds Class maxY")

-- fitScale: elige el tamaño de celda para que quepa el ancho.
T.eq(CIT.TreeModel.fitScale(7, 44, 308), 44, "fitScale no supera baseCell")
T.eq(CIT.TreeModel.fitScale(7, 44, 210), 30, "fitScale reduce para caber")
T.eq(CIT.TreeModel.fitScale(7, 44, 70, 20), 20, "fitScale respeta minCell")
T.eq(CIT.TreeModel.fitScale(0, 44, 308), 44, "fitScale con 0 cols devuelve baseCell")

-- layoutTabs: Class (primero) + la spec activa según el slot (tab N-ésimo).
local order = CIT.TreeModel.layoutTabs(model, 1)
T.eq(#order, 2, "layoutTabs devuelve Class + spec activa")
T.eq(order[1], "Class", "Class va primero (izquierda)")
T.eq(order[2], "Protection", "spec activa (slot 1 -> primer spec tab)")

-- La spec se elige por slot: spec2 y spec3 son otros tabs.
local m3 = CIT.TreeModel.build({
  { ID=1, Name="a", Tab="Fire",   PositionX=0, PositionY=0, ConnectedNodes={}, RequiredIDs={} },
  { ID=2, Name="b", Tab="Frost",  PositionX=0, PositionY=0, ConnectedNodes={}, RequiredIDs={} },
  { ID=3, Name="c", Tab="Arcane", PositionX=0, PositionY=0, ConnectedNodes={}, RequiredIDs={} },
  { ID=4, Name="d", Tab="Class",  PositionX=0, PositionY=0, ConnectedNodes={}, RequiredIDs={} },
}, {})
local o1 = CIT.TreeModel.layoutTabs(m3, 1)
T.eq(o1[1], "Class", "Class primero")
T.eq(o1[2], "Fire", "slot 1 -> primer spec (Fire)")
local o2 = CIT.TreeModel.layoutTabs(m3, 2)
T.eq(o2[2], "Frost", "slot 2 -> segundo spec (Frost)")
local o3 = CIT.TreeModel.layoutTabs(m3, 3)
T.eq(o3[2], "Arcane", "slot 3 -> tercer spec (Arcane)")
-- slot fuera de rango cae al primer spec.
local o9 = CIT.TreeModel.layoutTabs(m3, 9)
T.eq(o9[2], "Fire", "slot fuera de rango -> primer spec")
return T.done()
