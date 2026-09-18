lib.callback.register("jg-mechanic:server:dyno-share-with-player", function(source, targetId, dynoResults)
    -- Check if target player is busy
    local targetPlayer = Player(targetId)
    if targetPlayer and targetPlayer.state and targetPlayer.state.isBusy then
        Framework.Server.Notify(source, Locale.playerIsBusy, "error")
        return false
    end
    
    -- Send dyno results to the target player
    TriggerClientEvent("jg-mechanic:client:dyno-show-results-sheet", targetId, dynoResults)
    
    return true
end)