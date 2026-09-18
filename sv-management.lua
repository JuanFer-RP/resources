function getSocietyFund(playerId, mechanicName)
    if Config.UseFrameworkJobs then
        local jobName = Config.MechanicLocations[mechanicName] and Config.MechanicLocations[mechanicName].job
        if not jobName then
            return 0
        end
        local balance = Framework.Server.GetSocietyBalance(jobName, "job")
        return balance or 0
    else
        local balance = MySQL.scalar.await(
            "SELECT balance FROM mechanic_data WHERE name = ?",
            {mechanicName}
        )
        return balance or 0
    end
end

function addToSocietyFund(playerId, mechanicName, amount)
    if not amount or amount < 0 then
        return false
    end

    if Config.UseFrameworkJobs then
        local jobName = Config.MechanicLocations[mechanicName] and Config.MechanicLocations[mechanicName].job
        if not jobName then
            return false
        end
        Framework.Server.PayIntoSocietyFund(jobName, "job", amount)
    else
        MySQL.update.await(
            "UPDATE mechanic_data SET balance = balance + ? WHERE name = ?",
            {amount, mechanicName}
        )
    end
    return true
end

function removeFromSocietyFund(playerId, mechanicName, amount)
    if not amount or amount < 0 then
        return false
    end

    if Config.UseFrameworkJobs then
        local jobName = Config.MechanicLocations[mechanicName] and Config.MechanicLocations[mechanicName].job
        if not jobName then
            return false
        end
        local balance = Framework.Server.GetSocietyBalance(jobName, "job")
        if amount > balance then
            Framework.Server.Notify(playerId, Locale.notEnoughMoney, "error")
            return false
        end
        Framework.Server.RemoveFromSocietyFund(jobName, "job", amount)
    else
        local balance = MySQL.scalar.await(
            "SELECT balance FROM mechanic_data WHERE name = ?",
            {mechanicName}
        )
        if amount > balance then
            Framework.Server.Notify(playerId, Locale.notEnoughMoney, "error")
            return false
        end
        MySQL.update.await(
            "UPDATE mechanic_data SET balance = balance - ? WHERE name = ?",
            {amount, mechanicName}
        )
    end
    return true
end

lib.callback.register("jg-mechanic:server:get-mechanic-balance", function(playerId, mechanicName)
    if not isEmployee(playerId, mechanicName, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end
    return getSocietyFund(playerId, mechanicName)
end)

lib.callback.register("jg-mechanic:server:get-mechanic-employees", function(playerId, mechanicName)
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
    
    if Config.UseFrameworkJobs then
        return {}
    end

    if not isEmployee(playerId, mechanicName, "manager", true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local employees = MySQL.query.await(
        "SELECT * FROM mechanic_employees WHERE mechanic = ?",
        {mechanicName}
    )

    for i, employee in ipairs(employees) do
        local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(employee.identifier)
        employees[i] = {
            id = employee.player,
            identifier = employee.identifier,
            name = playerInfo and playerInfo.name or "-",
            role = employee.role,
            joined = employee.joined,
            me = (playerIdentifier == employee.identifier)
        }
    end

    return employees
end)

lib.callback.register("jg-mechanic:server:mechanic-deposit", function(playerId, mechanicName, paymentMethod, amount)
    if not isEmployee(playerId, mechanicName, "manager", true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    if amount < 0 then
        Framework.Server.Notify(playerId, "Stop trying to exploit the script", "error")
        return false
    end

    local playerBalance = Framework.Server.GetPlayerBalance(playerId, paymentMethod)
    if amount > playerBalance then
        Framework.Server.Notify(playerId, Locale.notEnoughMoney, "error")
        return false
    end

    Framework.Server.PlayerRemoveMoney(playerId, amount, paymentMethod)
    MySQL.update.await(
        "UPDATE mechanic_data SET balance = balance + ? WHERE name = ?",
        {amount, mechanicName}
    )

    Framework.Server.Notify(playerId, Locale.depositSuccess, "success")
    sendWebhook(
        playerId,
        Webhooks.Mechanic,
        "Mechanic: Money Deposited",
        nil,
        {
            {key = "Mechanic", value = mechanicName},
            {key = "Amount", value = amount}
        }
    )
    return true
end)

lib.callback.register("jg-mechanic:server:mechanic-withdraw", function(playerId, mechanicName, amount)
    if not isEmployee(playerId, mechanicName, "manager", true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    if amount < 0 then
        Framework.Server.Notify(playerId, "Stop trying to exploit the script", "error")
        return false
    end

    local mechanicData = MySQL.single.await(
        "SELECT * FROM mechanic_data WHERE name = ?",
        {mechanicName}
    )
    if not mechanicData then
        return false
    end

    if amount > mechanicData.balance then
        Framework.Server.Notify(playerId, string.format(Locale.insufficientFunds, amount), "error")
        return false
    end

    Framework.Server.PlayerAddMoney(playerId, amount, "bank")
    MySQL.update.await(
        "UPDATE mechanic_data SET balance = balance - ? WHERE name = ?",
        {amount, mechanicName}
    )

    Framework.Server.Notify(playerId, Locale.withdrawSuccess, "success")
    sendWebhook(
        playerId,
        Webhooks.Mechanic,
        "Mechanic: Money Withdraw",
        nil,
        {
            {key = "Mechanic", value = mechanicName},
            {key = "Amount", value = amount}
        }
    )
    return true
end)

lib.callback.register("jg-mechanic:server:update-mechanic-settings", function(playerId, mechanicName, settings)
    if not isEmployee(playerId, mechanicName, "manager", true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    MySQL.update.await(
        "UPDATE mechanic_data SET label = ? WHERE name = ?",
        {settings.label, mechanicName}
    )

    TriggerClientEvent("jg-mechanic:client:refresh-mechanic-zones-and-blips", -1)
    sendWebhook(
        playerId,
        Webhooks.Mechanic,
        "Mechanic: Name Updated",
        nil,
        {
            {key = "Mechanic", value = mechanicName},
            {key = "New name", value = settings.label}
        }
    )
    return true
end)