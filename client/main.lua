local QBCore = exports['qb-core']:GetCoreObject()
local ped = PlayerPedId()
local pedCoords = GetEntityCoords(ped)
local PlayerData = QBCore.Functions.GetPlayerData()

local PedCoords = nil

local isMissionStarted = false
local isThumbCollected = false
local isMissionFinished = false

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        PlayerJob = QBCore.Functions.GetPlayerData().job
        Contact()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    Contact()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function Contact()
    if not DoesEntityExist(contactmodel) then

        RequestModel("a_m_y_bevhills_01")
        while not HasModelLoaded("a_m_y_bevhills_01") do
            Wait(0)
        end

        contactmodel = CreatePed(1, "a_m_y_bevhills_01", 811.11, -282.11, 65.46, 101.04, false, false)
        SetEntityAsMissionEntity(contactmodel)
        SetBlockingOfNonTemporaryEvents(contactmodel, true)
        SetEntityInvincible(contactmodel, true)
        FreezeEntityPosition(contactmodel, true)
        TaskStartScenarioInPlace(contactmodel, "WORLD_HUMAN_STAND_MOBILE", 0, true)
        

        exports['qb-target']:AddTargetEntity(contactmodel, {
            options = {
                {
                    type = "client",
                    event = "sl-hitman:client:request",
                    icon = "fa-solid fa-user",
                    label = "Request Mission",
                    canInteract = function()
                        if isMissionStarted == true then return false end 
                        return true 
                    end,
                },
                {
                    num = 1,
                    type = "client",
                    event = "sl-hitman:client:claimreward",
                    icon = "fa-solid fa-sack-dollar",
                    label = "Claim Reward",
                    canInteract = function()
                        if isMissionStarted == false then return false end 
                        return true 
                    end,
                },
                {
                    num = 2,
                    type = "client",
                    event = "sl-hitman:client:endmission",
                    icon = "fa-solid fa-x",
                    label = "End Mission",
                    canInteract = function()
                        if isMissionStarted == false then return false end 
                        return true 
                    end,
                }
            },
            distance = 2.5,
        })
    end
end

RegisterNetEvent('sl-hitman:client:request', function()
    QBCore.Functions.TriggerCallback('sl-hitman:server:GetCopsAmount', function(cops)
        if cops >= Config.RequiredCops then
            if PlayerJob.name ~= 'police' then
                if isMissionStarted == false then
                    isMissionStarted = true
                    QBCore.Functions.Notify('You will get a email regarding information about the target shortly.', 'success', 5000)

                    Wait(10000)
                    TriggerEvent('sl-hitman:client:mission')
                    TriggerServerEvent('qb-phone:server:sendNewMail', {
                        sender = 'Unknown',
                        subject = 'I need someone gone..',
                        message = "I've sent the location of your target's vehicle to your GPS, follow them and eliminate them when the time is right. Don't forget to take a picture of him fast before the cops come.",
                        button = {}
                    })
                else
                    QBCore.Functions.Notify("You already requested a mission.", 'error', 5000)
                end
            else
                QBCore.Functions.Notify("I plead the fifth.", 'error', 5000)
            end
        else
            QBCore.Functions.Notify(Config.RequiredCops.. " police officers are needed to start this mission.", 'error', 5000)
        end
    end)
end)

RegisterNetEvent('sl-hitman:client:mission', function()
    local pedSelect = math.random(1, #Config.TargetPeds)
    local grabPed = Config.TargetPeds[pedSelect]["ped"]
    local locationSelect = math.random(1, #Config.PedLocations)
    local grabLocation = Config.PedLocations[locationSelect]["location"]
    local g17 = "WEAPON_COMBATPISTOL"

    if not DoesEntityExist(grabPed) then
        RequestModel(grabPed)
        while not HasModelLoaded(grabPed) do
            Wait(0)
        end

        targetlo = CreatePed(1, grabPed, grabLocation.x, grabLocation.y, grabLocation.z, true, true)
        SetPedFleeAttributes(targetlo, 0, 0)
        SetPedCombatAttributes(targetlo, 46, 1)
        SetPedCombatAbility(targetlo, 2)
        SetPedCombatMovement(targetlo, 2)
        SetPedCombatRange(targetlo, 2)
        SetPedKeepTask(targetlo, true)
        GiveWeaponToPed(targetlo, GetHashKey(g17), 250, false, true)
        SetEntityMaxHealth(targetlo, 200)
        SetEntityHealth(targetlo, GetEntityMaxHealth(targetlo))
        SetPedArmour(targetlo, 100)
        SetEntityAsMissionEntity(targetlo, true, true)

        if not GetIsTaskActive(targetlo, 221) then
            TaskWanderStandard(targetlo, 10.0, 10)
        end

        CreateThread(function()
            while true do
                Wait(1) 
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetlo))
                if dist < 25 then 
                    TaskShootAtEntity(targetlo, PlayerPedId(), 9999999.0, "FIRING_PATTERN_BURST_FIRE_PISTOL")
                    return false
                end
            end
        end)

        CreateThread(function()
            while true do
                Wait(500)
                if GetEntityHealth(targetlo) == 0 then
                    QBCore.Functions.Notify("Your target is dead, get his thumb quickly.", 'info', 5000)

                    exports['qb-target']:AddTargetEntity(targetlo, {
                        options = {
                            {
                                type = "client",
                                event = "sl-hitman:client:thumb",
                                icon = "fa-solid fa-fingerprint",
                                label = "Chop Thumb",
                                canInteract = function()
                                    if isThumbCollected == false then return true end 
                                    return false 
                                end,
                            }
                        },
                        distance = 2.5,
                    })
                    return false
                end
            end
        end)

        CreateThread(function()
            if isThumbCollected == false then
                local target = AddBlipForEntity(targetlo)
                SetBlipSprite(target, 458)
                SetBlipColour(target, 1)
                SetBlipScale(target, 0.8)
                SetBlipRoute(target, true)
                SetBlipRouteColour(target, 1)
                SetBlipAsShortRange(target, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Your Target")
                EndTextCommandSetBlipName(target)

                while true do
                    Wait(500)
                    if isThumbCollected == true then 
                        RemoveBlip(target)
                    end
                end
            end
       end)
    end
end)

RegisterNetEvent('sl-hitman:client:thumb', function()
    if isThumbCollected == false then 
        ClearPedTasksImmediately(PlayerPedId())
        QBCore.Functions.Progressbar('cutthumb', "Chopping target's thumb off", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'random@train_tracks',
            anim = 'idle_e',
            flags = 16,
        }, {}, {}, function()
            isThumbCollected = true
            QBCore.Functions.Notify("Bring the finger back to the boss.", 'info', 5000)
            TriggerServerEvent('sl-hitman:server:givethumb')
            ClearPedTasksImmediately(PlayerPedId())
        end, function()
            QBCore.Functions.Notify("What are you doing? Why did you stop cutting his thumb off?.", 'error', 5000)
            ClearPedTasksImmediately(PlayerPedId())
        end)
    else
        QBCore.Functions.Notify("You already collected his thumb, drive to the GPS location on your map.", 'error', 5000)
    end
end)

RegisterNetEvent('sl-hitman:client:claimreward', function()
    if isThumbCollected == true then 
        isMissionStarted = false
        isThumbCollected = false
        isMissionFinished = true
        TriggerServerEvent('sl-hitman:server:removethumb')
        QBCore.Functions.Notify("Good job, I will calcuate your pay. You may leave.", 'success', 5000)

        Wait(10000)
        TriggerServerEvent('sl-hitman:server:payment')
    else
        QBCore.Functions.Notify("You didn't bring me the target's thumb..", 'error', 5000)
    end
end)

RegisterNetEvent('sl-hitman:client:endmission', function()
    
    QBCore.Functions.Notify('Give me a few seconds to cancel this mission.', 'info', 5000)
    Wait(10000)
    isMissionStarted = false
    QBCore.Functions.Notify("I guess you're not man enough for his mission. You've ended the mission successfully.", 'success', 5000)
end)