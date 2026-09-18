local function doesVehicleNeedServicing(plate)
  if not plate then
    return false
  end

  
  local query = "SELECT " .. Framework.VehProps .. " FROM " .. Framework.VehiclesTable .. " WHERE plate = ?"
  local result = MySQL.scalar.await(query, {plate})
  
  if not result then
    return false
  end

 
  local vehicleProps = json.decode(result or "{}")
  
  
  local servicingData = vehicleProps.servicingData
  if not servicingData or type(servicingData) ~= "table" then
    return false
  end

 
  for partName, condition in pairs(servicingData) do
    if condition <= Config.ServiceRequiredThreshold then
      return true
    end
  end

  return false
end
exports("doesVehicleNeedServicing", doesVehicleNeedServicing)

local function getVehicleServiceHistory(plate)
  if not plate then
    return false
  end

  
  local query = [[
    SELECT msh.*, COALESCE(CASE WHEN md.label IS NOT NULL AND TRIM(md.label) != '' THEN md.label ELSE msh.mechanic END, msh.mechanic) AS mechanic_label 
    FROM mechanic_servicing_history msh 
    LEFT JOIN mechanic_data md ON msh.mechanic = md.name 
    WHERE msh.plate = ? 
    ORDER BY date DESC
  ]]
  
  return MySQL.query.await(query, {plate})
end
exports("getVehicleServiceHistory", getVehicleServiceHistory)

local function payForService(source, plate, serviceType)
  
  if not HasActiveTabletConnection(source, plate) then
    return false
  end

  local playerState = Player(source).state
  local serviceConfig = Config.Servicing[serviceType]
  
  if not serviceConfig then
    return false
  end

  local itemName = serviceConfig.itemName
  local itemQuantity = serviceConfig.itemQuantity or 1
  
  if not itemName then
    return false
  end

  local mechanicId = playerState.mechanicId
  if not mechanicId then
    return false
  end

  
  local isEmp = isEmployee(source, mechanicId, {"mechanic", "manager"}, true)
  if not isEmp then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end

  
  if not Framework.Server.RemoveItem(source, itemName, itemQuantity) then
    return false
  end

 
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(source)
  local currentMileage, mileageUnit = exports["jg-vehiclemileage"]:GetMileage(plate)

  
  MySQL.insert.await(
    "INSERT INTO mechanic_servicing_history (identifier, mechanic, plate, mileage_km, serviced_part) VALUES (?, ?, ?, ?, ?)",
    {playerIdentifier, mechanicId, plate, currentMileage, serviceType}
  )

  
  if Webhooks.Servicing then
    sendWebhook(
      source,
      Webhooks.Servicing,
      "Servicing: Vehicle Serviced",
      "success",
      {
        {key = "Mechanic", value = mechanicId},
        {key = "Vehicle Plate", value = plate},
        {key = "Part Serviced", value = Locale[serviceType] or serviceType}
      }
    )
  end

  return true
end
lib.callback.register("jg-mechanic:server:pay-for-service", payForService)

local function getServicingHistory(source, plate)
  local playerState = Player(source).state
  local mechanicId = playerState.mechanicId
  
  if not mechanicId then
    return false
  end


  local isEmp = isEmployee(source, mechanicId, {"mechanic", "manager"}, true)
  if not isEmp then
    Framework.Server.Notify(source, Locale.employeePermissionsError, "error")
    return false
  end


  local serviceHistory = exports["jg-mechanic"]:getVehicleServiceHistory(plate)
  local currentMileage, mileageUnit = exports["jg-vehiclemileage"]:GetMileage(plate)

  return {
    servicingHistory = serviceHistory,
    mileageUnit = mileageUnit
  }
end
lib.callback.register("jg-mechanic:server:get-servicing-history", getServicingHistory)