local resourceName = "jg-mechanic"
local versionURL = "https://raw.githubusercontent.com/jgscripts/versions/main/" .. resourceName .. ".txt"

local function compareVersions(current, latest)
    local currentParts = {}
    for part in string.gmatch(current, "[^.]+") do
        table.insert(currentParts, tonumber(part))
    end

    local latestParts = {}
    for part in string.gmatch(latest, "[^.]+") do
        table.insert(latestParts, tonumber(part))
    end

    for i = 1, math.max(#currentParts, #latestParts) do
        local currentVal = currentParts[i] or 0
        local latestVal = latestParts[i] or 0
        if currentVal < latestVal then
            return true
        end
    end
    return false
end

PerformHttpRequest(versionURL, function(status, response, headers)
    if status ~= 200 then
        print("^1Unable to perform update check")
        return
    end

    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    if not currentVersion then return end

    if currentVersion == "dev" then
        print("^3Using dev version")
        return
    end

    local latestVersion = response:match("^[^\n]+")
    if not latestVersion then return end

    if compareVersions(currentVersion:sub(2), latestVersion:sub(2)) then
        print("^3Update available for " .. resourceName .. "! (current: ^1" .. currentVersion .. "^3, latest: ^2" .. latestVersion .. "^3)")
        print("^3Release notes: discord.gg/jgscripts")
    end
end, "GET")

local function checkArtifactVersion()
    local version = GetConvar("version", "unknown")
    local buildNumber = string.match(version, "v%d+%.%d+%.%d+%.(%d+)")

    PerformHttpRequest("https://artifacts.jgscripts.com/check?artifact=" .. buildNumber, function(status, response, headers, errorData)
        if status ~= 200 or errorData then
            print("^1Could not check artifact version^0")
            return
        end

        if not response then return end

        local data = json.decode(response)
        if data.status == "BROKEN" then
            print("^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0")
            print("^0Artifact version:^3" .. buildNumber .. "\n^0Known issues:^3" .. data.reason .. "^0")
        end
    end)
end

CreateThread(function()
    checkArtifactVersion()
end)