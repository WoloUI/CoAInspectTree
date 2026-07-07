local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.NodeButton = {}

local NODE_SIZE = 32  -- px en pantalla (los SizeX del cliente son 64; escalamos)

-- Crea un botón de nodo hijo de `parent`. Reutilizable (pool en TreePanel).
function CIT.NodeButton.Create(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(NODE_SIZE)
  b:SetHeight(NODE_SIZE)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints(b)

  b.border = b:CreateTexture(nil, "OVERLAY")
  b.border:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 2)
  b.border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)

  b.rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.rank:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)

  return b
end

-- Aplica los datos de `node` al botón: ícono, atenuado si no aprendido,
-- rango sobreimpreso, tooltip. Forma según NodeType.
function CIT.NodeButton.Style(button, node)
  button.nodeData = node
  button.icon:SetTexture("Interface\\Icons\\" .. (node.icon or "INV_Misc_QuestionMark"))

  if node.known then
    button.icon:SetDesaturated(false)
    button.icon:SetVertexColor(1, 1, 1)
    button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.border:SetBlendMode("ADD")
    button.border:Show()
  else
    button.icon:SetDesaturated(true)
    button.icon:SetVertexColor(0.5, 0.5, 0.5)
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
    if node.tab then GameTooltip:AddLine(node.tab, 0.6, 0.6, 0.6) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
