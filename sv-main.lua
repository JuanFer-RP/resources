lib.callback.register("jg-mechanic:server:nearby-players", function(playerId, coords, radius, includeSelf)
    local nearbyPlayers = lib.getNearbyPlayers(coords, radius)
    local result = {}

    for _, player in ipairs(nearbyPlayers) do
        if not includeSelf and playerId == player.id then
            goto continue
        end

        local playerInfo = Framework.Server.GetPlayerInfo(player.id)
        result[#result + 1] = {
            id = player.id,
            name = playerInfo and playerInfo.name
        }

        ::continue::
    end

    return result
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    initSQL()

    for locationName, _ in pairs(Config.MechanicLocations) do
        MySQL.query.await(
            "INSERT IGNORE INTO mechanic_data (name, balance) VALUES(?, 0)",
            {locationName}
        )
    end
end)