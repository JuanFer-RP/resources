local function getMechanicIdIfEmployee(playerId)
    local player = Player(playerId)
    local mechanicId = player.state.mechanicId
    if not mechanicId then
        return false
    end

    local isEmployeeResult = isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true)
    if not isEmployeeResult then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    return mechanicId
end

local function insertInvoice(identifier, mechanic, total, data)
    local encodedData = json.encode(data)
    return MySQL.insert.await(
        "INSERT INTO mechanic_invoices (identifier, mechanic, total, data) VALUES(?, ?, ?, ?)",
        {identifier, mechanic, total, encodedData}
    )
end

lib.callback.register("jg-mechanic:server:get-unpaid-invoices", function(playerId)
    local mechanicId = getMechanicIdIfEmployee(playerId)
    if not mechanicId then
        return false
    end

    local invoices = MySQL.query.await(
        "SELECT * FROM mechanic_invoices WHERE mechanic = ? AND paid = 0 ORDER BY date DESC",
        {mechanicId}
    )

    for _, invoice in ipairs(invoices) do
        local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(invoice.identifier)
        invoice.recipient = playerInfo and playerInfo.name or "-"
    end

    return invoices
end)

lib.callback.register("jg-mechanic:server:send-invoice", function(playerId, targetId, invoiceItems, totalAmount)
    local mechanicId = getMechanicIdIfEmployee(playerId)
    if not mechanicId then
        return false
    end

    local targetIdentifier = Framework.Server.GetPlayerIdentifier(targetId)
    if not targetIdentifier then
        return false
    end

    local targetPlayer = Player(targetId)
    if targetPlayer.state and targetPlayer.state.isBusy and playerId ~= targetId then
        Framework.Server.Notify(playerId, Locale.playerIsBusy, "error")
        return false
    end

    local invoiceId = insertInvoice(targetIdentifier, mechanicId, totalAmount, invoiceItems)
    if not invoiceId then
        return false
    end

    local formattedItems = {}
    for _, item in ipairs(invoiceItems) do
        formattedItems[#formattedItems + 1] = string.format("%s (%d)", item.title, item.amount)
    end

    TriggerClientEvent(
        "jg-mechanic:client:show-invoice-to-player",
        targetId,
        playerId,
        invoiceId,
        invoiceItems,
        totalAmount
    )

    local webhookFields = {
        {key = "Mechanic", value = mechanicId},
        {key = "Invoice #", value = invoiceId},
        {key = "Recipient", value = (Framework.Server.GetPlayerInfo(targetId) or {name = targetId}).name},
        {key = "Total", value = totalAmount},
        {key = "Breakdown", value = table.concat(formattedItems, ", ")}
    }
    sendWebhook(playerId, Webhooks.Invoices, "Invoices: Invoice Sent", "success", webhookFields)

    return true
end)

lib.callback.register("jg-mechanic:server:resend-invoice", function(playerId, targetId, invoiceId)
    local mechanicId = getMechanicIdIfEmployee(playerId)
    if not mechanicId then
        return false
    end

    local targetIdentifier = Framework.Server.GetPlayerIdentifier(targetId)
    if not targetIdentifier then
        return false
    end

    local targetPlayer = Player(targetId)
    if targetPlayer.state and targetPlayer.state.isBusy then
        Framework.Server.Notify(playerId, Locale.playerIsBusy, "error")
        return false
    end

    local invoice = MySQL.single.await(
        "SELECT * FROM mechanic_invoices WHERE id = ? AND mechanic = ?",
        {invoiceId, mechanicId}
    )
    if not invoice then
        return false
    end

    MySQL.update.await(
        "UPDATE mechanic_invoices SET identifier = ? WHERE id = ? AND mechanic = ?",
        {targetIdentifier, invoiceId, mechanicId}
    )

    local invoiceData = json.decode(invoice.data)
    TriggerClientEvent(
        "jg-mechanic:client:show-invoice-to-player",
        targetId,
        playerId,
        invoiceId,
        invoiceData,
        invoice.total
    )

    local formattedItems = {}
    for _, item in ipairs(invoiceData) do
        formattedItems[#formattedItems + 1] = string.format("%s (%d)", item.title, item.amount)
    end

    local webhookFields = {
        {key = "Mechanic", value = mechanicId},
        {key = "Invoice #", value = invoiceId},
        {key = "Recipient", value = (Framework.Server.GetPlayerInfo(targetId) or {name = targetId}).name},
        {key = "Total", value = invoice.total},
        {key = "Breakdown", value = table.concat(formattedItems, ", ")}
    }
    sendWebhook(playerId, Webhooks.Invoices, "Invoices: Invoice Re-sent", "success", webhookFields)

    return true
end)

lib.callback.register("jg-mechanic:server:save-invoice", function(playerId, invoiceItems, totalAmount)
    local mechanicId = getMechanicIdIfEmployee(playerId)
    if not mechanicId then
        return false
    end

    return insertInvoice(nil, mechanicId, totalAmount, invoiceItems)
end)

lib.callback.register("jg-mechanic:server:delete-invoice", function(playerId, invoiceId)
    local mechanicId = getMechanicIdIfEmployee(playerId)
    if not mechanicId then
        return false
    end

    MySQL.update.await(
        "DELETE FROM mechanic_invoices WHERE id = ? AND mechanic = ?",
        {invoiceId, mechanicId}
    )

    sendWebhook(
        playerId,
        Webhooks.Invoices,
        "Invoices: Invoice Deleted",
        "danger",
        {
            {key = "Mechanic", value = mechanicId},
            {key = "Invoice #", value = invoiceId}
        }
    )

    return true
end)

lib.callback.register("jg-mechanic:server:pay-invoice", function(playerId, invoiceId, senderId, paymentMethod)
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)
    if not playerIdentifier then
        debugPrint("Failed to get identifier for src: " .. playerId, "warning")
        return false
    end

    local invoice = MySQL.single.await(
        "SELECT * FROM mechanic_invoices WHERE id = ? AND identifier = ?",
        {invoiceId, playerIdentifier}
    )
    if not invoice or invoice.total <= 0 then
        debugPrint("Invalid or unpaid invoice. ID: " .. invoiceId .. " Identifier: " .. playerIdentifier, "warning")
        return false
    end

    if paymentMethod ~= "bank" and paymentMethod ~= "cash" then
        debugPrint("Invalid payment method:" .. paymentMethod, "warning")
        Framework.Server.Notify(playerId, "INVALID_PAYMENT_METHOD", "error")
        return false
    end

    local playerBalance = Framework.Server.GetPlayerBalance(playerId, paymentMethod)
    debugPrint("Player balance for " .. paymentMethod .. " is " .. playerBalance, "debug")

    if playerBalance < invoice.total then
        Framework.Server.Notify(playerId, Locale.notEnoughMoney, "error")
        return false
    end

    Framework.Server.PlayerRemoveMoney(playerId, invoice.total, paymentMethod)
    debugPrint("Deducted " .. invoice.total .. " from player " .. playerId, "debug")

    local commissionRate = (Config.MechanicLocations[invoice.mechanic] or {}).commission or 0
    debugPrint("Commission rate for " .. invoice.mechanic .. " is " .. commissionRate .. "%", "debug")

    local commission = math.floor(invoice.total * (commissionRate / 100))
    debugPrint("Calculated commission: " .. commission, "debug")

    local societyContribution = invoice.total
    if commission > 0 and senderId and senderId ~= playerId then
        societyContribution = invoice.total - commission
        Framework.Server.PlayerAddMoney(senderId, commission, "bank")
        debugPrint("Paid commission of " .. commission .. " to sender " .. senderId)
    end

    addToSocietyFund(playerId, invoice.mechanic, societyContribution)
    debugPrint("Society fund contribution for " .. invoice.mechanic .. " is " .. societyContribution, "debug")

    MySQL.update.await(
        "UPDATE mechanic_invoices SET paid = 1 WHERE id = ? AND identifier = ?",
        {invoiceId, playerIdentifier}
    )
    debugPrint("Marked invoice as paid. ID: " .. invoiceId, "debug")

    Framework.Server.Notify(senderId, Locale.invoicePaid, "success")

    sendWebhook(
        playerId,
        Webhooks.Invoices,
        "Invoices: Invoice Paid",
        "success",
        {
            {key = "Mechanic", value = invoice.mechanic},
            {key = "Invoice #", value = invoiceId},
            {key = "Total", value = invoice.total},
            {key = "Commission", value = commission},
            {key = "Payment Method", value = paymentMethod}
        }
    )

    return true
end)