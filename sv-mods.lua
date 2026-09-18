local function shouldIgnorePriceMultiplier(categoryName)
  for _, cosmetic in pairs(Config.Mods.Cosmetics) do
    if cosmetic.name == categoryName and cosmetic.ignorePriceMult then
      return true
    end
  end
  return false
end

local function computeModsPrice(locationConfig, vehicleValue, modsByCategory)
  local totalPrice = 0
  local modsConfig = locationConfig.mods

  -- Update prices if using percentage of vehicle value
  if Config.ModsPricesAsPercentageOfVehicleValue then
    for _, modData in pairs(modsConfig) do
      local percent = modData.percentVehVal or 0.01
      modData.price = round(vehicleValue * percent, 0)
    end
  end

  -- Calculate total price for all modifications
  for categoryName, categoryMods in pairs(modsByCategory) do
    local categoryConfig = modsConfig[categoryName]
    if categoryConfig then
      local basePrice = categoryConfig.price or 0
      local priceMultiplier = categoryConfig.priceMult or 0
      local ignoreMultiplier = shouldIgnorePriceMultiplier(categoryName)

      for modName, modData in pairs(categoryMods) do
        local modIndex = modData.modIndex
        local modPrice = basePrice

        -- Apply multiplier if not ignored
        if not ignoreMultiplier and modPrice then
          local multiplier = 1
          if type(modIndex) == "number" and modIndex > 0 then
            multiplier = 1 + (modIndex * priceMultiplier)
          end
          modPrice = round(modPrice * multiplier, 0)
        end

        -- Stock mods are free
        if modIndex == -1 then
          modPrice = 0
        end

        totalPrice = totalPrice + modPrice
      end
    end
  end

  return totalPrice
end

local function purchaseMods(source, mechanicId, vehicleValue, modsByCategory, paymentMethod)
  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    return false
  end

  -- Check if player is employee
  local isEmp = isEmployee(source, mechanicId, {"mechanic", "manager"}, false)

  -- Validate payment method
  if paymentMethod ~= "noPayment" and paymentMethod ~= "mechanic" and paymentMethod ~= "bank" and paymentMethod ~= "cash" then
    Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
    return false
  end

  -- Handle no payment option
  if paymentMethod == "noPayment" then
    if mechanicLocation.type == "owned" and isEmp and not Config.DisableNoPaymentOptionForEmployees then
      return 0
    else
      Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
      return false
    end
  end

  -- Calculate total cost
  local totalCost = computeModsPrice(mechanicLocation, vehicleValue, modsByCategory)

  -- Handle different payment methods
  if paymentMethod == "mechanic" and isEmp and Config.MechanicEmployeesCanSelfServiceMods then
    -- Deduct from society fund
    if not removeFromSocietyFund(source, mechanicId, totalCost) then
      return false
    end
  elseif paymentMethod == "bank" or paymentMethod == "cash" then
    -- Check player balance
    local balance = Framework.Server.GetPlayerBalance(source, paymentMethod)
    if totalCost > balance then
      Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
      return false
    end

    -- Deduct from player
    Framework.Server.PlayerRemoveMoney(source, totalCost, paymentMethod)

    -- Add to society fund for owned businesses
    if mechanicLocation.type == "owned" then
      addToSocietyFund(source, mechanicId, totalCost)
    end
  else
    return false
  end

  return totalCost
end

lib.callback.register("jg-mechanic:server:purchase-mods", purchaseMods)

local function openModsMenu(source, netId)
  if Config.ChangePlateDuringPreview then
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    SetVehicleNumberPlateText(vehicle, Config.ChangePlateDuringPreview)
  end
  return true
end

lib.callback.register("jg-mechanic:server:open-mods-menu", openModsMenu)

local function selfServiceModsApplied(source, mechanicId, netId, plate, cart, totalCost, paymentMethod)
  
  if Config.ChangePlateDuringPreview then
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    SetVehicleNumberPlateText(vehicle, plate)
  end

  
  if Webhooks.SelfService then
    local fields = {}
    
   
    local function concatKeys(tbl, separator)
      local keys = {}
      for k in pairs(tbl) do
        table.insert(keys, k)
      end
      return table.concat(keys, separator)
    end


    for categoryName, mods in pairs(cart) do
      table.insert(fields, {
        key = Locale[categoryName] or categoryName,
        value = concatKeys(mods, ", ")
      })
    end

 
    local transactionFields = {
      {key = "Mechanic", value = mechanicId},
      {key = "Vehicle", value = plate},
      {key = "Paid", value = totalCost},
      {key = "Payment Method", value = paymentMethod}
    }

 
    sendWebhook(
      source, 
      Webhooks.SelfService, 
      "Self-Service Tuning Completed", 
      "success", 
      tableConcat(transactionFields, fields)
    )
  end

  return true
end

lib.callback.register("jg-mechanic:server:self-service-mods-applied", selfServiceModsApplied)

local function placeOrder(source, mechanicId, plate, cart, totalCost, propsToApply, paymentMethod)
  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    return false
  end

 
  local identifier = Framework.Server.GetPlayerIdentifier(source)

 
  local orderId = MySQL.insert.await(
    "INSERT INTO mechanic_orders (identifier, mechanic, plate, cart, props_to_apply, amount_paid) VALUES (?, ?, ?, ?, ?, ?)",
    {
      identifier,
      mechanicId,
      plate,
      json.encode(cart),
      json.encode(propsToApply),
      totalCost
    }
  )

 
  TriggerEvent("jg-mechanic:server:order-placed-config", orderId, mechanicId, plate, cart, totalCost, propsToApply, paymentMethod)

 
  if Webhooks.Orders then
    sendWebhook(
      source,
      Webhooks.Orders,
      "Orders: Order Placed",
      "success",
      {
        {key = "Mechanic", value = mechanicId},
        {key = "Order #", value = orderId},
        {key = "Vehicle", value = plate},
        {key = "Paid", value = totalCost},
        {key = "Payment Method", value = paymentMethod}
      }
    )
  end

  return true
end

lib.callback.register("jg-mechanic:server:place-order", placeOrder)

local function selfServiceRepairVehicle(source, mechanicId, vehicleValue, paymentMethod)
  local mechanicLocation = Config.MechanicLocations[mechanicId]
  if not mechanicLocation then
    return false
  end

  local repairConfig = mechanicLocation.mods.repair
  if not repairConfig.enabled then
    return false
  end

 
  local repairCost = repairConfig.price
  if Config.ModsPricesAsPercentageOfVehicleValue then
    local percent = repairConfig.percentVehVal or 0.01
    repairCost = round(vehicleValue * percent, 0)
  end


  if paymentMethod ~= "bank" and paymentMethod ~= "cash" then
    Framework.Server.Notify(source, "INVALID_PAYMENT_METHOD", "error")
    return false
  end

  
  local balance = Framework.Server.GetPlayerBalance(source, paymentMethod)
  if repairCost > balance then
    Framework.Server.Notify(source, Locale.notEnoughMoney, "error")
    return false
  end


  Framework.Server.PlayerRemoveMoney(source, repairCost, paymentMethod)

  
  if mechanicLocation.type == "owned" then
    addToSocietyFund(source, mechanicId, repairCost)
  end

  return true
end

lib.callback.register("jg-mechanic:server:self-service-repair-vehicle", selfServiceRepairVehicle)

local function countCurrentlyOnDuty(mechanicId)
  local mechanicsOnDuty = GlobalState.mechanicsOnDuty or {}
  local count = 0

  for playerId, assignedMechanicId in pairs(mechanicsOnDuty) do
    if assignedMechanicId == mechanicId then
      local playerPed = GetPlayerPed(playerId)
      if DoesEntityExist(playerPed) then
        count = count + 1
      end
    end
  end

  return count
end

lib.callback.register("jg-mechanic:server:count-currently-on-duty", countCurrentlyOnDuty)