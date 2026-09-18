local isNitrousActive = false
local isNitrousEnabled = false
local isPurgeActive = false
local currentVehicle = 0

function isVehicleInWaterStateMatch(ped, vehicle)
    local inWater = IsEntityInWater(vehicle)
    return (inWater == ped) and inWater
end

function enableNitrous(vehicle, fromStateBag)
    if isVehicleElectric(GetEntityArchetypeName(vehicle)) then
        return
    end
    if isNitrousEnabled then
        return
    end
    isNitrousEnabled = true
    
    local tailLightBones = {"taillight_l", "taillight_r"}
    local particleEffect = "veh_light_red_trail"
    local particleScale = 1.0
    
    RequestNamedPtfxAsset("veh_xs_vehicle_mods")
    while not HasNamedPtfxAssetLoaded("veh_xs_vehicle_mods") do
        Wait(1)
    end
    
    SetVehicleNitroEnabled(vehicle, true)
    SetVehicleRocketBoostPercentage(vehicle, 100)
    SetVehicleRocketBoostRefillTime(vehicle, 0.1)
    SetVehicleRocketBoostActive(vehicle, true)
    SetVehicleBoostActive(vehicle, true)
    
    if not fromStateBag then
        if Config.NitrousScreenEffects then
            SetTimecycleModifier("RaceTurboFlash")
            SetTimecycleModifierStrength(0.8)
            ShakeGameplayCam("SKY_DIVING_SHAKE", 0.25)
        end
        
        if Config.NitrousRearLightTrails then
            for _, boneName in ipairs(tailLightBones) do
                local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
                UseParticleFxAssetNextCall("core")
                local particle = StartParticleFxLoopedOnEntityBone(particleEffect, vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, particleScale, false, false, false)
                SetParticleFxLoopedEvolution(particle, "speed", 2.0, false)
            end
        end
        
        Entity(vehicle).state:set("nitrousFx", "nitrous", true)
    end
    
    CreateThread(function()
        while true do
            if fromStateBag then
                break
            end
            if not isNitrousEnabled then
                break
            end
            SetVehicleCheatPowerIncrease(vehicle, Config.NitrousPowerIncreaseMult or 2.0)
            Wait(0)
        end
    end)
end

function disableNitrous(vehicle, fromStateBag)
    isNitrousEnabled = false
    SetVehicleNitroEnabled(vehicle, false)
    SetVehicleRocketBoostActive(vehicle, false)
    SetVehicleBoostActive(vehicle, false)
    SetVehicleCheatPowerIncrease(vehicle, 1.0)
    
    if not fromStateBag then
        if Config.NitrousScreenEffects then
            ClearTimecycleModifier()
            StopGameplayCamShaking(true)
        end
        
        if Config.NitrousRearLightTrails then
            RemoveParticleFxFromEntity(vehicle)
        end
        
        Entity(vehicle).state:set("nitrousFx", false, true)
    end
end

function enablePurge(vehicle, fromStateBag)
    if isPurgeActive then
        return
    end
    isPurgeActive = true
    
    RemoveParticleFxFromEntity(vehicle)
    
    local wheelBones = {"wheel_lf", "wheel_rf"}
    local particleEffect = "ent_sht_steam"
    
    for _, boneName in ipairs(wheelBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
        local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
        local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, boneCoords.x, boneCoords.y, boneCoords.z)
        
        UseParticleFxAssetNextCall("core")
        StartParticleFxLoopedOnEntity(particleEffect, vehicle, offset.x + 0.03, offset.y + 0.1, offset.z + 0.2, 20.0, 0.0, 0.5, 1.0, false, false, false)
    end
    
    SetVehicleBoostActive(vehicle, true)
    
    if not fromStateBag then
        Entity(vehicle).state:set("nitrousFx", "purge", true)
    end
end

function disablePurge(vehicle, fromStateBag)
    isPurgeActive = false
    RemoveParticleFxFromEntity(vehicle)
    SetVehicleBoostActive(vehicle, false)
    
    if not fromStateBag then
        Entity(vehicle).state:set("nitrousFx", false, true)
    end
end

function updateNitrousHud(vehicle, isUsing, isCooldown, capacity)
    local state = Entity(vehicle).state
    if not state then
        return
    end
    
    SendNUIMessage({
        nitrousHudData = {
            using = isUsing,
            cooldown = isCooldown,
            installedBottles = state.nitrousInstalledBottles,
            filledBottles = state.nitrousFilledBottles,
            capacity = capacity,
            maxCapacity = Config.NitrousBottleDuration,
            empty = (state.nitrousFilledBottles == 0 and capacity <= 0)
        }
    })
end

RegisterCommand("+nitrousKeymap", function()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle then
        return
    end
    
    local state = Entity(vehicle).state
    if not state.nitrousInstalledBottles or state.nitrousInstalledBottles == 0 then
        return
    end
    
    if state.nitrousCooldown then
        updateNitrousHud(vehicle, false, true, 0)
        return
    end
    
    if state.nitrousFilledBottles == 0 and state.nitrousCapacity <= 0 then
        updateNitrousHud(vehicle, false, false, 0)
        return
    end
    
    isNitrousActive = true
    local capacity = state.nitrousCapacity or 0.0
    
    if capacity <= 0 and state.nitrousFilledBottles > 0 then
        local bottleDuration = Config.NitrousBottleDuration or 10.0
        state.nitrousFilledBottles = state.nitrousFilledBottles - 1
        capacity = bottleDuration
        setVehicleStatebag(vehicle, "nitrousCapacity", capacity, false)
        setVehicleStatebag(vehicle, "nitrousFilledBottles", state.nitrousFilledBottles, true)
    end
    
    CreateThread(function()
        while true do
            if not isNitrousActive then
                break
            end
            
            if isVehicleInWaterStateMatch(ped, vehicle) then
                break
            end
            
            if capacity <= 0 then
                break
            end
            
            currentVehicle = vehicle
            if IsControlPressed(0, 71) or GetVehicleThrottleOffset(vehicle) > 0.05 then
                if isPurgeActive then
                    disablePurge(vehicle, false)
                end
                enableNitrous(vehicle, false)
                capacity = round(capacity - 0.1, 2)
                updateNitrousHud(vehicle, true, false, capacity)
            else
                if isNitrousEnabled then
                    disableNitrous(vehicle, false)
                end
                enablePurge(vehicle, false)
                capacity = round(capacity - (0.1 * (Config.NitrousPurgeDrainRate or 1)), 2)
                updateNitrousHud(vehicle, true, false, capacity)
            end
            Wait(100)
        end
        
        disableNitrous(vehicle, false)
        disablePurge(vehicle, false)
        
        if capacity < 0 then
            capacity = 0
        end
        setVehicleStatebag(vehicle, "nitrousCapacity", capacity, true)
        
        if capacity <= 0 then
            setVehicleStatebag(vehicle, "nitrousCooldown", true)
            updateNitrousHud(vehicle, false, true, 0)
            
            CreateThread(function()
                Wait(Config.NitrousBottleCooldown * 1000)
                setVehicleStatebag(vehicle, "nitrousCooldown", false)
                updateNitrousHud(vehicle, false, false, 0)
            end)
        end
    end)
end, false)

RegisterCommand("-nitrousKeymap", function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then
        return
    end
    
    local state = Entity(vehicle).state
    if not state.nitrousInstalledBottles or state.nitrousInstalledBottles == 0 then
        return
    end
    
    if isNitrousActive then
        isNitrousActive = false
        disableNitrous(vehicle, false)
        disablePurge(vehicle, false)
    end
end, false)

RegisterKeyMapping("+nitrousKeymap", "Use installed nitrous", "keyboard", Config.NitrousDefaultKeyMapping)

AddStateBagChangeHandler("nitrousFx", "", function(bagName, _, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end
    
    if vehicle == currentVehicle then
        return
    end
    
    if value == "nitrous" then
        enableNitrous(vehicle, true)
    elseif value == "purge" then
        enablePurge(vehicle, true)
    else
        disableNitrous(vehicle, true)
        disablePurge(vehicle, true)
    end
end)

RegisterNUICallback("install-new-bottle", function(_, cb)
    local vehicle = LocalPlayer.state.tabletConnectedVehicle and LocalPlayer.state.tabletConnectedVehicle.vehicleEntity
    if not vehicle or not DoesEntityExist(vehicle) then
        return cb(false)
    end
    
    local model = GetEntityModel(vehicle)
    if not (IsThisModelACar(model) or IsThisModelAQuadbike(model)) then
        return cb(false)
    end
    
    if isVehicleElectric(GetEntityArchetypeName(vehicle)) then
        return cb(false)
    end
    
    playMinigame(vehicle, "prop", { prop = "canister" }, function(success)
        showTabletAfterInteractionPrompt()
        SetNuiFocus(true, true)
        if not success then
            return cb(false)
        end
        
        local result = lib.callback.await("jg-mechanic:server:install-new-bottle", false)
        if not result then
            return cb(false)
        end
        
        Framework.Client.Notify(Locale.nitrousBottleInstalled, "success")
        cb(true)
    end)
end)

RegisterNUICallback("refill-bottle", function(_, cb)
    Framework.Client.ProgressBar(Locale.refillingBottle, 5000, false, false, function()
        local result, message, type = lib.callback.await("jg-mechanic:server:refill-nitrous-bottle", false)
        cb(result, message, type)
    end, function()
        cb(false)
    end)
end)

RegisterNetEvent("jg-mechanic:client:use-nitrous-bottle", function()
    local canRefill = lib.callback.await("jg-mechanic:server:can-refill-bottle-in-current-vehicle", false)
    if not canRefill then
        return
    end

    Framework.Client.ProgressBar(Locale.refillingBottle, 2500, false, false, function()
        TriggerServerEvent("jg-mechanic:server:use-nitrous-bottle")
    end, function()
    end)
end)