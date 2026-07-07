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
return T.done()
