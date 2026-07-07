local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.EdgeLines = {}

local SOLID = "Interface\\ChatFrame\\ChatFrameBackground"  -- textura blanca sólida
local sqrt = math.sqrt

-- Dibuja una línea diagonal en la textura T dentro del frame C usando la técnica
-- clásica de 3.3.5 (SetTexCoord de 8 args para rotar). Coordenadas (sx,sy)-(ex,ey)
-- relativas a la esquina BOTTOMLEFT de C, con Y hacia arriba. `w` = grosor.
local function widgetLine(T, C, sx, sy, ex, ey, w)
  local dx, dy = ex - sx, ey - sy
  local cx, cy = (sx + ex) / 2, (sy + ey) / 2
  if dx < 0 then dx, dy = -dx, -dy end
  local l = sqrt(dx * dx + dy * dy)
  if l == 0 then T:Hide(); return end

  local s, c = -dy / l, dx / l
  local sc = s * c
  local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy
  if dy >= 0 then
    Bwid = (l * c) - (w * s)
    Bhgt = (w * c) - (l * s)
    BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc
    BRx, TLx, TLy = 1 - BLy, BLy, 1 - BRy
    TRx, TRy = 1 - BLx, 1
  else
    Bwid = (l * c) + (w * s)
    Bhgt = (w * c) + (l * s)
    BLx, BLy, BRx = s * s, (l / w) * sc, 1 - (w / l) * sc
    BRy, TLx, TRx = BLx, 1 - BRx, 1 - BLx
    TLy, TRy = 1, 1 - BLy
  end

  T:ClearAllPoints()
  T:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)
  T:SetPoint("BOTTOMLEFT", C, "BOTTOMLEFT", cx - (Bwid / 2), cy - (Bhgt / 2))
  T:SetPoint("TOPRIGHT",   C, "BOTTOMLEFT", cx + (Bwid / 2), cy + (Bhgt / 2))
  T:Show()
end

-- Dibuja todas las aristas. `centers` mapea clave -> { x, y, known } en coords
-- BOTTOMLEFT de `content`. Resalta (teal) las aristas entre dos nodos aprendidos.
function CIT.EdgeLines.Draw(content, edges, centers, thickness, linePool)
  local used = 0
  for _, e in ipairs(edges) do
    local a, b = centers[e.from], centers[e.to]
    if a and b then
      used = used + 1
      local tex = linePool[used]
      if not tex then
        tex = content:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(SOLID)
        linePool[used] = tex
      end
      if a.known and b.known then
        tex:SetVertexColor(0.25, 0.85, 0.80, 0.9)
      else
        tex:SetVertexColor(0.40, 0.40, 0.46, 0.55)
      end
      widgetLine(tex, content, a.x, a.y, b.x, b.y, thickness or 2)
    end
  end
  for i = used + 1, #linePool do linePool[i]:Hide() end
end
