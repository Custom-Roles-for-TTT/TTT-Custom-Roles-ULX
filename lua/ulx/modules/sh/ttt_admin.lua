local CATEGORY_NAME = "TTT"
local gamemode_error = "The current gamemode is not trouble in terrorist town!"

if SERVER then
    util.AddNetworkString("TTT_RoleChanged")
end

--[Ulx Completes]------------------------------------------------------------------------------
ulx.target_role = {}
local function UpdateRoles()
    table.Empty(ulx.target_role)

    for wrole = 0, ROLE_MAX or 25 do
        table.insert(ulx.target_role, ROLE_STRINGS_RAW[wrole])
    end
end

hook.Add(ULib.HOOK_UCLCHANGED, "ULXRoleNamesUpdate", UpdateRoles)
--updateNextround()
--UpdateRoles()

--[End]----------------------------------------------------------------------------------------

--[Global Helper Functions][Used by more than one command.]------------------------------------

--[[SetRole][Changes the role of the given player to the specified role]
@param  {[PlayerObject]} ply     [The player to change role.]
@param  {[Integer]}      role    [The player role to set.]
--]]
function SetRole(ply, role)
    ply:SetRole(role)

    if SERVER then
        net.Start("TTT_RoleChanged")
        net.WriteString(ply:SteamID64())
        net.WriteUInt(role, 8)
        net.Broadcast()
    end
end

--[[SendMessages][Sends messages to player(s)]
@param  {[PlayerObject]} v       [The player(s) to send the message to.]
@param  {[String]}       message [The message that will be sent.]
--]]
function SendMessages(v, message)
    if type(v) == "Players" then
        v:ChatPrint(message)
    elseif type(v) == "table" then
        for i = 1, #v do
            v[i]:ChatPrint(message)
        end
    end
end

--[[CorpseRemove][Gets the player owner of th corpse given.]
@param  {[Ragdoll]} corpse [The corpse whose owner is being found.]
--]]
function GetPlayerFromCorpse(corpse)
    return player.GetBySteamID64(corpse.sid64) or player.GetBySteamID(corpse.sid)
end

--[[CorpseFind][Finds the corpse of a given player.]
@param  {[PlayerObject]} v       [The player that to find the corpse for.]
--]]
function CorpseFind(v)
    for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
        if (ent.sid64 == v:SteamID64() or ent.sid == v:SteamID()) and IsValid(ent) then
            return ent or false
        end
    end
end

--[[CorpseRemove][Removes the corpse given.]
@param  {[Ragdoll]} corpse [The corpse to be removed.]
--]]
function CorpseRemove(corpse)
    CORPSE.SetFound(corpse, false)
    if string.find(corpse:GetModel(), "zm_", 6, true) or corpse.player_ragdoll then
        GetPlayerFromCorpse(corpse):SetNWBool("body_found", false)
        corpse:Remove()
        SendFullStateUpdate()
    end
end

--[[corpse_identify][Identifies the given corpse.]
@param  {[Ragdoll]} corpse [The corpse to be identified.]
--]]
function CorpseIdentify(corpse)
    if corpse then
        GetPlayerFromCorpse(corpse):SetNWBool("body_found", true)
        CORPSE.SetFound(corpse, true)
    end
end

--[End]----------------------------------------------------------------------------------------


--[Slay next round]---------------------------------------------------------------------------------
--[[ulx.slaynr][Kills <target(s)> at the start of the next round(s).]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[Number]}       num_slay      [The number of rounds the player(s) will be killed for.]
@param  {[Boolean]}      should_slaynr [If the number of rounds should be added or removed from the total.]
--]]
function ulx.slaynr(calling_ply, target_ply, num_slay, should_slaynr)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        if ulx.getExclusive(target_ply, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
        elseif num_slay < 0 then
            ULib.tsayError(calling_ply, "Invalid integer:\"" .. num_slay .. "\" specified.", true)
        else
            local current_slay = tonumber(target_ply:GetPData("slaynr_slays")) or 0
            local new_slay
            if not should_slaynr then
                new_slay = current_slay + num_slay
            else
                new_slay = current_slay - num_slay
            end

            --local slay_reason = reason
            --if slay_reason == "reason" then
            --    slay_reason = false
            --end

            if new_slay > 0 then
                target_ply:SetPData("slaynr_slays", new_slay)
                --target_ply:SetPData("slaynr_reason", slay_reason)
            else
                target_ply:RemovePData("slaynr_slays")
                --target_ply:RemovePData("slaynr_reason")
            end

            local slays_left = tonumber(target_ply:GetPData("slaynr_slays")) or 0
            local slays_removed = (current_slay - slays_left) or 0

            local chat_message = nil
            if slays_removed == 0 then
                chat_message = ("#T will not be slain next round.")
            elseif slays_removed > 0 then
                chat_message = ("#A removed " .. slays_removed .. " round(s) of slaying from #T.")
            elseif slays_left == 1 then
                chat_message = ("#A will slay #T next round.")
            elseif slays_left > 1 then
                chat_message = ("#A will slay #T for the next " .. tostring(slays_left) .. " rounds.")
            end

            if chat_message ~= nil then
                ulx.fancyLogAdmin(calling_ply, chat_message, target_ply)
            end
        end
    end
end

local slaynr = ulx.command(CATEGORY_NAME, "ulx slaynr", ulx.slaynr, "!slaynr")
slaynr:addParam { type = ULib.cmds.PlayerArg }
slaynr:addParam { type = ULib.cmds.NumArg, max = 100, default = 1, hint = "rounds", ULib.cmds.optional, ULib.cmds.round }
slaynr:addParam { type = ULib.cmds.BoolArg, invisible = true }
slaynr:defaultAccess(ULib.ACCESS_ADMIN)
slaynr:help("Slays target(s) for a number of rounds")
slaynr:setOpposite("ulx rslaynr", { _, _, _, true }, "!rslaynr")
--[Helper Functions]---------------------------------------------------------------------------
hook.Add("TTTBeginRound", "SlayPlayersNextRound", function()
    local affected_plys = {}

    for _, v in pairs(player.GetAll()) do
        local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0

        if v:Alive() and slays_left > 0 then
            slays_left = slays_left - 1

            if slays_left == 0 then
                v:RemovePData("slaynr_slays")
                v:RemovePData("slaynr_reason")
            else
                v:SetPData("slaynr_slays", slays_left)
            end

            v:StripWeapons()

            table.insert(affected_plys, v)

            timer.Create("check" .. v:SteamID(), 0.1, 0, function() --workaround for issue with tommys damage log

                v:Kill()

                GAMEMODE:PlayerSilentDeath(v)

                local corpse = CorpseFind(v)
                if corpse then
                    v:SetNWBool("body_found", true)
                    SendFullStateUpdate()

                    if string.find(corpse:GetModel(), "zm_", 6, true) then
                        corpse:Remove()
                    elseif corpse.player_ragdoll then
                        corpse:Remove()
                    end
                end

                v:SetTeam(TEAM_SPEC)
                if v:IsSpec() then timer.Destroy("check" .. v:SteamID()) return end
            end)

            timer.Create("traitorcheck" .. v:SteamID(), 1, 0, function() --have to wait for gamemode before doing this
                if v:IsTraitorTeam() then
                    SendConfirmedTraitors(GetInnocentFilter(false)) -- Update innocent's list of traitors.
                    SCORE:HandleBodyFound(v, v)
                end
            end)
        end
    end

    local slay_message
    for i = 1, #affected_plys do
        local v = affected_plys[i]
        local string_inbetween

        if i > 1 and #affected_plys == i then
            string_inbetween = " and "
        elseif i > 1 then
            string_inbetween = ", "
        end

        string_inbetween = string_inbetween or ""
        slay_message = ((slay_message or "") .. string_inbetween)
        slay_message = ((slay_message or "") .. v:Nick())
    end

    local slay_message_context
    if #affected_plys == 1 then slay_message_context = "was" else slay_message_context = "were" end
    if #affected_plys ~= 0 then
        ULib.tsay(_, slay_message .. " " .. slay_message_context .. " slain.")
    end
end)

hook.Add("PlayerSpawn", "Inform", function(ply)
    local slays_left = tonumber(ply:GetPData("slaynr_slays")) or 0
    local slay_reason = false

    if ply:Alive() and slays_left > 0 then
        local chat_message = ""

        if slays_left > 0 then
            chat_message = (chat_message .. "You will be slain this round")
        end
        if slays_left > 1 then
            chat_message = (chat_message .. " and " .. (slays_left - 1) .. " round(s) after the current round")
        end
        if slay_reason then
            chat_message = (chat_message .. " for \"" .. slay_reason .. "\".")
        else
            chat_message = (chat_message .. ".")
        end
        ply:ChatPrint(chat_message)
    end
end)
--[End]----------------------------------------------------------------------------------------


--[Force role]---------------------------------------------------------------------------------
--[[ulx.force][Forces <target(s)> to become a specified role.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[Number]}       target_role   [The role that target player(s) will have there role set to.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.force(calling_ply, target_plys, target_role, should_silent)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else

        local affected_plys = {}

        local role = table.KeyFromValue(ROLE_STRINGS_RAW, target_role)
        local role_string = ROLE_STRINGS_EXT[role]
        for i = 1, #target_plys do
            local v = target_plys[i]
            local current_role = v:GetRole()

            if ulx.getExclusive(v, calling_ply) then
                ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
            elseif GetRoundState() == 1 or GetRoundState() == 2 then
                ULib.tsayError(calling_ply, "The round has not begun!", true)
            elseif role == nil then
                ULib.tsayError(calling_ply, "Invalid role :\"" .. target_role .. "\" specified", true)
            elseif not v:Alive() then
                ULib.tsayError(calling_ply, v:Nick() .. " is dead!", true)
            elseif current_role == role then
                ULib.tsayError(calling_ply, v:Nick() .. " is already " .. role_string, true)
            else
                v:ResetEquipment()
                RemoveLoadoutWeapons(v)
                RemoveBoughtWeapons(v)

                SetRole(v, role)
                v:SetDefaultCredits()
                SendFullStateUpdate()

                GiveLoadoutItems(v)
                GiveLoadoutWeapons(v)

                if target_role == "doctor" then
                    local mode = GetConVar("ttt_doctor_mode"):GetInt()
                    if mode == DOCTOR_MODE_STATION then
                        v:Give("weapon_ttt_health_station")
                    elseif mode == DOCTOR_MODE_EMT then
                        v:Give("weapon_doc_defib")
                    end
                end

                table.insert(affected_plys, v)

                v:SetMaxHealth(100)
                v:SetHealth(100)
            end
        end
        ulx.fancyLogAdmin(calling_ply, should_silent, "#A forced #T to become the role of #s.", affected_plys, role_string)
        SendMessages(affected_plys, "Your role has been set to " .. role_string .. ".")
    end
end

local force = ulx.command(CATEGORY_NAME, "ulx force", ulx.force, "!force")
force:addParam { type = ULib.cmds.PlayersArg }
force:addParam { type = ULib.cmds.StringArg, completes = ulx.target_role, hint = "Role" }
force:addParam { type = ULib.cmds.BoolArg, invisible = true }
force:defaultAccess(ULib.ACCESS_SUPERADMIN)
force:setOpposite("ulx sforce", { _, _, _, true }, "!sforce", true)
force:help("Force <target(s)> to become a specified role.")

--[Helper Functions]---------------------------------------------------------------------------
--[[GetLoadoutWeapons][Returns the loadout weapons ]
@param  {[Number]} r [The role of the loadout weapons to be returned]
@return {[table]}    [A table of loadout weapons for the given role.]
--]]

local loadout_weapons = nil
local function GetLoadoutWeapons(r)
    if not loadout_weapons then
        local tbl = {}
        -- Initialize the table for every role
        for wrole = 0, ROLE_MAX do
            tbl[wrole] = {}
        end

        for _, w in pairs(weapons.GetList()) do
            if WEPS.GetClass(w) == "weapon_ttt_unarmed" or WEPS.GetClass(w) == "weapon_zm_carry" or WEPS.GetClass(w) == "weapon_zm_improvised" then
                for wrole = 0, ROLE_MAX do
                    table.insert(tbl[wrole], WEPS.GetClass(w))
                end
            elseif w and istable(w.InLoadoutFor) then
                for _, wrole in pairs(w.InLoadoutFor) do
                    table.insert(tbl[wrole], WEPS.GetClass(w))
                end
            end
        end

        loadout_weapons = tbl
    end

    return loadout_weapons[r]
end

--[[RemoveBoughtWeapons][Removes previously bought weapons from the shop.]
@param  {[PlayerObject]} ply [The player who will have their bought weapons removed.]
--]]
function RemoveBoughtWeapons(ply)
    for _, wep in pairs(weapons.GetList()) do
        local wep_class = WEPS.GetClass(wep)
        if wep and type(wep.CanBuy) == "table" then
            for _, weprole in pairs(wep.CanBuy) do
                if weprole == ply:GetRole() and ply:HasWeapon(wep_class) then
                    ply:StripWeapon(wep_class)
                end
            end
        end
    end
end

--[[RemoveLoadoutWeapons][Removes all loadout weapons for the given player.]
@param  {[PlayerObject]} ply [The player who will have their loadout weapons removed.]
--]]
function RemoveLoadoutWeapons(ply)
    local weps = GetLoadoutWeapons(GetRoundState() == ROUND_PREP and ROLE_INNOCENT or ply:GetRole())
    for _, cls in pairs(weps) do
        if ply:HasWeapon(cls) then
            ply:StripWeapon(cls)
        end
    end

	ply:StripRoleWeapons()
end

--[[GiveLoadoutWeapons][Gives the loadout weapons for that player.]
@param  {[PlayerObject]} ply [The player who will have their loadout weapons given.]
--]]
function GiveLoadoutWeapons(ply)
    local r = GetRoundState() == ROUND_PREP and ROLE_INNOCENT or ply:GetRole()
    local weps = GetLoadoutWeapons(r)
    if not weps then return end

    for _, cls in pairs(weps) do
        if not ply:HasWeapon(cls) and ply:CanCarryType(WEPS.TypeForWeapon(cls)) then
            ply:Give(cls)
        end
    end
end

--[[GiveLoadoutItems][Gives the default loadout items for that role.]
@param  {[PlayerObject]} ply [The player who the equipment will be given to.]
--]]
function GiveLoadoutItems(ply)
    local items = EquipmentItems[ply:GetRole()]
    if items then
        for _, item in pairs(items) do
            if item.loadout and item.id then
                ply:GiveEquipmentItem(item.id)
            end
        end
    end
end

--[End]----------------------------------------------------------------------------------------



--[Respawn]------------------------------------------------------------------------------------
--[[ulx.respawn][Respawns <target(s)>]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.respawn(calling_ply, target_plys, should_silent)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        local affected_plys = {}

        for i = 1, #target_plys do
            local v = target_plys[i]

            if ulx.getExclusive(v, calling_ply) then
                ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
            elseif GetRoundState() == 1 then
                ULib.tsayError(calling_ply, "Waiting for players!", true)

            elseif v:Alive() and v:IsSpec() then -- players arent really dead when they are spectating, we need to handle that correctly
                timer.Destroy("traitorcheck" .. v:SteamID())
                v:ConCommand("ttt_spectator_mode 0") -- just incase they are in spectator mode take them out of it
                timer.Create("respawndelay", 0.1, 0, function() --seems to be a slight delay from when you leave spec and when you can spawn this should get us around that
                    local corpse = CorpseFind(v) -- run the normal respawn code now
                    if corpse then CorpseRemove(corpse) end

                    v:SpawnForRound(true)
					v:SetDefaultCredits()

                    table.insert(affected_plys, v)

                    ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned #T!", affected_plys)
                    SendMessages(affected_plys, "You have been respawned.")

                    if v:Alive() then timer.Destroy("respawndelay") return end
                end)

            elseif v:Alive() then
                ULib.tsayError(calling_ply, v:Nick() .. " is already alive!", true)
            else
                timer.Destroy("traitorcheck" .. v:SteamID())
                local corpse = CorpseFind(v)
                if corpse then CorpseRemove(corpse) end

                v:SpawnForRound(true)
                v:SetDefaultCredits()
                table.insert(affected_plys, v)
            end
        end
        ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned #T!", affected_plys)
        SendMessages(affected_plys, "You have been respawned.")
    end
end

local respawn = ulx.command(CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn")
respawn:addParam { type = ULib.cmds.PlayersArg }
respawn:addParam { type = ULib.cmds.BoolArg, invisible = true }
respawn:defaultAccess(ULib.ACCESS_SUPERADMIN)
respawn:setOpposite("ulx srespawn", { _, _, true }, "!srespawn", true)
respawn:help("Respawns <target(s)>.")
--[End]----------------------------------------------------------------------------------------



--[Respawn teleport]---------------------------------------------------------------------------
--[[ulx.respawntp][Respawns <target(s)>]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_ply    [The player who will have the effects of the command applied to them.]
@param  {[Boolean]}      should_silent [Hidden, determines weather the output will be silent or not.]
--]]
function ulx.respawntp(calling_ply, target_ply, should_silent)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else

        local affected_ply = {}
        if not calling_ply:IsValid() then
            Msg("You are the console, you can't teleport or teleport others since you can't see the world!\n")
            return
        elseif ulx.getExclusive(target_ply, calling_ply) then
            ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
        elseif GetRoundState() == 1 then
            ULib.tsayError(calling_ply, "Waiting for players!", true)

        elseif target_ply:Alive() and target_ply:IsSpec() then
            timer.Destroy("traitorcheck" .. target_ply:SteamID())
            target_ply:ConCommand("ttt_spectator_mode 0")
            timer.Create("respawntpdelay", 0.1, 0, function() --have to wait for gamemode before doing this
                local t = {}
                t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
                t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
                t.filter = target_ply
                if target_ply ~= calling_ply then
                    t.filter = { target_ply, calling_ply }
                end
                local tr = util.TraceEntity(t, target_ply)

                local pos = tr.HitPos

                local corpse = CorpseFind(target_ply)
                if corpse then CorpseRemove(corpse) end

                target_ply:SpawnForRound(true)
				target_ply:SetDefaultCredits()

                target_ply:SetPos(pos)
                table.insert(affected_ply, target_ply)

                ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned and teleported #T!", affected_ply)
                SendMessages(target_ply, "You have been respawned and teleported.")

                if target_ply:Alive() then timer.Destroy("respawntpdelay") return end
            end)

        elseif target_ply:Alive() then
            ULib.tsayError(calling_ply, target_ply:Nick() .. " is already alive!", true)
        else
            timer.Destroy("traitorcheck" .. target_ply:SteamID())
            local t = {}
            t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
            t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
            t.filter = target_ply
            if target_ply ~= calling_ply then
                t.filter = { target_ply, calling_ply }
            end
            local tr = util.TraceEntity(t, target_ply)

            local pos = tr.HitPos

            local corpse = CorpseFind(target_ply)
            if corpse then CorpseRemove(corpse) end

            target_ply:SpawnForRound(true)
            target_ply:SetDefaultCredits()

            target_ply:SetPos(pos)
            table.insert(affected_ply, target_ply)
        end
        ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned and teleported #T!", affected_ply)
        SendMessages(affected_ply, "You have been respawned and teleported.")
    end
end

local respawntp = ulx.command(CATEGORY_NAME, "ulx respawntp", ulx.respawntp, "!respawntp")
respawntp:addParam { type = ULib.cmds.PlayerArg }
respawntp:addParam { type = ULib.cmds.BoolArg, invisible = true }
respawntp:defaultAccess(ULib.ACCESS_SUPERADMIN)
respawntp:setOpposite("ulx srespawntp", { _, _, true }, "!srespawntp", true)
respawntp:help("Respawns <target> to a specific location.")
--[End]----------------------------------------------------------------------------------------



--[Karma]--------------------------------------------------------------------------------------
--[[ulx.karma][Sets the <target(s)> karma to a given amount.]
@param  {[PlayerObject]} calling_ply [The player who used the command.]
@param  {[PlayerObject]} target_plys [The player(s) who will have the effects of the command applied to them.]
@param  {[Number]}       amount      [The number the target's karma will be set to.]
--]]
function ulx.karma(calling_ply, target_plys, amount)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        for i = 1, #target_plys do
            target_plys[i]:SetBaseKarma(amount)
            target_plys[i]:SetLiveKarma(amount)
        end
    end
    ulx.fancyLogAdmin(calling_ply, "#A set the karma for #T to #i", target_plys, amount)
end

local karma = ulx.command(CATEGORY_NAME, "ulx karma", ulx.karma, "!karma")
karma:addParam { type = ULib.cmds.PlayersArg }
karma:addParam { type = ULib.cmds.NumArg, min = 0, max = 10000, default = 1000, hint = "Karma", ULib.cmds.optional, ULib.cmds.round }
karma:defaultAccess(ULib.ACCESS_ADMIN)
karma:help("Changes the <target(s)> Karma.")
--[End]----------------------------------------------------------------------------------------


--[Toggle spectator]---------------------------------------------------------------------------
--[[ulx.spec][Forces <target(s)> to and from spectator.]
@param  {[PlayerObject]} calling_ply   [The player who used the command.]
@param  {[PlayerObject]} target_plys   [The player(s) who will have the effects of the command applied to them.]
--]]
function ulx.tttspec(calling_ply, target_plys, should_unspec)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else

        for i = 1, #target_plys do
            local v = target_plys[i]

            if should_unspec then
                v:ConCommand("ttt_spectator_mode 0")
            else
                v:Kill()
                v:SetForceSpec(true)
                v:SetTeam(TEAM_SPEC)
                v:ConCommand("ttt_spectator_mode 1")
                v:ConCommand("ttt_cl_idlepopup")
            end
        end
        if should_unspec then
            ulx.fancyLogAdmin(calling_ply, "#A has forced #T to join the world of the living next round.", target_plys)
        else
            ulx.fancyLogAdmin(calling_ply, "#A has forced #T to spectate.", target_plys)
        end
    end
end

local tttspec = ulx.command(CATEGORY_NAME, "ulx fspec", ulx.tttspec, "!fspec")
tttspec:addParam { type = ULib.cmds.PlayersArg }
tttspec:addParam { type = ULib.cmds.BoolArg, invisible = true }
tttspec:defaultAccess(ULib.ACCESS_ADMIN)
tttspec:setOpposite("ulx unspec", { _, _, true }, "!unspec")
tttspec:help("Forces the <target(s)> to/from spectator.")
--[End]----------------------------------------------------------------------------------------

------------------------------ Next Round  ------------------------------
ulx.next_round = {}
local function updateNextround()
    table.Empty(ulx.next_round) -- Don't reassign so we don't lose our refs

    for wrole = 0, ROLE_MAX do
        table.insert(ulx.next_round, ROLE_STRINGS_RAW[wrole])
    end
    table.insert(ulx.next_round, "unmark") -- Add "unmark" to the table.
end

hook.Add(ULib.HOOK_UCLCHANGED, "ULXNextRoundUpdate", updateNextround)

local PlysMarkedForNextRound = {}
local function MarkedElsewhere(id)
    if PlysMarkedForNextRound[id] and PlysMarkedForNextRound[id] ~= nil then
        return true
    end
    return false
end

function ulx.nextround(calling_ply, target_plys, next_round)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        local affected_plys = {}
        for i = 1, #target_plys do
            local v = target_plys[i]
            local id = v:SteamID64()

            if next_round == "unmark" then
                PlysMarkedForNextRound[id] = nil
                table.insert(affected_plys, v)
            elseif MarkedElsewhere(id) then
                ULib.tsayError(calling_ply, "that player is already marked for the next round!", true)
            else
                PlysMarkedForNextRound[id] = next_round
                table.insert(affected_plys, v)
            end
        end

        if next_round == "unmark" then
            ulx.fancyLogAdmin(calling_ply, true, "#A has unmarked #T ", affected_plys)
        else
            ulx.fancyLogAdmin(calling_ply, true, "#A marked #T to be #s next round.", affected_plys, next_round)
        end
    end
end

local nxtr = ulx.command(CATEGORY_NAME, "ulx forcenr", ulx.nextround, "!nr")
nxtr:addParam { type = ULib.cmds.PlayersArg }
nxtr:addParam { type = ULib.cmds.StringArg, completes = ulx.next_round, hint = "Next Round", error = "invalid role \"%s\" specified", ULib.cmds.restrictToCompletes }
nxtr:defaultAccess(ULib.ACCESS_SUPERADMIN)
nxtr:help("Forces the target to be a role in the following round.")

local function GetRoleFromString(role_string)
    for wrole = 0, ROLE_MAX do
        if ROLE_STRINGS_RAW[wrole] == role_string then
            return wrole
        end
    end
    return ROLE_NONE
end

local function RoleMarkedPlayers()
    for k, v in pairs(PlysMarkedForNextRound) do
        local role = GetRoleFromString(v)
        if role ~= ROLE_NONE then
            local ply = player.GetBySteamID64(k)
            ply:SetRole(role)
        end
        PlysMarkedForNextRound[k] = nil
    end
end
hook.Add("TTTSelectRoles", "Admin_Round_Select", RoleMarkedPlayers)

--- [Identify Corpse Thanks Neku]----------------------------------------------------------------------------
function ulx.identify(calling_ply, target_ply, unidentify)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        local body = CorpseFind(target_ply)
        if not body then ULib.tsayError(calling_ply, "This player's corpse does not exist!", true) return end

        if not unidentify then
            ulx.fancyLogAdmin(calling_ply, "#A identified #T's body!", target_ply)
            CORPSE.SetFound(body, true)
            target_ply:SetNWBool("body_found", true)

            if target_ply:IsTraitorTeam() then
                -- update innocent's list of traitors
                SendConfirmedTraitors(GetInnocentFilter(false))
                SCORE:HandleBodyFound(calling_ply, target_ply)
            end

        else
            ulx.fancyLogAdmin(calling_ply, "#A unidentified #T's body!", target_ply)
            CORPSE.SetFound(body, false)
            target_ply:SetNWBool("body_found", false)
            SendFullStateUpdate()
        end
    end
end

local identify = ulx.command(CATEGORY_NAME, "ulx identify", ulx.identify, "!identify")
identify:addParam { type = ULib.cmds.PlayerArg }
identify:addParam { type = ULib.cmds.BoolArg, invisible = true }
identify:defaultAccess(ULib.ACCESS_SUPERADMIN)
identify:setOpposite("ulx unidentify", { _, _, true }, "!unidentify", true)
identify:help("Identifies a target's body.")

--- [Remove Corpse Thanks Neku]----------------------------------------------------------------------------
function ulx.removebody(calling_ply, target_ply)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        local body = CorpseFind(target_ply)
        if not body then ULib.tsayError(calling_ply, "This player's corpse does not exist!", true) return end
        ulx.fancyLogAdmin(calling_ply, "#A removed #T's body!", target_ply)
        if string.find(body:GetModel(), "zm_", 6, true) then
            body:Remove()
        elseif body.player_ragdoll then
            body:Remove()
        end
    end
end

local removebody = ulx.command(CATEGORY_NAME, "ulx removebody", ulx.removebody, "!removebody")
removebody:addParam { type = ULib.cmds.PlayerArg }
removebody:defaultAccess(ULib.ACCESS_SUPERADMIN)
removebody:help("Removes a target's body.")

--- [Impair Next Round - Concpet and some code from Decicus next round slap]----------------------------------------------------------------------------
function ulx.inr(calling_ply, target_ply, amount)
	local chat_message = nil
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        local impairBy = target_ply:GetPData("ImpairNR", 0)
        if amount == 0 then
            target_ply:RemovePData("ImpairNR")
            chat_message = "#T was wrongly convicted. The fine has been removed."
        else
            if amount == impairBy then
                ULib.tsayError(calling_ply, calling_ply:Nick() .. " will already be impaired for that amount of health.")
            else
                target_ply:SetPData("ImpairNR", amount)
                chat_message = "#T did the crime and they will pay the fine of " .. amount .. " health next round."
            end
        end
    end
	if chat_message ~= nil then
    	ulx.fancyLogAdmin(calling_ply, chat_message, target_ply)
	end
end

local impair = ulx.command(CATEGORY_NAME, "ulx impairnr", ulx.inr, "!impairnr")
impair:addParam { type = ULib.cmds.PlayerArg }
impair:addParam { type = ULib.cmds.NumArg, min = 0, max = 99, default = 5, hint = "Amount of health to remove.", ULib.cmds.optional, ULib.cmds.round }
impair:defaultAccess(ULib.ACCESS_ADMIN)
impair:help("Impair the targets health the following round. Set to 0 to remove impairment")

--- [impair Next Round Helper Functions ]----------------------------------------------------------------------------

hook.Add("PlayerSpawn", "InformImpair", function(ply)
    local impairDamage = tonumber(ply:GetPData("ImpairNR")) or 0
    if ply:Alive() and impairDamage > 0 then
        local chat_message = ""

        if impairDamage > 0 then
            chat_message = (chat_message .. "You did the crime and they will pay the fine of " .. impairDamage .. " health next round.")
        end
        ply:ChatPrint(chat_message)
    end
end)


function ImpairPlayers()
    for _, ply in ipairs(player.GetAll()) do
        local impairDamage = tonumber(ply:GetPData("ImpairNR")) or 0
        if ply:Alive() and impairDamage > 0 then
            local name = ply:Nick()
            ply:TakeDamage(impairDamage)
            ply:EmitSound("player/pl_pain5.wav")
            ply:ChatPrint("You did the crime and they have paid the fine of " .. impairDamage .. " health.")
            ply:RemovePData("ImpairNR")
            ULib.tsay(nil, name .. " did the crime and they have paid the fine of " .. impairDamage .. " health.", false)
        end
    end
end

hook.Add("TTTBeginRound", "ImpairPlayers", ImpairPlayers)

--- [Round Restart]-------------------------------------------------------------------------
function ulx.roundrestart(calling_ply)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        ULib.consoleCommand("ttt_roundrestart" .. "\n")
        ulx.fancyLogAdmin(calling_ply, "#A has restarted the round.")
    end
end

local restartround = ulx.command(CATEGORY_NAME, "ulx roundrestart", ulx.roundrestart)
restartround:defaultAccess(ULib.ACCESS_SUPERADMIN)
restartround:help("Restarts the round.")

--- [Credits]-------------------------------------------------------------------------
function ulx.credits(calling_ply, target_plys, amount, should_silent)
    if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError(calling_ply, gamemode_error, true) else
        for i = 1, #target_plys do
            target_plys[i]:AddCredits(amount)
        end
        ulx.fancyLogAdmin(calling_ply, true, "#A gave #T #i credits", target_plys, amount)
    end
end

local credits = ulx.command(CATEGORY_NAME, "ulx credits", ulx.credits, "!credits")
credits:addParam { type = ULib.cmds.PlayersArg }
credits:addParam { type = ULib.cmds.NumArg, hint = "Credits", ULib.cmds.round }
credits:defaultAccess(ULib.ACCESS_SUPERADMIN)
credits:setOpposite("ulx silent credits", { _, _, _, true }, "!scredits", true)
credits:help("Gives the <target(s)> credits.")
--- [End]----------------------------------------------------------------------------------------
