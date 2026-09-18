-- Utilities to run the initial SQL for this resource

-- Split a large SQL string into statements by a given delimiter (e.g., ';')
local function splitSqlStatements(sqlText, delimiter)
  local parts = {}
  local pattern = "([^" .. delimiter .. "]+)"
  for chunk in string.gmatch(sqlText, pattern) do
    local trimmed = string.gsub(chunk, "^%s*(.-)%s*$", "%1")
    table.insert(parts, trimmed)
  end
  return parts
end

-- If enabled, automatically run the SQL in install/database/run.sql at resource start
function initSQL()
  if not Config.AutoRunSQL then return end
  local ok = pcall(function()
    local basePath = GetResourcePath(GetCurrentResourceName())
    local path = basePath .. "/install/database/run.sql"
    local handle = assert(io.open(path, "rb"))
    local sql = handle:read("*all")
    handle:close()
    local statements = splitSqlStatements(sql, ";")
    MySQL.transaction.await(statements)
  end)
  if not ok then
    print("^1[SQL ERROR] There was an error while automatically running the required SQL. Don't worry, you just need to run the SQL file for your framework, found in the 'install/database' folder manually. If you've already ran the SQL code previously, and this error is annoying you, set Config.AutoRunSQL = false^0")
  end
end

initSQL = initSQL
