-- Client-side helpers for live and cached procedural model icons.
-- Loaded automatically by Garry's Mod from lua/autorun/client.

hg = hg or {}
hg.ModelIcons = hg.ModelIcons or {}

local ModelIcons = hg.ModelIcons
local DEFAULT_MODEL = "models/props_junk/PopCan01a.mdl"

local function ResolveModel(model)
    if isstring(model) and model ~= "" and util.IsValidModel(model) then
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

    local extent = math.max(math.abs(boundsSize.x), math.abs(boundsSize.y), math.abs(boundsSize.z), 8)
    local distance = options.distance or extent * 2.4
    local height = options.cameraHeight or 0
    -- Keep the camera aimed at the model even when callers override its position.
    local cameraPos = options.cameraPos or (lookAt + Vector(-distance, 0, height))
    local cameraAng = options.cameraAngle or (lookAt - cameraPos):Angle()

    return lookAt, cameraPos, cameraAng, options.fov or 35
end

local function ApplyPanelCamera(panel, options)
    if not IsValid(panel) or not IsValid(panel.Entity) then return end

    local lookAt, cameraPos = GetCamera(options, panel.Entity)
    panel:SetLookAt(lookAt)
    panel:SetCamPos(cameraPos)
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
        ApplyPanelCamera(panel, options)
    end

    if options.ambientLight then
        panel:SetAmbientLight(options.ambientLight)
    end

    if istable(options.directionalLights) then
        for side, color in pairs(options.directionalLights) do
            panel:SetDirectionalLight(side, color)
        end
    end

    if options.rotate then
        panel.LayoutEntity = function(self, entity)
            entity:SetAngles(Angle(0, (RealTime() * (options.rotateSpeed or 24)) % 360, 0))
        end
    elseif options.hideEntity then
        panel.LayoutEntity = function() end
    end

    -- DModelPanel creates its entity after SetModel; refresh framing when
    -- the panel is laid out so attachment bounds are available on first draw.
    panel.Think = function(self)
        if not self.CameraConfigured and IsValid(self.Entity) then
            ConfigureEntity(self.Entity, options)
            ApplyPanelCamera(self, options)
            self.CameraConfigured = true
        end
    end

    return panel
end

-- Create a model preview for an attachment from hg.attachments. The model,
-- rotation and submaterials are read from the same definition used in-game.
-- Returns nil for integrated/empty attachments that do not have a model.
function ModelIcons.CreateAttachmentModelPanel(parent, placement, attachment, options)
    local attachmentTable = hg.attachments
    local placementTable = istable(attachmentTable) and attachmentTable[placement]
    local attachmentData = istable(placementTable) and placementTable[attachment]
    local model = istable(attachmentData) and attachmentData[2]

    if not isstring(model) or model == "" or not util.IsValidModel(model) then
        return nil
    end

    local panelOptions = table.Copy(options or {})
    panelOptions.modelAngle = panelOptions.modelAngle or attachmentData[3]
    panelOptions.subMaterials = panelOptions.subMaterials or attachmentData[4]

    return ModelIcons.CreateModelPanel(parent, model, panelOptions)
end

-- Rebuild a SpawnIcon's cached render using the same left-side camera setup.
-- SpawnIcon handles remain clickable and can be used in spawnmenu/VGUI layouts.
function ModelIcons.RebuildSpawnIcon(icon, model, options)
    if not IsValid(icon) then return false end

    options = options or {}
    if not isstring(model) or model == "" or not util.IsValidModel(model) then return false end
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
    if not isstring(model) or model == "" or not util.IsValidModel(model) then return nil end

    local icon = vgui.Create("SpawnIcon", parent)
    if not ModelIcons.RebuildSpawnIcon(icon, model, options) then
        if IsValid(icon) then icon:Remove() end
        return nil
    end
    return icon
end

function ModelIcons.CreateAttachmentSpawnIcon(parent, placement, attachment, options)
    local placementTable = istable(hg.attachments) and hg.attachments[placement]
    local attachmentData = istable(placementTable) and placementTable[attachment]
    local model = istable(attachmentData) and attachmentData[2]

    if not isstring(model) or model == "" or not util.IsValidModel(model) then return nil end

    local iconOptions = table.Copy(options or {})
    iconOptions.modelAngle = iconOptions.modelAngle or attachmentData[3]
    iconOptions.subMaterials = iconOptions.subMaterials or attachmentData[4]
    return ModelIcons.CreateSpawnIcon(parent, model, iconOptions)
end

-- Short aliases for UI code.
hg.CreateProceduralModelPanel = ModelIcons.CreateModelPanel
hg.CreateProceduralSpawnIcon = ModelIcons.CreateSpawnIcon
hg.RebuildProceduralSpawnIcon = ModelIcons.RebuildSpawnIcon
hg.CreateProceduralAttachmentModelPanel = ModelIcons.CreateAttachmentModelPanel
hg.CreateProceduralAttachmentSpawnIcon = ModelIcons.CreateAttachmentSpawnIcon
