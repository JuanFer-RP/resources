local activeTabletConnections = {}

-- Returns true if the given src is the active tablet connection for the plate
local function hasActiveTabletConnection(playerId, plate)
    local connection = activeTabletConnections[plate]
    if connection then
        return connection.src == playerId
    end
    return false
end
HasActiveTabletConnection = hasActiveTabletConnection

-- Connects a tablet to a vehicle (by plate+netId)
local function connectVehicle(playerId, plate, vehicleNetId)
    local existingConnection = activeTabletConnections[plate]
    if existingConnection and existingConnection.netId == vehicleNetId then
        return false
    end
    
    activeTabletConnections[plate] = {
        netId = vehicleNetId,
        src = playerId
    }
    
    return true
end
lib.callback.register("jg-mechanic:server:connect-vehicle", connectVehicle)

-- Disconnects a tablet from a vehicle (permission: only owner of connection)
local function disconnectVehicle(playerId, plate)
    local connection = activeTabletConnections[plate]
    if not connection then
        return true
    end
    
    if connection.src ~= playerId then
        return false
    end
    
    activeTabletConnections[plate] = nil
    return true
end
lib.callback.register("jg-mechanic:server:disconnect-vehicle", disconnectVehicle)

-- Returns a map of mechanicId -> label for mechanics the player can access
local function getPlayerMechanics(playerId)
    local availableMechanics = {}
    local isAdmin = Framework.Server.IsAdmin(playerId)
    local useFrameworkJobs = Config.UseFrameworkJobs
    
    if useFrameworkJobs then
        local playerJob = Framework.Server.GetPlayerJob(playerId)
        local mechanicData = MySQL.query.await("SELECT name, label FROM mechanic_data")
        
        for _, mechanic in pairs(mechanicData) do
            local mechanicConfig = Config.MechanicLocations[mechanic.name]
            if mechanicConfig then
                local adminsHavePermissions = Config.AdminsHaveEmployeePermissions
                if not adminsHavePermissions or not isAdmin then
                    if mechanicConfig.job ~= playerJob.name then
                        goto continue
                    end
                end
                
                local mechanicType = mechanicConfig.type
                if mechanicType == "owned" then
                    local label = mechanic.label ~= "" and mechanic.label or mechanic.name
                    availableMechanics[mechanic.name] = label
                end
            end
            ::continue::
        end
    else
        local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
        local mechanicData = MySQL.query.await(
            "SELECT d.*, e.identifier, e.role FROM mechanic_data d LEFT JOIN mechanic_employees e ON d.name = e.mechanic AND e.identifier = ?",
            {playerIdentifier}
        )
        
        for _, mechanic in pairs(mechanicData) do
            local mechanicConfig = Config.MechanicLocations[mechanic.name]
            if mechanicConfig then
                local adminsHavePermissions = Config.AdminsHaveEmployeePermissions
                if not adminsHavePermissions or not isAdmin then
                    if mechanic.owner_id ~= playerIdentifier then
                        if mechanic.role ~= "manager" and mechanic.role ~= "mechanic" then
                            goto continue
                        end
                    end
                end
                
                local mechanicType = mechanicConfig.type
                if mechanicType == "owned" then
                    local label = mechanic.label ~= "" and mechanic.label or mechanic.name
                    availableMechanics[mechanic.name] = label
                end
            end
            ::continue::
        end
    end
    
    return availableMechanics
end
lib.callback.register("jg-mechanic:server:get-player-mechanics", getPlayerMechanics)

-- Returns data/stats for tablet header for a specific mechanic
local function getTabletMechanicData(playerId, mechanicId)
    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end
    
    local mechanicData = MySQL.single.await("SELECT * FROM mechanic_data WHERE name = ?", {mechanicId})
    if not mechanicData then
        return false
    end
    
    local totalOrders = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ?", {mechanicId}) or 0
    local pendingOrders = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_orders WHERE mechanic = ? AND fulfilled = 0", {mechanicId}) or 0
    local totalInvoices = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_invoices WHERE mechanic = ?", {mechanicId}) or 0
    local unpaidInvoices = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_invoices WHERE paid = 0 AND mechanic = ?", {mechanicId}) or 0
    local totalEmployees = MySQL.scalar.await("SELECT COUNT(*) FROM mechanic_employees WHERE mechanic = ?", {mechanicId}) or 0
    
    return {
        label = mechanicData.label,
        balance = mechanicData.balance,
        ownerId = mechanicData.owner_id,
        ordersCount = pendingOrders,
        unpaidInvoicesCount = unpaidInvoices,
        employeeRole = isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true),
        stats = {
            totalOrders = totalOrders,
            totalInvoices = totalInvoices,
            totalEmployees = totalEmployees
        }
    }
end
lib.callback.register("jg-mechanic:server:get-tablet-mechanic-data", getTabletMechanicData)

-- Returns current vehicle mileage and unit
local function getVehicleMileage(playerId, vehicleNetId)
    return exports["jg-vehiclemileage"].GetMileage(vehicleNetId)
end
lib.callback.register("jg-mechanic:server:get-vehicle-mileage", getVehicleMileage)

-- Toggles player's on-duty status for a mechanic and updates GlobalState
local function toggleOnDuty(playerId, mechanicId)
    local player = Player(playerId).state
    if not player then
        return false
    end
    
    local playerMechanicId = player.mechanicId
    if not playerMechanicId then
        return false
    end
    
    if not isEmployee(playerId, playerMechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end
    
    local mechanicsOnDuty = GlobalState.mechanicsOnDuty or {}
    mechanicsOnDuty[tostring(playerId)] = mechanicId
    GlobalState.set("mechanicsOnDuty", mechanicsOnDuty, true)
    
    return true
end
lib.callback.register("jg-mechanic:server:toggle-on-duty", toggleOnDuty)

-- Checks if player is currently on duty for a mechanic
local function isOnDuty(playerId, mechanicId)
    if not GlobalState.mechanicsOnDuty then
        return false
    end
    
    return GlobalState.mechanicsOnDuty[tostring(playerId)] == mechanicId
end
lib.callback.register("jg-mechanic:server:is-on-duty", isOnDuty)

-- Returns saved tablet preferences for this player (or false if none)
local function getTabletPreferences(playerId)
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
    local preferences = MySQL.scalar.await(
        "SELECT preferences FROM mechanic_settings WHERE identifier = ?",
        {playerIdentifier}
    )
    
    if preferences then
        local decoded = json.decode(preferences)
        if decoded then
            return decoded
        end
    end
    
    return false
end
lib.callback.register("jg-mechanic:server:get-tablet-preferences", getTabletPreferences)

-- Saves tablet preferences for this player (permission-checked)
local function saveTabletSettings(playerId, settings)
    local player = Player(playerId).state
    if not player then
        return false
    end
    
    local mechanicId = player.mechanicId
    if not mechanicId then
        return false
    end
    
    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end
    
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
    MySQL.insert.await(
        "INSERT INTO mechanic_settings (identifier, preferences) VALUES(?, ?) ON DUPLICATE KEY UPDATE preferences = ?",
        {playerIdentifier, json.encode(settings), json.encode(settings)}
    )
    
    return true
end
lib.callback.register("jg-mechanic:server:save-tablet-settings", saveTabletSettings)

-- Register tablet command if enabled in config
if Config.UseTabletCommand ~= false then
    lib.addCommand(Config.UseTabletCommand or "tablet", {
        help = "Open mechanic tablet"
    }, function(playerId)
        TriggerClientEvent("jg-mechanic:client:use-tablet", playerId)
    end)
end