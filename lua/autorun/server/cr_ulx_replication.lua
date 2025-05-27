-- HACK: Replace ULib replicated convar broadcast on player connect to work around buffer overflow error

if ULib.VERSION > 2.71 then return end

util.AddNetworkString("ULX_CRReplicationReplacement_Part")
util.AddNetworkString("ULX_CRReplicationReplacement_Complete")

hook.Remove(ULib.HOOK_LOCALPLAYERREADY, "ULibSendCvars")
hook.Add(ULib.HOOK_LOCALPLAYERREADY, "ULibSendCvars", function(ply)
    local cvar_data = {}
    for sv_cvar, info in pairs(ULib.repcvars) do
        cvar_data[sv_cvar] = {
            d = info.default,
            c = info.cl_cvar,
            v = info.cvar_obj:GetString()
        }
    end

    local cvarJSON = util.TableToJSON(cvar_data)
    local compressedString = util.Compress(cvarJSON)
    local compressedLen = #compressedString

    local blockSize = 2560
    local offset = 1
    local idx = 1
    while (compressedLen > 0) do
        local sendSize = compressedLen
        if sendSize > blockSize then
            sendSize = blockSize
        end

        net.Start("ULX_CRReplicationReplacement_Part")
            net.WriteUInt(sendSize, 16)
            net.WriteUInt(idx, 16)
            net.WriteData(string.sub(compressedString, offset, offset + sendSize))
        net.Send(ply)

        -- Move up the string
        offset = offset + sendSize
        idx = idx + 1

        -- Keep track of how much we've sent
        compressedLen = compressedLen - sendSize
    end

    -- We've sent everything, so tell the client
    net.Start("ULX_CRReplicationReplacement_Complete")
    net.Send(ply)
end)