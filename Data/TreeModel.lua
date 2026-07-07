local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.TreeModel = {}

-- Combina el árbol crudo de la clase (lista de nodos de GetTalentsByClass) con
-- la build aprendida (mapa id -> {rank,maxRank}) en un modelo posicionable.
function CIT.TreeModel.build(rawTree, buildMap)
  buildMap = buildMap or {}
  local model = { tabs = {}, nodes = {}, edges = {} }
  local seenTab = {}

  for _, raw in ipairs(rawTree) do
    local id = raw.ID
    local learned = buildMap[id]
    model.nodes[id] = {
      id       = id,
      name     = raw.Name,
      icon     = raw.Icon,
      tab      = raw.Tab,
      x        = raw.PositionX,
      y        = raw.PositionY,
      sizeX    = raw.SizeX,
      sizeY    = raw.SizeY,
      nodeType = raw.NodeType,
      type     = raw.Type,
      color    = raw.Color,
      quality  = raw.Quality,
      known    = learned ~= nil,
      rank     = learned and learned.rank or 0,
      maxRank  = learned and learned.maxRank or nil,
      connected = raw.ConnectedNodes or {},
      required  = raw.RequiredIDs or {},
      spells    = raw.Spells,
    }
    if raw.Tab and not seenTab[raw.Tab] then
      seenTab[raw.Tab] = true
      table.insert(model.tabs, raw.Tab)
    end
  end

  -- Aristas: por cada nodo, una arista a cada ConnectedNode que exista en el set.
  for id, node in pairs(model.nodes) do
    for _, targetId in ipairs(node.connected) do
      if model.nodes[targetId] then
        table.insert(model.edges, { from = id, to = targetId })
      end
    end
  end

  return model
end

-- Límites de la grilla por Tab (y overall), usados por TreePanel para
-- dimensionar el panel al contenido real. Devuelve:
--   { maxX = <max x global>, tabs = { { name, maxX, maxY }, ... } }
-- en el orden de model.tabs.
function CIT.TreeModel.bounds(model)
  local overallMaxX = 0
  local tabs = {}
  for _, tabName in ipairs(model.tabs) do
    local minX, maxX, minY, maxY
    for _, node in pairs(model.nodes) do
      if node.tab == tabName then
        local x, y = node.x or 0, node.y or 0
        if not minX or x < minX then minX = x end
        if not maxX or x > maxX then maxX = x end
        if not minY or y < minY then minY = y end
        if not maxY or y > maxY then maxY = y end
      end
    end
    minX = minX or 0; maxX = maxX or 0; minY = minY or 0; maxY = maxY or 0
    if maxX > overallMaxX then overallMaxX = maxX end
    table.insert(tabs, { name = tabName, minX = minX, maxX = maxX, minY = minY, maxY = maxY })
  end
  return { maxX = overallMaxX, tabs = tabs }
end

-- Devuelve la lista ordenada de tabs a mostrar: "Class" primero (a la izquierda)
-- y luego la spec a la derecha. Preferimos la spec donde el jugador TIENE
-- talentos aprendidos (la que realmente usa); si ninguna tiene aprendidos (build
-- aún sin cargar o spec vacía), caemos a la spec N-ésima según `slot`. Nunca se
-- muestran todas las specs a la vez. Las demás quedan ocultas.
function CIT.TreeModel.layoutTabs(model, slot)
  local CLASS = "Class"
  local specs = {}
  local hasClass = false
  for _, t in ipairs(model.tabs) do
    if t == CLASS then hasClass = true else specs[#specs + 1] = t end
  end

  -- specs (no-Class) con al menos un talento aprendido.
  local learnedSpec = {}
  for _, node in pairs(model.nodes) do
    if node.known and node.tab ~= CLASS then learnedSpec[node.tab] = true end
  end

  local ordered = {}
  if hasClass then table.insert(ordered, CLASS) end

  local added = false
  for _, t in ipairs(specs) do
    if learnedSpec[t] then
      table.insert(ordered, t)
      added = true
    end
  end
  -- Ninguna spec con aprendidos: usar la del slot como mejor estimación.
  if not added and #specs > 0 then
    local idx = slot or 1
    if idx < 1 or idx > #specs then idx = 1 end
    table.insert(ordered, specs[idx])
  end

  -- Sin tabs (caso degenerado): devolver lo que haya en orden original.
  if #ordered == 0 then
    for _, t in ipairs(model.tabs) do table.insert(ordered, t) end
  end
  return ordered
end

-- Elige el tamaño de celda (px) para que `cols` columnas quepan en `maxWidth`,
-- sin superar baseCell ni bajar de minCell.
function CIT.TreeModel.fitScale(cols, baseCell, maxWidth, minCell)
  minCell = minCell or 20
  if not cols or cols <= 0 then return baseCell end
  local cell = math.floor(maxWidth / cols)
  if cell > baseCell then cell = baseCell end
  if cell < minCell then cell = minCell end
  return cell
end
