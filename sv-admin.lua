-- Register the admin command
lib.addCommand(Config.MechanicAdminCommand or "mechanicadmin", {
    help = Locale.mechanicAdminCmdDesc
}, function(source)
    -- Check if player is an admin
    if not Framework.Server.IsAdmin(source) then
        Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
        return
    end
    
    -- Open admin panel for the player
    TriggerClientEvent("jg-mechanic:client:open-admin", source)
end)

-- Register callback to get admin data
lib.callback.register("jg-mechanic:server:get-admin-data", function(source)
    -- Check if player is an admin
    if not Framework.Server.IsAdmin(source) then
        Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
        return false
    end
    
    -- Get all mechanic data from database
    local mechanicData = MySQL.query.await("SELECT * FROM mechanic_data")
    
    -- Enrich data with config information
    for i, mechanic in ipairs(mechanicData) do
        local config = Config.MechanicLocations[mechanic.name]
        local type = "-"
        local active = false
        
        if config then
            active = true
            type = config.type
        end
        
        mechanicData[i] = {
            name = mechanic.name,
            type = type,
            label = mechanic.label,
            balance = mechanic.balance,
            active = active,
            owner_id = mechanic.owner_id,
            owner_name = mechanic.owner_name,
            config = config
        }
    end
    
    return mechanicData
end)

-- Register callback to delete mechanic data
lib.callback.register("jg-mechanic:server:delete-mechanic-data", function(source, mechanicName)
    -- Check if player is an admin
    if not Framework.Server.IsAdmin(source) then
        Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
        return false
    end
    
    -- Delete all related data from database
    MySQL.query.await("DELETE FROM mechanic_employees WHERE mechanic = ?", {mechanicName})
    MySQL.query.await("DELETE FROM mechanic_servicing_history WHERE mechanic = ?", {mechanicName})
    MySQL.query.await("DELETE FROM mechanic_orders WHERE mechanic = ?", {mechanicName})
    MySQL.query.await("DELETE FROM mechanic_invoices WHERE mechanic = ?", {mechanicName})
    MySQL.query.await("DELETE FROM mechanic_data WHERE name = ?", {mechanicName})
    
    -- Send webhook notification
    sendWebhook(source, Webhooks.Admin, "Admin: Mechanic Data Deleted", "danger", {
        {key = "Mechanic", value = mechanicName}
    })
    
    return true
end)

-- Register callback to set mechanic owner
lib.callback.register("jg-mechanic:server:set-mechanic-owner", function(source, mechanicName, targetPlayerId)
    -- Check if player is an admin
    if not Framework.Server.IsAdmin(source) then
        Framework.Server.Notify(source, Locale.insufficientPermissions, "error")
        return false
    end
    
    -- Get target player info
    local targetIdentifier = Framework.Server.GetPlayerIdentifier(targetPlayerId)
    local targetInfo = Framework.Server.GetPlayerInfo(targetPlayerId)
    
    -- Check if target player exists
    if not targetInfo or not targetIdentifier then
        Framework.Server.Notify(source, Locale.playerNotOnline, "error")
        return false
    end
    
    -- Update mechanic owner in database
    local success = MySQL.update.await(
        "UPDATE mechanic_data SET owner_id = ?, owner_name = ? WHERE name = ?",
        {targetIdentifier, targetInfo.name, mechanicName}
    )
    
    if not success then
        return false
    end
    
    -- Refresh mechanic zones and blips for all players
    TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", -1)
    
    -- Send webhook notification
    sendWebhook(source, Webhooks.Admin, "Admin: Mechanic Owner Updated", nil, {
        {key = "Mechanic", value = mechanicName},
        {key = "Owner", value = targetInfo.name}
    })
    
    return true
end)