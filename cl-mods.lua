local currentMechanicId = nil
local isUIOpen = false
local showTextUI = false
local lastInteractPress = 0
local interactCooldownMs = 600
local currentVehicle = nil
local originalVehicleProperties = {}
local vehiclePlate = ""
local isSelfService = false
local isSmokePreviewActive = false
local originalBulletproofTyres = true
local isFreecamActive = false
local isHornPlaying = false

local previewMods = {
    repair = {},
    performance = {},
    cosmetics = {},
    stance = {},
    respray = {},
    wheels = {},
    neonLights = {},
    headlights = {},
    tyreSmoke = {},
    bulletproofTyres = {},
    extras = {}
}

local function toggleVehicleFreeze(vehicle, freeze)
    if not vehicle then
        return
    end
    
    SetVehicleEngineOn(vehicle, not freeze, true, true)
    FreezeEntityPosition(vehicle, freeze)
    SetEntityCollision(vehicle, not freeze, not freeze)
end

local function resetVehicleToOriginalState()
    if not currentVehicle then
        return
    end
    
    ClearPedTasks(cache.ped)
    SetVehicleTyresCanBurst(currentVehicle, originalBulletproofTyres)
    SetVehicleCurrentRpm(currentVehicle, 0.0)
    FreezeEntityPosition(currentVehicle, true)
    SetEntityCollision(currentVehicle, false, false)
    SetVehicleEngineOn(currentVehicle, false, true, true)
    isSmokePreviewActive = false
end

local function applyPreviewedMods()
    if not currentVehicle then
        return
    end
    
    if isSelfService then
        return
    end
    
    setVehicleProperties(currentVehicle, originalVehicleProperties, true)
end

local function getModSlotLabel(vehicle, modType)
    if type(modType) == "string" then
        return false
    end
    
    local label = GetLabelText(GetModSlotName(vehicle, modType))
    if label ~= "NULL" then
        return label
    end
    
    local modSlotName = GetModSlotName(vehicle, modType)
    if modSlotName and modSlotName ~= "" then
        return modSlotName
    end
    
    return false
end

local function getModLabel(vehicle, modType, modName, modIndex)
    if modType == "LIVERY" then
        local label = GetLabelText(GetLiveryName(vehicle, modIndex))
        if label ~= "NULL" then
            return label
        end
    end
    
    if type(modType) == "string" then
        return "ERROR"
    end
    
    local label = GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
    if label ~= "NULL" then
        return label
    end
    
    local modTextLabel = GetModTextLabel(vehicle, modType, modIndex)
    if modTextLabel and modTextLabel ~= "" then
        return modTextLabel
    end
    
    local name = modName or ""
    return name .. " " .. (modIndex + 1)
end

local function isModInList(modList, vehicle, modId)
    for _, mod in ipairs(modList) do
        if modId == mod then
            return true
        elseif type(mod) == "string" and type(modId) == "number" then
            local modSlotName = GetModSlotName(vehicle, modId)
            if modSlotName == mod then
                return true
            end
        end
    end
    
    return false
end

local function getAvailableMods(vehicle, vehicleProps, mechanicId)
    local mechanicLocation = Config.MechanicLocations[mechanicId]
    local mechanicMods = mechanicLocation.mods
    
    if not mechanicMods then
        return false
    end
    
    if Config.ModsPricesAsPercentageOfVehicleValue then
        local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(vehicle))
        
        for modType, modData in pairs(mechanicMods) do
            local price = round(vehicleValue * (modData.percentVehVal or 0.01), 0)
            modData.price = price
        end
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    SetVehicleModKit(vehicle, 0)
    
    local performanceMods = {}
    
    for _, performanceMod in pairs(Config.Mods.Performance) do
        local numMods = GetNumVehicleMods(vehicle, performanceMod.modType)
        
        if numMods > 0 or performanceMod.toggle then
            local modName = getModSlotLabel(vehicle, performanceMod.modType) or performanceMod.name
            local modOptions = {}
            
            modOptions[1] = {
                modIndex = -1,
                name = "Stock"
            }
            
            if performanceMod.overrideOptions and type(performanceMod.overrideOptions) == "table" then
                for _, option in pairs(performanceMod.overrideOptions) do
                    local optionPrice = option.price
                    
                    if not optionPrice then
                        local priceMult = mechanicMods.performance.priceMult or 0
                        optionPrice = round(mechanicMods.performance.price * (option.modIndex > 0 and (1 + option.modIndex * priceMult) or 1), 0)
                    end
                    
                    table.insert(modOptions, {
                        modIndex = option.modIndex,
                        name = option.name,
                        price = optionPrice
                    })
                end
            else
                for i = 0, numMods - 1 do
                    local priceMult = mechanicMods.performance.priceMult or 0
                    local price = round(mechanicMods.performance.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                    
                    table.insert(modOptions, {
                        modIndex = i,
                        name = getModLabel(vehicle, performanceMod.modType, modName, i),
                        price = price
                    })
                end
            end
            
            table.insert(performanceMods, {
                modType = performanceMod.modType,
                name = modName,
                mods = modOptions,
                toggle = performanceMod.toggle,
                price = mechanicMods.performance.price
            })
        end
    end
    
    local cosmeticMods = {}
    
    for _, cosmeticMod in pairs(Config.Mods.Cosmetics) do
        local modName = cosmeticMod.name
        local ignorePriceMult = cosmeticMod.ignorePriceMult
        local modOptions = {}
        
        if cosmeticMod.modType == "PLATE_INDEX" then
            if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) or IsThisModelABike(vehicleModel) then
                for i = 1, #Config.Mods.PlateIndexes do
                    if i < 6 or (i >= 6 and GetGameBuildNumber() >= 3095) then
                        local plateData = Config.Mods.PlateIndexes[i]
                        local platePrice = plateData.price
                        
                        if not ignorePriceMult and not platePrice then
                            local priceMult = mechanicMods.cosmetics.priceMult or 0
                            platePrice = round(mechanicMods.cosmetics.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                        end
                        
                        table.insert(modOptions, {
                            modIndex = i - 1,
                            name = plateData.name,
                            price = platePrice or mechanicMods.cosmetics.price
                        })
                    end
                end
            end
        elseif cosmeticMod.modType == "WINDOW_TINT" then
            if not IsThisModelABicycle(vehicleModel) then
                for i = 1, #Config.Mods.WindowTints do
                    local tintData = Config.Mods.WindowTints[i]
                    local tintPrice = tintData.price
                    
                    if not ignorePriceMult and not tintPrice then
                        local priceMult = mechanicMods.cosmetics.priceMult or 0
                        tintPrice = round(mechanicMods.cosmetics.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                    end
                    
                    table.insert(modOptions, {
                        modIndex = i - 1,
                        name = tintData.name,
                        price = tintPrice or mechanicMods.cosmetics.price
                    })
                end
            end
        else
            local numMods = 0
            
            if cosmeticMod.modType == "LIVERY" then
                numMods = GetVehicleLiveryCount(vehicle)
            elseif cosmeticMod.modType == "LIVERY_ROOF" then
                numMods = GetVehicleRoofLiveryCount(vehicle)
            else
                numMods = GetNumVehicleMods(vehicle, cosmeticMod.modType)
            end
            
            if numMods > 0 or cosmeticMod.toggle then
                local modLabel = getModSlotLabel(vehicle, cosmeticMod.modType)
                modName = modLabel or cosmeticMod.name
                
                if cosmeticMod.modType == 14 then -- Horns
                    for i = 1, #Config.Mods.Horns do
                        local hornData = Config.Mods.Horns[i]
                        local hornPrice = hornData.price
                        
                        if not ignorePriceMult and not hornPrice then
                            local priceMult = mechanicMods.cosmetics.priceMult or 0
                            hornPrice = round(mechanicMods.cosmetics.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                        end
                        
                        table.insert(modOptions, {
                            modIndex = i - 1,
                            name = hornData.name,
                            price = hornPrice or mechanicMods.cosmetics.price
                        })
                    end
                else
                    modOptions[1] = {
                        modIndex = -1,
                        name = "Stock"
                    }
                    
                    for i = 0, numMods - 1 do
                        local modPrice
                        
                        if ignorePriceMult then
                            modPrice = mechanicMods.cosmetics.price
                        else
                            local priceMult = mechanicMods.cosmetics.priceMult or 0
                            modPrice = round(mechanicMods.cosmetics.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                        end
                        
                        local displayName
                        if Config.UseCustomNamesInTuningMenu and cosmeticMod.name then
                            displayName = cosmeticMod.name
                        else
                            displayName = getModLabel(vehicle, cosmeticMod.modType, modName, i)
                        end
                        
                        table.insert(modOptions, {
                            modIndex = i,
                            name = displayName,
                            price = modPrice
                        })
                    end
                end
            end
        end
        
        if #modOptions > 0 then
            local displayName
            if Config.UseCustomNamesInTuningMenu and cosmeticMod.name then
                displayName = cosmeticMod.name
            else
                displayName = modName
            end
            
            table.insert(cosmeticMods, {
                modType = cosmeticMod.modType,
                name = displayName,
                mods = modOptions,
                toggle = cosmeticMod.toggle,
                price = mechanicMods.cosmetics.price
            })
        end
    end
    
    local wheelMods = {}
    
    if IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) or IsThisModelABike(vehicleModel) then
        for _, wheelType in ipairs(Config.Mods.WheelTypes) do
            if (IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel) or 
                (IsThisModelABike(vehicleModel) and wheelType.modIndex == 6)) then
                
                SetVehicleWheelType(vehicle, wheelType.modIndex)
                local numWheelMods = GetNumVehicleMods(vehicle, 23)
                
                if numWheelMods > 0 then
                    local wheelOptions = {}
                    
                    wheelOptions[1] = {
                        modIndex = -1,
                        name = "Stock"
                    }
                    
                    for i = 0, numWheelMods - 1 do
                        local priceMult = mechanicMods.wheels.priceMult or 0
                        local price = round(mechanicMods.wheels.price * (i > 0 and (1 + i * priceMult) or 1), 0)
                        
                        table.insert(wheelOptions, {
                            modIndex = i,
                            name = getModLabel(vehicle, 23, wheelType.name, i),
                            price = price
                        })
                    end
                    
                    table.insert(wheelMods, {
                        modType = wheelType.modIndex,
                        name = wheelType.name,
                        mods = wheelOptions
                    })
                end
            end
        end
    end
    
    -- Restore original wheel type
    SetVehicleWheelType(vehicle, vehicleProps.wheels)
    
    -- Restore original wheel mods
    if vehicleProps.modFrontWheels then
        SetVehicleMod(vehicle, 23, vehicleProps.modFrontWheels, vehicleProps.modCustomTiresF)
    end
    
    if vehicleProps.modBackWheels then
        SetVehicleMod(vehicle, 24, vehicleProps.modBackWheels, vehicleProps.modCustomTiresR)
    end
    
    local availableMods = {
        repair = mechanicMods.repair.enabled and mechanicMods.repair or nil,
        performance = mechanicMods.performance.enabled and #performanceMods > 0 and performanceMods or nil,
        cosmetics = mechanicMods.cosmetics.enabled and #cosmeticMods > 0 and cosmeticMods or nil,
        stance = IsThisModelACar(vehicleModel) and mechanicMods.stance.enabled and mechanicMods.stance or nil,
        respray = mechanicMods.respray.enabled and #Config.Mods.Colours > 0 and {
            price = mechanicMods.respray.price,
            colours = Config.Mods.Colours
        } or nil,
        wheels = mechanicMods.wheels.enabled and #wheelMods > 0 and wheelMods or nil,
        neonLights = (IsThisModelACar(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and 
                    mechanicMods.neonLights.enabled and mechanicMods.neonLights or nil,
        headlights = not IsThisModelABicycle(vehicleModel) and mechanicMods.headlights.enabled and mechanicMods.headlights or nil,
        tyreSmoke = (IsThisModelACar(vehicleModel) or IsThisModelABike(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and 
                   mechanicMods.tyreSmoke.enabled and mechanicMods.tyreSmoke or nil,
        bulletproofTyres = (IsThisModelACar(vehicleModel) or IsThisModelABike(vehicleModel) or IsThisModelAQuadbike(vehicleModel)) and 
                          mechanicMods.bulletproofTyres.enabled and mechanicMods.bulletproofTyres or nil,
        extras = mechanicMods.extras.enabled and next(vehicleProps.extras) ~= nil and mechanicMods.extras or nil
    }
    
    return availableMods
end

local function closeModMenu()
    if currentVehicle then
        toggleVehicleFreeze(currentVehicle, false)
        applyPreviewedMods()
        
        local vehicleState = Entity(currentVehicle).state
        vehicleState:set("unpaidModifications", false, true)
    end
    
    SetNuiFocusKeepInput(false)
    Framework.Client.ToggleHud(true)
    
    local playerState = LocalPlayer.state
    playerState:set("isBusy", false, true)
    
    previewMods = {
        repair = {},
        performance = {},
        cosmetics = {},
        stance = {},
        respray = {},
        wheels = {},
        neonLights = {},
        headlights = {},
        tyreSmoke = {},
        bulletproofTyres = {},
        extras = {}
    }
    
    isUIOpen = false
    currentMechanicId = nil
    currentVehicle = nil
    originalVehicleProperties = nil
    isSelfService = false
end

local function openModMenu(mechanicId, mechanicName)
    local mechanicLocation = Config.MechanicLocations[mechanicId]
    
    if not mechanicLocation then
        return false
    end
    
    currentMechanicId = mechanicId
    
    if not cache.vehicle then
        return false
    end
    
    currentVehicle = cache.vehicle
    
    if GetPedInVehicleSeat(currentVehicle, -1) ~= cache.ped then
        Framework.Client.Notify(Locale.notInDriversSeat, "error")
        currentVehicle = nil
        return false
    end
    
    local vehicleDamage = {
        GetVehicleBodyHealth(currentVehicle),
        GetVehicleEngineHealth(currentVehicle)
    }
    
    originalVehicleProperties = getVehicleProperties(currentVehicle, true)
    
    if not originalVehicleProperties then
        error("Could not get the vehicle's props")
    end
    
    vehiclePlate = Framework.Client.GetPlate(currentVehicle)
    
    if not vehiclePlate then
        error("Could not get the vehicle's plate")
    end
    
    originalBulletproofTyres = not originalVehicleProperties.bulletProofTyres
    originalVehicleProperties.windowTint = math.max(originalVehicleProperties.windowTint or 0, 0)
    
    local availableMods = getAvailableMods(currentVehicle, originalVehicleProperties, mechanicId)
    
    if not availableMods then
        return false
    end
    
    for i = 0, 5 do
        if GetPedInVehicleSeat(currentVehicle, i) ~= 0 then
            Framework.Client.Notify(Locale.passengersMustLeaveVehicleFirst, "error")
            return false
        end
    end
    
    toggleVehicleFreeze(currentVehicle, true)
    SetVehicleModKit(currentVehicle, 0)
    setupVehicleCamera(currentVehicle)
    
    if Config.ChangePlateDuringPreview then
        lib.callback.await("jg-mechanic:server:open-mods-menu", false, VehToNet(currentVehicle))
    end
    
    local isMechanicEmployee = lib.callback.await("jg-mechanic:server:is-mechanic-employee", false, mechanicId)
    local mechanicBalance
    
    if isMechanicEmployee then
        mechanicBalance = lib.callback.await("jg-mechanic:server:get-mechanic-balance", false, mechanicId)
    else
        mechanicBalance = false
    end
    
    local mechanicsOnDuty = lib.callback.await("jg-mechanic:server:count-currently-on-duty", false, mechanicId)
    
    local mechanicType = mechanicLocation.type
    if mechanicType ~= "self-service" and not (Config.MechanicEmployeesCanSelfServiceMods and isMechanicEmployee) then
        mechanicType = "owned"
    end
    
    LocalPlayer.state:set("isBusy", true, true)
    Framework.Client.ToggleHud(false)
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "show-vehicle-tuning",
        logo = mechanicLocation.logo,
        mechanicId = mechanicId,
        name = mechanicName or mechanicId,
        mechanicType = mechanicType,
        mechanicsOnDuty = mechanicsOnDuty,
        isMechanicEmployee = isMechanicEmployee,
        mechBalance = (isMechanicEmployee and mechanicType == "self-service") and mechanicBalance or false,
        bankBalance = Framework.Client.GetBalance("bank"),
        cashBalance = Framework.Client.GetBalance("cash"),
        changeCamBtn = parseControlBinding(0),
        vehicleDamaged = vehicleDamage,
        props = originalVehicleProperties,
        mods = availableMods,
        config = Config,
        locale = Locale
    })
    
    return true
end

RegisterNetEvent("jg-mechanic:client:open-customisation-menu", openModMenu)

function onEnterModsZone(mechanicId, mechanicName)
    if not cache.vehicle then
        return false
    end
    
    CreateThread(function()
        currentMechanicId = mechanicId
        
        while currentMechanicId do
            Wait(0)
            
            if not isUIOpen and not showTextUI then
                Framework.Client.ShowTextUI(Config.CustomiseVehiclePrompt)
                showTextUI = true
            end
            
            if IsControlJustPressed(0, Config.CustomiseVehicleKey) and not isUIOpen then
                local now = GetGameTimer()
                if now - lastInteractPress < interactCooldownMs then
                    goto continue
                end
                lastInteractPress = now
                if openModMenu(currentMechanicId, mechanicName) then
                    isUIOpen = true
                    showTextUI = false
                    Framework.Client.HideTextUI()
                end
            end
            ::continue::
        end
    end)
end

local function onExitModsZone()
    currentMechanicId = nil
    closeModMenu()
    
    SetTimeout(1, function()
        Framework.Client.HideTextUI()
        showTextUI = false
    end)
end

RegisterNUICallback("purchase-mods", function(data, cb)
    if not currentMechanicId or not currentVehicle or not originalVehicleProperties then
        cb({error = true})
        return
    end
    
    local cart = data.cart
    local paymentMethod = data.paymentMethod
    
    if not cart or type(cart) ~= "table" then
        cb({error = true})
        return
    end
    
    local mechanicLocation = Config.MechanicLocations[currentMechanicId]
    
    if not mechanicLocation then
        cb({error = false})
        return
    end
    
    local vehicleProps = getVehicleProperties(currentVehicle, true)
    vehicleProps.plate = vehiclePlate
    
    if not vehicleProps then
        cb({error = false})
        return
    end
    
    local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(currentVehicle))
    local totalCost = lib.callback.await("jg-mechanic:server:purchase-mods", false, currentMechanicId, vehicleValue, cart, paymentMethod)
    
    if totalCost == false then
        cb({error = true})
        return
    end
    
    local isMechanicEmployee = lib.callback.await("jg-mechanic:server:is-mechanic-employee", false, currentMechanicId)
    local mechanicType = mechanicLocation.type
    
    if mechanicType == "self-service" or (Config.MechanicEmployeesCanSelfServiceMods and isMechanicEmployee) then
        toggleVehicleFreeze(currentVehicle, false)
        
        local allMods = {}
        for category, mods in pairs(previewMods) do
            allMods = tableConcat(allMods, mods)
        end
        
        setStatebagsFromProps(currentVehicle, allMods, vehiclePlate)
        lib.callback.await("jg-mechanic:server:save-veh-statebag-data-to-db", false, vehiclePlate)
        
        isSelfService = true
        lib.callback.await("jg-mechanic:server:self-service-mods-applied", false, currentMechanicId, VehToNet(currentVehicle), vehiclePlate, cart, totalCost, paymentMethod)
        
        if Config.UpdatePropsOnChange then
            lib.callback.await("jg-mechanic:server:save-vehicle-props", false, vehiclePlate, vehicleProps)
        end
        
        if originalVehicleProperties and vehicleProps then
            originalVehicleProperties.wheels = vehicleProps.wheels
            originalVehicleProperties.modFrontWheels = vehicleProps.modFrontWheels
            originalVehicleProperties.modBackWheels = vehicleProps.modBackWheels
        end
    else
        local success = lib.callback.await("jg-mechanic:server:place-order", false, currentMechanicId, vehiclePlate, cart, totalCost, previewMods, paymentMethod)
        
        if not success then
            cb({error = true})
            return
        end
    end
    
    cb(true)
end)

RegisterNUICallback("exit-mods", function(data, cb)
    closeModMenu()
    cb(true)
end)

RegisterNUICallback("switch-camera", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local modId = data and data.modId
    
    CreateThread(function()
        SetVehicleDoorsShut(currentVehicle, true)
        
        if IsVehicleDoorDamaged(currentVehicle, 4) then
            SetVehicleFixed(currentVehicle)
        end
        
        resetVehicleToOriginalState()
        
        if isModInList({"TOP_HL_CV", "TOP_HLT", "TOP_SUNST", "HEADLIGHTS", "TOP_SPLIT"}, currentVehicle, modId) then
            transitionCamera("frontCamera")
        elseif isModInList({"TOP_TRUNK", "TOP_BOOT", "TOP_TGATE", "TOP_RPNL", "TOP_WINP", "TOP_WBAR", "TOP_COVER", "TOP_LOUV"}, currentVehicle, modId) then
            transitionCamera("backCamera")
        elseif isModInList({"TOP_CAGE"}, currentVehicle, modId) then
            transitionCamera("interior")
        elseif isModInList({"TOP_ROOFSC", "TOP_ROOFFIN"}, currentVehicle, modId) then
            transitionCamera("roof")
        elseif isModInList({"TOP_VALHD", "TOP_ENGHD"}, currentVehicle, modId) then
            transitionCamera("backCamera")
            SetVehicleDoorOpen(currentVehicle, 4, false, true)
        elseif isModInList({"TOP_SIDE_PAN", "TOP_MIR"}, currentVehicle, modId) then
            transitionCamera("sideCamera")
        elseif isModInList({"TOP_CATCH"}, currentVehicle, modId) then
            transitionCamera("engineBay")
        elseif isModInList({"TOP_ENGINE", "TOP_BRACE", "TOP_ENGD"}, currentVehicle, modId) then
            transitionCamera("engineBay")
            
            if GetEntityArchetypeName(currentVehicle) == "z190" then
                SetVehicleDoorBroken(currentVehicle, 4, true)
            end
            
            SetVehicleDoorOpen(currentVehicle, 4, false, true)
        elseif isModInList({1, 6, 26, 42, 43}, currentVehicle, modId) then
            transitionCamera("frontCamera")
        elseif isModInList({37}, currentVehicle, modId) then
            transitionCamera("backCamera")
            SetVehicleDoorOpen(currentVehicle, 5, false, true)
        elseif isModInList({5, 27, 32, "COLOR_INTERIOR"}, currentVehicle, modId) then
            transitionCamera("interior")
        elseif isModInList({4}, currentVehicle, modId) then
            transitionCamera("exhaust")
        elseif isModInList({0, 2, 4, 25, "PLATE_INDEX"}, currentVehicle, modId) then
            transitionCamera("backCamera")
        elseif isModInList({3, 8, 23, 24, "WHEELS"}, currentVehicle, modId) then
            transitionCamera("sideCamera")
        elseif isModInList({7}, currentVehicle, modId) then
            transitionCamera("engineBay")
        elseif isModInList({39, 40, 41}, currentVehicle, modId) then
            transitionCamera("engineBay")
            
            if GetEntityArchetypeName(currentVehicle) == "banshee2" then
                SetVehicleDoorBroken(currentVehicle, 4, true)
            end
            
            SetVehicleDoorOpen(currentVehicle, 4, false, true)
        elseif isModInList({31}, currentVehicle, modId) then
            transitionCamera("doorSpeaker")
        elseif isModInList({28, 29, 30, 33, 34, "COLOR_DASHBOARD"}, currentVehicle, modId) then
            transitionCamera("pov")
        else
            transitionCamera("default")
        end
        
        cb(true)
    end)
end)

RegisterNUICallback("toggle-freecam", function(data, cb)
    if data.enable then
        isFreecamActive = true
        toggleCamTemporarily(false)
    else
        toggleCamTemporarily(true)
        isFreecamActive = false
    end
    
    cb(true)
end)

RegisterNUICallback("move-freecam", function(data, cb)
    if not isFreecamActive then
        cb(false)
        return
    end
    
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    
    CreateThread(function()
        while isFreecamActive do
            DisableAllControlActions(0)
            EnableControlAction(0, 0, false) -- Next Camera
            EnableControlAction(0, 1, true)  -- Look Left/Right
            EnableControlAction(0, 2, true)  -- Look Up/Down
            EnableControlAction(0, 59, true) -- Move Left/Right
            Wait(0)
        end
    end)
    
    cb(true)
end)

RegisterNUICallback("stop-moving-freecam", function(data, cb)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    cb(true)
end)

RegisterNUICallback("repair-vehicle", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleValue = Framework.Client.GetVehicleValue(GetEntityArchetypeName(currentVehicle))
    local success = lib.callback.await("jg-mechanic:server:self-service-repair-vehicle", false, currentMechanicId, vehicleValue, data.paymentMethod)
    
    if success then
        Framework.Client.RepairVehicle(currentVehicle)
        
        if originalVehicleProperties then
            originalVehicleProperties.dirtLevel = 0.0
            originalVehicleProperties.engineHealth = 1000.0
            originalVehicleProperties.bodyHealth = 1000.0
            originalVehicleProperties.tankHealth = 1000.0
            originalVehicleProperties.windowStatus = nil
            originalVehicleProperties.doorStatus = nil
            originalVehicleProperties.tireHealth = nil
            originalVehicleProperties.tireBurstState = nil
            originalVehicleProperties.tireBurstCompletely = nil
            originalVehicleProperties.windowsBroken = nil
            originalVehicleProperties.doorsBroken = nil
            originalVehicleProperties.tyreBurst = nil
        end
    end
    
    cb(true)
end)

RegisterNUICallback("preview-performance-mod", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    local propKey = data.propKey
    local modType = data.modType
    local modIndex = data.modIndex
    local toggleMod = data.toggleMod
    
    SetVehicleModKit(currentVehicle, 0)
    
    if toggleMod then
        ToggleVehicleMod(currentVehicle, modType, modIndex)
        previewMods.performance[propKey] = modIndex
    elseif type(modType) == "number" then
        SetVehicleMod(currentVehicle, modType, modIndex, false)
        previewMods.performance[propKey] = modIndex
    end
    
    cb(true)
end)

RegisterNUICallback("preview-cosmetic-mod", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    local propKey = data.propKey
    local modType = data.modType
    local modIndex = data.modIndex
    local toggleMod = data.toggleMod
    
    SetVehicleModKit(currentVehicle, 0)
    
    if modType == "LIVERY" then
        SetVehicleLivery(currentVehicle, modIndex)
    elseif modType == "LIVERY_ROOF" then
        SetVehicleRoofLivery(currentVehicle, modIndex)
    elseif modType == "PLATE_INDEX" then
        SetVehicleNumberPlateTextIndex(currentVehicle, modIndex)
    elseif modType == "WINDOW_TINT" then
        SetVehicleWindowTint(currentVehicle, modIndex)
    elseif modType == 14 then
        SetVehicleMod(currentVehicle, 14, modIndex, false)
        
        Citizen.CreateThreadNow(function()
            if isHornPlaying then
                isHornPlaying = false
                Wait(10)
            end
            
            isHornPlaying = true
            
            local hornDuration = 100
            local hornData = Config.Mods.Horns[modIndex + 2]
            
            if hornData and hornData.musical then
                hornDuration = 750
            end
            
            while hornDuration > 1 and isHornPlaying do
                SetControlNormal(0, 86, 1.0)
                Wait(1)
                hornDuration = hornDuration - 1
            end
        end)
    elseif toggleMod then
        ToggleVehicleMod(currentVehicle, modType, modIndex)
    elseif type(modType) == "number" then
        SetVehicleMod(currentVehicle, modType, modIndex, false)
    end
    
    previewMods.cosmetics[propKey] = modIndex
    cb(true)
end)

RegisterNUICallback("preview-wheels", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    SetVehicleModKit(currentVehicle, 0)
    SetVehicleWheelType(currentVehicle, data.modType)
    
    previewMods.wheels.wheels = data.modType
    
    SetVehicleMod(currentVehicle, 23, data.modIndex, false)
    previewMods.wheels.modFrontWheels = data.modIndex
    
    if IsThisModelABike(GetEntityModel(currentVehicle)) then
        SetVehicleMod(currentVehicle, 24, data.modIndex, false)
        previewMods.wheels.modBackWheels = data.modIndex
    end
    
    previewMods.wheels.wheelWidth = GetVehicleWheelWidth(currentVehicle)
    previewMods.wheels.wheelSize = GetVehicleWheelSize(currentVehicle)
    
    cb(true)
end)

RegisterNUICallback("preview-pri-sec-colours", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    SetVehicleModKit(currentVehicle, 0)
    
    local vehicleStateObj = Entity(currentVehicle).state
    vehicleStateObj:set("primarySecondarySync", data.primarySecondarySync)
    
    previewMods.respray.primarySecondarySync = data.primarySecondarySync
    
    if data.paintTypeKey == "paintType1" then
        if data.enableRgb then
            SetVehicleModColor_1(currentVehicle, data.paint, 0, 0)
            SetVehicleCustomPrimaryColour(currentVehicle, data.rgbColour[1], data.rgbColour[2], data.rgbColour[3])
            previewMods.respray.color1 = data.rgbColour
        else
            local colorPrimary, colorSecondary = GetVehicleColours(currentVehicle)
            SetVehicleColours(currentVehicle, data.colourId, colorSecondary)
            ClearVehicleCustomPrimaryColour(currentVehicle)
            previewMods.respray.color1 = data.colourId
        end
        
        previewMods.respray.paintType1 = data.paint
    end
    
    if data.paintTypeKey == "paintType2" or data.primarySecondarySync then
        if data.enableRgb then
            SetVehicleModColor_2(currentVehicle, data.paint, 0)
            SetVehicleCustomSecondaryColour(currentVehicle, data.rgbColour[1], data.rgbColour[2], data.rgbColour[3])
            previewMods.respray.color2 = data.rgbColour
        else
            local colorPrimary, colorSecondary = GetVehicleColours(currentVehicle)
            SetVehicleColours(currentVehicle, colorPrimary, data.colourId)
            ClearVehicleCustomSecondaryColour(currentVehicle)
            previewMods.respray.color2 = data.colourId
        end
        
        previewMods.respray.paintType2 = data.paint
    end
    
    cb(true)
end)

RegisterNUICallback("preview-other-colours", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    SetVehicleModKit(currentVehicle, 0)
    
    if data.colourIdKey == "dashboardColor" then
        SetVehicleDashboardColor(currentVehicle, data.colourId)
    elseif data.colourIdKey == "interiorColor" then
        SetVehicleInteriorColor(currentVehicle, data.colourId)
    else
        local pearlescentColor, wheelColor = GetVehicleExtraColours(currentVehicle)
        
        if data.colourIdKey == "pearlescentColor" then
            SetVehicleExtraColours(currentVehicle, data.colourId, wheelColor)
            
            local vehicleStateObj = Entity(currentVehicle).state
            vehicleStateObj:set("disablePearl", data.disablePearl or false)
            
            previewMods.respray.disablePearl = data.disablePearl or false
        elseif data.colourIdKey == "wheelColor" then
            SetVehicleExtraColours(currentVehicle, pearlescentColor, data.colourId)
        end
    end
    
    previewMods.respray[data.colourIdKey] = data.colourId
    cb(true)
end)

RegisterNUICallback("preview-xenons", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    SetVehicleModKit(currentVehicle, 0)
    
    ToggleVehicleMod(currentVehicle, 22, data.enableXenons)
    SetVehicleLights(currentVehicle, 2)
    SetVehicleXenonLightsColor(currentVehicle, data.xenonColor)
    
    previewMods.headlights.modXenon = true
    previewMods.headlights.xenonColor = data.xenonColor
    
    cb(true)
end)

RegisterNUICallback("preview-neons", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    SetVehicleModKit(currentVehicle, 0)
    
    for i = 0, 3 do
        SetVehicleNeonLightEnabled(currentVehicle, i, data.enableNeons[i + 1])
    end
    
    SetVehicleNeonLightsColour(currentVehicle, data.neonColor[1], data.neonColor[2], data.neonColor[3])
    
    previewMods.neonLights.neonEnabled = data.enableNeons
    previewMods.neonLights.neonColor = data.neonColor
    
    cb(true)
end)

RegisterNUICallback("preview-tyre-smoke", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    if isSmokePreviewActive and not data.enableTyreSmoke then
        resetVehicleToOriginalState()
    end
    
    if not isSmokePreviewActive and data.enableTyreSmoke then
        CreateThread(function()
            isSmokePreviewActive = true
            
            if originalBulletproofTyres then
                SetVehicleTyresCanBurst(currentVehicle, false)
            end
            
            SetVehicleEngineOn(currentVehicle, true, true, true)
            SetEntityCollision(currentVehicle, true, true)
            FreezeEntityPosition(currentVehicle, false)
            TaskVehicleTempAction(cache.ped, currentVehicle, 30, 999999)
        end)
    end
    
    SetVehicleModKit(currentVehicle, 0)
    
    ToggleVehicleMod(currentVehicle, 20, data.enableTyreSmoke)
    SetVehicleTyreSmokeColor(currentVehicle, data.tyreSmokeColor[1], data.tyreSmokeColor[2], data.tyreSmokeColor[3])
    
    previewMods.tyreSmoke.modSmokeEnabled = data.enableTyreSmoke
    previewMods.tyreSmoke.tyreSmokeColor = data.tyreSmokeColor
    
    cb(true)
end)

RegisterNUICallback("preview-bulletproof-tyres", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    local disableBulletproof = not data.enableBulletproofTyres
    SetVehicleTyresCanBurst(currentVehicle, disableBulletproof)
    originalBulletproofTyres = disableBulletproof
    
    previewMods.bulletproofTyres.bulletProofTyres = data.enableBulletproofTyres
    
    cb(true)
end)

RegisterNUICallback("preview-extras", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    for extraId, enabled in pairs(data.extras) do
        SetVehicleExtra(currentVehicle, tonumber(extraId), not enabled)
    end
    
    previewMods.extras.extras = data.extras
    
    cb(true)
end)

RegisterNUICallback("preview-stance", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    previewVehicleStance(currentVehicle, data.enableStance, data.defaultStance, data.stance)
    PreviewingNewStance = true
    
    cb(true)
end)

RegisterNUICallback("save-previewed-stance", function(data, cb)
    if not currentVehicle then
        cb(false)
        return
    end
    
    local vehicleState = Entity(currentVehicle).state
    vehicleState:set("unpaidModifications", true, true)
    
    setStanceState(currentVehicle, data.enableStance, data.wheelsAdjIndv, data.defaultStance, data.stance)
    PreviewingNewStance = false
    
    previewMods.stance.enableStance = data.enableStance
    previewMods.stance.wheelsAdjIndv = data.wheelsAdjIndv
    previewMods.stance.defaultStance = data.defaultStance
    previewMods.stance.stance = data.stance
    
    cb(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentVehicle then
            applyPreviewedMods()
            
            local vehicleState = Entity(currentVehicle).state
            vehicleState:set("unpaidModifications", false, true)
            
            toggleVehicleFreeze(currentVehicle, false)
        end
    end
end)