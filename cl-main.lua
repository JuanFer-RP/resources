
function setVehicleStatebag(vehicle, key, value, replicated, bag)
    return lib.callback.await("jg-mechanic:server:set-vehicle-statebag", false, VehToNet(vehicle), key, value, replicated, bag)
end


function setVehicleStatebags(vehicle, key, value, replicated)
    return lib.callback.await("jg-mechanic:server:set-vehicle-statebags", false, VehToNet(vehicle), key, value, replicated)
end


function playAnimation(ped, animDict, animName, flag)
    CreateThread(function()
        lib.requestAnimDict(animDict)
        
        if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
            local flagValue = flag and 33 or 49
            TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, flagValue, 0, false, false, false)
        end
    end)
end


function stopAnimation(ped)
    ClearPedTasks(ped)
end


function playTabletAnim()
    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local animName = "base"
    local tabletModel = -1585232418
    local boneIndex = 60309
    local offset = vector3(0.03, 0.002, 0.0)
    local rotation = vector3(10.0, 160.0, 0.0)
    
    CreateThread(function()
        lib.requestAnimDict(animDict)
        lib.requestModel(tabletModel, 3000)
        
        local playerPed = cache.ped
        Globals.HoldingTablet = CreateObject(tabletModel, 0.0, 0.0, 0.0, true, true, false)
        
        local bone = GetPedBoneIndex(playerPed, boneIndex)
        SetCurrentPedWeapon(playerPed, -1569615261, true)
        
        AttachEntityToEntity(
            Globals.HoldingTablet, 
            playerPed, 
            bone, 
            offset.x, offset.y, offset.z, 
            rotation.x, rotation.y, rotation.z, 
            true, false, false, false, 2, true
        )
        
        SetModelAsNoLongerNeeded(tabletModel)
        
        if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
            TaskPlayAnim(playerPed, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)
        end
    end)
end


function stopTabletAnim()
    if not Globals.HoldingTablet then
        return
    end
    
    ClearPedTasks(cache.ped)
    DetachEntity(Globals.HoldingTablet, true, false)
    DeleteEntity(Globals.HoldingTablet)
    Globals.HoldingTablet = nil
end


function createPedForTarget(model, coords)
    lib.requestModel(model)
    
    local ped = CreatePed(0, joaat(model), coords.x, coords.y, coords.z, coords.w or 0, false, false)
    
    lib.waitFor(function()
        if not DoesEntityExist(ped) then
            return nil
        end
        return ped
    end)
    
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, false)
    SetPedCanRagdoll(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetModelAsNoLongerNeeded(model)
    
    return ped
end


RegisterNUICallback("has-item", function(data, cb)
    local itemName = data.itemName
    local qty = data.qty
    
    local hasItem, itemData, itemCount, itemMetadata = lib.callback.await("jg-mechanic:server:has-item", false, itemName, qty)
    cb(hasItem, itemData, itemCount, itemMetadata)
end)

RegisterNUICallback("nearby-players", function(data, cb)
    local playerCoords = GetEntityCoords(cache.ped)
    local radius = 10.0
    
    local players, playerNames, playerIds, playerCoordsList, playerDistances = lib.callback.await(
        "jg-mechanic:server:nearby-players", 
        false, 
        playerCoords, 
        radius, 
        data and data.includePlayer or false
    )
    cb(players, playerNames, playerIds, playerCoordsList, playerDistances)
end)

RegisterNUICallback("get-player-balances", function(data, cb)
    local balances = {}
    balances.bank = Framework.Client.GetBalance("bank")
    balances.cash = Framework.Client.GetBalance("cash")
    cb(balances)
end)

RegisterNUICallback("close", function(data, cb)
    exitCamera()
    stopTabletAnim()
    SetNuiFocus(false, false)
    
    LocalPlayer.state:set("isBusy", false, true)
    
    if not Globals.HoldingTablet then
        Framework.Client.ToggleHud(true)
    end
    
    cb(true)
end)


CreateThread(function()
    while true do
        if cache.vehicle then
            local entity = Entity(cache.vehicle)
            if entity and entity.state and entity.state.unpaidModifications then
                if GetEntitySpeed(cache.vehicle) > 1.0 then
                    Framework.Client.Notify("This vehicle appears to have unpaid for modifications. It has been repossessed.")
                    DeleteEntity(cache.vehicle)
                end
            end
        end
        Wait(10000)
    end
end)
