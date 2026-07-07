local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.TreePanel = {}
local TP = CIT.TreePanel

local PANEL_WIDTH = 360
local frame, scroll, content

-- Crea el panel una sola vez. Contiene un ScrollFrame con un content interno
-- donde TreePanel.Render posiciona los nodos.
function TP.Get()
  if frame then return frame end
  frame = CreateFrame("Frame", "CoAInspectTreePanel", UIParent)
  frame:SetWidth(PANEL_WIDTH)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -12)
  title:SetText("Árbol de talentos")
  frame.title = title

  scroll = CreateFrame("ScrollFrame", "CoAInspectTreeScroll", frame)
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -40)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)

  content = CreateFrame("Frame", "CoAInspectTreeContent", scroll)
  content:SetWidth(PANEL_WIDTH - 24)
  content:SetHeight(1)
  scroll:SetScrollChild(content)

  frame.content = content
  frame.scroll = scroll
  frame.buttons = {}      -- pool de NodeButton
  frame.buttonsById = {}  -- id -> button (última render)
  frame.linePool = {}     -- pool de texturas de EdgeLines
  frame:Hide()
  return frame
end

-- Ancla el panel al borde derecho del frame de inspect, mismo alto.
function TP.AttachTo(inspectFrame)
  local f = TP.Get()
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", inspectFrame, "TOPRIGHT", -4, 0)
  f:SetPoint("BOTTOMLEFT", inspectFrame, "BOTTOMRIGHT", -4, 0)
end

function TP.Show() TP.Get():Show() end
function TP.Hide() if frame then frame:Hide() end end

local CELL = 40          -- px por celda de grilla
local TAB_GAP = 24       -- separación vertical entre bloques de Tab
local TAB_HEADER = 18    -- alto del título de cada Tab

-- Obtiene (o crea) el botón i del pool.
local function acquireButton(f, i)
  local b = f.buttons[i]
  if not b then
    b = CIT.NodeButton.Create(f.content)
    f.buttons[i] = b
  end
  b:Show()
  return b
end

-- Obtiene (o crea) el header i del pool de títulos de Tab.
local function acquireHeader(f, i)
  f.headers = f.headers or {}
  local h = f.headers[i]
  if not h then
    h = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.headers[i] = h
  end
  h:Show()
  return h
end

-- Renderiza el modelo completo: agrupa nodos por Tab (en el orden model.tabs),
-- coloca cada nodo según PositionX/PositionY dentro de su bloque, y dibuja aristas.
function CIT.TreePanel.Render(model)
  local f = CIT.TreePanel.Get()
  -- Reset de pools (ocultar todo lo previo antes de reusar).
  for i = 1, #f.buttons do f.buttons[i]:Hide() end
  if f.headers then for i = 1, #f.headers do f.headers[i]:Hide() end end
  f.buttonsById = {}

  local btnIndex = 0
  local headerIndex = 0
  local yCursor = 0  -- offset vertical acumulado (negativo hacia abajo)

  for _, tabName in ipairs(model.tabs) do
    -- Título del Tab.
    headerIndex = headerIndex + 1
    local header = acquireHeader(f, headerIndex)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, yCursor)
    header:SetText(tabName)
    yCursor = yCursor - TAB_HEADER

    -- Nodos de este Tab: calcular extensión de la grilla (maxY) y colocar.
    local maxY = 0
    for _, node in pairs(model.nodes) do
      if node.tab == tabName and node.y and node.y > maxY then maxY = node.y end
    end

    for id, node in pairs(model.nodes) do
      if node.tab == tabName then
        btnIndex = btnIndex + 1
        local b = acquireButton(f, btnIndex)
        CIT.NodeButton.Style(b, node)
        b:ClearAllPoints()
        local px = (node.x or 0) * CELL
        local py = yCursor - ((node.y or 0) * CELL)
        b:SetPoint("TOPLEFT", f.content, "TOPLEFT", px, py)
        f.buttonsById[id] = b
      end
    end

    -- Avanzar el cursor bajo el bloque de este Tab.
    yCursor = yCursor - ((maxY + 1) * CELL) - TAB_GAP
  end

  -- Ajustar altura del content al total usado (yCursor es negativo).
  f.content:SetHeight(math.max(1, -yCursor + 20))

  -- Dibujar aristas entre los botones colocados.
  CIT.EdgeLines.Draw(f.content, model.edges, f.buttonsById, f.linePool)
end
