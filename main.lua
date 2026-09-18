-- JG Mechanic shared functions and globals
Globals = {}
Functions = {}

-- Set locale
Locale = Locales[Config.Locale or "en"]

-- Export config
exports("config", function()
    return Config
end)

-- Debug print function
function debugPrint(resource, level, ...)
    if not Config.Debug then
        return
    end
    
    local prefix = "^2[DEBUG]^7"
    if level == "warning" then
        prefix = "^3[WARNING]^7"
    end
    
    local args = {...}
    local message = ""
    
    for i = 1, #args do
        local arg = args[i]
        local argType = type(arg)
        
        if argType == "table" then
            message = message .. json.encode(arg)
        elseif argType ~= "string" then
            message = message .. tostring(arg)
        else
            message = message .. arg
        end
        
        if i ~= #args then
            message = message .. " "
        end
    end
    
    print(prefix, resource, message)
end

-- Get trimmed vehicle plate
function getTrimmedVehiclePlate(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            return string.gsub(plate, "^%s*(.-)%s*$", "%1")
        end
    end
    return false
end

-- Check if vehicle is electric
function isVehicleElectric(vehicle)
    local buildNumber = GetGameBuildNumber()
    if buildNumber >= 3258 then
        return Citizen.InvokeNative(2290933623539066425, joaat(vehicle)) == 1
    end
    return lib.table.contains(Config.ElectricVehicles, vehicle)
end

-- Round number function
function round(number, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

-- Deep merge tables
function deepMerge(target, source)
    for key, value in pairs(source) do
        local valueType = type(value)
        if valueType == "table" then
            local targetType = type(target[key])
            if targetType == "table" then
                deepMerge(target[key], value)
            end
        elseif value == "nil (deleted)" then
            target[key] = nil
        else
            target[key] = value
        end
    end
    return target
end

-- Concatenate tables
function tableConcat(table1, table2)
    local result = {}
    
    if #table1 > 0 and #table2 > 0 then
        for i = 1, #table1 do
            result[#result + 1] = table1[i]
        end
        for i = 1, #table2 do
            result[#result + 1] = table2[i]
        end
    else
        for key, value in pairs(table1) do
            result[key] = value
        end
        for key, value in pairs(table2) do
            result[key] = value
        end
    end
    
    return result
end

-- Get table keys
function tableKeys(table)
    local keys = {}
    for key, _ in pairs(table) do
        keys[#keys + 1] = key
    end
    return keys
end

-- Bit operations
function bitOper(a, b, operation)
    local result = 0
    local maxInt = 2.147483648E9
    local temp = 0
    
    repeat
        local sum = a + b + maxInt
        a = a % maxInt
        b = b % maxInt
        temp = sum
        local diff = maxInt * operation % (temp - a - b)
        result = result + diff
        maxInt = maxInt / 2
    until maxInt < 1
    
    return result
end

-- Check if flag is set
function hasFlag(value, flag)
    return bitOper(value, flag, 4) == flag
end

-- Add flag
function addFlag(value, flag)
    if hasFlag(value, flag) then
        return value
    end
    return math.floor(bitOper(value, flag, 1))
end

-- Remove flag
function removeFlag(value, flag)
    if not hasFlag(value, flag) then
        return value
    end
    return math.floor(bitOper(value, flag, 3))
end

-- Parse control binding
function parseControlBinding(control)
    local binding = GetControlInstructionalButton(0, control, true)
    local cleanBinding = string.gsub(binding, "^t_", "")
    
    if binding ~= cleanBinding then
        return cleanBinding
    end
    
    if CONTROL_KEYBINDS[binding] then
        return CONTROL_KEYBINDS[binding]
    end
    
    return binding
end
