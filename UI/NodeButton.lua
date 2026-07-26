local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.NodeButton = {}

local NODE_SIZE = 32  -- px por defecto; TreePanel puede reescalar por botón.
local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"  -- textura blanca sólida

-- Color de acento por el Color del árbol (node.color). Fallback dorado.
local COLORS = {
  TEAL   = { 0.20, 0.82, 0.78 },
  RED    = { 0.90, 0.25, 0.25 },
  GREEN  = { 0.35, 0.85, 0.35 },
  BLUE   = { 0.30, 0.55, 0.95 },
  PURPLE = { 0.68, 0.40, 0.90 },
  YELLOW = { 0.95, 0.82, 0.25 },
  ORANGE = { 0.95, 0.55, 0.20 },
  PINK   = { 0.95, 0.45, 0.75 },
  WHITE  = { 0.90, 0.90, 0.90 },
}
local function colorFor(name)
  return COLORS[name] or { 0.85, 0.70, 0.30 }
end

-- Intenta obtener un spellID del nodo para mostrar su tooltip real. `node.spells`
-- puede ser una lista de IDs o de tablas {ID=...}; preferimos el del rango actual.
local function spellIdFor(node)
  local sp = node.spells
  if type(sp) ~= "table" then return nil end
  local function idOf(v)
    if type(v) == "number" then return v end
    if type(v) == "table" then return v.ID or v.SpellID or v.Spell end
    return nil
  end
  local r = (node.rank and node.rank > 0) and node.rank or 1
  local cand = idOf(sp[r]) or idOf(sp[1])
  if cand then return cand end
  for _, v in pairs(sp) do
    local id = idOf(v)
    if id then return id end
  end
  return nil
end

-- Crea un botón de nodo hijo de `parent`. Reutilizable (pool en TreePanel).
function CIT.NodeButton.Create(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(NODE_SIZE)
  b:SetHeight(NODE_SIZE)

  -- Placa oscura exterior: canto de 1px alrededor de cada nodo (socket).
  b.plate = b:CreateTexture(nil, "BACKGROUND")
  b.plate:SetTexture(SOLID)
  b.plate:SetPoint("TOPLEFT", b, "TOPLEFT", -2.5, 2.5)
  b.plate:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2.5, -2.5)
  b.plate:SetVertexColor(0.02, 0.02, 0.03, 1)

  -- Borde: anillo de color (aprendido) o gris tenue (socket vacío) sobre la placa.
  b.border = b:CreateTexture(nil, "BORDER")
  b.border:SetTexture(SOLID)
  b.border:SetPoint("TOPLEFT", b, "TOPLEFT", -1.5, 1.5)
  b.border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1.5, -1.5)

  -- Icono recortado para quitar el marco negro por defecto de los iconos de WoW.
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints(b)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  -- Placa oscura tras el texto de rango, para que sea legible sobre cualquier icono.
  b.rankPlate = b:CreateTexture(nil, "OVERLAY")
  b.rankPlate:SetTexture(SOLID)
  b.rankPlate:SetVertexColor(0, 0, 0, 0.75)
  b.rankPlate:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, -1)

  b.rank = b:CreateFontString(nil, "OVERLAY")
  b.rank:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  b.rank:SetPoint("CENTER", b.rankPlate, "CENTER", 0, 0)

  -- Feedback de hover: resplandor aditivo suave.
  b:SetHighlightTexture(SOLID)
  local hl = b:GetHighlightTexture()
  if hl then
    hl:SetBlendMode("ADD")
    hl:SetVertexColor(1, 1, 1, 0.12)
    hl:SetAllPoints(b)
  end

  return b
end

-- Aplica los datos de `node` al botón: ícono, atenuado si no aprendido,
-- borde teñido por el color del árbol, rango sobreimpreso y tooltip.
function CIT.NodeButton.Style(button, node)
  button.nodeData = node
  button.icon:SetTexture("Interface\\Icons\\" .. (node.icon or "INV_Misc_QuestionMark"))

  local c = colorFor(node.color)
  if node.known then
    button.icon:SetDesaturated(false)
    button.icon:SetVertexColor(1, 1, 1)
    button.icon:SetAlpha(1)
    button.border:SetVertexColor(c[1], c[2], c[3], 1)
    button.plate:SetAlpha(1)
  else
    -- No aprendido: casilla vacía. Icono muy hundido, socket gris tenue, para
    -- ver la estructura del árbol sin competir con lo aprendido.
    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(0.8, 0.8, 0.8)
    button.icon:SetAlpha(0.35)
    button.border:SetVertexColor(0.22, 0.22, 0.27, 1)
    button.plate:SetAlpha(0.85)
  end

  if node.known and node.rank and node.rank > 0 then
    if node.maxRank then
      button.rank:SetText(node.rank .. "/" .. node.maxRank)
    else
      button.rank:SetText(tostring(node.rank))
    end
    -- Dorado si está maxeado; blanco si es parcial.
    if node.maxRank and node.rank >= node.maxRank then
      button.rank:SetTextColor(1, 0.82, 0)
    else
      button.rank:SetTextColor(1, 1, 1)
    end
    button.rankPlate:SetWidth(button.rank:GetStringWidth() + 4)
    button.rankPlate:SetHeight(12)
    button.rankPlate:Show()
    button.rank:Show()
  else
    button.rankPlate:Hide()
    button.rank:Hide()
  end

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    -- Tooltip real del hechizo si podemos resolver el spellID; si no, texto básico.
    local sid = spellIdFor(node)
    local shown = false
    if sid then
      shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. sid)
    end
    if not shown then
      GameTooltip:SetText(node.name or "?")
    end
    if node.known and node.rank and node.rank > 0 then
      local r = node.maxRank and (node.rank .. "/" .. node.maxRank) or tostring(node.rank)
      GameTooltip:AddLine("Rank " .. r, 0.2, 0.85, 0.78)
    end
    if node.tab then GameTooltip:AddLine(node.tab, 0.6, 0.6, 0.6) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
