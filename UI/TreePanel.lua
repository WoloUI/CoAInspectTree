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
local SECTION_GAP = 48 -- separación entre el árbol del inspeccionado y el tuyo

local frame, scroll, content

-- Crea el panel una sola vez. Contiene un ScrollFrame con un content interno,
-- una fila de selector de spec y un botón Comparar.
function TP.Get()
  if frame then return frame end
  frame = CreateFrame("Frame", "CoAInspectTreePanel", UIParent)
  frame:SetWidth(360)
  frame:SetHeight(400)
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

  -- Botón Comparar (arriba a la derecha).
  local cmp = CreateFrame("Button", nil, frame)
  cmp:SetWidth(84); cmp:SetHeight(20)
  cmp:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -6)
  cmp:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, tile = false, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 } })
  cmp.txt = cmp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  cmp.txt:SetAllPoints(cmp)
  cmp.txt:SetText("Comparar")
  cmp:Hide()
  frame.compareBtn = cmp

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
  frame.buttonsById = {}  -- clave prefijada -> button (última render)
  frame.linePool = {}     -- pool de texturas de EdgeLines
  frame:Hide()
  return frame
end

-- Ancla el panel al borde derecho del inspect por la esquina superior.
function TP.AttachTo(inspectFrame)
  local f = TP.Get()
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", inspectFrame, "TOPRIGHT", 4, 0)
end

function TP.Show() TP.Get():Show() end
function TP.Hide() if frame then frame:Hide() end end

-- Configura el botón Comparar: estado on/off y callback de clic.
function TP.SetCompare(isOn, onClick)
  local f = TP.Get()
  local b = f.compareBtn
  if isOn then
    b:SetBackdropColor(0.14, 0.45, 0.42, 0.95)
    b:SetBackdropBorderColor(0.25, 0.85, 0.80, 1)
  else
    b:SetBackdropColor(0.10, 0.10, 0.13, 0.9)
    b:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
  end
  b:SetScript("OnClick", function() if onClick then onClick() end end)
  b:Show()
end

-- Dibuja los botones de selección de spec.
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

-- Suma de columnas visibles (para elegir escala) y nº de tabs mostrados.
local function shownCols(model)
  local order = CIT.TreeModel.layoutTabs(model)
  local bounds = CIT.TreeModel.bounds(model)
  local byName = {}
  for _, ti in ipairs(bounds.tabs) do byName[ti.name] = ti end
  local cols, tabs = 0, 0
  for _, name in ipairs(order) do
    local ti = byName[name]
    if ti then cols = cols + (ti.maxX + 1); tabs = tabs + 1 end
  end
  return cols, tabs
end

-- Coloca las columnas de un modelo desde startX, con prefijo de clave (para no
-- colisionar IDs entre árboles) y prefijo de header (p.ej. "TÚ · "). Devuelve
-- (nuevoX, maxColH, btnIndex, headerIndex).
local function renderColumns(f, model, keyPrefix, headerPrefix, startX, cell, iconSize, btnIndex, headerIndex)
  local order = CIT.TreeModel.layoutTabs(model)
  local bounds = CIT.TreeModel.bounds(model)
  local byName = {}
  for _, ti in ipairs(bounds.tabs) do byName[ti.name] = ti end

  local xOffset = startX
  local maxColH = 0
  for _, tabName in ipairs(order) do
    local tabInfo = byName[tabName]
    if tabInfo then
      headerIndex = headerIndex + 1
      local header = acquireHeader(f, headerIndex)
      header:ClearAllPoints()
      header:SetPoint("TOPLEFT", f.content, "TOPLEFT", xOffset, 0)
      header:SetText(headerPrefix .. tabName)

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
          f.buttonsById[keyPrefix .. id] = b
        end
      end

      local colW = (tabInfo.maxX + 1) * cell
      local colH = TAB_HEADER + (tabInfo.maxY + 1) * cell
      if colH > maxColH then maxColH = colH end
      xOffset = xOffset + colW + TAB_COL_GAP
    end
  end
  return xOffset, maxColH, btnIndex, headerIndex
end

-- Renderiza el árbol del inspeccionado y, si `myModel` viene dado, tu propio
-- árbol a la derecha (separado por un divisor y con headers "TÚ · ...").
function CIT.TreePanel.Render(model, myModel)
  local f = CIT.TreePanel.Get()
  for i = 1, #f.buttons do f.buttons[i]:Hide() end
  if f.headers then for i = 1, #f.headers do f.headers[i]:Hide() end end
  if f.divider then f.divider:Hide() end
  f.buttonsById = {}

  local sw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1024
  local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768

  local cols1, tabs1 = shownCols(model)
  local cols2, tabs2 = 0, 0
  if myModel then cols2, tabs2 = shownCols(myModel) end
  local totalCols = cols1 + cols2
  local totalTabs = tabs1 + tabs2

  local widthFactor = myModel and 0.75 or 0.55
  local nGaps = math.max(0, totalTabs - 1)
  local extra = myModel and SECTION_GAP or 0
  local maxContentW = math.floor(sw * widthFactor) - nGaps * TAB_COL_GAP - extra
  local cell = CIT.TreeModel.fitScale(totalCols, BASE_CELL, maxContentW, MIN_CELL)
  local iconSize = math.max(14, cell - 8)

  local edges = {}
  local x, maxColH, btnIndex, headerIndex = renderColumns(f, model, "t", "", 0, cell, iconSize, 0, 0)
  for _, e in ipairs(model.edges) do edges[#edges + 1] = { from = "t" .. e.from, to = "t" .. e.to } end

  if myModel then
    -- x trae un TAB_COL_GAP de más al final; convertirlo en el hueco de sección.
    local dividerX = x - TAB_COL_GAP + math.floor(SECTION_GAP / 2)
    local myStartX = x - TAB_COL_GAP + SECTION_GAP
    local x2, h2
    x2, h2, btnIndex, headerIndex = renderColumns(f, myModel, "m", "TÚ · ", myStartX, cell, iconSize, btnIndex, headerIndex)
    if h2 > maxColH then maxColH = h2 end
    x = x2
    for _, e in ipairs(myModel.edges) do edges[#edges + 1] = { from = "m" .. e.from, to = "m" .. e.to } end

    f.divider = f.divider or f.content:CreateTexture(nil, "BACKGROUND")
    f.divider:SetTexture(0.30, 0.30, 0.36, 0.85)
    f.divider:ClearAllPoints()
    f.divider:SetPoint("TOPLEFT", f.content, "TOPLEFT", dividerX, 0)
    f.divider:SetWidth(2)
    f.divider:SetHeight(maxColH)
    f.divider:Show()
  end

  local contentW = math.max(1, x - TAB_COL_GAP)
  local contentH = math.max(1, maxColH + 10)
  f.content:SetWidth(contentW)
  f.content:SetHeight(contentH)

  local headerTotal = TITLE_H + SPEC_H
  local maxPanelInner = math.floor(sh * 0.9) - headerTotal - PAD
  local innerH = math.min(contentH, maxPanelInner)
  f:SetWidth(contentW + 2 * PAD)
  f:SetHeight(innerH + headerTotal + PAD)

  CIT.EdgeLines.Draw(f.content, edges, f.buttonsById, f.linePool)
end
