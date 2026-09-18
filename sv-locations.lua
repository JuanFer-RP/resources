lib.callback.register("jg-mechanic:server:get-mechanic-locations-data", function()
    return MySQL.query.await("SELECT * FROM mechanic_data")
end)