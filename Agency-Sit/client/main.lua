-- Agency-Sit - Client Side
-- Discord Support: https://discord.gg/zbG53tTUXR
-- Shop: https://agency-script.tebex.io
-- Agency-Notify: https://agency-script.tebex.io/package/6937769

local isSitting = false
local sittingAt = nil
local cachedSittables = {}
local cachedAt = 0

local function draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - coords)

    if not onScreen then return end

    local scale = (1.0 / dist) * 2.0
    local fov = (1.0 / GetGameplayCamFov()) * 100.0
    scale = scale * fov

    SetTextScale(0.0, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function stopSitting(playStandAnim)
    local ped = PlayerPedId()
    if not isSitting then return end

    if playStandAnim then
        -- Clear scenario first
        ClearPedTasks(ped)
        Wait(100)
        
        -- Simple stand-up animation that actually plays and is visible
        local dict = 'move_fall'
        local name = 'quickgetup'
        
        if loadAnimDict(dict) then
            TaskPlayAnim(ped, dict, name, 8.0, 8.0, 500, 0, 0, false, false, false)
            Wait(500)
        end
    else
        ClearPedTasksImmediately(ped)
    end

    isSitting = false
    sittingAt = nil
end

local function getModelOffset(model)
    if not Config.ModelOffsets then return vector3(0.0, 0.0, 0.0), 0.0 end
    local entry = Config.ModelOffsets[model]
    if not entry then
        entry = Config.ModelOffsets[tostring(model)]
    end
    if not entry then return vector3(0.0, 0.0, 0.0), 0.0 end
    local off = entry.offset or vector3(0.0, 0.0, 0.0)
    local headingOff = entry.headingOffset or 0.0
    return off, headingOff
end

local function getDefaultHeadingOffset()
    if Config.DefaultHeadingOffset == nil then return 0.0 end
    return Config.DefaultHeadingOffset
end

local function getEntitySeatPoint(entity, model, heading)
    local minDim, maxDim = GetModelDimensions(model)

    local height = (maxDim.z - minDim.z)

    local z = (minDim.z + (height * 0.55))
    local gap = Config.BackrestGap or 0.04
    local y = (minDim.y + gap)

    local pos = GetOffsetFromEntityInWorldCoords(entity, 0.0, y, z)

    return pos
end

local function chooseBestHeadingAndPos(entity, model, heading)
    local headingA = heading
    local headingB = (heading + 180.0) % 360.0

    local posA = getEntitySeatPoint(entity, model, headingA)
    local posB = getEntitySeatPoint(entity, model, headingB)

    local minDim, maxDim = GetModelDimensions(model)
    local probeDist = Config.BackrestProbeDistance or 0.35
    local probeH = (Config.BackrestProbeHeight or 0.55)
    local halfWidth = (maxDim.x - minDim.x) * 0.35

    local function hitScoreForHeading(h)
        local right = GetOffsetFromEntityInWorldCoords(entity, halfWidth, 0.0, 0.0)
        local left = GetOffsetFromEntityInWorldCoords(entity, -halfWidth, 0.0, 0.0)
        local center = GetEntityCoords(entity)
        local z = center.z + (maxDim.z - minDim.z) * probeH

        local behind = GetOffsetFromEntityInWorldCoords(entity, 0.0, minDim.y - probeDist, z - center.z)
        local ahead = GetOffsetFromEntityInWorldCoords(entity, 0.0, maxDim.y + probeDist, z - center.z)

        local function ray(from, to)
            local r = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 16, entity, 7)
            local _, hit, _, _, ent = GetShapeTestResult(r)
            if hit == 1 and ent == entity then return 1 end
            return 0
        end

        local score = 0

        score = score + ray(vector3(right.x, right.y, z), vector3(behind.x, behind.y, behind.z))
        score = score + ray(vector3(left.x, left.y, z), vector3(behind.x, behind.y, behind.z))
        score = score + ray(vector3(center.x, center.y, z), vector3(behind.x, behind.y, behind.z))

        score = score - ray(vector3(right.x, right.y, z), vector3(ahead.x, ahead.y, ahead.z))
        score = score - ray(vector3(left.x, left.y, z), vector3(ahead.x, ahead.y, ahead.z))
        score = score - ray(vector3(center.x, center.y, z), vector3(ahead.x, ahead.y, ahead.z))

        return score
    end

    local scoreA = hitScoreForHeading(headingA)
    local scoreB = hitScoreForHeading(headingB)

    if scoreB > scoreA then
        return headingB, posB
    end

    return headingA, posA
end

local function startSitting(target)
    local ped = PlayerPedId()
    if isSitting then return end

    if IsPedInAnyVehicle(ped, true) then
        Framework.Notify('You cannot sit in a vehicle.', 'error')
        return
    end

    local entity = target.entity
    if not entity or not DoesEntityExist(entity) then
        Framework.Notify('Object not found.', 'error')
        return
    end

    local model = target.model
    local offset, headingOffset = getModelOffset(model)
    if headingOffset == 0.0 then
        headingOffset = getDefaultHeadingOffset()
    end
    local heading = (GetEntityHeading(entity) + headingOffset) % 360.0

    local autoHeading, autoPos = chooseBestHeadingAndPos(entity, model, heading)

    local pos = autoPos

    if offset.x ~= 0.0 or offset.y ~= 0.0 or offset.z ~= 0.0 then
        pos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    end

    if Config.SeatAdjustOffset then
        pos = pos + Config.SeatAdjustOffset
    end

    heading = autoHeading

    if Config.SeatAdjustHeading and Config.SeatAdjustHeading ~= 0.0 then
        heading = (heading + Config.SeatAdjustHeading) % 360.0
    end

    -- Use scenario flags that prevent visible teleporting
    -- Last parameter false = warping disabled for smoother transition
    TaskStartScenarioAtPosition(ped, Config.SitScenario, pos.x, pos.y, pos.z, heading, -1, true, false)

    isSitting = true
    sittingAt = target

    Framework.Notify('Press E to stand up.', 'primary')
end

local function isModelSittable(model)
    if not Config.SittableModels or #Config.SittableModels == 0 then return false end
    for i = 1, #Config.SittableModels do
        if GetHashKey(Config.SittableModels[i]) == model then
            return true
        end
    end
    return false
end

local function refreshSittables()
    local now = GetGameTimer()
    if (now - cachedAt) < (Config.ScanIntervalMs or 1500) then return end
    cachedAt = now

    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local radius = Config.ScanRadius or 25.0
    cachedSittables = {}

    local handle, entity = FindFirstObject()
    local success = true
    while success do
        if DoesEntityExist(entity) then
            local model = GetEntityModel(entity)
            if isModelSittable(model) then
                local ecoords = GetEntityCoords(entity)
                local dist = #(pcoords - ecoords)
                if dist <= radius then
                    cachedSittables[#cachedSittables + 1] = {
                        entity = entity,
                        model = model,
                        coords = ecoords
                    }
                end
            end
        end
        success, entity = FindNextObject(handle)
    end
    EndFindObject(handle)
end

local function registerOxTarget()
    if not Config.UseOxTargetIfAvailable then return false end
    if not Framework.HasOxTarget() then return false end

    local modelHashes = {}
    for i = 1, #Config.SittableModels do
        modelHashes[#modelHashes + 1] = GetHashKey(Config.SittableModels[i])
    end

    exports.ox_target:addModel(modelHashes, {
        {
            name = 'sit_script:sit',
            icon = 'fa-solid fa-chair',
            label = 'Sit Down',
            distance = Config.InteractDistance or 1.8,
            onSelect = function(data)
                if isSitting then return end
                if data and data.entity then
                    startSitting({ entity = data.entity, model = GetEntityModel(data.entity), coords = GetEntityCoords(data.entity) })
                end
            end
        },
        {
            name = 'sit_script:stand',
            icon = 'fa-solid fa-person-walking',
            label = 'Stand Up',
            distance = Config.InteractDistance or 1.8,
            canInteract = function()
                return isSitting
            end,
            onSelect = function()
                stopSitting(true)
            end
        }
    })

    return true
end

CreateThread(function()
    local usedTarget = registerOxTarget()

    while true do
        local wait = 750
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        if isSitting then
            wait = 0
            if IsControlJustReleased(0, Config.InteractKey) then
                stopSitting(true)
            end
        elseif not usedTarget then
            refreshSittables()

            local nearest = nil
            local nearestDist = nil
            for i = 1, #cachedSittables do
                local s = cachedSittables[i]
                if s.entity and DoesEntityExist(s.entity) then
                    local dist = #(pcoords - s.coords)
                    if dist <= (Config.DrawDistance or 8.0) then
                        if not nearestDist or dist < nearestDist then
                            nearest = s
                            nearestDist = dist
                        end
                    end
                end
            end

            if nearest then
                wait = 0
                draw3DText(nearest.coords + vector3(0.0, 0.0, 1.0), '[E] Sit Down')

                if nearestDist and nearestDist <= (Config.InteractDistance or 1.8) and IsControlJustReleased(0, Config.InteractKey) then
                    startSitting(nearest)
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isSitting then
        stopSitting(false)
    end
end)
