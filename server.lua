ESX = exports["es_extended"]:getSharedObject()

local function getCategories(cb)
    exports.oxmysql:execute('SELECT DISTINCT category FROM vehicles', {}, function(result)
        local categories = {}
        for _, row in ipairs(result) do
            table.insert(categories, row.category)
        end
        cb(categories)
    end)
end

local function getVehiclesByCategory(category, cb)
    exports.oxmysql:execute('SELECT name, model FROM vehicles WHERE category = ?', {category}, function(result)
        cb(result)
    end)
end

RegisterNetEvent('givecar:checkAdmin')
AddEventHandler('givecar:checkAdmin', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'admin' then
        getCategories(function(categories)
            TriggerClientEvent('givecar:openMenu', source, categories)
        end)
    else
        xPlayer.showNotification('Du hast keine Berechtigung, diesen Befehl auszuführen.')
    end
end)

RegisterNetEvent('givecar:getVehicles')
AddEventHandler('givecar:getVehicles', function(category)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'admin' then
        getVehiclesByCategory(category, function(vehicles)
            TriggerClientEvent('givecar:updateVehicles', source, vehicles)
        end)
    else
        xPlayer.showNotification('Du hast keine Berechtigung, auf diese Daten zuzugreifen.')
    end
end)

RegisterNetEvent('givecar:getPlayers')
AddEventHandler('givecar:getPlayers', function()
    local source = source
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            table.insert(players, {id = playerId, name = GetPlayerName(playerId)})
        end
    end
    print("Sending players to client: " .. json.encode(players))
    TriggerClientEvent('givecar:receivePlayers', source, players)
end)

RegisterNetEvent('givecar:spawnVehicle')
AddEventHandler('givecar:spawnVehicle', function(model)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() == 'admin' then
        TriggerClientEvent('givecar:spawnVehicle', source, model)
    else
        xPlayer.showNotification('Du hast keine Berechtigung, Fahrzeuge zu spawnen.')
    end
end)

RegisterNetEvent('givecar:addToGarage')
AddEventHandler('givecar:addToGarage', function(model, targetPlayerId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)

    if xPlayer.getGroup() == 'admin' and targetPlayer then
        local plate = GeneratePlate()
        
        exports.oxmysql:execute('SELECT * FROM vehicles WHERE model = ?', {model}, function(vehicles)
            if vehicles and #vehicles > 0 then
                local vehicle = vehicles[1]
                local vehicleProps = {
                    model = GetHashKey(vehicle.model),
                    plate = plate
                }

                -- Fügen Sie hier alle erforderlichen Fahrzeugeigenschaften hinzu
                local fullVehicleProps = {
                    model = vehicleProps.model,
                    plate = plate,
                    bodyHealth = 1000.0,
                    engineHealth = 1000.0,
                    fuelLevel = 100.0,
                    dirtLevel = 0.0,
                    color1 = 0,
                    color2 = 0,
                    pearlescentColor = 0,
                    wheelColor = 0,
                    wheels = 0,
                    windowTint = 0,
                    neonEnabled = {false, false, false, false},
                    neonColor = {255, 0, 255},
                    extras = {},
                    tyreSmokeColor = {255, 255, 255},
                    modSpoilers = -1,
                    modFrontBumper = -1,
                    modRearBumper = -1,
                    modSideSkirt = -1,
                    modExhaust = -1,
                    modFrame = -1,
                    modGrille = -1,
                    modHood = -1,
                    modFender = -1,
                    modRightFender = -1,
                    modRoof = -1,
                    modEngine = -1,
                    modBrakes = -1,
                    modTransmission = -1,
                    modHorns = -1,
                    modSuspension = -1,
                    modArmor = -1,
                    modTurbo = false,
                    modSmokeEnabled = false,
                    modXenon = false,
                    modFrontWheels = -1,
                    modBackWheels = -1,
                    modCustomTiresF = false,
                    modCustomTiresR = false,
                    modPlateHolder = -1,
                    modVanityPlate = -1,
                    modTrimA = -1,
                    modOrnaments = -1,
                    modDashboard = -1,
                    modDial = -1,
                    modDoorSpeaker = -1,
                    modSeats = -1,
                    modSteeringWheel = -1,
                    modShifterLeavers = -1,
                    modAPlate = -1,
                    modSpeakers = -1,
                    modTrunk = -1,
                    modHydrolic = -1,
                    modEngineBlock = -1,
                    modAirFilter = -1,
                    modStruts = -1,
                    modArchCover = -1,
                    modAerials = -1,
                    modTrimB = -1,
                    modTank = -1,
                    modWindows = -1,
                    modLivery = -1
                }

                exports.oxmysql:insert('INSERT INTO owned_vehicles (owner, state, plate, vehicle) VALUES (?, 1, ?, ?)',
                {
                    targetPlayer.identifier,
                    plate,
                    json.encode(fullVehicleProps)
                }, function(insertId)
                    if insertId > 0 then
                        xPlayer.showNotification('Fahrzeug wurde zur Garage des Spielers hinzugefügt.')
                        targetPlayer.showNotification('Ein neues Fahrzeug wurde Ihrer Garage hinzugefügt.')
                        
                        -- Aktualisieren Sie die Garage des Spielers
                        TriggerClientEvent('esx_advancedgarage:refreshVehicles', targetPlayerId)
                    else
                        xPlayer.showNotification('Fahrzeugs zur Garage Hinzugefügt.')
                    end
                end)
            else
                xPlayer.showNotification('Fahrzeugmodell nicht gefunden.')
            end
        end)
    else
        xPlayer.showNotification('Fehler beim Hinzufügen des Fahrzeugs zur Garage.')
    end
end)

function GeneratePlate()
    local plate = string.upper(ESX.GetRandomString(3) .. ' ' .. ESX.GetRandomString(3))
    exports.oxmysql:execute('SELECT 1 FROM owned_vehicles WHERE plate = ?', {plate}, function(result)
        if result and #result > 0 then
            return GeneratePlate()
        end
    end)
    return plate
end

-- Stilisierte Nachricht beim Serverstart
print("^2====================================^0")
print("^2|          Clever Scripts           |^0")
print("^2|          Givecar Skript           |^0")
print("^2====================================^0")