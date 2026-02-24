Framework = {
    name = 'standalone',
    obj = nil
}

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

CreateThread(function()
    if resourceStarted('es_extended') then
        Framework.name = 'esx'
        Framework.obj = exports['es_extended']:getSharedObject()
    elseif resourceStarted('qb-core') then
        Framework.name = 'qb'
        Framework.obj = exports['qb-core']:GetCoreObject()
    else
        Framework.name = 'standalone'
        Framework.obj = nil
    end
end)

function Framework.Notify(msg, nType)
    -- Try Agency-Notify first if enabled
    -- Get it here: https://agency-script.tebex.io/package/6937769
    if Config.UseAgencyNotify and resourceStarted('agency-notify') then
        local ok = pcall(function()
            exports['agency-notify']:Notify({
                title = 'Agency-Sit',
                text = msg,
                type = nType or 'primary',
                duration = 5000
            })
        end)
        if ok then return end
    end

    -- Framework fallbacks
    if Framework.name == 'esx' then
        if Framework.obj and Framework.obj.ShowNotification then
            Framework.obj.ShowNotification(msg)
            return
        end
    elseif Framework.name == 'qb' then
        if Framework.obj and Framework.obj.Functions and Framework.obj.Functions.Notify then
            Framework.obj.Functions.Notify(msg, nType or 'primary')
            return
        end
    end

    -- Default GTA notification
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

function Framework.HasOxTarget()
    return resourceStarted('ox_target')
end
