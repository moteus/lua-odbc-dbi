---
-- ODBC connector for Lua-DBI library
--

local odbc = require "odbc"

local DBD_ODBC_CONNECTION = "DBD.ODBC.Connection"
local DBD_ODBC_STATEMENT  = "DBD.ODBC.Statement"

local Connection, Statement

local function odbc_error(err)
  return tostring(err)
end

local function odbc_return(ok, ...)
  if not ok then return nil, odbc_error(...) end
  return ok, ...
end

local function Statement_new(stmt)
  local self = setmetatable({
    _stmt = stmt,
  }, Statement)

  return self
end

Connection = {} do

Connection.__index = Connection

function Connection.New(self, ...)
  local cnn, err
  if self == Connection then
    cnn, err = odbc.connect(...)
  else
    cnn, err = odbc.connect(self, ...)
  end
  if not cnn then return odbc_return(nil, err) end

  self = setmetatable({
    _cnn = cnn
  }, Connection)

  return self
end

function Connection:ping()
  return not not self._cnn:connected()
end

function Connection:autocommit(turn_on)
  return odbc_return(self._cnn:setautocommit(turn_on))
end

function Connection:close(turn_on)
  if self._cnn then
    local env = self._cnn:environment()
    self._cnn:destroy()
    env:destroy()
    self._cnn = nil
  end
  return true
end

function Connection:commit()
  return odbc_return(self._cnn:commit())
end

function Connection:rollback()
  return odbc_return(self._cnn:rollback())
end

function Connection:prepare(sql)
  local ok, err = self._cnn:prepare(sql)
  if not ok then return odbc_return(nil, err) end
  return Statement_new(ok)
end

function Connection:quote(sql)
  error("Not implemented")
end

function Connection:__tostring()
  local ptr
  if not self._cnn then ptr = 'closed'
  else ptr = tostring(self._cnn) end

  return DBD_ODBC_CONNECTION .. ": " .. ptr
end

end

Statement = {} do
Statement.__index = Statement

function Statement:close()
  if self._stmt then
    self._stmt:destroy()
  end
  return true
end

function Statement:columns()
  return odbc_return(self._stmt:colnames())
end

function Statement:execute(...)
  assert(self._stmt:prepared())

  self._rows_affected = nil

  local n = select('#', ...)
  if n > 0 then
    local args = {...}
    for i = 1, n do
      local ok, err = self._stmt:bind(i, args[i])
      if not ok then return odbc_return(nil, err) end
    end
  end

  local ok, err = self._stmt:execute()
  if not ok then return odbc_return(nil, err) end

  if type(ok) == 'number' then
    self._rows_affected = ok
  else
    self._rows_affected = self._stmt:rowcount()
  end

  return true
end

function Statement:fetch(named_columns)
  local row, err = self._stmt:fetch({}, named_columns and "a" or "n")
  return odbc_return(row, err)
end

function Statement:affected()
  return self._rows_affected
end

function Statement:rowcount()
  return self._rows_affected
end

function Statement:rows(named_columns)
  local res, fetch_mode = {}, named_columns and "a" or "n"
  return function ()
    local res, err = self._stmt:fetch(res, fetch_mode)
    if res then return res end
    if err then error(tostring(err)) end
  end
end

function Statement:__tostring()
  local ptr
  if not self._stmt then ptr = 'closed'
  else ptr = tostring(self._stmt) end

  return DBD_ODBC_STATEMENT .. ": " .. ptr
end

end

if tonumber(string.sub(_VERSION, -3)) < 5.2 then
  package.loaded[DBD_ODBC_CONNECTION] = Connection
end

return Connection