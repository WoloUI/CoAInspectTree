-- El cambio de spec se maneja con el selector PROPIO del panel (TreePanel.SetSpecs),
-- que re-consulta el árbol de la spec elegida. No dependemos de los botones nativos.
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
  -- Rank desde GetInspectedBuild (en inspect, UnitTalentRankByID da rank nil).
  local buildMap = CIT.CAReader.unitBuild(unit, slot)
  local model = CIT.TreeModel.build(current.tree, buildMap)
  local inspectFrame = getInspectFrame()
  if inspectFrame then CIT.TreePanel.AttachTo(inspectFrame) end
  CIT.TreePanel.Get().title:SetText((UnitName(unit) or "") .. " — spec " .. tostring(slot))

  -- Selector de spec propio: al hacer clic, re-consulta el árbol de esa spec.
  local _, unlocked = CIT.CAReader.inspectInfo(unit)
  local specs = {}
  if type(unlocked) == "table" then
    for _, s in ipairs(unlocked) do specs[#specs + 1] = s end
  elseif type(unlocked) == "number" then
    for s = 1, unlocked do specs[#specs + 1] = s end
  end
  if #specs == 0 then specs = { slot } end
  CIT.TreePanel.SetSpecs(specs, slot, function(s) renderFor(unit, s) end)

  CIT.TreePanel.Render(model)
  CIT.TreePanel.Show()
end
CIT.InspectHook.RenderFor = renderFor

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
