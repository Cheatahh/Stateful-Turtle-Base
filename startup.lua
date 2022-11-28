--- EDIT SECTION --- Script: Example turtle program

-- Example Display Name
local name = "Example Turtle Program"

-- Example Config
local config = {
    steps = { 0 } -- default value
}

-- Function to build the initial config
-- Only called on initial turtle setup
local function buildConfig()
    print("Enter the amount of steps:")
    config.steps[1] = tonumber(io.read())
    print("Set config.steps to ", config.steps[1])
end

-- Intruction Lookup
-- Mapping   Char => Function
local instructions = {
    m = function()
        turtle.forward()
    end
}

-- Function to build the program (string of instruction chars)
-- Program will be looped
local function buildProgram()
    return string.rep("m", config.steps[1]), false
end

--- INTERNAL SECTION --- utility

local function splitString(str, pat) -- Source: http://lua-users.org/wiki/SplitJoin
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fPat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fPat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e+1
        s, e, cap = str:find(fPat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

--- INTERNAL SECTION --- config io

local function writeConfig()
    local fileHandle = fs.open("config.txt", "w")
    if not fileHandle then
        error("Config could not be saved")
        return false
    end
    for key, value in pairs(config) do
        if type(key) ~= "string" then
            error("Config keys should be string")
            return false
        end
        if type(value) ~= "table" then
            error("Config values should be tables")
            return false
        end
        fileHandle.writeLine(key.." = ".. table.concat(value, ", "))
    end
    fileHandle.close()
    return true
end

local function readConfig()
    local fileHandle = fs.open("config.txt", "r")
    if not fileHandle then
        return false
    end
    while true do
        local line = fileHandle.readLine()
        if not line or #line < 3 then break end
        local keyData = splitString(line, "%s*=%s*")
        if #keyData ~= 2 then
            error("Insufficient attribute syntax (required: name = value, ...) at\n", line)
            return false
        end
        local valueData = splitString(keyData[2], "%s*,%s*")
        config[keyData[1]] = valueData
    end
    fileHandle.close()
    return true
end

--- INTERNAL SECTION --- state io

local initialState

local function writeState(state)
    local fileHandle = fs.open("state", "w")
    if not fileHandle then
        error("State could not be saved")
        return
    end
    fileHandle.write(state)
    fileHandle.close()
end

local function readState()
    local fileHandle = fs.open("state", "r")
    if not fileHandle then return end
    initialState = tonumber(fileHandle.readAll())
    fileHandle.close()
end

--- INTERNAL SECTION --- async worker thread

local workerThreadEventFilter
local workerThread
local function resumeWorkerThread(event, ...)
    if not workerThreadEventFilter or workerThreadEventFilter == event or event == "terminate" then
        local _, message = coroutine.resume(workerThread, event, ...)
        if coroutine.status(workerThread) == "dead" then
            workerThread = nil
        end
        workerThreadEventFilter = message
    end
end
local function startWorkerThread(workerFn, terminationFn)
    workerThread = coroutine.create(workerFn)
    resumeWorkerThread()
    repeat
        local event = { os.pullEventRaw() }
        resumeWorkerThread(table.unpack(event))
    until event[1] == 'terminate' or not workerThread
    -- termination event
    terminationFn()
end

--- INTERNAL SECTION --- main

print(name)

readState()
if not initialState then
    readConfig()
    buildConfig()
    writeConfig()
else
    if not readConfig() then
        print("Could not read initial config. Using the default config instead.")
    end
end

-- build program
local program, loopProgram = buildProgram()
if type(program) ~= "string" then
    error("Function buildProgram() must return a string.")
end

-- build instructions
local instructionsArray = {}
instructionsArray[256] = function(utf)
    print("Unknown instruction '"..string.char(utf).."'")
end
for utfChar = 1, 255 do
    instructionsArray[utfChar] = instructionsArray[256]
end
for key, fun in pairs(instructions) do
    if type(key) ~= "string" or #key ~= 1 then
        error("Instruction keys should be single characters")
    end
    if type(fun) ~= "function" then
        error("Instruction values should be functions")
    end
    local byteValue = string.byte(key)
    if byteValue < 0 or byteValue > 255 then
        error("Instruction keys should be a single UTF8 character")
    end
    instructionsArray[byteValue + 1] = fun
end

-- interpreter
print("Starting execution, hold CTRL-T for 3 seconds to exit.")

--initialize interpreter execution
if not initialState or initialState <= 0 or initialState > #program then
    initialState = 1
end
local function runIteration(startState)
    for state = startState, #program do
        writeState(state)
        local instruction = string.byte(program, state)
        instructionsArray[instruction + 1](instruction)
    end
end

startWorkerThread(function()
    -- main function
    runIteration(initialState)
    if loopProgram then
        while true do
            runIteration(1)
        end
    end
end, function()
    print("Terminating execution, deleting state")
    fs.delete("state")
end)
