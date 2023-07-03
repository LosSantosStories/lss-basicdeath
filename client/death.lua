RegisterNetEvent('lss-basicdeath:client:SetPlayerDead', function()
    TriggerServerEvent('lss-basicdeath:server:SetDeathStatus', true)
    DoScreenFadeOut(500)
    Wait(500)
    if lib.progressActive() then
        lib.cancelProgress()
    end
    exports.ox_target:disableTargeting(true)
    LocalPlayer.state:set('invBusy', true, true)

    lib.requestAnimDict("veh@low@front_ps@idle_duck")
    lib.requestAnimDict('combat@damage@writhe')

    local PedPos = GetEntityCoords(cache.ped)
    local Heading = GetEntityHeading(cache.ped)
    while GetEntitySpeed(cache.ped) > 0.5 or IsPedRagdoll(cache.ped) do
        Wait(100)
    end
    if cache.vehicle then
        local Seat = GetVehicleModelNumberOfSeats(GetHashKey(GetEntityModel(cache.vehicle)))
        for i = -1, Seat do
            local Occupant = GetPedInVehicleSeat(cache.vehicle, i)
            if Occupant == cache.ped then
                NetworkResurrectLocalPlayer(PedPos.x, PedPos.y, PedPos.z + 0.5, Heading, true, false)
                SetPedIntoVehicle(cache.ped, cache.vehicle, i)
            end
        end
    else
        NetworkResurrectLocalPlayer(PedPos.x, PedPos.y, PedPos.z + 0.5, Heading, true, false)
    end
    SetEntityInvincible(cache.ped, true)
    SendNUIMessage({
        type = "show",
        timer = Config.DeathTime,
        header = locale('header'),
        desc = locale('description')
    })
    DoScreenFadeIn(500)
    while LocalPlayer.state.isDead do
        if IsPedInAnyVehicle(cache.ped, false) then
            if not IsEntityPlayingAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                TaskPlayAnim(cache.ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, false, false, false)
            end
        else
            if not IsEntityPlayingAnim(cache.ped, 'combat@damage@writhe', 'writhe_loop', 3) then
                TaskPlayAnim(cache.ped, 'combat@damage@writhe', 'writhe_loop', 1.0, 1.0, -1, 1, 0, false, false,
                    false)
            end
        end
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 245, true)
        EnableControlAction(0, 38, true)
        EnableControlAction(0, 0, true)
        EnableControlAction(0, 322, true)
        EnableControlAction(0, 288, true)
        EnableControlAction(0, 213, true)
        EnableControlAction(0, 249, true)
        EnableControlAction(0, 46, true)
        EnableControlAction(0, 47, true)
        Wait(100)
    end
    FreezeEntityPosition(cache.ped, false)
end)

RegisterNetEvent('lss-basicdeath:client:RevivePlayer', function(type)
    TriggerServerEvent('lss-basicdeath:server:SetDeathStatus', false)
    DoScreenFadeOut(500)
    Wait(500)
    SendNUIMessage({ type = "hide" })
    LocalPlayer.state:set('invBusy', false, true)
    if type == nil then
        local ClosestHospital = nil
        local MinDistance = math.huge

        for k, v in pairs(Config.Hopsitals) do
            local PlayerCoords = GetEntityCoords(cache.ped)
            local Distance = math.sqrt(((PlayerCoords.x - v.coords.x) * (PlayerCoords.x - v.coords.x)) +
                ((PlayerCoords.y - v.coords.y) * (PlayerCoords.y - v.coords.y)))
            if Distance < MinDistance then
                MinDistance = Distance
                ClosestHospital = v
            end
        end

        TriggerServerEvent('lss-basicdeath:server:ClearInventory')
        lib.notify({
            title = locale('respawn_header'),
            description = locale('respawn_description', ClosestHospital.name),
            type = 'success'
        })
        NetworkResurrectLocalPlayer(ClosestHospital.coords, true, false)
    elseif type == 'admin' then
        NetworkResurrectLocalPlayer(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped), true, false)
    end
    exports.ox_target:disableTargeting(false)
    DoScreenFadeIn(500)

    TriggerEvent('esx_basicneeds:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
end)

RegisterNuiCallback("time_expired", function(data)
    TriggerEvent('lss-basicdeath:client:RevivePlayer')
end)

lib.callback.register('lss-basicdeath:callback:GetDialog', function()
    local Alert = lib.alertDialog({
        header = locale('all_header'),
        content = locale('all_content'),
        centered = true,
        cancel = true
    })
    return Alert
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    TriggerEvent('lss-basicdeath:client:SetPlayerDead')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    local DeathStatus = lib.callback.await('lss-basicdeath:callback:GetDeathStatus', nil)
    if DeathStatus == true then
        TriggerEvent('lss-basicdeath:client:SetPlayerDead')
    end
end)
