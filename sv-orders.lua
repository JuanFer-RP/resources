local processingOrders = {}

lib.callback.register("jg-mechanic:server:get-orders", function(playerId, page, pageSize)
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        return {}
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return {}
    end

    local orders = MySQL.query.await(
        "SELECT * FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0 ORDER BY date DESC LIMIT ? OFFSET ?",
        {mechanicId, pageSize, page * pageSize}
    )

    for _, order in ipairs(orders) do
        local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(order.identifier)
        order.recipient = playerInfo and playerInfo.name or "-"
    end

    local totalOrders = MySQL.scalar.await(
        "SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0",
        {mechanicId}
    )
    
    local pageCount = math.ceil(totalOrders / pageSize)
    
    return {
        orders = orders,
        pageCount = pageCount,
        totalOrders = totalOrders
    }
end)

lib.callback.register("jg-mechanic:server:can-apply-order", function(playerId, orderId)
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    return MySQL.single.await(
        "SELECT * FROM mechanic_orders WHERE id = ? AND mechanic = ? AND fulfilled = 0",
        {orderId, mechanicId}
    )
end)

lib.callback.register("jg-mechanic:server:pay-for-order-installation", function(playerId, modName, quantity)
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        return false
    end

    local modConfig = Config.Mods.ItemsRequired[modName]
    if not modConfig or not modConfig.itemName then
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    if modConfig.removeItem then
        local removeQuantity = quantity or 1
        if not Framework.Server.RemoveItem(playerId, modConfig.itemName, removeQuantity) then
            return false
        end
    end

    return true
end)

lib.callback.register("jg-mechanic:server:mark-category-installed", function(playerId, orderId, category)
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local progressJson = MySQL.scalar.await(
        "SELECT installation_progress FROM mechanic_orders WHERE id = ? AND mechanic = ? AND fulfilled = 0",
        {orderId, mechanicId}
    )
    
    local progress = progressJson and json.decode(progressJson) or {}
    if type(progress) ~= "table" then
        progress = {}
    end

    progress[category] = true
    
    MySQL.update.await(
        "UPDATE mechanic_orders SET installation_progress = ? WHERE id = ? AND mechanic = ?",
        {json.encode(progress), orderId, mechanicId}
    )
    
    return true
end)

lib.callback.register("jg-mechanic:server:mark-order-fulfilled", function(playerId, orderId)
    if processingOrders[orderId] then
        return false
    end
    
    processingOrders[orderId] = true
    
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        processingOrders[orderId] = nil
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        processingOrders[orderId] = nil
        return false
    end

    local mechanicConfig = Config.MechanicLocations[mechanicId]
    if not mechanicConfig then
        processingOrders[orderId] = nil
        return false
    end

    local amountPaid = MySQL.scalar.await(
        "SELECT amount_paid FROM mechanic_orders WHERE id = ? AND fulfilled = 0",
        {orderId}
    )
    
    if not amountPaid then
        debugPrint(string.format("Order could not be found in mechanic_orders - id: %s", orderId), "warning")
        processingOrders[orderId] = nil
        return false
    end

    local commissionRate = (mechanicConfig.commission or 0)
    local commissionAmount = math.floor(amountPaid * (commissionRate / 100))
    
    debugPrint("Mechanic ID: " .. mechanicId, "debug")
    debugPrint("Order ID: " .. orderId, "debug")
    debugPrint("Order Amount: " .. amountPaid, "debug")
    debugPrint("Commission Percentage: " .. commissionRate, "debug")
    debugPrint("Commission Amount: " .. commissionAmount, "debug")
    debugPrint("Society Name: " .. (mechanicConfig.job or "N/A"), "debug")

    if commissionAmount > 0 then
        removeFromSocietyFund(playerId, mechanicId, commissionAmount)
        Framework.Server.PlayerAddMoney(playerId, commissionAmount, "bank")
        Framework.Server.Notify(playerId, "Commission paid", "success")
    else
        debugPrint("Invalid commission amount. Skipping the removal of money...", "warning")
    end

    MySQL.update.await(
        "UPDATE mechanic_orders SET fulfilled = 1 WHERE mechanic = ? AND id = ?",
        {mechanicId, orderId}
    )

    sendWebhook(
        playerId,
        Webhooks.Orders,
        "Orders: Order Marked as Fulfilled",
        "default",
        {
            {key = "Mechanic", value = mechanicId},
            {key = "Order #", value = orderId},
            {key = "Commission Earned", value = commissionAmount}
        }
    )
    
    processingOrders[orderId] = nil
    return true
end)

lib.callback.register("jg-mechanic:server:delete-order", function(playerId, orderId)
    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    if not mechanicId then
        return false
    end

    local requiredRoles = Config.RequireManagementForOrderDeletion and {"manager"} or {"mechanic", "manager"}
    if not isEmployee(playerId, mechanicId, requiredRoles, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local order = MySQL.single.await(
        "SELECT identifier, amount_paid FROM mechanic_orders WHERE fulfilled = 0 AND id = ?",
        {orderId}
    )
    
    if not order then
        Framework.Server.Notify(playerId, "NO_UNFULFILLED_ORDER", "error")
        return false
    end

    if order.amount_paid < 0 then
        return false
    end

    if not removeFromSocietyFund(playerId, mechanicId, order.amount_paid) then
        return false
    end

    Framework.Server.PlayerAddMoneyOffline(order.identifier, order.amount_paid)
    
    MySQL.update.await(
        "UPDATE mechanic_orders SET fulfilled = 1 WHERE mechanic = ? AND id = ?",
        {mechanicId, orderId}
    )

    sendWebhook(
        playerId,
        Webhooks.Orders,
        "Orders: Order Deleted",
        "default",
        {
            {key = "Mechanic", value = mechanicId},
            {key = "Order #", value = orderId},
            {key = "Amount Refunded", value = order.amount_paid}
        }
    )
    
    return true
end)