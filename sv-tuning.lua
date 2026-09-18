lib.callback.register("jg-mechanic:server:pay-for-tune", function(playerId, category, newTune, oldTune, vehiclePlate)
    if Config.Debug then
        print(("[jg-mechanic][SV][pay-for-tune] pid=%s plate=%s cat=%s new=%s old=%s"):format(tostring(playerId), tostring(vehiclePlate), tostring(category), tostring(newTune), tostring(oldTune)))
    end
    if not HasActiveTabletConnection(playerId, vehiclePlate) then
        if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] no active tablet connection") end
        return false
    end

    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    local tuningConfig = Config.Tuning and Config.Tuning[category] and Config.Tuning[category][newTune]
    if not tuningConfig then
        if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] tuningConfig not found") end
        return false
    end

    local mechanicLocation = Config.MechanicLocations and Config.MechanicLocations[mechanicId]
    if not mechanicLocation then
        if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] mechanic location not found for player") end
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] not an employee or insufficient role") end
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    local tuningCategory = mechanicLocation.tuning and mechanicLocation.tuning[category]
    if tuningCategory and tuningCategory.requiresItem then
        if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] requires item path") end
        if not tuningConfig.itemName then
            if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] itemName missing in tuningConfig") end
            return false
        end

        local removedItem = Framework.Server.RemoveItem(playerId, tuningConfig.itemName)
        if not removedItem then
            if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] failed to remove required item") end
            Framework.Server.Notify(playerId, "Failed to remove required item", "error")
            return false
        end

        if Config.TuningGiveInstalledItemBackOnRemoval then
            local oldTuningConfig = Config.Tuning and Config.Tuning[category] and Config.Tuning[category][oldTune]
            if oldTuningConfig and oldTuningConfig.itemName then
                local addedItem = Framework.Server.GiveItem(playerId, oldTuningConfig.itemName)
                if not addedItem then
                    if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] failed to return old item (inventory full)") end
                    Framework.Server.Notify(playerId, "Inventory full, couldn't return old part", "warning")
                end
            end
        end
    else
        if tuningConfig.price and tuningConfig.price > 0 then
            if Config.Debug then print(("[jg-mechanic][SV][pay-for-tune] charging society funds: %s"):format(tostring(tuningConfig.price))) end
            local removedFunds = removeFromSocietyFund(playerId, mechanicId, tuningConfig.price)
            if not removedFunds then
                if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] insufficient society funds") end
                Framework.Server.Notify(playerId, "Insufficient funds in mechanic society", "error")
                return false
            end
        end
    end

    sendWebhook(
        playerId,
        Webhooks.TabletTuning,
        "Tuning: Tune Applied via Tablet",
        "success",
        {
            {key = "Mechanic", value = mechanicId},
            {key = "Vehicle Plate", value = vehiclePlate},
            {key = "Tune Category", value = Locale[category] or category},
            {key = "Tune Option", value = tuningConfig.name}
        }
    )
    
    if Config.Debug then print("[jg-mechanic][SV][pay-for-tune] success") end
    return true
end)

lib.callback.register("jg-mechanic:server:remove-tune", function(playerId, category, tuneOption, vehiclePlate)
    if Config.Debug then
        print(("[jg-mechanic][SV][remove-tune] pid=%s plate=%s cat=%s option=%s"):format(tostring(playerId), tostring(vehiclePlate), tostring(category), tostring(tuneOption)))
    end
    if not HasActiveTabletConnection(playerId, vehiclePlate) then
        if Config.Debug then print("[jg-mechanic][SV][remove-tune] no active tablet connection") end
        return false
    end

    local player = Player(playerId).state
    local mechanicId = player and player.mechanicId
    
    local tuningConfig = Config.Tuning and Config.Tuning[category] and Config.Tuning[category][tuneOption]
    if not tuningConfig then
        if Config.Debug then print("[jg-mechanic][SV][remove-tune] tuningConfig not found") end
        return false
    end

    local mechanicLocation = Config.MechanicLocations and Config.MechanicLocations[mechanicId]
    if not mechanicLocation then
        return false
    end

    if not isEmployee(playerId, mechanicId, {"mechanic", "manager"}, true) then
        Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")
        return false
    end

    if Config.TuningGiveInstalledItemBackOnRemoval then
        local tuningCategory = mechanicLocation.tuning and mechanicLocation.tuning[category]
        if tuningCategory and tuningCategory.requiresItem and tuningConfig.itemName then
            local addedItem = Framework.Server.GiveItem(playerId, tuningConfig.itemName)
            if not addedItem then
                if Config.Debug then print("[jg-mechanic][SV][remove-tune] failed to return item (inventory full)") end
                Framework.Server.Notify(playerId, "Inventory full, couldn't return part", "warning")
                return false
            end
        end
    end

    sendWebhook(
        playerId,
        Webhooks.TabletTuning,
        "Tuning: Tune Removed",
        "danger",
        {
            {key = "Mechanic", value = mechanicId},
            {key = "Vehicle Plate", value = vehiclePlate},
            {key = "Tune Category", value = Locale[category] or category},
            {key = "Tune Option", value = tuningConfig.name}
        }
    )
    
    return true
end)