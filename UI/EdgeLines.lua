local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.EdgeLines = {}

-- Dibuja una línea (textura fina) entre los centros de dos botones.
-- Usa la técnica clásica 3.3.5 de líneas: una textura rotada NO está disponible
-- sin SetTexCoord manual, así que usamos una textura estirada entre anchors
-- aproximando con un rectángulo fino horizontal/vertical + diagonal por tramos.
-- Para árboles CoA las conexiones son mayormente verticales/horizontales.
local function drawLine(tex, fromBtn, toBtn)
  local ax, ay = fromBtn:GetCenter()
  local bx, by = toBtn:GetCenter()
  if not (ax and bx) then tex:Hide(); return end
  local parent = tex:GetParent()
  local px, py = parent:GetCenter()
  -- Coordenadas relativas al parent.
  tex:ClearAllPoints()
  tex:SetPoint("CENTER", parent, "CENTER", ((ax + bx) / 2) - px, ((ay + by) / 2) - py)
  local dx, dy = math.abs(bx - ax), math.abs(by - ay)
  if dx >= dy then
    tex:SetWidth(math.max(dx, 2)); tex:SetHeight(2)
  else
    tex:SetWidth(2); tex:SetHeight(math.max(dy, 2))
  end
  tex:Show()
end

-- Dibuja todas las aristas. linePool es una tabla reutilizable de texturas.
function CIT.EdgeLines.Draw(parent, edges, buttonsById, linePool)
  for i = 1, #linePool do linePool[i]:Hide() end
  for i, e in ipairs(edges) do
    local a, b = buttonsById[e.from], buttonsById[e.to]
    if a and b then
      local tex = linePool[i]
      if not tex then
        tex = parent:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(0.5, 0.5, 0.5, 0.6)  -- gris translúcido (RGBA sólido)
        linePool[i] = tex
      end
      drawLine(tex, a, b)
    end
  end
end
