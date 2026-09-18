local wasTabletShown = false

function hideTabletToShowInteractionPrompt(instructionText)
    if Globals.HoldingTablet then
        stopTabletAnim()
        wasTabletShown = true
    end
    
    TriggerEvent("jg-mechanic:client:tablet-hidden-for-interaction")
    SendNUIMessage({
        instructionText = instructionText
    })
end

function showTabletAfterInteractionPrompt()
    if wasTabletShown then
        playTabletAnim()
        wasTabletShown = false
    end
    
    TriggerEvent("jg-mechanic:client:tablet-shown-after-interaction")
    SendNUIMessage({
        instructionText = false
    })
end

function ConnectVehicle(vehicleData)
    if not vehicleData then
        return false
    end
    
    local netId = vehicleData.netId
    local plate = vehicleData.plate
    
    while not NetworkGetEntityFromNetworkId(netId) do
        Wait(0)
    end
    
    local vehicleEntity = NetToVeh(netId)
    if not DoesEntityExist(vehicleEntity) then
        return false
    end
    
    if GetEntitySpeed(vehicleEntity) > 1.0 then
        Framework.Client.Notify(Locale.stopVehicleFirst, "error")
        return false
    end
    
    local connectionSuccess = lib.callback.await("jg-mechanic:server:connect-vehicle", false, plate, netId)
    if not connectionSuccess then
        Framework.Client.Notify("Another mechanic is connected to this vehicle", "error")
        return false
    end
    
    FreezeEntityPosition(vehicleEntity, true)
    vehicleData.vehicleEntity = vehicleEntity
    
    LocalPlayer.state:set("tabletConnectedVehicle", vehicleData, true)
    
    local vehicleState = Entity(vehicleEntity).state
    local vehicleModel = GetEntityModel(vehicleEntity)
    local vehicleType
    
    if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) then
        vehicleType = "car"
    elseif IsThisModelABike(vehicleModel) then
        vehicleType = "bike"
    else
        vehicleType = "other"
    end
    
    local tuningConfig = getVehicleTuningConfig(vehicleEntity, vehicleState.tuningConfig)
    local isElectric = isVehicleElectric(GetEntityArchetypeName(vehicleEntity))
    
    local vehicleInfo = {
        vehicleType = vehicleType,
        archetypeName = GetEntityArchetypeName(vehicleEntity),
        isVehicleElectric = isElectric,
        tuningConfig = tuningConfig,
        servicingData = vehicleState.servicingData,
        nitrousData = {
            installedBottles = vehicleState.nitrousInstalledBottles,
            filledBottles = vehicleState.nitrousFilledBottles,
            activeBtlCapacity = vehicleState.nitrousCapacity and (vehicleState.nitrousCapacity * 10) or 0
        }
    }
    
    return vehicleInfo
end

function DisconnectVehicle()
    local connectedVehicle = LocalPlayer.state.tabletConnectedVehicle
    if not connectedVehicle then
        return false
    end
    
    local vehicleEntity = connectedVehicle.vehicleEntity
    if vehicleEntity and DoesEntityExist(vehicleEntity) then
        FreezeEntityPosition(vehicleEntity, false)
    end
    
    lib.callback.await("jg-mechanic:server:disconnect-vehicle", false, connectedVehicle.plate)
    LocalPlayer.state:set("tabletConnectedVehicle", nil, true)
    
    return true
end

local function getNearbyVehicles()
    local playerPed = cache.ped
    local vehicles = {}
    local playerCoords = GetEntityCoords(playerPed)
    local maxDistance = Config.TabletConnectionMaxDistance or 4.0
    
    local nearbyVehicles = lib.getNearbyVehicles(playerCoords, maxDistance, true) or {}
    
    for _, vehicleData in ipairs(nearbyVehicles) do
        local plate = Framework.Client.GetPlate(vehicleData.vehicle)
        local mileage, mileageUnit = lib.callback.await("jg-mechanic:server:get-vehicle-mileage", false, plate)
        
        table.insert(vehicles, {
            netId = VehToNet(vehicleData.vehicle),
            label = Framework.Client.GetVehicleLabel(GetEntityArchetypeName(vehicleData.vehicle)),
            plate = plate,
            mileage = mileage,
            mileageUnit = mileageUnit
        })
    end
    
    return vehicles
end

local function openTablet()
    local connectedVehicle = false
    local mechanicData = lib.callback.await("jg-mechanic:server:get-player-mechanics", false)
    
    if next(mechanicData) == nil then
        Framework.Client.Notify(Locale.notPartOfAnyMechanics, "error")
        return false
    end
    
    if cache.vehicle then
        local vehicle = cache.vehicle
        local plate = Framework.Client.GetPlate(vehicle)
        local mileage, mileageUnit = lib.callback.await("jg-mechanic:server:get-vehicle-mileage", false, plate)
        
        connectedVehicle = {
            netId = VehToNet(vehicle),
            label = Framework.Client.GetVehicleLabel(GetEntityArchetypeName(vehicle)),
            plate = plate,
            mileage = mileage,
            mileageUnit = mileageUnit
        }
        
        local connectionResult = ConnectVehicle(connectedVehicle)
        if not connectionResult then
            return false
        end
        connectedVehicle = connectionResult
    end
    
    local preferences = lib.callback.await("jg-mechanic:server:get-tablet-preferences", false)
    LocalPlayer.state:set("isBusy", true, true)
    playTabletAnim()
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "show-tablet",
        gameBuild = GetGameBuildNumber() or 0,
        connectedVehicle = connectedVehicle,
        availableMechanics = mechanicData,
        vehicleConnections = getNearbyVehicles(),
        gameTime = {
            hours = GetClockHours(),
            mins = GetClockMinutes()
        },
        preferences = preferences,
        config = Config,
        locale = Locale
    })
end

RegisterNUICallback("tablet-login", function(data, cb)
    local mechanicId = data.mechanicId
    local mechanicLocation = Config.MechanicLocations and Config.MechanicLocations[mechanicId]
    
    if not mechanicId or not mechanicLocation then
        return cb({ error = true })
    end
    
    LocalPlayer.state:set("mechanicId", mechanicId, true)
    local mechanicInfo = lib.callback.await("jg-mechanic:server:get-tablet-mechanic-data", false, mechanicId)
    
    if not mechanicInfo then
        return cb({ error = true })
    end
    
    cb({
        onDuty = Framework.Client.GetPlayerJobDuty(mechanicId),
        label = mechanicInfo.label,
        balance = mechanicInfo.balance,
        ownerId = mechanicInfo.ownerId,
        ordersCount = mechanicInfo.ordersCount,
        unpaidInvoicesCount = mechanicInfo.unpaidInvoicesCount,
        employeeRole = mechanicInfo.employeeRole,
        stats = mechanicInfo.stats,
        mechanicTuningConfig = mechanicLocation.tuning,
        playerBalance = {
            bank = Framework.Client.GetBalance("bank"),
            cash = Framework.Client.GetBalance("cash")
        }
    })
end)

RegisterNUICallback("connect-vehicle", function(data, cb)
    cb(ConnectVehicle(data.vehicle))
end)

RegisterNUICallback("disconnect-vehicle", function(data, cb)
    cb(DisconnectVehicle())
end)

RegisterNUICallback("toggle-on-duty", function(data, cb)
    if not data then return cb(false) end
    
    local success = lib.callback.await("jg-mechanic:server:toggle-on-duty", false, data.toggle)
    if not success then return cb(false) end
    
    Framework.Client.ToggleJobDuty(data.toggle)
    
    if data.toggle then
        Framework.Client.Notify(Locale.onDutyNotify, "success")
    else
        Framework.Client.Notify(Locale.offDutyNotify, "success")
    end
    
    cb(true)
end)

RegisterNUICallback("save-preferences", function(data, cb)
    if not data.preferences then return cb(false) end
    
    local success = lib.callback.await("jg-mechanic:server:save-tablet-settings", false, data.preferences)
    cb(success or false)
end)

RegisterNetEvent("jg-mechanic:client:use-tablet", openTablet)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        local connectedVehicle = LocalPlayer.state.tabletConnectedVehicle
        if connectedVehicle and connectedVehicle.vehicleEntity then
            FreezeEntityPosition(connectedVehicle.vehicleEntity, false)
        end

        SetNuiFocus(false, false)
        if Globals and Globals.HoldingTablet then
            stopTabletAnim()
            wasTabletShown = false
        end
        SendNUIMessage({ instructionText = false })
    end
end)