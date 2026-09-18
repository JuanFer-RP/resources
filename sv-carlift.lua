local PLATFORM_MODEL = -1375594465
local STAND_MODEL = -277236775
local carLiftsData = {}
local liftsCreated = false

function createCarLift(x, y, z, heading)
    -- Create the platform
    local platform = CreateObjectNoOffset(PLATFORM_MODEL, x, y, z - 1.025, true, true, true)
    if not platform then
        return false, false
    end
    
    -- Wait for the entity to exist
    while not DoesEntityExist(platform) do
        Wait(1)
    end
    
    SetEntityHeading(platform, heading)
    FreezeEntityPosition(platform, true)
    
    -- Create the stand
    local stand = CreateObjectNoOffset(STAND_MODEL, x, y, z - 1.0, true, true, true)
    if not stand then
        return false, false
    end
    
    -- Wait for the entity to exist
    while not DoesEntityExist(stand) do
        Wait(1)
    end
    
    SetEntityHeading(stand, heading)
    FreezeEntityPosition(stand, true)
    
    -- Get network IDs
    local platformNetId = NetworkGetNetworkIdFromEntity(platform)
    local standNetId = NetworkGetNetworkIdFromEntity(stand)
    
    return platformNetId, standNetId
end

function initializeCarLifts()
    liftsCreated = true
    
    -- Delete existing lifts if they exist
    if GlobalState.carLiftsData then
        for _, lifts in pairs(GlobalState.carLiftsData) do
            for _, lift in ipairs(lifts) do
                local platform = NetworkGetEntityFromNetworkId(lift.platform)
                if DoesEntityExist(platform) then
                    DeleteEntity(platform)
                end
                
                local stand = NetworkGetEntityFromNetworkId(lift.stand)
                if DoesEntityExist(stand) then
                    DeleteEntity(stand)
                end
            end
        end
    end
    
    -- Create new lifts based on config
    carLiftsData = {}
    for locationName, locationConfig in pairs(Config.MechanicLocations) do
        if locationConfig.carLifts then
            -- Ensure the location has an entry in carLiftsData
            if not carLiftsData[locationName] then
                carLiftsData[locationName] = {}
            end
            
            for _, liftConfig in ipairs(locationConfig.carLifts) do
                local platformNetId, standNetId = createCarLift(
                    liftConfig.x, 
                    liftConfig.y, 
                    liftConfig.z, 
                    liftConfig.w
                )
                
                if not platformNetId or not standNetId then
                    return false
                end
                
                -- Add the lift to the location's data
                table.insert(carLiftsData[locationName], {
                    platform = platformNetId,
                    stand = standNetId,
                    coords = liftConfig
                })
            end
        end
    end
    
    -- Update global state
    GlobalState:set("carLiftsData", carLiftsData)
end

lib.callback.register("jg-mechanic:server:get-created-lifts", function()
    -- If lifts haven't been created yet, initialize them
    if not liftsCreated then
        initializeCarLifts()
    end
    
    -- Wait for lifts to be created (with timeout)
    lib.waitFor(function()
        return next(carLiftsData) ~= nil
    end, "Lifts say they have been created, but they are still false", 30000)
    
    return carLiftsData
end)