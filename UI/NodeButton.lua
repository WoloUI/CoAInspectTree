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

-- Crea un botón de nodo hijo de `parent`. Reutilizable (pool en TreePanel).
function CIT.NodeButton.Create(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(NODE_SIZE)
  b:SetHeight(NODE_SIZE)

  -- Borde: cuadro sólido detrás del icono; el reborde asoma como marco de color.
  b.border = b:CreateTexture(nil, "BACKGROUND")
  b.border:SetTexture(SOLID)
  b.border:SetPoint("TOPLEFT", b, "TOPLEFT", -1.5, 1.5)
  b.border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1.5, -1.5)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints(b)

  b.rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.rank:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)

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
    button.border:SetVertexColor(c[1], c[2], c[3])
    button.border:SetAlpha(1)
    button.border:Show()
  else
    -- No aprendido: atenuado pero visible, para ver el árbol completo.
    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(0.85, 0.85, 0.85)
    button.icon:SetAlpha(0.6)
    button.border:Hide()
  end

  if node.known and node.rank and node.rank > 0 then
    if node.maxRank then
      button.rank:SetText(node.rank .. "/" .. node.maxRank)
    else
      button.rank:SetText(tostring(node.rank))
    end
    button.rank:Show()
  else
    button.rank:Hide()
  end

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(node.name or "?")
    if node.known and node.rank and node.rank > 0 then
      local r = node.maxRank and (node.rank .. "/" .. node.maxRank) or tostring(node.rank)
      GameTooltip:AddLine("Rango " .. r, 0.2, 0.85, 0.78)
    end
    if node.tab then GameTooltip:AddLine(node.tab, 0.6, 0.6, 0.6) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
