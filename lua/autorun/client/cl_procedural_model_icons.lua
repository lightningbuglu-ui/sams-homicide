-- Client-side helpers for live and cached procedural model icons.
-- Loaded automatically by Garry's Mod from lua/autorun/client.

hg = hg or {}
hg.ModelIcons = hg.ModelIcons or {}

local ModelIcons = hg.ModelIcons
local DEFAULT_MODEL = "models/props_junk/PopCan01a.mdl"

local function ResolveModel(model)
    if isstring(model) and util.IsValidModel(model) then
        return model
    end

    return DEFAULT_MODEL
end

local function ConfigureEntity(entity, options)
    if not IsValid(entity) then return end

    options = options or {}

    if options.skin ~= nil then
        entity:SetSkin(options.skin)
    end

    if options.bodygroups then
        if isstring(options.bodygroups) then
            entity:SetBodyGroups(options.bodygroups)
        elseif istable(options.bodygroups) then
            for group, value in pairs(options.bodygroups) do
                entity:SetBodygroup(tonumber(group) or group, value)
            end
        end
    end

    if istable(options.subMaterials) then
        for index, material in pairs(options.subMaterials) do
            entity:SetSubMaterial(tonumber(index) or index, material)
        end
    end

    if options.color then
        entity:SetColor(options.color)
    end

    if options.material then
        entity:SetMaterial(options.material)
    end

    if options.modelAngle then
        entity:SetAngles(options.modelAngle)
    end
end

local function GetCamera(options, entity)
    options = options or {}

    local lookAt = options.lookAt
    local boundsSize = Vector(16, 16, 16)

    if IsValid(entity) then
        local mins, maxs = entity:GetRenderBounds()
        lookAt = lookAt or (mins + maxs) * 0.5
        boundsSize = maxs - mins
    end

    lookAt = lookAt or vector_origin

    local extent = math.max(boundsSize.x, boundsSize.y, boundsSize.z, 8)
    local distance = options.distance or extent * 2.4
    local height = options.cameraHeight or 0
    -- The default camera looks at the model from its left (-X) side.
    local cameraPos = options.cameraPos or (lookAt + Vector(-distance, 0, height))
    local cameraAng = options.cameraAngle or (lookAt - cameraPos):Angle()

    return lookAt, cameraPos, cameraAng, options.fov or 35
end

-- Create a live DModelPanel. Supply options for skin, bodygroups,
-- subMaterials, color, material, modelAngle, cameraPos, cameraAngle, lookAt,
-- distance, cameraHeight, and fov.
function ModelIcons.CreateModelPanel(parent, model, options)
    options = options or {}

    local panel = vgui.Create("DModelPanel", parent)
    panel:SetModel(ResolveModel(model))
    panel:SetFOV(options.fov or 35)

    if IsValid(panel.Entity) then
        ConfigureEntity(panel.Entity, options)
        local lookAt, cameraPos = GetCamera(options, panel.Entity)
        panel:SetLookAt(lookAt)
        panel:SetCamPos(cameraPos)
    end

    if options.ambientLight then
        panel:SetAmbientLight(options.ambientLight)
    end

    if istable(options.directionalLights) then
        for side, color in pairs(options.directionalLights) do
            panel:SetDirectionalLight(side, color)
        end
    end

    if options.hideEntity then
        function panel:LayoutEntity() end
    end

    return panel
end

-- Rebuild a SpawnIcon's cached render using the same left-side camera setup.
-- SpawnIcon handles remain clickable and can be used in spawnmenu/VGUI layouts.
function ModelIcons.RebuildSpawnIcon(icon, model, options)
    if not IsValid(icon) then return false end

    options = options or {}
    model = ResolveModel(model)
    icon:SetModel(model)

    local entity = icon.Entity
    if IsValid(entity) then
        ConfigureEntity(entity, options)
    end

    local lookAt, cameraPos, cameraAng, fov = GetCamera(options, entity)
    local light = options.light or Color(255, 255, 255)
    local ambient = options.ambient or Color(150, 150, 150)

    icon:RebuildSpawnIconEx(model, cameraPos, cameraAng, fov, light, ambient)
    return true
end

-- Convenience constructor for a SpawnIcon with a procedural cached image.
function ModelIcons.CreateSpawnIcon(parent, model, options)
    local icon = vgui.Create("SpawnIcon", parent)
    ModelIcons.RebuildSpawnIcon(icon, model, options)
    return icon
end

-- Short aliases for UI code.
hg.CreateProceduralModelPanel = ModelIcons.CreateModelPanel
hg.CreateProceduralSpawnIcon = ModelIcons.CreateSpawnIcon
hg.RebuildProceduralSpawnIcon = ModelIcons.RebuildSpawnIcon
