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
