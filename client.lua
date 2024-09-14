ESX = exports["es_extended"]:getSharedObject()
local display = false
local categories = {}
local vehicles = {}
local isSpawning = false

RegisterNetEvent('givecar:openMenu')
AddEventHandler('givecar:openMenu', function(receivedCategories)
    categories = receivedCategories
    vehicles = {}
    SetDisplay(true)
end)

RegisterNetEvent('givecar:updateVehicles')
AddEventHandler('givecar:updateVehicles', function(receivedVehicles)
    vehicles = receivedVehicles
    SendNUIMessage({
        type = "updateVehicles",
        vehicles = vehicles
    })
end)

RegisterCommand("givecar", function(source, args)
    TriggerServerEvent("givecar:checkAdmin")
end)

RegisterNUICallback("selectCategory", function(data, cb)
    TriggerServerEvent('givecar:getVehicles', data.category)
    cb('ok')
end)

RegisterNUICallback("spawnVehicle", function(data, cb)
    if not isSpawning then
        isSpawning = true
        local model = data.model
        TriggerServerEvent('givecar:spawnVehicle', model)
        Citizen.SetTimeout(1000, function()
            isSpawning = false
        end)
    end
    cb('ok')
end)

RegisterNUICallback("getPlayers", function(data, cb)
    TriggerServerEvent("givecar:getPlayers")
    cb('ok')
end)

RegisterNUICallback("addToGarage", function(data, cb)
    TriggerServerEvent('givecar:addToGarage', data.model, data.playerId)
    cb('ok')
end)

RegisterNUICallback("getPlayerVehicles", function(data, cb)
    TriggerServerEvent('givecar:getPlayerVehicles', data.playerId)
    cb('ok')
end)

RegisterNUICallback("closeMenu", function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNetEvent('givecar:spawnVehicle')
AddEventHandler('givecar:spawnVehicle', function(model)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    ESX.Game.SpawnVehicle(model, coords, 0.0, function(vehicle)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    end)
end)

RegisterNetEvent('givecar:receivePlayers')
AddEventHandler('givecar:receivePlayers', function(playerList)
    print("Received players: " .. json.encode(playerList))
    SendNUIMessage({
        type = "updatePlayers",
        players = playerList
    })
end)

RegisterNetEvent('givecar:receivePlayerVehicles')
AddEventHandler('givecar:receivePlayerVehicles', function(vehicles)
    SendNUIMessage({
        type = "updatePlayerVehicles",
        vehicles = vehicles
    })
end)

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "setDisplay",
        status = bool,
        categories = categories
    })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if display then
            DisableControlAction(0, 1, display)
            DisableControlAction(0, 2, display)
            DisableControlAction(0, 142, display)
            DisableControlAction(0, 18, display)
            DisableControlAction(0, 322, display)
            DisableControlAction(0, 106, display)
        end
    end
end)