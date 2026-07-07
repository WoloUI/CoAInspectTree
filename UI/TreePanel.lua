local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.TreePanel = {}
local TP = CIT.TreePanel

local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"  -- textura blanca sólida
local BASE_CELL = 44   -- px por celda de grilla a escala completa
local MIN_CELL = 22    -- px mínimos por celda al reducir para caber
local TITLE_H = 24     -- alto del título
local SPEC_H = 24      -- alto de la fila de selector de spec
local PAD = 12         -- margen interior
local TAB_HEADER = 18  -- alto del título de cada Tab (dentro del content)
local TAB_COL_GAP = 26 -- separación horizontal entre columnas de Tab

local frame, scroll, content

-- Crea el panel una sola vez. Contiene un ScrollFrame con un content interno
-- donde TreePanel.Render posiciona los nodos, y una fila de selector de spec.
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
  title:SetPoint("TOP", frame, "TOP", 0, -6)
  title:SetText("Árbol de talentos")
  frame.title = title

  -- Fila de selector de spec (botones propios, no dependemos del panel nativo).
  frame.specRow = CreateFrame("Frame", nil, frame)
  frame.specRow:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -TITLE_H)
  frame.specRow:SetHeight(SPEC_H)
  frame.specRow:SetWidth(240)
  frame.specButtons = {}

  scroll = CreateFrame("ScrollFrame", "CoAInspectTreeScroll", frame)
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(TITLE_H + SPEC_H))
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

-- Dibuja los botones de selección de spec. `specs` es una lista de slots
-- (p.ej. {1,2,3}); `current` el activo; `onClick(slot)` el callback.
function TP.SetSpecs(specs, current, onClick)
  local f = TP.Get()
  for i = 1, #f.specButtons do f.specButtons[i]:Hide() end
  local x = 0
  for i, slot in ipairs(specs or {}) do
    local b = f.specButtons[i]
    if not b then
      b = CreateFrame("Button", nil, f.specRow)
      b:SetWidth(28); b:SetHeight(20)
      b:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 } })
      b.txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      b.txt:SetAllPoints(b)
      f.specButtons[i] = b
    end
    b:ClearAllPoints()
    b:SetPoint("LEFT", f.specRow, "LEFT", x, 0)
    b.txt:SetText(tostring(slot))
    if slot == current then
      b:SetBackdropColor(0.14, 0.45, 0.42, 0.95)
      b:SetBackdropBorderColor(0.25, 0.85, 0.80, 1)
    else
      b:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
      b:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    end
    b:SetScript("OnClick", function() if onClick then onClick(slot) end end)
    b:Show()
    x = x + 32
  end
end

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

-- Renderiza el modelo con los Tabs (clase + spec) en COLUMNAS lado a lado.
-- Cada tab conserva sus tiers verticales; el panel se dimensiona al contenido.
function CIT.TreePanel.Render(model)
  local f = CIT.TreePanel.Get()
  for i = 1, #f.buttons do f.buttons[i]:Hide() end
  if f.headers then for i = 1, #f.headers do f.headers[i]:Hide() end end
  f.buttonsById = {}

  local bounds = CIT.TreeModel.bounds(model)

  -- Escala: que la suma de columnas de todos los tabs quepa en ~55% del ancho.
  local totalCols = 0
  for _, tabInfo in ipairs(bounds.tabs) do totalCols = totalCols + (tabInfo.maxX + 1) end
  local sw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1024
  local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768
  local nGaps = math.max(0, #bounds.tabs - 1)
  local maxContentW = math.floor(sw * 0.55) - nGaps * TAB_COL_GAP
  local cell = CIT.TreeModel.fitScale(totalCols, BASE_CELL, maxContentW, MIN_CELL)
  local iconSize = math.max(14, cell - 8)

  local btnIndex, headerIndex = 0, 0
  local xOffset = 0
  local maxColH = 0

  for _, tabInfo in ipairs(bounds.tabs) do
    local tabName = tabInfo.name
    headerIndex = headerIndex + 1
    local header = acquireHeader(f, headerIndex)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", f.content, "TOPLEFT", xOffset, 0)
    header:SetText(tabName)

    for id, node in pairs(model.nodes) do
      if node.tab == tabName then
        btnIndex = btnIndex + 1
        local b = acquireButton(f, btnIndex)
        b:SetWidth(iconSize)
        b:SetHeight(iconSize)
        CIT.NodeButton.Style(b, node)
        b:ClearAllPoints()
        local px = xOffset + (node.x or 0) * cell
        local py = -TAB_HEADER - ((node.y or 0) * cell)
        b:SetPoint("TOPLEFT", f.content, "TOPLEFT", px, py)
        f.buttonsById[id] = b
      end
    end

    local colW = (tabInfo.maxX + 1) * cell
    local colH = TAB_HEADER + (tabInfo.maxY + 1) * cell
    if colH > maxColH then maxColH = colH end
    xOffset = xOffset + colW + TAB_COL_GAP
  end

  local contentW = math.max(1, xOffset - TAB_COL_GAP)
  local contentH = math.max(1, maxColH + 10)
  f.content:SetWidth(contentW)
  f.content:SetHeight(contentH)

  -- Dimensionar el panel al contenido, con tope al 90% del alto de pantalla.
  local headerTotal = TITLE_H + SPEC_H
  local maxPanelInner = math.floor(sh * 0.9) - headerTotal - PAD
  local innerH = math.min(contentH, maxPanelInner)
  f:SetWidth(contentW + 2 * PAD)
  f:SetHeight(innerH + headerTotal + PAD)

  CIT.EdgeLines.Draw(f.content, model.edges, f.buttonsById, f.linePool)
end
