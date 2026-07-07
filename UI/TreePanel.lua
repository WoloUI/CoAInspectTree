local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.TreePanel = {}
local TP = CIT.TreePanel

local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"  -- textura blanca sólida
local BASE_CELL = 44   -- px por celda de grilla a escala completa
local MIN_CELL = 22    -- px mínimos por celda al reducir para caber
local TITLE_H = 34     -- alto reservado para el título
local PAD = 12         -- margen interior
local TAB_HEADER = 18  -- alto del título de cada Tab
local TAB_GAP = 20     -- separación vertical entre bloques de Tab

local frame, scroll, content

-- Crea el panel una sola vez. Contiene un ScrollFrame con un content interno
-- donde TreePanel.Render posiciona los nodos.
function TP.Get()
  if frame then return frame end
  frame = CreateFrame("Frame", "CoAInspectTreePanel", UIParent)
  frame:SetWidth(360)
  frame:SetHeight(400)
  -- Estilo plano oscuro (ElvUI): fondo opaco + borde fino de 1px.
  frame:SetBackdrop({
    bgFile = SOLID,
    edgeFile = SOLID,
    tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
  frame:SetBackdropBorderColor(0.16, 0.16, 0.20, 1)
  frame:SetFrameStrata("HIGH")

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -10)
  title:SetText("Árbol de talentos")
  frame.title = title

  scroll = CreateFrame("ScrollFrame", "CoAInspectTreeScroll", frame)
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -TITLE_H)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)

  content = CreateFrame("Frame", "CoAInspectTreeContent", scroll)
  content:SetWidth(1)
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

-- Ancla el panel al borde derecho del inspect por la esquina superior, dejando
-- que el auto-tamaño de Render defina ancho y alto.
function TP.AttachTo(inspectFrame)
  local f = TP.Get()
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", inspectFrame, "TOPRIGHT", 4, 0)
end

function TP.Show() TP.Get():Show() end
function TP.Hide() if frame then frame:Hide() end end

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

-- Renderiza el modelo completo con auto-ajuste al contenido: calcula límites,
-- elige la escala de celda para caber en ~38% del ancho de pantalla, dimensiona
-- el panel al árbol real y dibuja las aristas.
function CIT.TreePanel.Render(model)
  local f = CIT.TreePanel.Get()
  -- Reset de pools (ocultar todo lo previo antes de reusar).
  for i = 1, #f.buttons do f.buttons[i]:Hide() end
  if f.headers then for i = 1, #f.headers do f.headers[i]:Hide() end end
  f.buttonsById = {}

  local bounds = CIT.TreeModel.bounds(model)
  local cols = (bounds.maxX or 0) + 1
  local sw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1024
  local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768
  local maxContentW = math.floor(sw * 0.38)
  local cell = CIT.TreeModel.fitScale(cols, BASE_CELL, maxContentW, MIN_CELL)
  local iconSize = math.max(14, cell - 8)
  local contentW = cols * cell

  local btnIndex, headerIndex = 0, 0
  local yCursor = 0  -- offset vertical acumulado (negativo hacia abajo)

  for _, tabInfo in ipairs(bounds.tabs) do
    local tabName = tabInfo.name
    headerIndex = headerIndex + 1
    local header = acquireHeader(f, headerIndex)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, yCursor)
    header:SetText(tabName)
    yCursor = yCursor - TAB_HEADER

    for id, node in pairs(model.nodes) do
      if node.tab == tabName then
        btnIndex = btnIndex + 1
        local b = acquireButton(f, btnIndex)
        b:SetWidth(iconSize)
        b:SetHeight(iconSize)
        CIT.NodeButton.Style(b, node)
        b:ClearAllPoints()
        local px = (node.x or 0) * cell
        local py = yCursor - ((node.y or 0) * cell)
        b:SetPoint("TOPLEFT", f.content, "TOPLEFT", px, py)
        f.buttonsById[id] = b
      end
    end

    yCursor = yCursor - ((tabInfo.maxY + 1) * cell) - TAB_GAP
  end

  local contentH = -yCursor + 10
  f.content:SetWidth(math.max(1, contentW))
  f.content:SetHeight(math.max(1, contentH))

  -- Dimensionar el panel al contenido, con tope al 90% del alto de pantalla
  -- (si excede, el ScrollFrame permite desplazarse verticalmente).
  local maxPanelInner = math.floor(sh * 0.9) - TITLE_H - PAD
  local innerH = math.min(contentH, maxPanelInner)
  f:SetWidth(contentW + 2 * PAD)
  f:SetHeight(innerH + TITLE_H + PAD)

  -- Dibujar aristas entre los botones colocados.
  CIT.EdgeLines.Draw(f.content, model.edges, f.buttonsById, f.linePool)
end
