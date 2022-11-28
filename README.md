# Stateful-Turtle-Base

State-saving turtle scripts for the Minecraft Computercraft Mod.


Due to Computercraft´s internal implementation, any turtle will reinitialize once it gets reloaded (or the world). This is especially painfull, as for example long-running turtles (like Mining Turtles) tend to leave loaded chunks quite often. To mitigate the issue of running back to the turtle, breaking it, placing it in the starting location and starting any given program, you can implement your logic using this script base. The turtle will save its state during execution and simply pick the program state whereever the shutdown happened.

To terminate a program, send a KeyboardInterrupt (Termination Event) at any given point in time.


The following example program tries to move the turtle 3 blocks forward, then quits.

```lua
local instructions = {
    m = function()
        turtle.forward()
    end
}
```

```lua
local function buildProgram()
    return "mmm", false   -- set me to true, if the program should be looped
end
```
