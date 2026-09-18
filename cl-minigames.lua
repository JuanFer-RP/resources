local MODEL_REQUEST_TIMEOUT = 3000
local INTERACT_KEY = 201
local CANCEL_KEY = 202

function isPlayerNearVehicleBones(vehicle, boneNames)
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    for _, boneName in ipairs(boneNames) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
        if boneIndex == -1 then
            return true
        else
            local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local distance = #(playerCoords - boneCoords)
            if distance <= 3.0 then
                return true
            end
        end
    end
    return false
end

function playRepairAnimation(ped, partType, vehicle)
    if not ped or not vehicle then
        return
    end
    local vehicleCoords = GetEntityCoords(vehicle)
    local pedCoords = GetEntityCoords(ped)
    local heightDifference = vehicleCoords.z - pedCoords.z
    if heightDifference > 1.0 then
        playAnimation(ped, "missheist_agency2aig_3", "chat_a_worker2")
    elseif partType == "engine" then
        playAnimation(ped, "mini@repair", "fixing_a_ped")
    elseif partType == "kneeling" then
        playAnimation(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", true)
    end
end

function createEngineHoist(position)
    local engineHoistModel = 232216084
    local baseModel = 1450715350
    lib.requestModel(engineHoistModel, MODEL_REQUEST_TIMEOUT)
    lib.requestModel(baseModel, MODEL_REQUEST_TIMEOUT)
    
    local baseObject = CreateObject(baseModel, position.x, position.y, position.z, true, true, false)
    NetworkSetObjectForceStaticBlend(baseObject, true)
    while not HasCollisionLoadedAroundEntity(baseObject) do
        Wait(1)
    end
    PlaceObjectOnGroundProperly(baseObject)
    
    local engineObject = CreateObject(engineHoistModel, position.x, position.y, position.z, true, true, false)
    NetworkSetObjectForceStaticBlend(engineObject, true)
    while not HasCollisionLoadedAroundEntity(engineObject) do
        Wait(1)
    end
    
    AttachEntityToEntity(engineObject, baseObject, 0, 0.0, -1.1, 1.25, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
    SetEntityCollision(baseObject, false, false)
    SetEntityCanBeDamaged(baseObject, false)
    SetEntityCollision(engineObject, false, true)
    
    return baseObject, engineObject
end

function deleteEntities(entity1, entity2)
    if entity1 then
        DeleteEntity(entity1)
    end
    if entity2 then
        DeleteEntity(entity2)
    end
end

function swapEngineMinigame(vehicle, _, callback)
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    local offset = vector3(1.5, 0.0, 0.0)
    
    TaskLeaveVehicle(ped, vehicle, 16)
    Entity(vehicle).state:set("vehicleBonnetDeleted", true, true)
    
    local baseObject, engineObject = createEngineHoist(playerCoords)
    
    PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    SetNuiFocus(false, false)
    hideTabletToShowInteractionPrompt(Locale.takeEngineHoistToVehicle)
    
    CreateThread(function()
        while true do
            if IsControlJustPressed(0, INTERACT_KEY) then
                break
            end
            if IsControlJustReleased(0, CANCEL_KEY) then
                break
            end
            
            local pedCoords = GetEntityCoords(ped)
            local forwardVector = GetEntityForwardVector(ped)
            local rightVector = vector3(forwardVector.y, -forwardVector.x, forwardVector.z)
            
            local newPosition = pedCoords + (forwardVector * offset.x) + (rightVector * offset.y)
            newPosition = newPosition + vector3(0.0, 0.0, offset.z)
            
            local groundZ = GetGroundZFor_3dCoord(newPosition.x, newPosition.y, newPosition.z, true)
            SetEntityCoords(engineObject, newPosition.x, newPosition.y, groundZ, true, true, true, false)
            
            local angle = math.deg(math.atan((newPosition.y - pedCoords.y) / (newPosition.x - pedCoords.x))) - 270.0
            if newPosition.x < pedCoords.x then
                angle = angle - 180.0
            end
            SetEntityRotation(engineObject, 0.0, 0.0, angle, 2, true)
            
            Wait(0)
        end
        
        if IsControlJustReleased(0, CANCEL_KEY) then
            showTabletAfterInteractionPrompt()
            stopAnimation(ped)
            deleteEntities(baseObject, engineObject)
            Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
            return callback(false)
        end
        
        hideTabletToShowInteractionPrompt(Locale.goToEngineToInstall)
        Wait(100)
        PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        
        while true do
            if IsControlJustPressed(0, INTERACT_KEY) then
                if isPlayerNearVehicleBones(vehicle, {"engine"}) then
                    break
                end
            end
            if IsControlJustPressed(0, INTERACT_KEY) then
                Framework.Client.Notify(Locale.notNearbyToEngine, "error")
                Wait(100)
            end
            Wait(0)
        end
        
        playRepairAnimation(ped, "engine", vehicle)
        local repairSound = Framework.Client.PlaySound("repair", playerCoords)
        
        Framework.Client.SkillCheck(function()
            showTabletAfterInteractionPrompt()
            stopAnimation(ped)
            Framework.Client.StopSound(repairSound)
            deleteEntities(baseObject, engineObject)
            Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
            callback(true)
        end, function()
            showTabletAfterInteractionPrompt()
            stopAnimation(ped)
            Framework.Client.StopSound(repairSound)
            deleteEntities(baseObject, engineObject)
            Entity(vehicle).state:set("vehicleBonnetDeleted", false, true)
            Framework.Client.Notify(Locale.installationFailed, "error")
            callback(false)
        end)
    end)
end

AddStateBagChangeHandler("vehicleBonnetDeleted", "", function(bagName, _, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end
    if value then
        SetVehicleDoorBroken(vehicle, 4, true)
    else
        SetVehicleFixed(vehicle)
    end
end)

function createProp(modelName, position)
    local modelHash = GetHashKey(modelName)
    lib.requestModel(modelHash, MODEL_REQUEST_TIMEOUT)
    local prop = CreateObject(modelHash, position.x, position.y, position.z, true, true, false)
    NetworkSetObjectForceStaticBlend(prop, true)
    while not HasCollisionLoadedAroundEntity(prop) do
        Wait(1)
    end
    return prop
end

function propBasedMinigame(vehicle, config, callback)
    local propConfig = config.prop
    if not propConfig then
        return callback(false)
    end
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    TaskLeaveVehicle(ped, vehicle, 16)
    
    local boneNames = {}
    local promptText
    local animationType = "kneeling"
    
    if propConfig == "wheel" then
        boneNames = {"wheel_lf", "wheel_rf", "wheel_lr", "wheel_rr"}
        promptText = Locale.notNearWheel
        local wheelProp = createProp("prop_wheel_01", playerCoords)
        AttachEntityToEntity(wheelProp, ped, 62, 0.075443142898393, 0.093685241510963, 0.28141744731019, -172.34215070538, 0, 0, true, true, false, true, 1, true)
        playAnimation(ped, "anim@heists@box_carry@", "idle")
        hideTabletToShowInteractionPrompt(Locale.takeWheel)
    elseif propConfig == "canister" then
        boneNames = {"engine"}
        promptText = Locale.notNearbyToEngine
        local canisterProp = createProp("prop_gascyl_01a", playerCoords)
        AttachEntityToEntity(canisterProp, ped, 62, 0.03949541175723, 0.11786201460733, 0.12430043235594, -157.12101467039, 7.9513867036588E-16, 37.736651343458, true, true, false, true, 1, true)
        playAnimation(ped, "anim@heists@box_carry@", "idle")
        SetVehicleDoorOpen(vehicle, 4, false, false)
        hideTabletToShowInteractionPrompt(Locale.takeCanisterToEngine)
    elseif propConfig == "spanner" then
        boneNames = {"engine"}
        promptText = Locale.notNearbyToEngine
        local spannerProp = createProp("prop_tool_spanner01", playerCoords)
        AttachEntityToEntity(spannerProp, ped, 62, 0.08416675285639, -0.0059900812103676, 0.011921186133477, -93.957684264985, -79.548849524562, 21.94560085578, true, true, false, true, 1, true)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        hideTabletToShowInteractionPrompt(Locale.goToEngineToInstallOrCancel)
    end
    
    if not wheelProp and not canisterProp and not spannerProp then
        showTabletAfterInteractionPrompt()
        return callback(false)
    end
    
    CreateThread(function()
        SetNuiFocus(false, false)
        Wait(200)
        PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        
        while true do
            if IsControlJustPressed(0, INTERACT_KEY) then
                break
            end
            if IsControlJustReleased(0, CANCEL_KEY) then
                break
            end
            Wait(0)
        end
        
        while true do
            if IsControlJustReleased(0, CANCEL_KEY) then
                break
            end
            if IsControlJustPressed(0, INTERACT_KEY) then
                if isPlayerNearVehicleBones(vehicle, boneNames) then
                    break
                end
            end
            if IsControlJustPressed(0, INTERACT_KEY) then
                Framework.Client.Notify(promptText, "error")
                Wait(100)
            end
            Wait(0)
        end
        
        DeleteEntity(wheelProp or canisterProp or spannerProp)
        stopAnimation(ped)
        
        if IsControlJustReleased(0, CANCEL_KEY) then
            SetVehicleDoorsShut(vehicle, false)
            showTabletAfterInteractionPrompt()
            return callback(false)
        end
        
        Wait(200)
        playRepairAnimation(ped, animationType, vehicle)
        local repairSound = Framework.Client.PlaySound("repair", playerCoords)
        
        Framework.Client.SkillCheck(function()
            showTabletAfterInteractionPrompt()
            stopAnimation(ped)
            DeleteEntity(wheelProp or canisterProp or spannerProp)
            SetVehicleDoorsShut(vehicle, false)
            Framework.Client.StopSound(repairSound)
            callback(true)
        end, function()
            showTabletAfterInteractionPrompt()
            stopAnimation(ped)
            DeleteEntity(wheelProp or canisterProp or spannerProp)
            SetVehicleDoorsShut(vehicle, false)
            Framework.Client.StopSound(repairSound)
            Framework.Client.Notify(Locale.installationFailed, "error")
            callback(false)
        end)
    end)
end

function paintSprayMinigame(vehicle, _, callback)
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    TaskLeaveVehicle(ped, vehicle, 16)
    
    CreateThread(function()
        local animDict = "switch@franklin@cleaning_car"
        local animName = "001946_01_gc_fras_v2_ig_5_base"
        local particleModel = "prop_paint_spray01b"
        local particleFx = "core"
        local particleName = "ent_sht_steam"
        
        lib.requestAnimDict(animDict)
        lib.requestModel(particleModel, MODEL_REQUEST_TIMEOUT)
        lib.requestNamedPtfxAsset(particleFx)
        
        local sprayProp = CreateObject(GetHashKey(particleModel), playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
        AttachEntityToEntity(sprayProp, ped, 71, 0.05, 0.0, -0.02, 0.0, 90.0, 90.0, true, true, false, true, 1, true)
        
        SetNuiFocus(false, false)
        hideTabletToShowInteractionPrompt(Locale.pressToRespray)
        Wait(200)
        PlaySoundFrontend(-1, "CONTINUE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        
        while true do
            if IsControlJustPressed(0, INTERACT_KEY) then
                break
            end
            if IsControlJustReleased(0, CANCEL_KEY) then
                break
            end
            Wait(0)
        end
        
        while true do
            if IsControlJustReleased(0, CANCEL_KEY) then
                break
            end
            if IsControlJustPressed(0, INTERACT_KEY) then
                local pedPos = GetEntityCoords(ped)
                local vehiclePos = GetEntityCoords(vehicle)
                local distance = #(pedPos - vehiclePos)
                if distance <= 4.0 then
                    break
                end
            end
            if IsControlJustPressed(0, INTERACT_KEY) then
                Framework.Client.Notify(Locale.tooFarFromVehicle, "error")
                Wait(100)
            end
            Wait(0)
        end
        
        if IsControlJustReleased(0, CANCEL_KEY) then
            DeleteObject(sprayProp)
            ClearPedTasksImmediately(ped)
            showTabletAfterInteractionPrompt()
            return callback(false)
        end
        
        Wait(200)
        hideTabletToShowInteractionPrompt(Locale.paintEvenlyMsg)
        TaskPlayAnim(ped, animDict, animName, 8.0, -8, -1, 49, 0, false, false, false)
        
        CreateThread(function()
            for _ = 1, 3 do
                UseParticleFxAssetNextCall(particleFx)
                local particle = StartParticleFxLoopedOnEntity(particleName, sprayProp, 0.0, 0.0, 0.15, 0.0, 0.0, 0.0, 1.0, false, false, false)
                Citizen.Wait(5000)
                StopParticleFxLooped(particle, false)
            end
        end)
        
        Framework.Client.ProgressBar(Locale.resprayingVehicleProgress, 15000, false, false, function()
            showTabletAfterInteractionPrompt()
            DeleteObject(sprayProp)
            ClearPedTasksImmediately(ped)
            callback(true)
        end, function()
            showTabletAfterInteractionPrompt()
            DeleteObject(sprayProp)
            ClearPedTasksImmediately(ped)
            callback(false)
        end)
    end)
end

function playMinigame(vehicle, minigameType, config, callback)
    if not vehicle or vehicle == 0 then
        return callback(false)
    end
    
    local minigameFunction = propBasedMinigame
    if minigameType == "respray" then
        minigameFunction = paintSprayMinigame
    elseif minigameType == "engineSwap" then
        minigameFunction = swapEngineMinigame
    end
    
    minigameFunction(vehicle, config, callback)
end