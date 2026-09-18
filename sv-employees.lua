function isEmployee(source, mechanicId, requiredRole, isAdminCheck)
    -- Check if admins have employee permissions
    if isAdminCheck and Config.AdminsHaveEmployeePermissions then
        if Framework.Server.IsAdmin(source) then
            return "server_admin"
        end
    end

    -- Using framework jobs system
    if Config.UseFrameworkJobs then
        local mechanicConfig = Config.MechanicLocations[mechanicId]
        if not mechanicConfig then return false end
        
        local playerJob = Framework.Server.GetPlayerJob(source)
        if not playerJob then return false end
        
        -- Check if player has the correct job
        if playerJob.name == mechanicConfig.job then
            local role = "mechanic"
            
            -- Check if player has management rank
            if mechanicConfig.jobManagementRanks and 
               lib.table.contains(mechanicConfig.jobManagementRanks, playerJob.grade) then
                role = "manager"
            end
            
            -- Validate required role
            if requiredRole then
                if type(requiredRole) == "string" then
                    if requiredRole ~= role then return false end
                elseif type(requiredRole) == "table" then
                    if not lib.table.contains(requiredRole, role) then return false end
                end
            end
            
            return role
        end
    else
        -- Using custom database system
        local identifier = Framework.Server.GetPlayerIdentifier(source)
        if not identifier then return false end
        
        -- Check if player is the owner
        local ownerCheck = MySQL.single.await(
            "SELECT name FROM mechanic_data WHERE name = ? AND owner_id = ?", 
            {mechanicId, identifier}
        )
        if ownerCheck then
            return "owner"
        end
        
        -- Check if player is an employee
        local employeeCheck = MySQL.single.await(
            "SELECT role FROM mechanic_employees WHERE identifier = ? AND mechanic = ?", 
            {identifier, mechanicId}
        )
        
        if not employeeCheck then return false end
        local role = employeeCheck.role
        
        -- Validate required role
        if requiredRole then
            if type(requiredRole) == "string" then
                if requiredRole ~= role then return false end
            elseif type(requiredRole) == "table" then
                if not lib.table.contains(requiredRole, role) then return false end
            end
        end
        
        return role
    end
    
    return false
end

lib.callback.register("jg-mechanic:server:is-mechanic-employee", function(source, mechanicId)
    return isEmployee(source, mechanicId, {"owner", "manager", "mechanic"}, true)
end)

RegisterNetEvent("jg-mechanic:server:request-hire-employee", function(data)
    local source = source
    data.requesterId = source
    
    -- Check if requester is a manager
    local isManager = isEmployee(source, data.mechanicId, "manager", true)
    if not isManager then
        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
        return
    end
    
    -- Send employment offer to target player
    TriggerClientEvent("jg-mechanic:client:show-confirm-employment", data.playerId, data)
end)

RegisterNetEvent("jg-mechanic:server:employee-hire-rejected", function(playerId)
    Framework.Server.Notify(playerId, Locale.employeeRejectedMsg, "error")
end)

RegisterNetEvent("jg-mechanic:server:hire-employee", function(data)
    local source = source
    
    -- Insert employee record into database
    local identifier = Framework.Server.GetPlayerIdentifier(data.playerId)
    MySQL.insert.await(
        "INSERT INTO mechanic_employees (identifier, mechanic, role) VALUES (?, ?, ?)",
        {identifier, data.mechanicId, data.role}
    )
    
    -- Update player job if using framework jobs
    local mechanicConfig = Config.MechanicLocations[data.mechanicId]
    if mechanicConfig and mechanicConfig.job then
        Framework.Server.PlayerSetJob(data.playerId, mechanicConfig.job, data.role)
    end
    
    -- Get player info for webhook
    local playerInfo = Framework.Server.GetPlayerInfo(data.playerId)
    local playerName = playerInfo and playerInfo.name or identifier
    
    -- Send webhook notification
    sendWebhook(
        source,
        Webhooks.Mechanic,
        "Mechanic: Employee Hired",
        "success",
        {
            {key = "mechanic", value = data.mechanicId},
            {key = "Employee", value = playerName},
            {key = "Role", value = data.role}
        }
    )
    
    -- Notify requester
    Framework.Server.Notify(data.requesterId, Locale.employeeHiredMsg, "success")
    
    -- Refresh mechanic zones for all players
    TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", -1)
end)

RegisterNetEvent("jg-mechanic:server:fire-employee", function(identifier, mechanicId)
    local source = source
    
    -- Check if requester is a manager
    local isManager = isEmployee(source, mechanicId, "manager", true)
    if not isManager then
        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
        return
    end
    
    -- Remove employee from database
    MySQL.insert.await(
        "DELETE FROM mechanic_employees WHERE identifier = ? AND mechanic = ?",
        {identifier, mechanicId}
    )
    
    -- Update player job
    local player = Framework.Server.GetPlayerFromIdentifier(identifier)
    if player then
        Framework.Server.PlayerSetJob(player, "unemployed", 0)
        
        -- Notify fired employee
        Framework.Server.Notify(
            player, 
            string.gsub(Locale.firedNotification, "%%{value}", mechanicId), 
            "error"
        )
        
        -- Refresh mechanic zones for fired employee
        TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", player)
    else
        Framework.Server.PlayerSetJobOffline(identifier, "unemployed", 0)
    end
    
    -- Get player info for webhook
    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
    local playerName = playerInfo and playerInfo.name or identifier
    
    -- Send webhook notification
    sendWebhook(
        source,
        Webhooks.Mechanic,
        "Mechanic: Employee Fired",
        "danger",
        {
            {key = "mechanic", value = mechanicId},
            {key = "Employee", value = playerName}
        }
    )
end)

RegisterNetEvent("jg-mechanic:server:update-employee-role", function(identifier, mechanicId, newRole)
    local source = source
    
    -- Check if requester is a manager
    local isManager = isEmployee(source, mechanicId, "manager", true)
    if not isManager then
        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
        return
    end
    
    -- Update employee role in database
    MySQL.insert.await(
        "UPDATE mechanic_employees SET role = ? WHERE identifier = ? AND mechanic = ?",
        {newRole, identifier, mechanicId}
    )
    
    -- Update player job if using framework jobs
    local mechanicConfig = Config.MechanicLocations[mechanicId]
    if mechanicConfig and mechanicConfig.job then
        local player = Framework.Server.GetPlayerFromIdentifier(identifier)
        if player then
            Framework.Server.PlayerSetJob(player, mechanicConfig.job, newRole)
            TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", player)
        else
            Framework.Server.PlayerSetJobOffline(identifier, mechanicConfig.job, newRole)
        end
    end
    
    -- Get player info for webhook
    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)
    local playerName = playerInfo and playerInfo.name or identifier
    
    -- Send webhook notification
    sendWebhook(
        source,
        Webhooks.Mechanic,
        "Mechanic: Employee Updated",
        nil,
        {
            {key = "mechanic", value = mechanicId},
            {key = "Employee", value = playerName},
            {key = "New role", value = newRole}
        }
    )
end)