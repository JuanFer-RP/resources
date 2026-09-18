
local currentInvoice = nil

RegisterNUICallback("get-unpaid-invoices", function(data, cb)
    cb(lib.callback.await("jg-mechanic:server:get-unpaid-invoices", false))
end)

RegisterNUICallback("save-invoice", function(data, cb)
    if not data.invoiceItems or not data.invoiceTotal then
        return cb(false)
    end
    
    cb(lib.callback.await("jg-mechanic:server:save-invoice", false, data.invoiceItems, data.invoiceTotal))
end)

RegisterNUICallback("send-invoice", function(data, cb)
    if not data.player or not data.invoiceItems then
        return cb(false)
    end
    
    cb(lib.callback.await("jg-mechanic:server:send-invoice", false, data.player, data.invoiceItems, data.invoiceTotal))
end)

RegisterNUICallback("resend-invoice", function(data, cb)
    if not data.player or not data.invoiceId then
        return cb(false)
    end
    
    cb(lib.callback.await("jg-mechanic:server:resend-invoice", false, data.player, data.invoiceId))
end)

RegisterNUICallback("delete-invoice", function(data, cb)
    cb(lib.callback.await("jg-mechanic:server:delete-invoice", false, data.invoiceId))
end)

RegisterNUICallback("pay-invoice", function(data, cb)
    if not currentInvoice then
        return cb({ error = true })
    end

    local success = lib.callback.await("jg-mechanic:server:pay-invoice", false, 
        currentInvoice.invoiceId, currentInvoice.senderPlayerId, data.paymentMethod)
    
    if not success then
        return cb({ error = true })
    end

    currentInvoice = nil
    cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-invoice-to-player", function(senderId, invoiceId, invoiceItems, invoiceTotal)
    currentInvoice = {
        invoiceId = invoiceId,
        senderPlayerId = senderId
    }

    if cache.serverId == senderId then
        DisconnectVehicle()
        LocalPlayer.state:set("mechanicId", nil, true)
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "show-invoice",
        invoiceItems = invoiceItems,
        invoiceTotal = invoiceTotal,
        bankBalance = Framework.Client.GetBalance("bank"),
        cashBalance = Framework.Client.GetBalance("cash"),
        locale = Locale,
        config = Config
    })
end)