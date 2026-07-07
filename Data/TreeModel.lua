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
    local maxX, maxY = 0, 0
    for _, node in pairs(model.nodes) do
      if node.tab == tabName then
        if (node.x or 0) > maxX then maxX = node.x end
        if (node.y or 0) > maxY then maxY = node.y end
      end
    end
    if maxX > overallMaxX then overallMaxX = maxX end
    table.insert(tabs, { name = tabName, maxX = maxX, maxY = maxY })
  end
  return { maxX = overallMaxX, tabs = tabs }
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
