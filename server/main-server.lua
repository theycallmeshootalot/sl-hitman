local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('sl-hitman:server:GetCopsAmount', function(_, cb)
    local amount = 0
    for _, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    cb(amount)
end)


RegisterNetEvent('sl-hitman:server:payment', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = math.random(10000, 25000)
    Player.Functions.AddMoney("bank", amount, "hitman-payment")
    TriggerClientEvent('QBCore:Notify', src, "You earned $" ..amount.. " from completing the mission.", 'info')
end)

RegisterNetEvent('sl-hitman:server:givethumb', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    Player.Functions.AddItem("human_thumb", 1, false)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["human_thumb"], "add")
end)

RegisterNetEvent('sl-hitman:server:removethumb', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    Player.Functions.RemoveItem("human_thumb", 1, false)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["human_thumb"], "remove")
end)