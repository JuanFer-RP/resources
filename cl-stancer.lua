PreviewingNewStance = false
local isStancerActive = false

function isVehicleStanceCompatible(vehicle)
    local model = GetEntityModel(vehicle)
    local isCar = IsThisModelACar(model)
    if not isCar then
        isCar = IsThisModelAQuadbike(model)
    end
    return isCar
end

function applyStanceToVehicle(vehicle, stance, isPreview)
    if vehicle then
        local isValid = DoesEntityExist(vehicle)
        if isValid and isPreview then
            local isCompatible = isVehicleStanceCompatible(vehicle)
            if isCompatible then
              
                SetVehicleSuspensionHeight(vehicle, -stance.height)
                
             
                SetVehicleWheelXOffset(vehicle, 0, -stance.xOffset[1])
                SetVehicleWheelXOffset(vehicle, 1, stance.xOffset[2])
                SetVehicleWheelXOffset(vehicle, 2, -stance.xOffset[3])
                SetVehicleWheelXOffset(vehicle, 3, stance.xOffset[4])
                
          
                SetVehicleWheelYRotation(vehicle, 0, -stance.yRot[1])
                SetVehicleWheelYRotation(vehicle, 1, stance.yRot[2])
                SetVehicleWheelYRotation(vehicle, 2, -stance.yRot[3])
                SetVehicleWheelYRotation(vehicle, 3, stance.yRot[4])
            end
        end
    end
end

function getVehicleDefaultStance(vehicle)
    if vehicle then
        local isValid = DoesEntityExist(vehicle)
        if isValid then
            local isCompatible = isVehicleStanceCompatible(vehicle)
            if isCompatible then
                local stance = {}
                stance.height = round(GetVehicleSuspensionHeight(vehicle), 4)
                
             
                stance.xOffset = {
                    -round(GetVehicleWheelXOffset(vehicle, 0), 4),
                    round(GetVehicleWheelXOffset(vehicle, 1), 4),
                    -round(GetVehicleWheelXOffset(vehicle, 2), 4),
                    round(GetVehicleWheelXOffset(vehicle, 3), 4)
                }
                
          
                stance.yRot = {
                    -round(GetVehicleWheelYRotation(vehicle, 0), 4),
                    round(GetVehicleWheelYRotation(vehicle, 1), 4),
                    -round(GetVehicleWheelYRotation(vehicle, 2), 4),
                    round(GetVehicleWheelYRotation(vehicle, 3), 4)
                }
                
                return stance
            end
        end
    end
    return false
end

function previewVehicleStance(vehicle, isPreview, defaultStance, newStance)
    if vehicle then
        local isCompatible = isVehicleStanceCompatible(vehicle)
        if isCompatible then
            if isPreview then
                applyStanceToVehicle(vehicle, newStance, true)
            else
                applyStanceToVehicle(vehicle, defaultStance, false)
            end
        end
    end
end

function setStanceState(vehicle, isEnabled, isIndividualWheels, defaultStance, newStance)
    if vehicle then
        local isCompatible = isVehicleStanceCompatible(vehicle)
        if isCompatible then
            local vehicleState = Entity(vehicle).state
            vehicleState:set("enableStance", isEnabled, true)
            
            if isEnabled then
                vehicleState:set("wheelsAdjIndv", isIndividualWheels, true)
                vehicleState:set("stance", newStance, true)
            end
            
            local defaultStanceData = vehicleState.defaultStance
            if not defaultStanceData then
                vehicleState:set("defaultStance", defaultStance, true)
            end
        end
    end
end

local trackedVehicles = {}
local stanceData = {}
local stanceChangeCount = {}
local currentStanceHash = {}
local currentStanceVehicle = nil
local isStanceThreadActive = false
local isVehicleTrackingActive = false
local stanceNearbyVehiclesFreqMs = Config and Config.StanceNearbyVehiclesFreqMs or 500
local maxStanceDistance = 80.0

function getVehicleFromStateBag(bagName)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        return vehicle
    end
    return nil
end

function calculateStanceHash(stance)
    if not stance then
        return 0
    end
    
    local hash = stance.height * 131.0
    
    if stance.xOffset then
        for i = 1, #stance.xOffset do
            hash = hash * 31.0 + (stance.xOffset[i] or 0)
        end
    end
    
    if stance.yRot then
        for i = 1, #stance.yRot do
            hash = hash * 37.0 + (stance.yRot[i] or 0)
        end
    end
    
    return math.floor(hash * 1000.0)
end

function incrementStanceChangeCount(vehicle)
    stanceChangeCount[vehicle] = (stanceChangeCount[vehicle] or 0) + 1
end

function removeVehicleFromTracking(vehicle)
    trackedVehicles[vehicle] = nil
    stanceData[vehicle] = nil
    stanceChangeCount[vehicle] = nil
    currentStanceHash[vehicle] = nil
end

function updateVehicleStance(vehicle, forceUpdate)
    local vehicleStanceData = stanceData[vehicle]
    if not vehicleStanceData or not vehicleStanceData.stance then
        return
    end
    
    local stanceHash = calculateStanceHash(vehicleStanceData.stance)
    if not forceUpdate and stanceHash == currentStanceHash[vehicle] then
        return
    end
    
    applyStanceToVehicle(vehicle, vehicleStanceData.stance)
    currentStanceHash[vehicle] = stanceHash
end

function trackActiveStanceVehicle(vehicle)
    local vehicleState = Entity(vehicle).state
    if not vehicleState then
        return
    end
    
    local isEnabled = vehicleState.enableStance
    if isEnabled then
        trackedVehicles[vehicle] = true
        stanceData[vehicle] = stanceData[vehicle] or {}
        stanceData[vehicle].stance = vehicleState.stance
        stanceData[vehicle].defaultStance = vehicleState.defaultStance
        incrementStanceChangeCount(vehicle)
    end
end

function startStancePreviewThread()
    if isStanceThreadActive then
        return
    end
    
    if not currentStanceVehicle then
        return
    end
    
    if not trackedVehicles[currentStanceVehicle] then
        return
    end
    
    isStanceThreadActive = true
    
    CreateThread(function()
        while true do
            if not currentStanceVehicle then
                break
            end
            
            if not trackedVehicles[currentStanceVehicle] then
                break
            end
            
            if not DoesEntityExist(currentStanceVehicle) then
                break
            end
            
            if not PreviewingNewStance then
                updateVehicleStance(currentStanceVehicle, true)
            end
            
            Wait(0)
        end
        
        isStanceThreadActive = false
    end)
end

function startVehicleTrackingThread()
    if isVehicleTrackingActive then
        return
    end
    
    if not next(trackedVehicles) then
        return
    end
    
    isVehicleTrackingActive = true
    
    CreateThread(function()
        while true do
            local ped = cache.ped or PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            
            local vehicle = cache.vehicle or GetVehiclePedIsIn(ped, false)
            
            for _, nearbyVehicle in ipairs(GetGamePool("CVehicle")) do
                if nearbyVehicle ~= vehicle then
                    if DoesEntityExist(nearbyVehicle) then
                        local vehicleCoords = GetEntityCoords(nearbyVehicle)
                        local distance = #(vehicleCoords - pedCoords)
                        
                        if distance <= maxStanceDistance then
                            local vehicleState = Entity(nearbyVehicle).state
                            if vehicleState then
                                local isEnabled = vehicleState.enableStance
                                if isEnabled then
                                    if not trackedVehicles[nearbyVehicle] then
                                        trackedVehicles[nearbyVehicle] = true
                                        stanceData[nearbyVehicle] = {
                                            stance = vehicleState.stance,
                                            defaultStance = vehicleState.defaultStance
                                        }
                                        incrementStanceChangeCount(nearbyVehicle)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            for trackedVehicle in pairs(trackedVehicles) do
                if not DoesEntityExist(trackedVehicle) then
                    removeVehicleFromTracking(trackedVehicle)
                elseif trackedVehicle ~= vehicle then
                    local vehicleCoords = GetEntityCoords(trackedVehicle)
                    local distance = #(vehicleCoords - pedCoords)
                    
                    if distance <= maxStanceDistance then
                        updateVehicleStance(trackedVehicle, true)
                    end
                end
            end
            
            if not next(trackedVehicles) then
                break
            end
            
            Wait(stanceNearbyVehiclesFreqMs)
        end
        
        isVehicleTrackingActive = false
    end)
end

AddStateBagChangeHandler("enableStance", "", function(bagName, _, value)
    local vehicle = getVehicleFromStateBag(bagName)
    if not vehicle then
        return
    end
    
    if value then
        trackedVehicles[vehicle] = true
        stanceData[vehicle] = stanceData[vehicle] or {}
        stanceData[vehicle].stance = Entity(vehicle).state.stance
        stanceData[vehicle].defaultStance = Entity(vehicle).state.defaultStance
        incrementStanceChangeCount(vehicle)
        currentStanceHash[vehicle] = nil
        
        if vehicle == currentStanceVehicle then
            startStancePreviewThread()
            if not PreviewingNewStance then
                updateVehicleStance(vehicle, true)
            end
        end
    else
        local defaultStance = stanceData[vehicle] and stanceData[vehicle].defaultStance
        if defaultStance then
            applyStanceToVehicle(vehicle, defaultStance, false)
            currentStanceHash[vehicle] = calculateStanceHash(defaultStance)
        end
        
        trackedVehicles[vehicle] = nil
    end
    
    startVehicleTrackingThread()
end)

AddStateBagChangeHandler("stance", "", function(bagName, _, value)
    local vehicle = getVehicleFromStateBag(bagName)
    if not vehicle then
        return
    end
    
    trackedVehicles[vehicle] = true
    stanceData[vehicle] = stanceData[vehicle] or {}
    stanceData[vehicle].stance = value
    incrementStanceChangeCount(vehicle)
end)

AddStateBagChangeHandler("defaultStance", "", function(bagName, _, value)
    local vehicle = getVehicleFromStateBag(bagName)
    if not vehicle then
        return
    end
    
    stanceData[vehicle] = stanceData[vehicle] or {}
    stanceData[vehicle].defaultStance = value
end)

function handleVehicleCacheChange(vehicle)
    currentStanceVehicle = vehicle
    if vehicle then
        local isValid = DoesEntityExist(vehicle)
        if isValid then
            local isVehicle = IsEntityAVehicle(vehicle)
            if isVehicle then
                trackActiveStanceVehicle(vehicle)
            end
        end
    end
    startStancePreviewThread()
end

lib.onCache("vehicle", handleVehicleCacheChange)

if cache.vehicle then
    handleVehicleCacheChange(cache.vehicle)
end

CreateThread(function()
    Wait(0)
    
    for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            trackActiveStanceVehicle(vehicle)
        end
    end
    
    startVehicleTrackingThread()
end)

RegisterNUICallback("save-kit-stance", function(data, cb)
    if not isStancerActive then
        return cb({ error = true })
    end
    
    if not cache.vehicle then
        return cb({ error = true })
    end
    
    PreviewingNewStance = false
    setVehicleStatebag(cache.vehicle, "defaultStance", data.defaultStance)
    setVehicleStatebag(cache.vehicle, "wheelsAdjIndv", data.wheelsAdjIndv)
    setVehicleStatebag(cache.vehicle, "stance", data.stance)
    setVehicleStatebag(cache.vehicle, "enableStance", data.enableStance, true)
    
    cb(true)
end)

RegisterNUICallback("preview-kit-stance", function(data, cb)
    if not isStancerActive then
        return cb({ error = true })
    end
    
    if not cache.vehicle then
        return cb({ error = true })
    end
    
    PreviewingNewStance = true
    previewVehicleStance(cache.vehicle, data.enableStance, data.defaultStance, data.stance)
    cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-stancer-kit", function()
    local hasStancerKit = lib.callback.await("jg-mechanic:server:has-item", false, "stancing_kit")
    isStancerActive = hasStancerKit
    
    if not isStancerActive then
        return
    end
    
    if not cache.vehicle then
        Framework.Client.Notify(Locale.notInsideVehicle, "error")
        return
    end
    
    if not isVehicleStanceCompatible(cache.vehicle) then
        Framework.Client.Notify(Locale.cannotStanceVehicleType or "VEHICLE_INCOMPATIBLE", "error")
        return
    end
    
    local vehicleState = Entity(cache.vehicle).state
    setupVehicleCamera(cache.vehicle)
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "show-stancing-menu",
        enableStance = vehicleState.enableStance or false,
        wheelsAdjIndv = vehicleState.wheelsAdjIndv or false,
        stance = vehicleState.stance or getVehicleDefaultStance(cache.vehicle),
        defaultStance = vehicleState.defaultStance or getVehicleDefaultStance(cache.vehicle),
        config = Config,
        locale = Locale
    })
end)