-- RECONOCIMIENTO IN-GAME PENDIENTE (Task 9 Step 1):
-- Con el inspect abierto, ejecutar en el juego para hallar los nombres reales:
--   /dump InspectFrame and InspectFrame:GetName()
--   /run for i=1,select("#",WorldFrame:GetChildren()) do local f=select(i,WorldFrame:GetChildren()); if f:IsVisible() and f.unit then print(f:GetName()) end end
-- Anotar aquí el frame real de inspect y el patrón de botones de spec, y
-- rellenar `getInspectFrame` (lista `names`) y `hookSpecButtons` (`specButtonPattern`).
local CIT = _G.CoAInspectTree
if not CIT then CIT = {}; _G.CoAInspectTree = CIT end
CIT.InspectHook = {}

-- Estado del inspect en curso.
local current = { unit = nil, className = nil, tree = nil, slot = nil }

-- Devuelve el frame de inspect visible, o nil. Rellenar con el nombre real
-- hallado en el Step 1 de reconocimiento.
local function getInspectFrame()
  local names = { "InspectFrame", "InspectPaperDollFrame" }
  for _, n in ipairs(names) do
    local f = _G[n]
    if f and f.IsVisible and f:IsVisible() then return f end
  end
  return nil
end

-- Carga el árbol de la clase del unit y renderiza para la spec `slot`.
local function renderFor(unit, slot)
  if not CIT.enabled then return end
  local className = CIT.CAReader.className(unit)
  if not className then return end
  current.unit = unit
  current.className = className
  current.slot = slot
  current.tree = CIT.CAReader.classTree(className, slot)
  if #current.tree == 0 then
    current.retries = (current.retries or 0) + 1
    CIT.TreePanel.Get().title:SetText("Cargando talentos...")
    CIT.TreePanel.Show()
    if current.retries <= 5 then
      local u, s = unit, slot
      -- C_Timer no existe en 3.3.5; usar un frame OnUpdate de un disparo.
      local t = CreateFrame("Frame")
      local waited = 0
      t:SetScript("OnUpdate", function(self, e)
        waited = waited + e
        if waited >= 0.5 then
          self:SetScript("OnUpdate", nil)
          renderFor(u, s)
        end
      end)
    else
      CIT.TreePanel.Get().title:SetText("Sin datos de talentos")
    end
    return
  end
  current.retries = 0
  local buildMap = CIT.CAReader.unitBuild(unit, slot)
  local model = CIT.TreeModel.build(current.tree, buildMap)
  local inspectFrame = getInspectFrame()
  if inspectFrame then CIT.TreePanel.AttachTo(inspectFrame) end
  CIT.TreePanel.Get().title:SetText((UnitName(unit) or "") .. " — spec " .. tostring(slot))
  CIT.TreePanel.Render(model)
  CIT.TreePanel.Show()
end
CIT.InspectHook.RenderFor = renderFor

-- Re-resalta el árbol ya cargado para otra spec sin recargar la estructura.
local function restyleFor(slot)
  if not (current.unit and current.tree) then return end
  current.slot = slot
  local buildMap = CIT.CAReader.unitBuild(current.unit, slot)
  local model = CIT.TreeModel.build(current.tree, buildMap)
  CIT.TreePanel.Get().title:SetText((UnitName(current.unit) or "") .. " — spec " .. tostring(slot))
  CIT.TreePanel.Render(model)
end
CIT.InspectHook.RestyleFor = restyleFor

-- Al llegar la data CoA del inspeccionado, renderizar su spec activa.
CIT.RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT", function()
  local unit = "target"
  local inspectFrame = getInspectFrame()
  if inspectFrame and inspectFrame.unit then unit = inspectFrame.unit end
  local active = CIT.CAReader.inspectInfo(unit) or 1
  renderFor(unit, active)
end)

-- Ocultar el panel cuando se cierra el inspect.
CIT.RegisterEvent("PLAYER_TARGET_CHANGED", function()
  local f = getInspectFrame()
  if not f then CIT.TreePanel.Hide() end
end)

-- Engancha los botones del selector de spec del panel nativo, si existen.
-- Rellenar `specButtonPattern` con el patrón real hallado en el Step 1.
local function hookSpecButtons()
  local specButtonPattern = nil  -- p.ej. "CoATalentsSpecButton%d"
  if not specButtonPattern then return end
  for slot = 1, 3 do
    local btn = _G[specButtonPattern:format(slot)]
    if btn and not btn.__coaitHooked then
      btn.__coaitHooked = true
      btn:HookScript("OnClick", function() restyleFor(slot) end)
    end
  end
end

CIT.RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT", function()
  CIT.safe(hookSpecButtons)
end)

-- Muestra el panel solo cuando la pestaña Build del inspect está activa.
-- RECONOCIMIENTO PENDIENTE: rellenar `isBuildTabActive` con la comprobación
-- real del selectedTab del frame nativo (ver Task 9 Step 1). Mientras no se
-- determine, se asume visible cuando hay un inspect en curso.
local buildTabWatcher = CreateFrame("Frame")
local accum = 0
buildTabWatcher:SetScript("OnUpdate", function(_, elapsed)
  if not CIT.enabled then return end
  accum = accum + elapsed
  if accum < 0.2 then return end
  accum = 0
  local f = getInspectFrame()
  if not f then CIT.TreePanel.Hide(); return end
  local function isBuildTabActive()
    -- Placeholder de detección: si no se pudo determinar la pestaña, asumir
    -- visible. Reemplazar por la comprobación real del selectedTab del frame.
    return true
  end
  if current.unit and isBuildTabActive() then
    CIT.TreePanel.Show()
  else
    CIT.TreePanel.Hide()
  end
end)
