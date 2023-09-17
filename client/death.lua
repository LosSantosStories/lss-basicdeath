local called = false
local blipTable = {}

function StartBlipCheck()
    while true do
        if #blipTable ~= 0 then
            for k, v in pairs(blipTable) do
                local currentTime = GetGameTimer()
                if (currentTime - v.time) >= Config.BlipTimer then
                    RemoveBlip(v.blip)
                    table.remove(blipTable, k)
                end
            end
        end
        Wait(2500)
    end
end

function SendDistressSignal()
    local coords = GetEntityCoords(cache.ped)

    if Config.Dispatch == 'default' then
        TriggerServerEvent('lss-basicdeath:server:SendDistress', coords)
    elseif Config.Dispatch == 'quasar' then
        local message = locale('injuried_person')
        local alert = {
            message = message,
            location = coords,
        }

        TriggerServerEvent('qs-smartphone:server:sendJobAlert', alert, Config.Job)
        TriggerServerEvent('qs-smartphone:server:AddNotifies', {
            head = "Google My Business",
            msg = message,
            app = 'business'
        })
    elseif Config.Dispatch == 'cd_dispatch' then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = { Config.Job, },
            coords = data.coords,
            title = locale('injuried_person'),
            message = 'A ' .. data.sex .. ' got injuried at ' .. data.street,
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                flashes = false,
                text = locale('injuried_person'),
                time = 5,
                radius = 0,
            }
        })
    end
end

RegisterNetEvent('lss-basicdeath:client:GetDistress', function(coords)
    lib.notify({
        title = locale('injuried_person'),
        type = 'success'
    })
    local blip = AddBlipForCoord(coords)
    SetBlipScale(blip, Config.InjuriedBlip.scale)
    SetBlipColour(blip, Config.InjuriedBlip.colour)
    SetBlipSprite(blip, Config.InjuriedBlip.sprite)

    local timer = GetGameTimer()
    blipTable[#blipTable + 1] = { blip = blip, time = timer }
end)

RegisterNetEvent('lss-basicdeath:client:SetPlayerDead', function()
    TriggerServerEvent('lss-basicdeath:server:SetDeathStatus', true)
    CreateThread(DistressLoop)
    SendNUIMessage({
        type = "show",
        timer = Config.DeathTime,
        header = locale('header'),
        desc = locale('description')
    })

    DoScreenFadeOut(250)
    Wait(250)
    if lib.progressActive() then
        lib.cancelProgress()
    end
    if Config.OxTarget then
        exports.ox_target:disableTargeting(true)
    end

    LocalPlayer.state:set('invBusy', true, true)

    lib.requestAnimDict("veh@low@front_ps@idle_duck")
    lib.requestAnimDict('combat@damage@writhe')

    local PedPos = GetEntityCoords(cache.ped)
    local Heading = GetEntityHeading(cache.ped)

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
    DoScreenFadeIn(250)
    while LocalPlayer.state.isDead do
        if not LocalPlayer.state.inCPR then
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
    DoScreenFadeOut(250)
    Wait(250)
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
    elseif type == 'ambulance' then
        NetworkResurrectLocalPlayer(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped), true, false)
    elseif type == 'admin' then
        NetworkResurrectLocalPlayer(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped), true, false)
    end
    if Config.OxTarget then
        exports.ox_target:disableTargeting(true)
    end
    called = false
    DoScreenFadeIn(250)

    TriggerEvent('esx_basicneeds:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
end)

RegisterNuiCallback("time_expired", function(data)
    TriggerEvent('lss-basicdeath:client:RevivePlayer')
end)

function DistressLoop()
    while true do
        if called == false and LocalPlayer.state.isDead then
            if IsControlJustPressed(0, Config.DistressButton) then
                called = true
                SendNUIMessage({ type = "change" })
                SendDistressSignal()
                break
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end

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

RegisterNetEvent('lss-basicdeath:client:SetHealthToZero', function()
    SetEntityHealth(cache.ped, 0)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    Wait(100)
    StartBlipCheck()
    local DeathStatus = lib.callback.await('lss-basicdeath:callback:GetDeathStatus', nil)
    if DeathStatus == true then
        TriggerEvent('lss-basicdeath:client:SetHealthToZero')
    end
end)
