RegisterNUICallback("get-mechanic-orders", function(data, cb)
    local pageIndex = data.pageIndex
    local pageSize = data.pageSize
    local result = lib.callback.await("jg-mechanic:server:get-orders", false, pageIndex, pageSize)
    cb(result)
end)

RegisterNUICallback("mark-order-fulfilled", function(data, cb)
    local orderId = data.orderId
    local result = lib.callback.await("jg-mechanic:server:mark-order-fulfilled", false, orderId)
    cb(result)
end)

RegisterNUICallback("delete-order", function(data, cb)
    local orderId = data.orderId
    local result = lib.callback.await("jg-mechanic:server:delete-order", false, orderId)
    cb(result)
end)

RegisterNUICallback("orders-install-category", function(data, cb)
    local orderId = data.orderId
    local category = data.category
    
    local canApply = lib.callback.await("jg-mechanic:server:can-apply-order", false, orderId)
    if not canApply then
        return cb({ error = true })
    end
    
    local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
    if not vehicle or not DoesEntityExist(vehicle) then
        return cb(false)
    end
    
    local playerPlate = Framework.Client.GetPlate(vehicle)
    if playerPlate ~= canApply.plate then
        Framework.Client.Notify(Locale.vehPlateMismatch, "error")
        return cb({ error = true })
    end
    
    local minigameType = "prop"
    local minigameConfig = { prop = "spanner" }
    
    if category == "respray" then
        minigameType = "respray"
    elseif category == "wheels" then
        minigameConfig = { prop = "wheel" }
    end
    
    playMinigame(vehicle, minigameType, minigameConfig, function(success)
        showTabletAfterInteractionPrompt()
        SetNuiFocus(true, true)
        
        if not success then
            return cb(false)
        end
        
        local cartItems = json.decode(canApply.cart or "{}")[category]
        local itemCount = #tableKeys(cartItems)
        
        if not itemCount then
            return cb(false)
        end
        
        local paymentSuccess = lib.callback.await("jg-mechanic:server:pay-for-order-installation", false, category, itemCount)
        if not paymentSuccess then
            return cb(false)
        end
        
        if category == "repair" then
            Framework.Client.RepairVehicle(vehicle)
            Framework.Client.Notify(Locale.vehicleRepaired, "success")
        else
            local propsToApply = json.decode(canApply.props_to_apply or "{}")[category]
            if not propsToApply then
                return cb(false)
            end
            
            setVehicleProperties(vehicle, propsToApply, true)
            Entity(vehicle).state:set("applyVehicleProps", propsToApply, true)
            Framework.Client.Notify(Locale.installationSuccessful, "success")
            
            if Config.UpdatePropsOnChange then
                SetTimeout(1000, function()
                    lib.callback.await("jg-mechanic:server:save-vehicle-props", false, playerPlate, getVehicleProperties(vehicle))
                end)
            end
        end
        
        lib.callback.await("jg-mechanic:server:mark-category-installed", false, orderId, category)
        cb(true)
    end)
end)