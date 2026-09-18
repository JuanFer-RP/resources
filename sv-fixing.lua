local commandName = Config.FullRepairAdminCommand or "vfix"
local commandOptions = {
    help = "Fully fix a vehicle (admin only)"
}

local function handleVehicleFix(playerId)
    if not Framework.Server.IsAdmin(playerId) then
        Framework.Server.Notify(playerId, Locale.insufficientPermissions, "error")
        return
    end
    TriggerClientEvent("jg-mechanic:client:fix-vehicle-admin", playerId)
end

lib.addCommand(commandName, commandOptions, handleVehicleFix)