local defaultServicingData = {
    suspension = 100,
    tyres = 100,
    brakePads = 100,
    engineOil = 100,
    clutch = 100,
    airFilter = 100,
    sparkPlugs = 100,
    evMotor = 100,
    evBattery = 100,
    evCoolant = 100
}

AddStateBagChangeHandler("vehicleMileage", "", function(bagName, _, mileage)
    if not Config.EnableVehicleServicing then
        return
    end

    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    if cache.vehicle ~= vehicle then
        return
    end
    if cache.seat ~= -1 then
        return
    end

    local archetype = GetEntityArchetypeName(vehicle)
    if Config.ServicingBlacklist then
        local blacklistType = type(Config.ServicingBlacklist)
        if blacklistType == "table" and lib.table.contains(Config.ServicingBlacklist, archetype) then
            return
        end
    end

    if mileage % 1 ~= 0 or mileage < 1 then
        return
    end

    local model = GetEntityModel(vehicle)
    local isElectric = isVehicleElectric(archetype)
    local isValidVehicleType = IsThisModelACar(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model)
    if not isValidVehicleType then
        return
    end

    local vehicleState = Entity(vehicle).state
    local servicingData = vehicleState.servicingData or defaultServicingData

    for partName, partConfig in pairs(Config.Servicing) do
        local restricted = partConfig.restricted
        if (restricted == "electric" and not isElectric) or 
           (restricted == "combustion" and isElectric) then
            goto continue
        end

        local lifespan = partConfig.lifespanInKm or 0
        local decrement = lifespan > 0 and (100 / lifespan) or 0
        local newCondition = math.max(0, servicingData[partName] - decrement)
        servicingData[partName] = round(newCondition, 5)

        ::continue::
    end

    setVehicleStatebag(vehicle, "servicingData", servicingData, true)

    local needsService = false
    for _, condition in pairs(servicingData) do
        if condition <= Config.ServiceRequiredThreshold then
            needsService = true
            break
        end
    end

    if needsService then
        Framework.Client.Notify(Locale.serviceVehicleSoon, "error")
    end
end)

RegisterNUICallback("service-vehicle", function(data, cb)
    local partName = data.name
    local partStats = data.stats
    local partConfig = Config.Servicing[partName]
    
    if not partConfig or not partStats then
        return cb(false)
    end
    
    local vehicleData = LocalPlayer.state.tabletConnectedVehicle
    if not vehicleData or not vehicleData.vehicleEntity then
        return cb(false)
    end
    
    local vehicle = vehicleData.vehicleEntity
    if not DoesEntityExist(vehicle) then
        return cb(false)
    end

    local plate = Framework.Client.GetPlate(vehicle)
    
    local vehicleState = Entity(vehicle).state
    local servicingData = vehicleState.servicingData or defaultServicingData
    
    local prop = "spanner"
    if partName == "tyres" or partName == "brakePads" then
        prop = "wheel"
    end

    playMinigame(vehicle, "prop", { prop = prop }, function(success)
        showTabletAfterInteractionPrompt()
        SetNuiFocus(true, true)
        
        if not success then
            return cb(false)
        end
        
        local paymentSuccess = lib.callback.await("jg-mechanic:server:pay-for-service", false, plate, partName)
        if not paymentSuccess then
            return cb(false)
        end
        
        local partNameText = Locale[partName] or partName
        local message = string.format(Locale.partServiced, partNameText)
        Framework.Client.Notify(message, "success")
        
        servicingData[partName] = 100
        setVehicleStatebag(vehicle, "servicingData", servicingData, true)
        
        cb(true)
    end)
end)

RegisterNUICallback("get-service-history", function(_, cb)
    local vehicleData = LocalPlayer.state.tabletConnectedVehicle
    if not vehicleData or not vehicleData.vehicleEntity then
        return cb(false)
    end
    
    local vehicle = vehicleData.vehicleEntity
    if not DoesEntityExist(vehicle) then
        return cb(false)
    end
    
    local plate = Framework.Client.GetPlate(vehicle)
    
    local history = lib.callback.await("jg-mechanic:server:get-servicing-history", false, plate)
    cb(history)
end)