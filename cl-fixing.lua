
RegisterNetEvent("jg-mechanic:client:fix-vehicle-admin", function()
    local isAdmin = lib.callback.await("jg-mechanic:server:is-admin", false)
    if not isAdmin then return end

    if not cache.vehicle then
        Framework.Client.Notify(Locale.notInsideVehicle, "error")
        return
    end

    Framework.Client.RepairVehicle(cache.vehicle)
end)

RegisterNetEvent("jg-mechanic:client:clean-vehicle", function()
    local hasItem = lib.callback.await("jg-mechanic:server:has-item", 250, "cleaning_kit")
    if not hasItem then return end

    local ped = cache.ped
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, true)
    
    if not vehicle then
        Framework.Client.Notify(Locale.noVehicleNearby, "error")
        return
    end

    if IsPedInVehicle(ped, vehicle, true) then
        TaskLeaveVehicle(ped, vehicle, 16)
    end

    local anim = { dict = "amb@world_human_maid_clean@", name = "base" }
    local prop = {
        model = "prop_sponge_01",
        bone = 28422,
        coords = vector3(0.0, 0.0, -0.01),
        rotation = vector3(90.0, 0.0, 0.0)
    }

    Framework.Client.ProgressBar(Locale.cleaningVehicle, 3500, anim, prop, function()
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        Framework.Client.Notify(Locale.vehicleCleaned, "success")
        TriggerServerEvent("jg-mechanic:server:remove-item", "cleaning_kit")
    end, function() end)
end)

RegisterNetEvent("jg-mechanic:client:repair-vehicle", function()
    local hasItem = lib.callback.await("jg-mechanic:server:has-item", 250, "repair_kit")
    if not hasItem then return end

    local ped = cache.ped
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, true)
    
    if not vehicle then
        Framework.Client.Notify(Locale.noVehicleNearby, "error")
        return
    end

    if cache.vehicle then
        Framework.Client.Notify(Locale.leaveVehicleFirst, "error")
        return
    end

    playMinigame(vehicle, "prop", { prop = "spanner" }, function(success)
        if not success then return end
        
        local stillHasItem = lib.callback.await("jg-mechanic:server:has-item", false, "repair_kit")
        if not stillHasItem then return end

        Framework.Client.RepairVehicle(vehicle)
        Framework.Client.Notify(Locale.vehicleRepaired, "success")
        TriggerServerEvent("jg-mechanic:server:remove-item", "repair_kit")
    end)
end)

RegisterNetEvent("jg-mechanic:client:use-duct-tape", function()
    local hasItem = lib.callback.await("jg-mechanic:server:has-item", 250, "duct_tape")
    if not hasItem then return end

    local ped = cache.ped
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, true)
    
    if not vehicle then
        Framework.Client.Notify(Locale.noVehicleNearby, "error")
        return
    end

    local engineHealth = GetVehicleEngineHealth(vehicle)
    if engineHealth > Config.DuctTapeMinimumEngineHealth then
        Framework.Client.Notify(Locale.ductTapeEngineHealthTooHigh, "error")
        return
    end

    playMinigame(vehicle, "prop", { prop = "spanner" }, function(success)
        if not success then return end
        
        local stillHasItem = lib.callback.await("jg-mechanic:server:has-item", false, "duct_tape")
        if not stillHasItem then return end

        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineHealth(vehicle, engineHealth + Config.DuctTapeEngineHealthIncrease)
        Framework.Client.Notify(Locale.ductTapeUsed, "success")
        TriggerServerEvent("jg-mechanic:server:remove-item", "duct_tape")
    end)
end)