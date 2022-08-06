--- EDIT SECTION --- Script: Example turtle program

local name = "Example Turtle Program"

local config = {
    steps = { 0 } -- default value
}

local function buildConfig()
    print("Enter the amount of steps:")
    config.steps[1] = tonumber(io.read())
    print("Set config.steps to ", config.steps[1])
end

local instructions = {
    m = function()
        turtle.forward()
    end
}

local function buildProgram()
    return string.rep("m", config.steps[1]), false
end

--- INTERNAL ---
local function a(b,c)local d={}local e="(.-)"..c;local f=1;local g,h,i=b:find(e,1)while g do if g~=1 or i~=""then table.insert(d,i)end;f=h+1;g,h,i=b:find(e,f)end;if f<=#b then i=b:sub(f)table.insert(d,i)end;return d end;local function j()local k=fs.open("config.txt","w")if not k then error("Config could not be saved")return false end;for l,m in pairs(config)do if type(l)~="string"then error("Config keys should be string")return false end;if type(m)~="table"then error("Config values should be tables")return false end;k.writeLine(l.." = "..table.concat(m,", "))end;k.close()return true end;local function n()local k=fs.open("config.txt","r")if not k then return false end;while true do local o=k.readLine()if not o or#o<3 then break end;local p=a(o,"%s*=%s*")if#p~=2 then error("Insufficient attribute syntax (required: name = value, ...) at\n",o)return false end;local q=a(p[2],"%s*,%s*")config[p[1]]=q end;k.close()return true end;local r;local function s(t)local k=fs.open("state","w")if not k then error("State could not be saved")return end;k.write(t)k.close()end;local function u()local k=fs.open("state","r")if not k then return end;r=tonumber(k.readAll())k.close()end;local v;local w;local function x(y,...)if not v or v==y or y=="terminate"then local _,A=coroutine.resume(w,y,...)if coroutine.status(w)=="dead"then w=nil end;v=A end end;local function B(C,D)w=coroutine.create(C)x()repeat local y={os.pullEventRaw()}x(table.unpack(y))until y[1]=='terminate'or not w;D()end;print(name)u()if not r then n()buildConfig()j()else if not n()then print("Could not read initial config. Using the default config instead.")end end;local E,F=buildProgram()if type(E)~="string"then error("Function buildProgram() must return a string.")end;local G={}G[256]=function(H)print("Unknown instruction '"..string.char(H).."'")end;for I=1,255 do G[I]=G[256]end;for l,J in pairs(instructions)do if type(l)~="string"or#l~=1 then error("Instruction keys should be single characters")end;if type(J)~="function"then error("Instruction values should be functions")end;local K=string.byte(l)if K<0 or K>255 then error("Instruction keys should be a single UTF8 character")end;G[K+1]=J end;print("Starting execution, hold CTRL-T for 3 seconds to exit.")if not r or r<=0 or r>#E then r=1 end;local function L(M)for t=M,#E do s(t)local N=string.byte(E,t)G[N+1](N)end end;B(function()L(r)if F then while true do L(1)end end end,function()print("Terminating execution, deleting state")fs.delete("state")end)