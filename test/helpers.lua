-- Helper functions for the test suite

-- assert library used by busted
local assert = require("luassert")

-- gloabl varables to set $XDG_CONFIG_HOME and $XDG_DATA_HOME to for the
-- tests.
local tmp = os.getenv("TMPDIR") or "/tmp"
local confdir = tmp .. "/nvimpager-testsuite/no-config"
local datadir = tmp .. "/nvimpager-testsuite/no-data"

-- Run a shell command, assert it terminates with return code 0 and return its
-- output.
--
-- The assertion of the return status works even with Lua 5.1.  The last byte
-- of output of the command *must not* be a decimal digit.
--
-- command: string -- the shell command to execute
-- returns: string -- the output of the command
local function run(command)
  -- From Lua 5.2 on we could use io.close to retrieve the return status of
  -- the process.  It would return true, "exit", x where x is the status.
  -- For Lua 5.1 (currently used by neovim) we have to echo the return status
  -- in the shell command and extract it from the output.
  -- References:
  -- https://www.lua.org/manual/5.1/manual.html#pdf-io.close
  -- https://www.lua.org/manual/5.1/manual.html#pdf-file:close
  -- https://www.lua.org/manual/5.2/manual.html#pdf-io.close
  -- https://www.lua.org/manual/5.2/manual.html#pdf-file:close
  -- https://www.lua.org/manual/5.2/manual.html#pdf-os.execute
  -- https://stackoverflow.com/questions/7607384
  command = string.format("XDG_CONFIG_HOME=%s XDG_DATA_HOME=%s %s; echo $?",
    confdir, datadir, command)
  local proc = io.popen(command)
  local output = proc:read('*a')
  local status = {proc:close()}
  -- This is *not* the return value of the command.
  assert.equal(true, status[1])
  -- In Lua 5.2 we could also assert this and it would be meaningful:
  -- assert.equal("exit", status[2])
  -- assert.equal(0, status[3])
  -- For Lua 5.1 we have echoed the return status with the output.  First we
  -- assert the last two bytes, which is easy:
  assert.equal("0\n", output:sub(-2), "command failed")
  -- When the original command did not produce any output this is it.
  if #output ~= 2 then
    -- Otherwise we can only hope that the command did not produce a digit as
    -- it's last character of output.
    assert.is_nil(tonumber(output:sub(-3, -3)), "command failed")
  end
  -- If the assert succeeded we can remove two bytes from the end.
  return output:sub(1, -3)
end

-- Read contents of a file and return them.
--
-- filename: string -- the name of the file to read
-- returns: string -- the contents of the file
local function read(filename)
  local file = io.open(filename)
  local contents = file:read('*a')
  return contents
end

-- Write contents to a file.
--
-- filename: string -- the name of the file to write
-- contents: string -- the contents to write to the file
-- returns: nil
local function write(filename, contents)
  local handle = io.open(filename, "w")
  if handle == nil then assert.not_nil(handle, "could not open file") end
  handle:write(contents)
  handle:flush()
  handle:close()
end

-- Freshly require the nvimpager module, optinally with mocks
--
-- api: table|nil -- a mock for the neovim api table (:help lua-api)
-- return: table -- the nvimpager module
local function load_nvimpager(api)
  -- Create a local mock of the vim module that is provided by neovim.
  local default_api = {
    nvim_get_hl_by_id = function() return {} end,
    -- These can return different types so we just default to nil.
    nvim_call_function = function() end,
    nvim_get_option = function() end,
  }
  if api == nil then
    api = default_api
  else
    for key, value in pairs(default_api) do
      if api[key] == nil then api[key] = value end
    end
  end
  local vim = { api = api }
  -- Register the api mock in the globals.
  _G.vim = vim
  -- Reload the nvimpager script
  package.loaded["lua/nvimpager"] = nil
  return require("lua/nvimpager")
end

-- generator for random strings
local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local len = chars:len()
local function random(count)
  local i = math.random(len)
  if count == nil or count <= 1 then return chars:sub(i, i) end
  return chars:sub(i, i) .. random(count - 1)
end

return {
  confdir = confdir,
  datadir = datadir,
  load_nvimpager = load_nvimpager,
  read = read,
  run = run,
  write = write,
}
