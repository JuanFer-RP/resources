local statebagCache = {}

local function applyStatebagData(vehicleNetId, statebagData)
    if not vehicleNetId or vehicleNetId == 0 then
        return false
    end

    local vehicle = Entity(vehicleNetId).state
    
    -- Apply all statebag properties if they exist in the data
    if statebagData.primarySecondarySync then
        vehicle:set("primarySecondarySync", statebagData.primarySecondarySync, true)
    end
    
    if statebagData.disablePearl then
        vehicle:set("disablePearl", statebagData.disablePearl, true)
    end
    
    if statebagData.enableStance ~= nil then
        vehicle:set("enableStance", statebagData.enableStance, true)
    end
    
    if statebagData.wheelsAdjIndv then
        vehicle:set("wheelsAdjIndv", statebagData.wheelsAdjIndv, true)
    end
    
    if statebagData.stance then
        vehicle:set("stance", statebagData.stance, true)
    end
    
    if statebagData.lcInstalled then
        vehicle:set("lightingControllerInstalled", statebagData.lcInstalled, true)
    end
    
    if statebagData.lcXenons then
        vehicle:set("xenons", statebagData.lcXenons, true)
    end
    
    if statebagData.lcUnderglowDirections then
        vehicle:set("underglowDirections", statebagData.lcUnderglowDirections, true)
    end
    
    if statebagData.lcUnderglow then
        vehicle:set("underglow", statebagData.lcUnderglow, true)
    end
    
    if statebagData.tuningConfig then
        vehicle:set("tuningConfig", statebagData.tuningConfig, true)
    end
    
    if statebagData.servicingData then
        vehicle:set("servicingData", statebagData.servicingData, true)
    end
    
    if statebagData.nitrousInstalledBottles then
        vehicle:set("nitrousInstalledBottles", statebagData.nitrousInstalledBottles, true)
    end
    
    if statebagData.nitrousFilledBottles then
        vehicle:set("nitrousFilledBottles", statebagData.nitrousFilledBottles, true)
    end
    
    if statebagData.nitrousCapacity then
        vehicle:set("nitrousCapacity", statebagData.nitrousCapacity, true)
    end
    
    -- Mark that statebags have been applied
    vehicle:set("jgMechStatebagsApplied", true, true)
    
    debugPrint("applyStatebagData run successfully", "debug", Framework.Server.GetPlate(vehicleNetId))
    return true
end

local function retrieveAndApplyVehicleStatebagData(vehicleNetId, plate)
    local cachedData = statebagCache[plate]
    
    if not cachedData then
        local dbData = MySQL.scalar.await(
            "SELECT data FROM mechanic_vehicledata WHERE plate = ?",
            {plate}
        )
        
        if not dbData then
            debugPrint(
                "Statebag data not available in cache or database - ignore if vehicle has not interacted with jg-mechanic", 
                "warning", 
                plate
            )
            return false
        end
        
        debugPrint("Retrieved statebag data from database", "debug", plate)
        statebagCache[plate] = dbData
        cachedData = dbData
    else
        debugPrint("Retrieved statebag data from cache", "debug", plate)
    end
    
    return applyStatebagData(vehicleNetId, json.decode(cachedData))
end

local function saveVehicleStatebagDataToDB(plate, immediate)
    if not plate or plate == "" then
        print("^1[ERROR] Trying to write to mechanic_vehicledata with an empty vehicle plate - why are your vehicle plates returning as empty strings/false?")
        return false
    end
    
    local cachedData = statebagCache[plate]
    if not cachedData then
        return false
    end
    
    if immediate then
        MySQL.update.await(
            "UPDATE mechanic_vehicledata SET data = ? WHERE plate = ?",
            {cachedData, plate}
        )
    else
        MySQL.insert.await(
            "INSERT INTO mechanic_vehicledata (plate, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE plate = VALUES(plate), data = VALUES(data)",
            {plate, cachedData}
        )
    end
    
    debugPrint("Statebag data saved to DB", "debug", plate)
    return true
end

local function setVehicleStatebag(vehicleNetId, key, value, immediateSave, plate)
    if not (vehicleNetId and vehicleNetId ~= 0 and key) or value == nil then
        debugPrint("Could not set statebag on vehicle - data:", "warning", key, value)
        return false
    end
    
    -- Get plate if not provided
    local vehiclePlate = plate or Framework.Server.GetPlate(vehicleNetId)
    if not vehiclePlate then
        debugPrint("Could not get plate for vehicle", "warning", vehicleNetId)
        return false
    end
    
    -- Set statebag directly on vehicle
    local vehicle = Entity(vehicleNetId).state
    vehicle:set(key, value, true)
    
    -- Skip DB update if using special preview plate
    if Config.ChangePlateDuringPreview and vehiclePlate == Config.ChangePlateDuringPreview then
        debugPrint("Successfully set statebag on vehicle", "debug", vehiclePlate, key, value)
        return true
    end
    
    -- Update cache
    if not statebagCache[vehiclePlate] then
        statebagCache[vehiclePlate] = "{}"
    end
    
    local stateData = json.decode(statebagCache[vehiclePlate])
    stateData[key] = value
    statebagCache[vehiclePlate] = json.encode(stateData)
    
    -- Schedule save if requested
    if immediateSave then
        SetTimeout(500, function()
            saveVehicleStatebagDataToDB(vehiclePlate)
        end)
    end
    
    debugPrint("Successfully set statebag on vehicle", "debug", vehiclePlate, key, value)
    return true
end

lib.callback.register("jg-mechanic:server:retrieve-and-apply-veh-statebag-data", function(playerId, vehicleNetId, plate)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not (plate and vehicle) or vehicle == 0 then
        debugPrint("Vehicle or plate were nil when running retrieve-and-apply-veh-statebag-data", "warning", vehicleNetId)
        return false
    end
    
    return retrieveAndApplyVehicleStatebagData(vehicle, plate)
end)

lib.callback.register("jg-mechanic:server:set-vehicle-statebag", function(playerId, vehicleNetId, key, value, immediateSave, plate)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    return setVehicleStatebag(vehicle, key, value, immediateSave, plate)
end)

lib.callback.register("jg-mechanic:server:set-vehicle-statebags", function(playerId, vehicleNetId, statebagData, immediateSave, plate)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    for key, value in pairs(statebagData) do
        setVehicleStatebag(vehicle, key, value, false, plate)
    end
    
    if immediateSave then
        setVehicleStatebag(vehicle, "_sbFromTableSet", true, true, plate)
    end
    
    return true
end)

lib.callback.register("jg-mechanic:server:save-veh-statebag-data-to-db", function(playerId, plate, immediate)
    return saveVehicleStatebagDataToDB(plate, immediate)
end)

exports("vehiclePlateUpdated", function(oldPlate, newPlate)
    if oldPlate == newPlate then
        return
    end
    
    -- Move cached data to new plate
    statebagCache[newPlate] = statebagCache[oldPlate]
    statebagCache[oldPlate] = nil
    
    -- Save new plate data
    saveVehicleStatebagDataToDB(newPlate)
    
    -- Update database references
    MySQL.query.await("DELETE FROM mechanic_vehicledata WHERE plate = ?", {oldPlate})
    MySQL.query.await("UPDATE mechanic_orders SET plate = ? WHERE plate = ?", {newPlate, oldPlate})
    MySQL.query.await("UPDATE mechanic_servicing_history SET plate = ? WHERE plate = ?", {newPlate, oldPlate})
    MySQL.query.await("UPDATE mechanic_servicing_history SET plate = ? WHERE plate = ?", {newPlate, oldPlate})
end)