--[[
    CATDOORS [🌐]
    DOORS | DELTA ANDROID
    VERSION 1.7 — ULTRA PERFORMANCE
    WINDUI EDITION
]]

-- SERVICES

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- WINDUI

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "CATDOORS [🌐]",
    Author = "DOORS | V1.7",
    Icon = "door-open",
    Theme = "Dark",
    Size = UDim2.fromOffset(570,480),
    MinSize = Vector2.new(320,380),
    SideBarWidth = 165,
    ToggleKey = Enum.KeyCode.RightControl,
    Folder = "CATDOORS"
})

-- COLORS

local Accent = Color3.fromRGB(0,255,120)
local PotatoColor = Color3.fromRGB(162,181,196)

-- STATE

local Active = {
    Graphics = false,
    Fog = false,
    Potato = false,
    Textures = false,
    Effects = false,
    HUD = false,

    Library = false,
    Door100 = false,

    AntiShake = false,
    SeekMode = false
}

local Closed = false

-- CONNECTIONS

local HudConnection
local AddedConnection
local LightingConnection
local RoomsConnection
local CharacterConnection

local FloorConnections = {}

-- CACHES

local OriginalParts = {}
local TextureCache = {}
local EffectCache = {}
local AtmosphereCache = {}
local LightCache = {}

local SeekPartCache = {}
local SeekEffectCache = {}

local FloorPartCache = {}

local OriginalLighting = {
    Shadows = Lighting.GlobalShadows,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd
}

-- NOTIFICATIONS

local function Notify(title,content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 3
        })
    end)
end

-- BATCH PROCESSING
-- Evita procesar miles de objetos en un solo instante.

local function ProcessInBatches(objects,callback,enabledCheck)
    task.spawn(function()
        local count = 0

        for _,obj in ipairs(objects) do
            if Closed then return end

            if enabledCheck and not enabledCheck() then
                return
            end

            if obj and obj.Parent then
                pcall(callback,obj)
            end

            count += 1

            if count >= 120 then
                count = 0
                task.wait()
            end
        end
    end)
end

-- CHARACTER FILTER

local function IsCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")

    return model
        and model:FindFirstChildOfClass("Humanoid") ~= nil
end

-- POTATO MODE

local function OptimizePart(part)
    if not part:IsA("BasePart") then return end
    if IsCharacterPart(part) then return end
    if OriginalParts[part] then return end

    OriginalParts[part] = {
        Material = part.Material,
        Color = part.Color,
        Reflectance = part.Reflectance
    }

    pcall(function()
        part.Material = Enum.Material.SmoothPlastic
        part.Color = PotatoColor
        part.Reflectance = 0
    end)
end

local function RestorePotato()
    for part,data in pairs(OriginalParts) do
        pcall(function()
            if part.Parent then
                part.Material = data.Material
                part.Color = data.Color
                part.Reflectance = data.Reflectance
            end
        end)
    end

    table.clear(OriginalParts)
end

local function SetPotato(state)
    if state then
        local objects = Workspace:GetDescendants()

        ProcessInBatches(objects,function(obj)
            if Active.Potato then
                OptimizePart(obj)
            end
        end,function()
            return Active.Potato
        end)
    else
        RestorePotato()
    end
end

-- TEXTURES

local function OptimizeTexture(obj)
    if not obj:IsA("Decal")
    and not obj:IsA("Texture") then
        return
    end

    if TextureCache[obj] ~= nil then return end

    TextureCache[obj] = obj.Transparency

    pcall(function()
        obj.Transparency = 1
    end)
end

local function RestoreTextures()
    for obj,value in pairs(TextureCache) do
        pcall(function()
            if obj.Parent then
                obj.Transparency = value
            end
        end)
    end

    table.clear(TextureCache)
end

local function SetTextures(state)
    if state then
        local objects = Workspace:GetDescendants()

        ProcessInBatches(objects,function(obj)
            if Active.Textures then
                OptimizeTexture(obj)
            end
        end,function()
            return Active.Textures
        end)
    else
        RestoreTextures()
    end
end

-- EFFECTS

local function IsEffect(obj)
    return obj:IsA("PostEffect")
        or obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Fire")
        or obj:IsA("Smoke")
        or obj:IsA("Sparkles")
end

local function OptimizeEffect(obj)
    if not IsEffect(obj) then return end
    if EffectCache[obj] ~= nil then return end

    EffectCache[obj] = obj.Enabled

    pcall(function()
        obj.Enabled = false
    end)
end

-- LIGHTS

local function OptimizeLight(obj)
    if not obj:IsA("PointLight")
    and not obj:IsA("SpotLight")
    and not obj:IsA("SurfaceLight") then
        return
    end

    if LightCache[obj] then return end

    LightCache[obj] = {
        Brightness = obj.Brightness,
        Shadows = obj.Shadows,
        Range = obj.Range
    }

    pcall(function()
        obj.Shadows = false
        obj.Brightness = math.min(obj.Brightness,0.5)
        obj.Range = math.min(obj.Range,12)
    end)
end

local function RestoreEffects()
    for obj,value in pairs(EffectCache) do
        pcall(function()
            if obj.Parent then
                obj.Enabled = value
            end
        end)
    end

    table.clear(EffectCache)

    for obj,data in pairs(LightCache) do
        pcall(function()
            if obj.Parent then
                obj.Brightness = data.Brightness
                obj.Shadows = data.Shadows
                obj.Range = data.Range
            end
        end)
    end

    table.clear(LightCache)
end

-- GRAPHICS

local function GraphicsEnabled()
    return Active.Graphics
        or Active.Effects
        or Active.Library
        or Active.Door100
end

local function RefreshGraphics()
    if Active.Graphics or Active.Effects then
        Lighting.GlobalShadows = false

        local objects = {}

        for _,obj in ipairs(Workspace:GetDescendants()) do
            table.insert(objects,obj)
        end

        for _,obj in ipairs(Lighting:GetDescendants()) do
            table.insert(objects,obj)
        end

        ProcessInBatches(objects,function(obj)
            if Active.Graphics or Active.Effects
            or Active.Library or Active.Door100 then
                OptimizeEffect(obj)
                OptimizeLight(obj)
            end
        end,function()
            return GraphicsEnabled()
        end)
    else
        if not Active.Library and not Active.Door100 then
            RestoreEffects()
        end

        Lighting.GlobalShadows = OriginalLighting.Shadows
    end
end

local function SetGraphics()
    RefreshGraphics()
end

local function SetEffects()
    RefreshGraphics()
end

-- FOG

local function OptimizeAtmosphere(obj)
    if not obj:IsA("Atmosphere") then return end
    if AtmosphereCache[obj] then return end

    AtmosphereCache[obj] = {
        Density = obj.Density,
        Haze = obj.Haze,
        Glare = obj.Glare
    }

    pcall(function()
        obj.Density = 0
        obj.Haze = 0
        obj.Glare = 0
    end)
end

local function RestoreAtmosphere()
    for obj,data in pairs(AtmosphereCache) do
        pcall(function()
            if obj.Parent then
                obj.Density = data.Density
                obj.Haze = data.Haze
                obj.Glare = data.Glare
            end
        end)
    end

    table.clear(AtmosphereCache)
end

local function SetFog(state)
    if state then
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000

        local objects = Lighting:GetDescendants()

        ProcessInBatches(objects,function(obj)
            if Active.Fog then
                OptimizeAtmosphere(obj)
            end
        end,function()
            return Active.Fog
        end)
    else
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd

        RestoreAtmosphere()
    end
end-- FLOOR OPTIMIZERS

local function GetRoomNumber(room)
    return tonumber(room.Name)
end

local function IsLibraryRoom(room)
    if not room then return false end

    local number = GetRoomNumber(room)
    local name = room.Name:lower()

    return number == 49
        or number == 50
        or name:find("library") ~= nil
end

local function IsDoor100Room(room)
    if not room then return false end

    local number = GetRoomNumber(room)
    local name = room.Name:lower()

    return number == 99
        or number == 100
        or name:find("a100") ~= nil
        or name:find("door100") ~= nil
end

local function IsFloorTarget(room)
    return (Active.Library and IsLibraryRoom(room))
        or (Active.Door100 and IsDoor100Room(room))
end

local function OptimizeFloorObject(obj)
    OptimizeEffect(obj)
    OptimizeLight(obj)

    if obj:IsA("BasePart") then
        if not FloorPartCache[obj] then
            FloorPartCache[obj] = {
                CastShadow = obj.CastShadow,
                Reflectance = obj.Reflectance
            }
        end

        pcall(function()
            obj.CastShadow = false
            obj.Reflectance = 0
        end)
    end
end

local function OptimizeRoom(room)
    if not room then return end

    local objects = room:GetDescendants()

    ProcessInBatches(objects,function(obj)
        if IsFloorTarget(room) then
            OptimizeFloorObject(obj)
        end
    end,function()
        return IsFloorTarget(room)
    end)
end

local function RestoreFloorParts()
    for part,data in pairs(FloorPartCache) do
        pcall(function()
            if part.Parent then
                part.CastShadow = data.CastShadow
                part.Reflectance = data.Reflectance
            end
        end)
    end

    table.clear(FloorPartCache)
end

local function ApplyLibraryOptimizer()
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    if not rooms then return end

    for _,room in ipairs(rooms:GetChildren()) do
        if IsLibraryRoom(room) then
            OptimizeRoom(room)
        end
    end
end

local function ApplyDoor100Optimizer()
    local rooms = Workspace:FindFirstChild("CurrentRooms")

    if rooms then
        for _,room in ipairs(rooms:GetChildren()) do
            if IsDoor100Room(room) then
                OptimizeRoom(room)
            end
        end
    end

    local special = Workspace:FindFirstChild("A100")
        or Workspace:FindFirstChild("Door100")

    if special then
        OptimizeRoom(special)
    end
end

local function RefreshFloor()
    if Active.Library then
        ApplyLibraryOptimizer()
    end

    if Active.Door100 then
        ApplyDoor100Optimizer()
    end
end

local function SetLibrary(state)
    if state then
        ApplyLibraryOptimizer()
    end

    if not Active.Library and not Active.Door100 then
        RestoreFloorParts()

        if not Active.Graphics and not Active.Effects then
            RestoreEffects()
        end
    end
end

local function SetDoor100(state)
    if state then
        ApplyDoor100Optimizer()
    end

    if not Active.Library and not Active.Door100 then
        RestoreFloorParts()

        if not Active.Graphics and not Active.Effects then
            RestoreEffects()
        end
    end
end

-- SEEK DETECTION
-- Ya no se escanea todo Workspace constantemente.

local function IsSeekModel(obj)
    if not obj:IsA("Model") then return false end

    local name = obj.Name:lower()

    return name == "seek"
        or name:find("seek") ~= nil
end

local function FindSeekAncestor(obj)
    local current = obj

    while current and current ~= Workspace do
        if current:IsA("Model") and IsSeekModel(current) then
            return current
        end

        current = current.Parent
    end

    return nil
end

local function HideSeekObject(obj)
    if obj:IsA("BasePart") then
        if SeekPartCache[obj] == nil then
            SeekPartCache[obj] = {
                Type = "Part",
                Value = obj.LocalTransparencyModifier
            }
        end

        pcall(function()
            obj.LocalTransparencyModifier = 1
        end)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if SeekPartCache[obj] == nil then
            SeekPartCache[obj] = {
                Type = "Texture",
                Value = obj.Transparency
            }
        end

        pcall(function()
            obj.Transparency = 1
        end)
    end
end

local function HideSeekModel(model)
    if not model then return end

    for _,obj in ipairs(model:GetDescendants()) do
        HideSeekObject(obj)
    end
end

local function HideSeekEffects()
    for _,obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BlurEffect") then

            local shouldHide =
                obj.Name:lower():find("seek") ~= nil

            if obj:IsA("ColorCorrectionEffect") then
                local tint = obj.TintColor

                if tint.R > tint.G * 1.25
                and tint.R > tint.B * 1.15 then
                    shouldHide = true
                end
            end

            if shouldHide and SeekEffectCache[obj] == nil then
                SeekEffectCache[obj] = obj.Enabled

                pcall(function()
                    obj.Enabled = false
                end)
            end
        end
    end
end

local function ProcessSeekObject(obj)
    if not Active.SeekMode or not obj then return end

    if IsSeekModel(obj) then
        HideSeekModel(obj)
        return
    end

    local model = FindSeekAncestor(obj)

    if model then
        HideSeekObject(obj)
    end
end

local function RestoreSeekVisuals()
    for obj,data in pairs(SeekPartCache) do
        pcall(function()
            if obj.Parent then
                if data.Type == "Part" then
                    obj.LocalTransparencyModifier = data.Value
                else
                    obj.Transparency = data.Value
                end
            end
        end)
    end

    table.clear(SeekPartCache)

    for obj,value in pairs(SeekEffectCache) do
        pcall(function()
            if obj.Parent then
                obj.Enabled = value
            end
        end)
    end

    table.clear(SeekEffectCache)
end

local function UpdateSeekMode()
    if not Active.SeekMode then
        RestoreSeekVisuals()
        return
    end

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if IsSeekModel(obj) then
            HideSeekModel(obj)
        end
    end

    HideSeekEffects()
end

-- WINDUI TABS

local Updates = Window:Tab({
    Title = "Updates •",
    Icon = "bell"
})

local Optimization = Window:Tab({
    Title = "Optimización",
    Icon = "gauge"
})

local Floor = Window:Tab({
    Title = "Floor",
    Icon = "building-2"
})

local Visuals = Window:Tab({
    Title = "Visuales",
    Icon = "eye"
})

local Protection = Window:Tab({
    Title = "Protección",
    Icon = "shield"
})

local Diagnostics = Window:Tab({
    Title = "Diagnóstico",
    Icon = "activity"
})

local Settings = Window:Tab({
    Title = "Ajustes",
    Icon = "settings"
})

-- UPDATES

Updates:Paragraph({
    Title = "CATDOORS [🌐] V1.7",
    Desc = "WINDUI EDITION | DOORS | DELTA ANDROID"
})

Updates:Paragraph({
    Title = "ACTUALIZACIONES RECIENTES",
    Desc = "• Optimización interna de procesos\n• Menos escaneos repetidos\n• Detección de objetos por eventos\n• Library Optimizer\n• Door 100 Optimizer\n• Anti Camera Shake — Seek\n• Seek Mode\n• FPS + DOOR HUD\n• Contador desde puerta 0"
})

Updates:Paragraph({
    Title = "VERSIONES ANTERIORES",
    Desc = "V1.6 — WindUI Edition\nV1.5 — Floor & Seek Update\nV1.4 — Mejoras de estabilidad\nV1.3 — HUD FPS + DOOR\nV1.2 — Potato Mode y Low Graphics\nV1.1 — Interfaz móvil\nV1.0 — Lanzamiento inicial"
})

-- OPTIMIZATION

Optimization:Paragraph({
    Title = "OPTIMIZACIÓN DEL JUEGO",
    Desc = "Reduce elementos visuales para intentar mejorar el rendimiento."
})

Optimization:Toggle({
    Title = "🥔 POTATO MODE",
    Desc = "Materiales suaves y color gris azulado.",
    Default = false,
    Callback = function(state)
        Active.Potato = state
        SetPotato(state)
    end
})

Optimization:Toggle({
    Title = "⚡ LOW GRAPHICS",
    Desc = "Reduce sombras, luces y efectos.",
    Default = false,
    Callback = function(state)
        Active.Graphics = state
        SetGraphics()
    end
})

Optimization:Toggle({
    Title = "🧱 ELIMINAR TEXTURAS",
    Desc = "Oculta texturas y decals.",
    Default = false,
    Callback = function(state)
        Active.Textures = state
        SetTextures(state)
    end
})

Optimization:Toggle({
    Title = "✨ ELIMINAR PARTÍCULAS, SOMBRAS Y EFECTOS",
    Desc = "Desactiva efectos visuales compatibles.",
    Default = false,
    Callback = function(state)
        Active.Effects = state
        SetEffects()
    end
})

-- FLOOR

Floor:Paragraph({
    Title = "OPTIMIZACIÓN POR ZONAS",
    Desc = "Opciones especiales para zonas que pueden provocar caídas fuertes de FPS."
})

Floor:Toggle({
    Title = "📚 LIBRARY OPTIMIZER",
    Desc = "Reduce efectos y luces de las habitaciones detectadas como Library.",
    Default = false,
    Callback = function(state)
        Active.Library = state
        SetLibrary(state)
    end
})

Floor:Toggle({
    Title = "🚪 DOOR 100 OPTIMIZER",
    Desc = "Reduce efectos y luces de la zona final detectada.",
    Default = false,
    Callback = function(state)
        Active.Door100 = state
        SetDoor100(state)
    end
})-- VISUALS

Visuals:Paragraph({
    Title = "EFECTOS VISUALES",
    Desc = "Ajustes visuales locales. Algunas secuencias pueden controlar sus propios efectos."
})

Visuals:Toggle({
    Title = "🌫️ REMOVER FOG",
    Desc = "Reduce la niebla y la atmósfera.",
    Default = false,
    Callback = function(state)
        Active.Fog = state
        SetFog(state)
    end
})

Visuals:Toggle({
    Title = "📷 ANTI CAMERA SHAKE — SEEK",
    Desc = "Intenta mantener CameraOffset en cero.",
    Default = false,
    Callback = function(state)
        Active.AntiShake = state
    end
})

Visuals:Toggle({
    Title = "👁 SEEK MODE — OCULTAR SEEK",
    Desc = "Oculta partes visibles de Seek y algunos efectos detectados.",
    Default = false,
    Callback = function(state)
        Active.SeekMode = state

        if state then
            UpdateSeekMode()
        else
            RestoreSeekVisuals()
        end
    end
})

Visuals:Paragraph({
    Title = "INFORMACIÓN",
    Desc = "Seek Mode no elimina intencionalmente scripts, colisiones ni mecánicas. Solo intenta ocultar elementos visuales locales."
})

-- PROTECTION

Protection:Paragraph({
    Title = "PROTECCIÓN",
    Desc = "Las funciones de protección avanzada todavía están pendientes de desarrollo."
})

-- DIAGNOSTICS

Diagnostics:Paragraph({
    Title = "ESTADO DEL JUEGO",
    Desc = "Activa FPS + DOOR HUD para mostrar tus FPS y la habitación actual."
})

-- FLOATING HUD

local OldHUD = PlayerGui:FindFirstChild("CATDOORS_HUD")

if OldHUD then
    OldHUD:Destroy()
end

local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "CATDOORS_HUD"
HUDGui.ResetOnSpawn = false
HUDGui.DisplayOrder = 999
HUDGui.Parent = PlayerGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Name = "FloatingHUD"
HUDFrame.Size = UDim2.fromOffset(165,76)
HUDFrame.Position = UDim2.new(0,12,0,110)
HUDFrame.BackgroundColor3 = Color3.fromRGB(10,12,15)
HUDFrame.BorderSizePixel = 0
HUDFrame.Visible = false
HUDFrame.Active = true
HUDFrame.Parent = HUDGui

Instance.new("UICorner",HUDFrame).CornerRadius =
    UDim.new(0,9)

local HUDStroke = Instance.new("UIStroke")
HUDStroke.Color = Accent
HUDStroke.Thickness = 2
HUDStroke.Parent = HUDFrame

local HUDHeader = Instance.new("TextLabel")
HUDHeader.Size = UDim2.new(1,0,0,25)
HUDHeader.BackgroundColor3 = Color3.fromRGB(19,22,26)
HUDHeader.Text = "CATDOORS • LIVE"
HUDHeader.TextColor3 = Accent
HUDHeader.Font = Enum.Font.GothamBold
HUDHeader.TextSize = 11
HUDHeader.Parent = HUDFrame

Instance.new("UICorner",HUDHeader).CornerRadius =
    UDim.new(0,7)

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1,-16,0,20)
FPSLabel.Position = UDim2.new(0,8,0,29)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: --"
FPSLabel.TextColor3 = Color3.new(1,1,1)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 12
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = HUDFrame

local DoorLabel = Instance.new("TextLabel")
DoorLabel.Size = UDim2.new(1,-16,0,20)
DoorLabel.Position = UDim2.new(0,8,0,50)
DoorLabel.BackgroundTransparency = 1
DoorLabel.Text = "DOOR: 0"
DoorLabel.TextColor3 = Color3.new(1,1,1)
DoorLabel.Font = Enum.Font.GothamBold
DoorLabel.TextSize = 12
DoorLabel.TextXAlignment = Enum.TextXAlignment.Left
DoorLabel.Parent = HUDFrame

-- HUD DRAG

local HUDDragging = false
local HUDDragStart
local HUDStartPos

HUDHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        HUDDragging = true
        HUDDragStart = input.Position
        HUDStartPos = HUDFrame.Position
    end
end)

local HUDInputChanged = UIS.InputChanged:Connect(function(input)
    if not HUDDragging or Closed then return end

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - HUDDragStart

        HUDFrame.Position = UDim2.new(
            HUDStartPos.X.Scale,
            HUDStartPos.X.Offset + delta.X,
            HUDStartPos.Y.Scale,
            HUDStartPos.Y.Offset + delta.Y
        )
    end
end)

local HUDInputEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        HUDDragging = false
    end
end)

Diagnostics:Toggle({
    Title = "📊 FPS + DOOR HUD",
    Desc = "Muestra un panel flotante con FPS y habitación.",
    Default = false,
    Callback = function(state)
        Active.HUD = state
        HUDFrame.Visible = state
    end
})

-- SETTINGS

Settings:Paragraph({
    Title = "PERSONALIZACIÓN",
    Desc = "Cambia el tema de WindUI y el color del HUD."
})

-- WINDUI THEMES

local ThemeNames = {}

for themeName in pairs(WindUI:GetThemes()) do
    table.insert(ThemeNames,themeName)
end

table.sort(ThemeNames)

Settings:Dropdown({
    Title = "TEMA DE LA INTERFAZ",
    Values = ThemeNames,
    Value = "Dark",
    Callback = function(theme)
        WindUI:SetTheme(theme)
        Notify("Tema aplicado",theme)
    end
})

-- HUD COLOR

local function ApplyHUDColor(color)
    Accent = color
    HUDStroke.Color = color
    HUDHeader.TextColor3 = color
end

Settings:Colorpicker({
    Title = "COLOR DEL HUD",
    Default = Accent,
    Callback = function(color)
        ApplyHUDColor(color)
    end
})

local Presets = {
    {"Verde Neón",Color3.fromRGB(0,255,120)},
    {"Azul",Color3.fromRGB(0,160,255)},
    {"Morado",Color3.fromRGB(175,80,255)},
    {"Rojo",Color3.fromRGB(255,65,65)},
    {"Cian",Color3.fromRGB(0,230,230)},
    {"Rosa",Color3.fromRGB(255,80,170)},
    {"Blanco",Color3.fromRGB(235,240,245)}
}

for _,preset in ipairs(Presets) do
    local presetName = preset[1]
    local presetColor = preset[2]

    Settings:Button({
        Title = presetName,
        Callback = function()
            ApplyHUDColor(presetColor)
            Notify("Color aplicado",presetName)
        end
    })
end

-- CUSTOM HEX INPUT

Settings:Input({
    Title = "COLOR HEX DEL HUD",
    Placeholder = "#00FF78",
    Callback = function(value)
        local hex = tostring(value):gsub("#","")

        if #hex == 6 and hex:match("^%x+$") then
            local r = tonumber(hex:sub(1,2),16)
            local g = tonumber(hex:sub(3,4),16)
            local b = tonumber(hex:sub(5,6),16)

            local color = Color3.fromRGB(r,g,b)

            ApplyHUDColor(color)

            Notify("Color HEX aplicado","#"..hex:upper())
        else
            Notify("Error","Código HEX inválido.")
        end
    end
})

-- RESET COLOR

Settings:Button({
    Title = "RESET COLOR",
    Callback = function()
        ApplyHUDColor(Color3.fromRGB(0,255,120))
        Notify("Color restaurado","Verde Neón")
    end
})-- CLEANUP FUNCTION

local function DisconnectConnection(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function Cleanup()
    if Closed then return end

    Closed = true

    for key in pairs(Active) do
        Active[key] = false
    end

    -- RESTORE POTATO

    RestorePotato()

    -- RESTORE TEXTURES

    RestoreTextures()

    -- RESTORE EFFECTS

    RestoreEffects()

    -- RESTORE FLOOR

    RestoreFloorParts()

    -- RESTORE SEEK

    RestoreSeekVisuals()

    -- RESTORE ATMOSPHERE

    RestoreAtmosphere()

    -- RESTORE LIGHTING

    Lighting.GlobalShadows = OriginalLighting.Shadows
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd

    -- RESTORE CAMERA OFFSET

    local character = Player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.CameraOffset = Vector3.zero
    end

    -- DISCONNECT CONNECTIONS

    DisconnectConnection(HudConnection)
    DisconnectConnection(AddedConnection)
    DisconnectConnection(LightingConnection)
    DisconnectConnection(RoomsConnection)
    DisconnectConnection(CharacterConnection)

    DisconnectConnection(HUDInputChanged)
    DisconnectConnection(HUDInputEnded)

    for _,connection in ipairs(FloorConnections) do
        DisconnectConnection(connection)
    end

    table.clear(FloorConnections)

    -- REMOVE HUD

    pcall(function()
        HUDGui:Destroy()
    end)

    Notify("CATDOORS","Optimizaciones restauradas.")
end

Settings:Button({
    Title = "RESTAURAR TODO Y CERRAR",
    Desc = "Desactiva las opciones y restaura los cambios guardados.",
    Callback = function()
        Cleanup()

        task.delay(0.2,function()
            pcall(function()
                WindUI.ScreenGui:Destroy()
            end)
        end)
    end
})

-- FLOOR OBJECT DETECTION

local function FindFloorContainer(obj)
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    local current = obj

    while current and current ~= Workspace do
        if currentRooms and current.Parent == currentRooms then
            return current
        end

        if current.Parent == Workspace then
            local name = current.Name:lower()

            if name == "a100" or name == "door100" then
                return current
            end
        end

        current = current.Parent
    end

    return nil
end

local function ProcessFloorObject(obj)
    if not Active.Library and not Active.Door100 then
        return
    end

    local room = FindFloorContainer(obj)

    if not room then return end
    if not IsFloorTarget(room) then return end

    if obj == room then
        OptimizeRoom(room)
    else
        OptimizeFloorObject(obj)
    end
end

-- NEW OBJECT DETECTION
-- Una sola conexión para Workspace.
-- No se utiliza game.DescendantAdded para evitar duplicados.

AddedConnection = Workspace.DescendantAdded:Connect(function(obj)
    if Closed then return end

    if Active.Potato then
        OptimizePart(obj)
    end

    if Active.Textures then
        OptimizeTexture(obj)
    end

    if Active.Graphics or Active.Effects
    or Active.Library or Active.Door100 then
        OptimizeEffect(obj)
        OptimizeLight(obj)
    end

    if Active.Library or Active.Door100 then
        ProcessFloorObject(obj)
    end

    if Active.SeekMode then
        ProcessSeekObject(obj)
    end
end)

-- LIGHTING OBJECT DETECTION

LightingConnection = Lighting.DescendantAdded:Connect(function(obj)
    if Closed then return end

    if Active.Graphics or Active.Effects
    or Active.Library or Active.Door100 then
        OptimizeEffect(obj)
        OptimizeLight(obj)
    end

    if Active.Fog then
        OptimizeAtmosphere(obj)
    end

    if Active.SeekMode then
        if obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BlurEffect") then

            local shouldHide =
                obj.Name:lower():find("seek") ~= nil

            if obj:IsA("ColorCorrectionEffect") then
                local tint = obj.TintColor

                if tint.R > tint.G * 1.25
                and tint.R > tint.B * 1.15 then
                    shouldHide = true
                end
            end

            if shouldHide and SeekEffectCache[obj] == nil then
                SeekEffectCache[obj] = obj.Enabled

                pcall(function()
                    obj.Enabled = false
                end)
            end
        end
    end
end)

-- CURRENT DOOR DETECTION

local function GetCurrentDoor()
    local character = Player.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local rooms = Workspace:FindFirstChild("CurrentRooms")
    if not rooms then return nil end

    local position = root.Position
    local bestRoom = nil
    local bestDistance = math.huge

    for _,room in ipairs(rooms:GetChildren()) do
        local roomNumber = tonumber(room.Name)

        if roomNumber and room:IsA("Model") then
            local success,cf,size = pcall(function()
                local boxCF,boxSize = room:GetBoundingBox()
                return boxCF,boxSize
            end)

            if success then
                local localPosition = cf:PointToObjectSpace(position)

                local inside =
                    math.abs(localPosition.X) <= size.X/2 + 3
                    and math.abs(localPosition.Y) <= size.Y/2 + 3
                    and math.abs(localPosition.Z) <= size.Z/2 + 3

                if inside then
                    local distance = (cf.Position-position).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestRoom = roomNumber
                    end
                end
            end
        end
    end

    if bestRoom == nil then
        bestDistance = math.huge

        for _,room in ipairs(rooms:GetChildren()) do
            local roomNumber = tonumber(room.Name)

            if roomNumber and room:IsA("Model") then
                local success,cf = pcall(function()
                    local boxCF = room:GetBoundingBox()
                    return boxCF
                end)

                if success then
                    local distance = (cf.Position-position).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestRoom = roomNumber
                    end
                end
            end
        end
    end

    return bestRoom
end

-- RENDER LOOP
-- Solo se actualizan los datos cuando hace falta.

local frames = 0
local elapsed = 0
local lastDoorUpdate = 0

HudConnection = RunService.RenderStepped:Connect(function(dt)
    if Closed then return end

    -- ANTI CAMERA SHAKE

    if Active.AntiShake then
        local character = Player.Character

        local humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.CameraOffset = Vector3.zero
        end
    end

    -- HUD FPS

    if Active.HUD then
        frames += 1
        elapsed += dt

        if elapsed >= 1 then
            local fps = math.floor(frames / elapsed)

            FPSLabel.Text = "FPS: "..fps

            frames = 0
            elapsed = 0
        end

        lastDoorUpdate += dt

        -- Actualiza la habitación una vez por segundo.

        if lastDoorUpdate >= 1 then
            lastDoorUpdate = 0

            local door = GetCurrentDoor()

            if door ~= nil then
                DoorLabel.Text = "DOOR: "..door
            else
                DoorLabel.Text = "DOOR: --"
            end
        end
    end
end)

-- STARTUP

Window:SelectTab(1)

Notify(
    "CATDOORS [🌐]",
    "V1.7 ULTRA PERFORMANCE cargado."
)

print("CATDOORS [🌐] V1.7 ULTRA PERFORMANCE LOADED!")