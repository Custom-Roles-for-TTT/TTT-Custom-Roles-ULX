-- HACK: Replace ULib replicated convar broadcast on player connect to work around buffer overflow error

if ULib.VERSION > 2.71 then return end

-- Copied from ulib/client/cl_util.lua
-- Slightly modified

local cvarinfo = {} -- Stores the client cvar object indexed by name of the server cvar
local reversecvar = {} -- Stores the name of server cvars indexed by the client cvar

-- When our client side cvar is changed, notify the server to change it's cvar too.
local function clCvarChanged(cl_cvar, oldvalue, newvalue)
    if not reversecvar[cl_cvar] then -- Error
        return
    elseif reversecvar[cl_cvar].ignore then -- ignore
        reversecvar[cl_cvar].ignore = nil
        return
    end

    local sv_cvar = reversecvar[cl_cvar].sv_cvar
    RunConsoleCommand("ulib_update_cvar", sv_cvar, newvalue)
end

local function repWriteCvar(sv_cvar, cl_cvar, default_value, current_value)
    cvarinfo[sv_cvar] = GetConVar(cl_cvar) or CreateClientConVar(cl_cvar, default_value, false, false) -- Make sure it's created one way or another (second case is most common)
    reversecvar[cl_cvar] = { sv_cvar=sv_cvar }

    ULib.queueFunctionCall(function() -- Queued to ensure we don't overload the client console
        hook.Call(ULib.HOOK_REPCVARCHANGED, _, sv_cvar, cl_cvar, nil, nil, current_value)
        if cvarinfo[sv_cvar]:GetString() ~= current_value then
            reversecvar[cl_cvar].ignore = true -- Flag so hook doesn't do anything. Flag is removed at hook.
            RunConsoleCommand(cl_cvar, current_value)
        end
    end)

    cvars.AddChangeCallback(cl_cvar, clCvarChanged)
end

-- This is the counterpart to <replicatedWithWritableCvar>. See that function for more info. We also add callbacks from here.

net.Receive("ulib_repWriteCvar", function(len)
    local sv_cvar = net.ReadString()
    local cl_cvar = net.ReadString()
    local default_value = net.ReadString()
    local current_value = net.ReadString()
    repWriteCvar(sv_cvar, cl_cvar, default_value, current_value)
end)

-- This is called when they've attempted to change a cvar they don't have access to.

net.Receive("ulib_repChangeCvar", function(len)
    local ply = net.ReadEntity()
    local cl_cvar = net.ReadString()
    local oldvalue = net.ReadString()
    local newvalue = net.ReadString()
    local changed = oldvalue ~= newvalue

    if not reversecvar[cl_cvar] then -- Error!
        return
    end

    local sv_cvar = reversecvar[cl_cvar].sv_cvar
    ULib.queueFunctionCall(function() -- Queued so we won't overload the client console and so that changes are always going to be called via the hook AFTER the initial hook is called
        if changed then
            hook.Call(ULib.HOOK_REPCVARCHANGED, _, sv_cvar, cl_cvar, ply, oldvalue, newvalue)
        end

        if GetConVar(cl_cvar):GetString() ~= newvalue then
            reversecvar[cl_cvar].ignore = true -- Flag so hook doesn't do anything. Flag is removed at hook.
            RunConsoleCommand(cl_cvar, newvalue)
        end
    end)
end)

-- End copied from ulib/client/cl_util.lua

local compressedCvars = {}
net.Receive("ULX_CRReplicationReplacement_Part", function()
    local len = net.ReadUInt(16)
    local idx = net.ReadUInt(16)
    compressedCvars[idx] = net.ReadData(len)
end)

net.Receive("ULX_CRReplicationReplacement_Complete", function()
    local cvarCount = table.Count(compressedCvars)
    local compressedString = ""
    for idx = 1, cvarCount do
        compressedString = compressedString .. compressedCvars[idx]
    end

    local cvarJSON = util.Decompress(compressedString)
    local results = util.JSONToTable(cvarJSON)

    for sv_cvar, info in pairs(results) do
        repWriteCvar(sv_cvar, info.c, info.d, info.v)
    end

    compressedCvars = {}
end)