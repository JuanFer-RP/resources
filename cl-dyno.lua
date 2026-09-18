local dynoActive = false

local function setWheelRotationSpeeds(vehicle, speed)
    local driveBias = getVehicleHandlingValue(vehicle, "CHandlingData", "fDriveBiasFront")
    
    if driveBias >= 0.5 then
        SetVehicleWheelRotationSpeed(vehicle, 0, speed)
        SetVehicleWheelRotationSpeed(vehicle, 1, speed)
    end
    
    if driveBias <= 0.5 then
        SetVehicleWheelRotationSpeed(vehicle, 2, speed)
        SetVehicleWheelRotationSpeed(vehicle, 3, speed)
    end
end

local function startDynoTest(vehicle)
    CreateThread(function()
        local timeout = 0
        dynoActive = true
        SetVehicleGravity(vehicle, false)
        
        while timeout < 33500 and dynoActive do
            local startTime = GetGameTimer()
            local state = Entity(vehicle).state
            
            state:set("vehicleDyno", {
                rpm = math.min(1.0, (timeout + 7500) / 33500),
                wheelSpeed = timeout / 200
            }, true)
            
            Wait(50)
            timeout = timeout + (GetGameTimer() - startTime)
        end
        
        Entity(vehicle).state:set("vehicleDyno", false, true)
        SetVehicleGravity(vehicle, true)
    end)
end

AddStateBagChangeHandler("vehicleDyno", nil, function(bagName, key, value)
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end

    if not value then
        setWheelRotationSpeeds(entity, 0)
        return
    end
    
    SetVehicleCurrentRpm(entity, value.rpm)
    setWheelRotationSpeeds(entity, value.wheelSpeed)
end)

RegisterNUICallback("start-dyno", function(data, cb)
    local vehicle = LocalPlayer.state.tabletConnectedVehicle?.vehicleEntity
    if not vehicle or not DoesEntityExist(vehicle) then
        return cb(false)
    end

    CreateThread(function()
        SetNuiFocus(false, false)
        
        if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then
            hideTabletToShowInteractionPrompt(Locale.enterVehicleToStartDynoMsg)
            while GetPedInVehicleSeat(vehicle, -1) ~= cache.ped do
                Wait(100)
            end
        end

        hideTabletToShowInteractionPrompt(Locale.startDynoMsg)
        while not IsControlJustPressed(0, 201) do
            Wait(0)
        end

        SetNuiFocus(true, true)
        showTabletAfterInteractionPrompt()
        
        cb({
            maxSpeed = getVehicleHandlingValue(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel"),
            fDriveInertia = getVehicleHandlingValue(vehicle, "CHandlingData", "fDriveInertia"),
            fInitialDriveForce = getVehicleHandlingValue(vehicle, "CHandlingData", "fInitialDriveForce")
        })
        
        startDynoTest(vehicle)
    end)
end)

RegisterNUICallback("stop-dyno", function(data, cb)
    dynoActive = false
    cb(true)
end)

RegisterNUICallback("dyno-share-with-player", function(data, cb)
    if not data.player or not data.results then
        return cb(false)
    end
    
    cb(lib.callback.await("jg-mechanic:server:dyno-share-with-player", false, data.player, data.results))
end)

RegisterNetEvent("jg-mechanic:client:dyno-show-results-sheet", function(results)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "show-dyno-share-sheet",
        results = results,
        locale = Locale,
        config = Config
    })
end)