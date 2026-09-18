
RegisterNUICallback("get-mechanic-balance", function(data, cb)
    cb(lib.callback.await("jg-mechanic:server:get-mechanic-balance", false, data.mechanicId))
end)

RegisterNUICallback("update-mechanic-balance", function(data, cb)
    local action = data.action
    local mechanicId = data.mechanicId
    local amount = data.amount
    local source = data.source

    if action == "deposit" then
        cb(lib.callback.await("jg-mechanic:server:mechanic-deposit", false, mechanicId, source, amount))
    elseif action == "withdraw" then
        cb(lib.callback.await("jg-mechanic:server:mechanic-withdraw", false, mechanicId, amount))
    else
        cb({ error = true })
    end
end)

RegisterNUICallback("get-mechanic-employees", function(data, cb)
    cb(lib.callback.await("jg-mechanic:server:get-mechanic-employees", false, data.mechanicId))
end)

RegisterNUICallback("update-mechanic-settings", function(data, cb)
    cb(lib.callback.await("jg-mechanic:server:update-mechanic-settings", false, data.mechanicId, data))
end)