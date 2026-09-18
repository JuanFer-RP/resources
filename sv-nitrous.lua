local function isNitrousInstalled(playerId, vehicleState)
    if not vehicleState.nitrousInstalledBottles or vehicleState.nitrousInstalledBottles == 0 then
        Framework.Server.Notify(playerId, Locale.nitrousNotInstalled, "error")
        return false
    end
    return true
end

local function canReplaceNitrousBottle(playerId, vehicleState)
    vehicleState = vehicleState or {}

    local installed = tonumber(vehicleState.nitrousInstalledBottles) or 0
    local filled = tonumber(vehicleState.nitrousFilledBottles) or 0
    local capacity = tonumber(vehicleState.nitrousCapacity) or 0

    if installed ~= filled or (installed == filled and capacity > 0) then
        return true
    end

    Framework.Server.Notify(playerId, Locale.noEmptyNitrousBottlesToReplace, "error")
    return false
end

local function replaceNitrousBottle(playerId, vehicleNetId)
    if not vehicleNetId or vehicleNetId == 0 then
        return false
    end

    local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicleEntity or vehicleEntity == 0 then
        return false
    end

    local vehicleState = (Entity(vehicleEntity) and Entity(vehicleEntity).state) or {}
    if not isNitrousInstalled(playerId, vehicleState) then
        return false
    end

    if not canReplaceNitrousBottle(playerId, vehicleState) then
        return false
    end

    if not Framework.Server.RemoveItem(playerId, "nitrous_bottle") then
        Framework.Server.Notify(playerId, Locale.couldNotRemoveNitrousInvItem, "error")
        return false
    end

    local newFilled = (vehicleState.nitrousFilledBottles or 0) + 1
    setVehicleStatebag(vehicleEntity, "nitrousFilledBottles", newFilled, true)

    if not Framework.Server.GiveItem(playerId, "empty_nitrous_bottle") then
        Framework.Server.Notify(playerId, Locale.couldNotGiveNitrousInvItem, "error")
        return false
    end

    Framework.Server.Notify(playerId, Locale.nitrousBottleInstalled, "success")
    return true
end

RegisterNetEvent("jg-mechanic:server:use-nitrous-bottle", function()
    local playerId = source
    local ped = GetPlayerPed(playerId)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        Framework.Server.Notify(playerId, Locale.notInsideVehicle, "error")
        return
    end
    
    replaceNitrousBottle(playerId, vehicle)
end)

lib.callback.register("jg-mechanic:server:can-refill-bottle-in-current-vehicle", function(playerId)
    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        Framework.Server.Notify(playerId, Locale.notInsideVehicle, "error")
        return false
    end

    local vehicleState = Entity(vehicle).state
    return isNitrousInstalled(playerId, vehicleState) and canReplaceNitrousBottle(playerId, vehicleState)
end)

lib.callback.register("jg-mechanic:server:refill-nitrous-bottle", function(playerId)
    local player = Player(playerId).state
    if not player or not player.mechanicId then
        return false
    end

    if not isEmployee(playerId, player.mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local vehicleNetId = player.tabletConnectedVehicle and player.tabletConnectedVehicle.netId
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if not vehicle or vehicle == 0 then
        return false
    end

    return replaceNitrousBottle(playerId, vehicle)
end)

lib.callback.register("jg-mechanic:server:install-new-bottle", function(playerId)
    local playerObj = Player(playerId)
    local player = playerObj and playerObj.state
    if not player or not player.mechanicId then
        return false
    end

    if not isEmployee(playerId, player.mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local vehicleNetId = player.tabletConnectedVehicle and player.tabletConnectedVehicle.netId
    if not vehicleNetId then
        return false
    end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 then
        return false
    end

    local vehicleState = (Entity(vehicle) and Entity(vehicle).state) or {}
    if vehicleState.nitrousInstalledBottles and vehicleState.nitrousInstalledBottles >= Config.NitrousMaxBottlesPerVehicle then
        Framework.Server.Notify(playerId, Locale.maxBottlesInstalled, "error")
        return false
    end

    if not Framework.Server.RemoveItem(playerId, "nitrous_install_kit") then
        Framework.Server.Notify(playerId, Locale.couldNotRemoveNitrousInstallInvItem, "error")
        return false
    end

    local newInstalledBottles = (vehicleState.nitrousInstalledBottles or 0) + 1
    setVehicleStatebag(vehicle, "nitrousInstalledBottles", newInstalledBottles, true)

    local newFilledBottles = (vehicleState.nitrousFilledBottles or 0) + 1
    setVehicleStatebag(vehicle, "nitrousFilledBottles", newFilledBottles, true)

    return true
end)