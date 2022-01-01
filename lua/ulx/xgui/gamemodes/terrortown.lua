--Terrortown settings module for ULX GUI
--Defines ttt cvar limits and ttt specific settings for the ttt gamemode.

local terrortown_settings = xlib.makepanel { parent = xgui.null }

xlib.makelabel { x = 5, y = 5, w = 600, wordwrap = true, label = "Trouble in Terrorist Town ULX Commands XGUI module Created by: Bender180", parent = terrortown_settings }
xlib.makelabel { x = 2, y = 345, w = 600, wordwrap = true, label = "The settings above DO NOT SAVE when the server changes maps, is restarted or crashes. They are for easy access only", parent = terrortown_settings }

xlib.makelabel { x = 5, y = 230, w = 160, wordwrap = true, label = "Note to sever owners: to restrict this panel allow or deny permission to xgui_gmsettings.", parent = terrortown_settings }
xlib.makelabel { x = 5, y = 275, w = 160, wordwrap = true, label = "All settings listed are explained here: http://ttt.badking.net/config- and-commands/convars", parent = terrortown_settings }
xlib.makelabel { x = 5, y = 330, w = 160, wordwrap = true, label = "Not all settings echo to chat.", parent = terrortown_settings }

terrortown_settings.panel = xlib.makepanel { x = 160, y = 25, w = 420, h = 318, parent = terrortown_settings }
terrortown_settings.catList = xlib.makelistview { x = 5, y = 25, w = 150, h = 200, parent = terrortown_settings }
terrortown_settings.catList:AddColumn("Terrorist Town Settings")
terrortown_settings.catList.Columns[1].DoClick = function() end

terrortown_settings.catList.OnRowSelected = function(self, lineid, line)
    local panel = xgui.modules.submodule[line:GetValue(2)].panel
    if panel ~= terrortown_settings.curPanel then
        panel:SetZPos(0)
        xlib.addToAnimQueue("pnlSlide", { panel = panel, startx = -435, starty = 0, endx = 0, endy = 0, setvisible = true })
        if terrortown_settings.curPanel then
            terrortown_settings.curPanel:SetZPos(-1)
            xlib.addToAnimQueue(terrortown_settings.curPanel.SetVisible, terrortown_settings.curPanel, false)
        end
        xlib.animQueue_start()
        terrortown_settings.curPanel = panel
    else
        xlib.addToAnimQueue("pnlSlide", { panel = panel, startx = 0, starty = 0, endx = -435, endy = 0, setvisible = false })
        self:ClearSelection()
        terrortown_settings.curPanel = nil
        xlib.animQueue_start()
    end
    if panel.onOpen then panel.onOpen() end --If the panel has it, call a function when it's opened
end

--Process modular settings
function terrortown_settings.processModules()
    terrortown_settings.catList:Clear()
    for i, module in ipairs(xgui.modules.submodule) do
        if module.mtype == "terrortown_settings" and (not module.access or LocalPlayer():query(module.access)) then
            local w, h = module.panel:GetSize()
            if w == h and h == 0 then module.panel:SetSize(275, 322) end

            if module.panel.scroll then --For DListLayouts
                module.panel.scroll.panel = module.panel
                module.panel = module.panel.scroll
            end
            module.panel:SetParent(terrortown_settings.panel)

            local line = terrortown_settings.catList:AddLine(module.name, i)
            if (module.panel == terrortown_settings.curPanel) then
                terrortown_settings.curPanel = nil
                terrortown_settings.catList:SelectItem(line)
            else
                module.panel:SetVisible(false)
            end
        end
    end
    terrortown_settings.catList:SortByColumn(1, false)
end
terrortown_settings.processModules()

xgui.hookEvent("onProcessModules", nil, terrortown_settings.processModules)
xgui.addModule("TTT", terrortown_settings, "vgui/ttt/ulx_ttt.png", "xgui_gmsettings")

local missing_cvars = {}

local function GetReplicatedConVar(name)
    return GetConVar("rep_" .. name)
end

local function GetReplicatedConVarDefault(name, default)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return default
    end
    return convar:GetDefault()
end

local function GetReplicatedConVarMin(name, min)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return min
    end
    return convar:GetMin()
end

local function GetReplicatedConVarMax(name, max)
    local convar = GetReplicatedConVar(name)
    if not convar then
        missing_cvars[name] = true
        return max
    end
    return convar:GetMax()
end

local function GetShopRoles()
    if not GetGlobalBool("ttt_shop_for_all", false) then
        return SHOP_ROLES
    end

    local shop_roles = {}
    for role = 0, ROLE_MAX do
        shop_roles[role] = true
    end
    return shop_roles
end

local function GetCreditRoles()
    local shop_roles = GetShopRoles()
    -- Add any roles that have credits but don't have a shop to the full list
    local shopless_credit_roles = table.ToLookup(table.UnionedKeys(CAN_LOOT_CREDITS_ROLES, ROLE_STARTING_CREDITS))
    return table.ToLookup(table.UnionedKeys(shop_roles, shopless_credit_roles))
end

local function AddRoundStructureModule()
    local rspnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Preparation and Post-Round
    local rspapclp = vgui.Create("DCollapsibleCategory", rspnl)
    rspapclp:SetSize(390, 70)
    rspapclp:SetExpanded(1)
    rspapclp:SetLabel("Preparation and Post-Round")

    local rspaplst = vgui.Create("DPanelList", rspapclp)
    rspaplst:SetPos(5, 25)
    rspaplst:SetSize(390, 70)
    rspaplst:SetSpacing(5)

    local prept = xlib.makeslider { label = "ttt_preptime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_preptime_seconds", parent = rspaplst }
    rspaplst:AddItem(prept)

    local fprept = xlib.makeslider { label = "ttt_firstpreptime (def. 60)", min = 1, max = 120, repconvar = "rep_ttt_firstpreptime", parent = rspaplst }
    rspaplst:AddItem(fprept)

    local pstt = xlib.makeslider { label = "ttt_posttime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_posttime_seconds", parent = rspaplst }
    rspaplst:AddItem(pstt)

    --Round Length
    local rsrlclp = vgui.Create("DCollapsibleCategory", rspnl)
    rsrlclp:SetSize(390, 90)
    rsrlclp:SetExpanded(0)
    rsrlclp:SetLabel("Round Length")

    local rsrllst = vgui.Create("DPanelList", rsrlclp)
    rsrllst:SetPos(5, 25)
    rsrllst:SetSize(390, 90)
    rsrllst:SetSpacing(5)

    local hstmd = xlib.makecheckbox { label = "ttt_haste", repconvar = "rep_ttt_haste", parent = rsrllst }
    rsrllst:AddItem(hstmd)

    local hstsm = xlib.makeslider { label = "ttt_haste_starting_minutes (def. 5)", min = 1, max = 60, repconvar = "rep_ttt_haste_starting_minutes", parent = rsrllst }
    rsrllst:AddItem(hstsm)

    local hstmpd = xlib.makeslider { label = "ttt_haste_minutes_per_death (def. 0.5)", min = 0.1, max = 9, decimal = 2, repconvar = "rep_ttt_haste_minutes_per_death", parent = rsrllst }
    rsrllst:AddItem(hstmpd)

    local rtm = xlib.makeslider { label = "ttt_roundtime_minutes (def. 10)", min = 1, max = 60, repconvar = "rep_ttt_roundtime_minutes", parent = rsrllst }
    rsrllst:AddItem(rtm)

    --Map Switching and Voting
    local msavclp = vgui.Create("DCollapsibleCategory", rspnl)
    msavclp:SetSize(390, 50)
    msavclp:SetExpanded(0)
    msavclp:SetLabel("Map Switching and Voting")

    local msavlst = vgui.Create("DPanelList", msavclp)
    msavlst:SetPos(5, 25)
    msavlst:SetSize(390, 50)
    msavlst:SetSpacing(5)

    local rndl = xlib.makeslider { label = "ttt_round_limit (def. 6)", min = 1, max = 100, repconvar = "rep_ttt_round_limit", parent = msavlst }
    msavlst:AddItem(rndl)

    local rndtlm = xlib.makeslider { label = "ttt_time_limit_minutes (def. 75)", min = 1, max = 150, repconvar = "rep_ttt_time_limit_minutes", parent = msavlst }
    msavlst:AddItem(rndtlm)

    xgui.hookEvent("onProcessModules", nil, rspnl.processModules)
    xgui.addSubModule("Round Structure", rspnl, nil, "terrortown_settings")
end

local function AddTraitorAndDetectiveSettings(gppnl)
    local gptdcclp = vgui.Create("DCollapsibleCategory", gppnl)
    gptdcclp:SetSize(390, 150)
    gptdcclp:SetExpanded(1)
    gptdcclp:SetLabel("Traitor and Detective Settings")

    local gptdlst = vgui.Create("DPanelList", gptdcclp)
    gptdlst:SetPos(5, 25)
    gptdlst:SetSize(390, 150)
    gptdlst:SetSpacing(5)

    local tpercet = xlib.makeslider { label = "ttt_traitor_pct (def. 0.25)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_traitor_pct", parent = gptdlst }
    gptdlst:AddItem(tpercet)

    local tmax = xlib.makeslider { label = "ttt_traitor_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_traitor_max", parent = gptdlst }
    gptdlst:AddItem(tmax)

    local dpercet = xlib.makeslider { label = "ttt_detective_pct (def. 0.13)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_detective_pct", parent = gptdlst }
    gptdlst:AddItem(dpercet)

    local dmax = xlib.makeslider { label = "ttt_detective_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_detective_max", parent = gptdlst }
    gptdlst:AddItem(dmax)

    local dmp = xlib.makeslider { label = "ttt_detective_min_players (def. 10)", min = 1, max = 50, repconvar = "rep_ttt_detective_min_players", parent = gptdlst }
    gptdlst:AddItem(dmp)

    local dkm = xlib.makeslider { label = "ttt_detective_karma_min (def. 600)", min = 1, max = 1000, repconvar = "rep_ttt_detective_karma_min", parent = gptdlst }
    gptdlst:AddItem(dkm)
end

local function AddDefaultRoleSettings(lst, role_list)
    for _, r in pairs(role_list) do
        local role_string = ROLE_STRINGS_RAW[r]
        local enabled = xlib.makecheckbox { label = "ttt_" .. role_string .. "_enabled (def. 0)", repconvar = "rep_ttt_" .. role_string .. "_enabled", parent = lst }
        lst:AddItem(enabled)

        local spawn_weight = xlib.makeslider { label = "ttt_" .. role_string .. "_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_" .. role_string .. "_spawn_weight", parent = lst }
        lst:AddItem(spawn_weight)

        local min_players = xlib.makeslider { label = "ttt_" .. role_string .. "_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_" .. role_string .. "_min_players", parent = lst }
        lst:AddItem(min_players)
    end
end

local function AddSpecialistTraitorSettings(gppnl)
    local traitor_roles = table.ExcludedKeys(TRAITOR_ROLES, {ROLE_TRAITOR})
    local sptraclp = vgui.Create("DCollapsibleCategory", gppnl)
    sptraclp:SetSize(390, 50 + (70 * #traitor_roles))
    sptraclp:SetExpanded(1)
    sptraclp:SetLabel("Specialist Traitor Settings")

    local sptralst = vgui.Create("DPanelList", sptraclp)
    sptralst:SetPos(5, 25)
    sptralst:SetSize(390, 50 + (70 * #traitor_roles))
    sptralst:SetSpacing(5)

    local stpercet = xlib.makeslider { label = "ttt_special_traitor_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_pct", parent = sptralst }
    sptralst:AddItem(stpercet)

    local stchance = xlib.makeslider { label = "ttt_special_traitor_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_chance", parent = sptralst }
    sptralst:AddItem(stchance)

    AddDefaultRoleSettings(sptralst, traitor_roles)
end

local function AddSpecialistInnocentSettings(gppnl)
    local inno_roles = table.ExcludedKeys(INNOCENT_ROLES, table.Add({ROLE_INNOCENT}, GetTeamRoles(DETECTIVE_ROLES)))
    local spinnclp = vgui.Create("DCollapsibleCategory", gppnl)
    spinnclp:SetSize(390, 50 + (70 * #inno_roles))
    spinnclp:SetExpanded(1)
    spinnclp:SetLabel("Specialist Innocent Settings")

    local spinnlst = vgui.Create("DPanelList", spinnclp)
    spinnlst:SetPos(5, 25)
    spinnlst:SetSize(390, 50 + (70 * #inno_roles))
    spinnlst:SetSpacing(5)

    local sipercet = xlib.makeslider { label = "ttt_special_innocent_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_pct", parent = spinnlst }
    spinnlst:AddItem(sipercet)

    local sichance = xlib.makeslider { label = "ttt_special_innocent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_chance", parent = spinnlst }
    spinnlst:AddItem(sichance)

    AddDefaultRoleSettings(spinnlst, inno_roles)
end

local function AddSpecialistDetectiveSettings(gppnl)
    local det_roles = table.ExcludedKeys(DETECTIVE_ROLES, {ROLE_DETECTIVE})
    local spdetclp = vgui.Create("DCollapsibleCategory", gppnl)
    spdetclp:SetSize(390, 50 + (70 * #det_roles))
    spdetclp:SetExpanded(1)
    spdetclp:SetLabel("Specialist Detective Settings")

    local spdetlst = vgui.Create("DPanelList", spdetclp)
    spdetlst:SetPos(5, 25)
    spdetlst:SetSize(390, 50 + (70 * #det_roles))
    spdetlst:SetSpacing(5)

    local sdpercet = xlib.makeslider { label = "ttt_special_detective_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_pct", parent = spdetlst }
    spdetlst:AddItem(sdpercet)

    local sdchance = xlib.makeslider { label = "ttt_special_detective_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_chance", parent = spdetlst }
    spdetlst:AddItem(sdchance)

    AddDefaultRoleSettings(spdetlst, det_roles)
end

local function AddIndependentRoleSettings(gppnl)
    local indep_roles = GetTeamRoles(INDEPENDENT_ROLES)
    local jester_roles = GetTeamRoles(JESTER_ROLES)
    local height = 95 + (70 * #indep_roles) + (70 * #jester_roles)
    local indclp = vgui.Create("DCollapsibleCategory", gppnl)
    indclp:SetSize(390, height)
    indclp:SetExpanded(1)
    indclp:SetLabel("Independent Role Settings")

    local indlst = vgui.Create("DPanelList", indclp)
    indlst:SetPos(5, 25)
    indlst:SetSize(390, height)
    indlst:SetSpacing(5)

    local indchance = xlib.makeslider { label = "ttt_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_independent_chance", parent = indlst }
    indlst:AddItem(indchance)

    local jeschance = xlib.makeslider { label = "ttt_jester_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_chance", parent = indlst }
    indlst:AddItem(jeschance)

    local singlejind = xlib.makecheckbox { label = "ttt_single_jester_independent (def. 1)", repconvar = "rep_ttt_single_jester_independent", parent = indlst }
    indlst:AddItem(singlejind)

    local singlejindmp = xlib.makeslider { label = "ttt_single_jester_independent_max_players (def. 0)", min = 0, max = 32, repconvar = "rep_ttt_single_jester_independent_max_players", parent = indlst }
    indlst:AddItem(singlejindmp)

    AddDefaultRoleSettings(indlst, indep_roles)
    AddDefaultRoleSettings(indlst, jester_roles)
end

local function AddMonsterSettings(gppnl)
    local monster_roles = GetTeamRoles(MONSTER_ROLES)
    local monclp = vgui.Create("DCollapsibleCategory", gppnl)
    monclp:SetSize(390, 50 + (70 * #monster_roles))
    monclp:SetExpanded(1)
    monclp:SetLabel("Monster Settings")

    local monlst = vgui.Create("DPanelList", monclp)
    monlst:SetPos(5, 25)
    monlst:SetSize(390, 50 + (70 * #monster_roles))
    monlst:SetSpacing(5)

    local monpercet = xlib.makeslider { label = "ttt_monster_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_pct", parent = monlst }
    monlst:AddItem(monpercet)

    local monchance = xlib.makeslider { label = "ttt_monster_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_chance", parent = monlst }
    monlst:AddItem(monchance)

    AddDefaultRoleSettings(monlst, monster_roles)
end

local function AddRoleHealthSettings(gppnl)
    local rolehealthclp = vgui.Create("DCollapsibleCategory", gppnl)
    local height = (ROLE_MAX + 1) * 50
    rolehealthclp:SetSize(390, height)
    rolehealthclp:SetExpanded(1)
    rolehealthclp:SetLabel("Role Health Settings")

    local rolehealthlst = vgui.Create("DPanelList", rolehealthclp)
    rolehealthlst:SetPos(5, 25)
    rolehealthlst:SetSize(390, height)
    rolehealthlst:SetSpacing(5)

    for role = 0, ROLE_MAX do
        local rolestring = ROLE_STRINGS_RAW[role]
        local convar = "ttt_" .. rolestring .. "_starting_health"
        local default = GetReplicatedConVarDefault(convar, "100")
        local starthealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = 1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
        rolehealthlst:AddItem(starthealth)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = starthealth
        end

        convar = "ttt_" .. rolestring .. "_max_health"
        default = GetReplicatedConVarDefault(convar, "100")
        local maxhealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = 1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
        rolehealthlst:AddItem(maxhealth)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = maxhealth
        end
    end
end

local function GetExternalRolesForTeam(role_list, excludes_team)
    local team_list = {}
    if ROLE_MAX >= ROLE_EXTERNAL_START then
        for role = ROLE_EXTERNAL_START, ROLE_MAX do
            if role_list[role] and not (excludes_team and excludes_team[role]) then
                table.insert(team_list, role)
            end
        end
    end
    return team_list
end

local function GetExternalRoleConVars(team_list)
    local role_cvars = {}
    local num_count, bool_count, text_count = 0, 0, 0
    for _, r in ipairs(team_list) do
        if ROLE_CONVARS[r] then
            local role_nums, role_bools, role_texts = {}, {}, {}
            for _, cvar in ipairs(ROLE_CONVARS[r]) do
                if cvar.type == ROLE_CONVAR_TYPE_NUM then
                    table.insert(role_nums, cvar)
                elseif cvar.type == ROLE_CONVAR_TYPE_BOOL then
                    table.insert(role_bools, cvar)
                elseif cvar.type == ROLE_CONVAR_TYPE_TEXT then
                    table.insert(role_texts, cvar)
                else
                    ErrorNoHalt("WARNING: Role (" .. r .. ") tried to register a convar with an unknown type: " .. tostring(cvar.type))
                end
            end
            num_count = num_count + #role_nums
            bool_count = bool_count + #role_bools
            text_count = text_count + #role_texts
            role_cvars[r] = {
                nums = role_nums,
                bools = role_bools,
                texts = role_texts
            }
        end
    end
    return role_cvars, num_count, bool_count, text_count
end

local function AddExternalRoleProperties(role, role_cvars, list)
    local rolestring = ROLE_STRINGS[role]
    local label = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = rolestring .. " settings:", parent = list }
    list:AddItem(label)

    for _, c in ipairs(role_cvars.nums) do
        local name = c.cvar
        local default = GetReplicatedConVarDefault(name, "0")
        local min = GetReplicatedConVarMin(name, 0)
        local max = GetReplicatedConVarMax(name, 1)
        local decimal = c.decimal or 0

        local slider = xlib.makeslider { label = name .. " (def. " .. default .. ")", min = min, max = max, decimal = decimal, repconvar = "rep_" .. name, parent = list }
        list:AddItem(slider)

        -- Save the control so it can be updated later
        if missing_cvars[name] then
            missing_cvars[name] = slider
        end
    end

    for _, c in ipairs(role_cvars.bools) do
        local name = c.cvar
        local default = GetReplicatedConVarDefault(name, "0")
        local check = xlib.makecheckbox { label = name .. " (def. " .. default .. ")", repconvar = "rep_" .. name, parent = list }
        list:AddItem(check)

        -- Save the control so it can be updated later
        if missing_cvars[name] then
            missing_cvars[name] = check
        end
    end

    for _, c in ipairs(role_cvars.texts) do
        local name = c.cvar
        local textlabel = xlib.makelabel { label = name, parent = list }
        list:AddItem(textlabel)
        local textbox = xlib.maketextbox { repconvar = "rep_" .. name, enableinput = true, parent = list }
        list:AddItem(textbox)
    end
end

local function GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local external_roles_with_cvars = table.Count(role_cvars)
    -- Labels
    return (external_roles_with_cvars * 20) +
            -- Sliders
            (num_count * 25) +
            -- Checkboxes
            (bool_count * 20) +
            -- Textboxes
            (text_count * 43)
end

local function AddTraitorProperties(gppnl)
    local external_traitors = GetExternalRolesForTeam(TRAITOR_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_traitors)
    local height = 1270 + GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local trapropclp = vgui.Create("DCollapsibleCategory", gppnl)
    trapropclp:SetSize(390, height)
    trapropclp:SetExpanded(1)
    trapropclp:SetLabel("Traitor Properties")

    local traproplst = vgui.Create("DPanelList", trapropclp)
    traproplst:SetPos(5, 25)
    traproplst:SetSize(390, height)
    traproplst:SetSpacing(5)

    local travis = xlib.makecheckbox { label = "ttt_traitor_vision_enable (def. 0)", repconvar = "rep_ttt_traitor_vision_enable", parent = traproplst }
    traproplst:AddItem(travis)

    local trapd = xlib.makecheckbox { label = "ttt_traitor_phantom_cure (def. 0)", repconvar = "rep_ttt_traitor_phantom_cure", parent = traproplst }
    traproplst:AddItem(trapd)

    local implbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Impersonator settings:", parent = traproplst }
    traproplst:AddItem(implbl)

    local imppen = xlib.makeslider { label = "ttt_impersonator_damage_penalty (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_impersonator_damage_penalty", parent = traproplst }
    traproplst:AddItem(imppen)

    local impudi = xlib.makecheckbox { label = "ttt_impersonator_use_detective_icon (def. 1)", repconvar = "rep_ttt_impersonator_use_detective_icon", parent = traproplst }
    traproplst:AddItem(impudi)

    local impwd = xlib.makecheckbox { label = "ttt_impersonator_without_detective (def. 0)", repconvar = "rep_ttt_impersonator_without_detective", parent = traproplst }
    traproplst:AddItem(impwd)

    local impac = xlib.makeslider { label = "ttt_impersonator_activation_credits (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_impersonator_activation_credits", parent = traproplst }
    traproplst:AddItem(impac)

    local impdc = xlib.makeslider { label = "ttt_impersonator_detective_chance (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_impersonator_detective_chance", parent = traproplst }
    traproplst:AddItem(impdc)

    local hyplbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Hypnotist settings:", parent = traproplst }
    traproplst:AddItem(hyplbl)

    local hypdl = xlib.makecheckbox { label = "ttt_hypnotist_device_loadout (def. 1)", repconvar = "rep_ttt_hypnotist_device_loadout", parent = traproplst }
    traproplst:AddItem(hypdl)

    local hypds = xlib.makecheckbox { label = "ttt_hypnotist_device_shop (def. 0)", repconvar = "rep_ttt_hypnotist_device_shop", parent = traproplst }
    traproplst:AddItem(hypds)

    local hypdr = xlib.makecheckbox { label = "ttt_hypnotist_device_shop_rebuyable (def. 0)", repconvar = "rep_ttt_hypnotist_device_shop_rebuyable", parent = traproplst }
    traproplst:AddItem(hypdr)

    local hypcd = xlib.makecheckbox { label = "ttt_hypnotist_convert_detectives (def. 0)", repconvar = "rep_ttt_hypnotist_convert_detectives", parent = traproplst }
    traproplst:AddItem(hypcd)

    local hypdt = xlib.makeslider { label = "ttt_hypnotist_device_time (def. 8)", min = 0, max = 60, repconvar = "rep_ttt_hypnotist_device_time", parent = traproplst }
    traproplst:AddItem(hypdt)

    local asnlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Assassin settings:", parent = traproplst }
    traproplst:AddItem(asnlbl)

    local asntgt = xlib.makecheckbox { label = "ttt_assassin_show_target_icon (def. 0)", repconvar = "rep_ttt_assassin_show_target_icon", parent = traproplst }
    traproplst:AddItem(asntgt)

    local asntve = xlib.makecheckbox { label = "ttt_assassin_target_vision_enable (def. 0)", repconvar = "rep_ttt_assassin_target_vision_enable", parent = traproplst }
    traproplst:AddItem(asntve)

    local asntgtdelay = xlib.makeslider { label = "ttt_assassin_next_target_delay (def. 5)", min = 0, max = 10, repconvar = "rep_ttt_assassin_next_target_delay", parent = traproplst }
    traproplst:AddItem(asntgtdelay)

    local asntdb = xlib.makeslider { label = "ttt_assassin_target_damage_bonus (def. 1)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_target_damage_bonus", parent = traproplst }
    traproplst:AddItem(asntdb)

    local asntbb = xlib.makecheckbox { label = "ttt_assassin_target_bonus_bought (def. 1)", repconvar = "rep_ttt_assassin_target_bonus_bought", parent = traproplst }
    traproplst:AddItem(asntbb)

    local asnwdp = xlib.makeslider { label = "ttt_assassin_wrong_damage_penalty (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_wrong_damage_penalty", parent = traproplst }
    traproplst:AddItem(asnwdp)

    local asnfdp = xlib.makeslider { label = "ttt_assassin_failed_damage_penalty (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_failed_damage_penalty", parent = traproplst }
    traproplst:AddItem(asnfdp)

    local asnsrl = xlib.makecheckbox { label = "ttt_assassin_shop_roles_last (def. 0)", repconvar = "rep_ttt_assassin_shop_roles_last", parent = traproplst }
    traproplst:AddItem(asnsrl)

    local vamlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Vampire settings:", parent = traproplst }
    traproplst:AddItem(vamlbl)

    local vamamon = xlib.makecheckbox { label = "ttt_vampires_are_monsters (def. 0)", repconvar = "rep_ttt_vampires_are_monsters", parent = traproplst }
    traproplst:AddItem(vamamon)

    local vamain = xlib.makecheckbox { label = "ttt_vampires_are_independent (def. 0)", repconvar = "rep_ttt_vampires_are_independent", parent = traproplst }
    traproplst:AddItem(vamain)

    local vamcen = xlib.makecheckbox { label = "ttt_vampire_convert_enable (def. 0)", repconvar = "rep_ttt_vampire_convert_enable", parent = traproplst }
    traproplst:AddItem(vamcen)

    local vamden = xlib.makecheckbox { label = "ttt_vampire_drain_enable (def. 1)", repconvar = "rep_ttt_vampire_drain_enable", parent = traproplst }
    traproplst:AddItem(vamden)

    local vamdfi = xlib.makecheckbox { label = "ttt_vampire_drain_first (def. 0)", repconvar = "rep_ttt_vampire_drain_first", parent = traproplst }
    traproplst:AddItem(vamdfi)

    local vamdc = xlib.makeslider { label = "ttt_vampire_drain_credits (def. 0)", min = 0, max = 5, repconvar = "rep_ttt_vampire_drain_credits", parent = traproplst }
    traproplst:AddItem(vamdc)

    local vamkc = xlib.makecheckbox { label = "ttt_vampire_kill_credits (def. 1)", repconvar = "rep_ttt_vampire_kill_credits", parent = traproplst }
    traproplst:AddItem(vamkc)

    local vamlc = xlib.makecheckbox { label = "ttt_vampire_loot_credits (def. 1)", repconvar = "rep_ttt_vampire_loot_credits", parent = traproplst }
    traproplst:AddItem(vamlc)

    local vamft = xlib.makeslider { label = "ttt_vampire_fang_timer (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_vampire_fang_timer", parent = traproplst }
    traproplst:AddItem(vamft)

    local vamfdt = xlib.makeslider { label = "ttt_vampire_fang_dead_timer (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_vampire_fang_dead_timer", parent = traproplst }
    traproplst:AddItem(vamfdt)

    local vamfh = xlib.makeslider { label = "ttt_vampire_fang_heal (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_vampire_fang_heal", parent = traproplst }
    traproplst:AddItem(vamfh)

    local vamfoh = xlib.makeslider { label = "ttt_vampire_fang_overheal (def. 25)", min = 0, max = 100, repconvar = "rep_ttt_vampire_fang_overheal", parent = traproplst }
    traproplst:AddItem(vamfoh)

    local vamfohl = xlib.makeslider { label = "ttt_vampire_fang_overheal_living (def. -1)", min = -1, max = 100, repconvar = "rep_ttt_vampire_fang_overheal_living", parent = traproplst }
    traproplst:AddItem(vamfohl)

    local vamdre = xlib.makeslider { label = "ttt_vampire_damage_reduction (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_vampire_damage_reduction", parent = traproplst }
    traproplst:AddItem(vamdre)

    local vampoc = xlib.makecheckbox { label = "ttt_vampire_prime_only_convert (def. 1)", repconvar = "rep_ttt_vampire_prime_only_convert", parent = traproplst }
    traproplst:AddItem(vampoc)

    local vampdm = xlib.makeslider { label = "ttt_vampire_prime_death_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_vampire_prime_death_mode", parent = traproplst }
    traproplst:AddItem(vampdm)

    local vamsti = xlib.makecheckbox { label = "ttt_vampire_show_target_icon (def. 0)", repconvar = "rep_ttt_vampire_show_target_icon", parent = traproplst }
    traproplst:AddItem(vamsti)

    local vamve = xlib.makecheckbox { label = "ttt_vampire_vision_enable (def. 0)", repconvar = "rep_ttt_vampire_vision_enable", parent = traproplst }
    traproplst:AddItem(vamve)

    local qualbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Quack settings:", parent = traproplst }
    traproplst:AddItem(qualbl)

    local quacurmo = xlib.makeslider { label = "ttt_quack_fake_cure_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_quack_fake_cure_mode", parent = traproplst }
    traproplst:AddItem(quacurmo)

    local quapt = xlib.makeslider { label = "ttt_quack_fake_cure_time (def. -1)", min = -1, max = 60, repconvar = "rep_ttt_quack_fake_cure_time", parent = traproplst }
    traproplst:AddItem(quapt)

    local quapd = xlib.makecheckbox { label = "ttt_quack_phantom_cure (def. 0)", repconvar = "rep_ttt_quack_phantom_cure", parent = traproplst }
    traproplst:AddItem(quapd)

    local quasb = xlib.makecheckbox { label = "ttt_quack_station_bomb (def. 0)", repconvar = "rep_ttt_quack_station_bomb", parent = traproplst }
    traproplst:AddItem(quasb)

    local quasbt = xlib.makeslider { label = "ttt_quack_station_bomb_time (def. 4)", min = 0, max = 60, repconvar = "rep_ttt_quack_station_bomb_time", parent = traproplst }
    traproplst:AddItem(quasbt)

    local parlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Parasite settings:", parent = traproplst }
    traproplst:AddItem(parlbl)

    local partim = xlib.makeslider { label = "ttt_parasite_infection_time (def. 45)", min = 0, max = 300, repconvar = "rep_ttt_parasite_infection_time", parent = traproplst }
    traproplst:AddItem(partim)

    local parit = xlib.makecheckbox { label = "ttt_parasite_infection_transfer (def. 0)", repconvar = "rep_ttt_parasite_infection_transfer", parent = traproplst }
    traproplst:AddItem(parit)

    local paritr = xlib.makecheckbox { label = "ttt_parasite_infection_transfer_reset (def. 1)", repconvar = "rep_ttt_parasite_infection_transfer_reset", parent = traproplst }
    traproplst:AddItem(paritr)

    local parism = xlib.makeslider { label = "ttt_parasite_infection_suicide_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_parasite_infection_suicide_mode", parent = traproplst }
    traproplst:AddItem(parism)

    local parrmd = xlib.makeslider { label = "ttt_parasite_respawn_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_parasite_respawn_mode", parent = traproplst }
    traproplst:AddItem(parrmd)

    local parhea = xlib.makeslider { label = "ttt_parasite_respawn_health (def. 100)", min = 0, max = 100, repconvar = "rep_ttt_parasite_respawn_health", parent = traproplst }
    traproplst:AddItem(parhea)

    local parann = xlib.makecheckbox { label = "ttt_parasite_announce_infection (def. 0)", repconvar = "rep_ttt_parasite_announce_infection", parent = traproplst }
    traproplst:AddItem(parann)

    local parcurmo = xlib.makeslider { label = "ttt_parasite_cure_mode (def. 2)", min = 0, max = 2, repconvar = "rep_ttt_parasite_cure_mode", parent = traproplst }
    traproplst:AddItem(parcurmo)

    local parcurt = xlib.makeslider { label = "ttt_parasite_cure_time (def. 3)", min = 0, max = 60, repconvar = "rep_ttt_parasite_cure_time", parent = traproplst }
    traproplst:AddItem(parcurt)

    for _, r in ipairs(external_traitors) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], traproplst)
        end
    end
end

local function AddInnocentProperties(gppnl)
    local external_innocents = GetExternalRolesForTeam(INNOCENT_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_innocents)
    local height = 860 + GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local innpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    innpropclp:SetSize(390, height)
    innpropclp:SetExpanded(1)
    innpropclp:SetLabel("Innocent Properties")

    local innproplst = vgui.Create("DPanelList", innpropclp)
    innproplst:SetPos(5, 25)
    innproplst:SetSize(390, height)
    innproplst:SetSpacing(5)

    local glilbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Glitch settings:", parent = innproplst }
    innproplst:AddItem(glilbl)

    local glimo = xlib.makeslider { label = "ttt_glitch_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_glitch_mode", parent = innproplst }
    innproplst:AddItem(glimo)

    local gliut = xlib.makecheckbox { label = "ttt_glitch_use_traps (def. 0)", repconvar = "rep_ttt_glitch_use_traps", parent = innproplst }
    innproplst:AddItem(gliut)

    local phalbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Phantom settings:", parent = innproplst }
    innproplst:AddItem(phalbl)

    local phrh = xlib.makeslider { label = "ttt_phantom_respawn_health (def. 50)", min = 1, max = 100, repconvar = "rep_ttt_phantom_respawn_health", parent = innproplst }
    innproplst:AddItem(phrh)

    local phwer = xlib.makecheckbox { label = "ttt_phantom_weaker_each_respawn (def. 0)", repconvar = "rep_ttt_phantom_weaker_each_respawn", parent = innproplst }
    innproplst:AddItem(phwer)

    local phad = xlib.makecheckbox { label = "ttt_phantom_announce_death (def. 0)", repconvar = "rep_ttt_phantom_announce_death", parent = innproplst }
    innproplst:AddItem(phad)

    local phks = xlib.makecheckbox { label = "ttt_phantom_killer_smoke (def. 0)", repconvar = "rep_ttt_phantom_killer_smoke", parent = innproplst }
    innproplst:AddItem(phks)

    local phkft = xlib.makeslider { label = "ttt_phantom_killer_footstep_time (def. 0)", min = 1, max = 60, repconvar = "rep_ttt_phantom_killer_footstep_time", parent = innproplst }
    innproplst:AddItem(phkft)

    local phkh = xlib.makecheckbox { label = "ttt_phantom_killer_haunt (def. 1)", repconvar = "rep_ttt_phantom_killer_haunt", parent = innproplst }
    innproplst:AddItem(phkh)

    local phkhpm = xlib.makeslider { label = "ttt_phantom_killer_haunt_power_max (def. 100)", min = 1, max = 200, repconvar = "rep_ttt_phantom_killer_haunt_power_max", parent = innproplst }
    innproplst:AddItem(phkhpm)

    local phkhpr = xlib.makeslider { label = "ttt_phantom_killer_haunt_power_rate (def. 10)", min = 1, max = 25, repconvar = "rep_ttt_phantom_killer_haunt_power_rate", parent = innproplst }
    innproplst:AddItem(phkhpr)

    local phkhmc = xlib.makeslider { label = "ttt_phantom_killer_haunt_move_cost (def. 25)", min = 1, max = 100, repconvar = "rep_ttt_phantom_killer_haunt_move_cost", parent = innproplst }
    innproplst:AddItem(phkhmc)

    local phkhjc = xlib.makeslider { label = "ttt_phantom_killer_haunt_jump_cost (def. 50)", min = 1, max = 100, repconvar = "rep_ttt_phantom_killer_haunt_jump_cost", parent = innproplst }
    innproplst:AddItem(phkhjc)

    local phkhdc = xlib.makeslider { label = "ttt_phantom_killer_haunt_drop_cost (def. 75)", min = 1, max = 100, repconvar = "rep_ttt_phantom_killer_haunt_drop_cost", parent = innproplst }
    innproplst:AddItem(phkhdc)

    local phkhac = xlib.makeslider { label = "ttt_phantom_killer_haunt_attack_cost (def. 100)", min = 1, max = 100, repconvar = "rep_ttt_phantom_killer_haunt_attack_cost", parent = innproplst }
    innproplst:AddItem(phkhac)

    local phkhwb = xlib.makecheckbox { label = "ttt_phantom_killer_haunt_without_body (def. 1)", repconvar = "rep_ttt_phantom_killer_haunt_without_body", parent = innproplst }
    innproplst:AddItem(phkhwb)

    local phcurt = xlib.makeslider { label = "ttt_phantom_cure_time (def. 3)", min = 0, max = 60, repconvar = "rep_ttt_phantom_cure_time", parent = innproplst }
    innproplst:AddItem(phcurt)

    local revlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Revenger settings:", parent = innproplst }
    innproplst:AddItem(revlbl)

    local revrad = xlib.makeslider { label = "ttt_revenger_radar_timer (def. 15)", min = 1, max = 60, repconvar = "rep_ttt_revenger_radar_timer", parent = innproplst }
    innproplst:AddItem(revrad)

    local revbon = xlib.makeslider { label = "ttt_revenger_damage_bonus (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_revenger_damage_bonus", parent = innproplst }
    innproplst:AddItem(revbon)

    local revdht = xlib.makeslider { label = "ttt_revenger_drain_health_to (def. -1)", min = -1, max = 200, repconvar = "rep_ttt_revenger_drain_health_to", parent = innproplst }
    innproplst:AddItem(revdht)

    local deplbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Deputy settings:", parent = innproplst }
    innproplst:AddItem(deplbl)

    local deppen = xlib.makeslider { label = "ttt_deputy_damage_penalty (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_deputy_damage_penalty", parent = innproplst }
    innproplst:AddItem(deppen)

    local depudi = xlib.makecheckbox { label = "ttt_deputy_use_detective_icon (def. 1)", repconvar = "rep_ttt_deputy_use_detective_icon", parent = innproplst }
    innproplst:AddItem(depudi)

    local depwd = xlib.makecheckbox { label = "ttt_deputy_without_detective (def. 0)", repconvar = "rep_ttt_deputy_without_detective", parent = innproplst }
    innproplst:AddItem(depwd)

    local depac = xlib.makeslider { label = "ttt_deputy_activation_credits (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_deputy_activation_credits", parent = innproplst }
    innproplst:AddItem(depac)

    local vetlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Veteran settings:", parent = innproplst }
    innproplst:AddItem(vetlbl)

    local vetbon = xlib.makeslider { label = "ttt_veteran_damage_bonus (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_veteran_damage_bonus", parent = innproplst }
    innproplst:AddItem(vetbon)

    local vetheal = xlib.makecheckbox { label = "ttt_veteran_full_heal (def. 1)", repconvar = "rep_ttt_veteran_full_heal", parent = innproplst }
    innproplst:AddItem(vetheal)

    local vethbon = xlib.makeslider { label = "ttt_veteran_heal_bonus (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_veteran_heal_bonus", parent = innproplst }
    innproplst:AddItem(vethbon)

    local vetann = xlib.makecheckbox { label = "ttt_veteran_announce (def. 0)", repconvar = "rep_ttt_veteran_announce", parent = innproplst }
    innproplst:AddItem(vetann)

    local vetac = xlib.makeslider { label = "ttt_veteran_activation_credits (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_veteran_activation_credits", parent = innproplst }
    innproplst:AddItem(vetac)

    local medlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Paramedic settings:", parent = innproplst }
    innproplst:AddItem(medlbl)

    local meddl = xlib.makecheckbox { label = "ttt_paramedic_device_loadout (def. 1)", repconvar = "rep_ttt_paramedic_device_loadout", parent = innproplst }
    innproplst:AddItem(meddl)

    local medds = xlib.makecheckbox { label = "ttt_paramedic_device_shop (def. 0)", repconvar = "rep_ttt_paramedic_device_shop", parent = innproplst }
    innproplst:AddItem(medds)

    local meddsr = xlib.makecheckbox { label = "ttt_paramedic_device_shop_rebuyable (def. 0)", repconvar = "rep_ttt_paramedic_device_shop_rebuyable", parent = innproplst }
    innproplst:AddItem(meddsr)

    local meddai = xlib.makecheckbox { label = "ttt_paramedic_defib_as_innocent (def. 0)", repconvar = "rep_ttt_paramedic_defib_as_innocent", parent = innproplst }
    innproplst:AddItem(meddai)

    local meddt = xlib.makeslider { label = "ttt_paramedic_defib_time (def. 8)", min = 0, max = 60, repconvar = "rep_ttt_paramedic_defib_time", parent = innproplst }
    innproplst:AddItem(meddt)

    for _, r in ipairs(external_innocents) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], innproplst)
        end
    end
end

local function AddDetectiveProperties(gppnl)
    local external_detectives = GetExternalRolesForTeam(DETECTIVE_ROLES, INNOCENT_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_detectives)
    local height = 390 + GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local detpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    detpropclp:SetSize(390, height)
    detpropclp:SetExpanded(1)
    detpropclp:SetLabel("Detective Properties")

    local detproplst = vgui.Create("DPanelList", detpropclp)
    detproplst:SetPos(5, 25)
    detproplst:SetSize(390, height)
    detproplst:SetSpacing(5)

    local detlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = detproplst }
    detproplst:AddItem(detlbl)

    local detsch = xlib.makecheckbox { label = "ttt_detective_search_only (def. 1)", repconvar = "rep_ttt_detective_search_only", parent = detproplst }
    detproplst:AddItem(detsch)

    local detdlo = xlib.makecheckbox { label = "ttt_detective_disable_looting (def. 0)", repconvar = "rep_ttt_detective_disable_looting", parent = detproplst }
    detproplst:AddItem(detdlo)

    local detsdal = xlib.makecheckbox { label = "ttt_special_detectives_armor_loadout (def. 1)", repconvar = "rep_ttt_special_detectives_armor_loadout", parent = detproplst }
    detproplst:AddItem(detsdal)

    local prsrch = xlib.makecheckbox { label = "ttt_all_search_postround (def. 1)", repconvar = "rep_ttt_all_search_postround", parent = detproplst }
    detproplst:AddItem(prsrch)

    local bnsrch = xlib.makecheckbox { label = "ttt_all_search_binoc (def. 0)", repconvar = "rep_ttt_all_search_binoc", parent = detproplst }
    detproplst:AddItem(bnsrch)

    local pallbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Paladin settings:", parent = detproplst }
    detproplst:AddItem(pallbl)

    local palrad = xlib.makeslider { label = "ttt_paladin_aura_radius (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_paladin_aura_radius", parent = detproplst }
    detproplst:AddItem(palrad)

    local palred = xlib.makeslider { label = "ttt_paladin_damage_reduction (def. 0.3)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_paladin_damage_reduction", parent = detproplst }
    detproplst:AddItem(palred)

    local palheal = xlib.makeslider { label = "ttt_paladin_heal_rate (def. 100)", min = 1, max = 10, repconvar = "rep_ttt_paladin_heal_rate", parent = detproplst }
    detproplst:AddItem(palheal)

    local palslfp = xlib.makecheckbox { label = "ttt_paladin_protect_self (def. 0)", repconvar = "rep_ttt_paladin_protect_self", parent = detproplst }
    detproplst:AddItem(palslfp)

    local palslfh = xlib.makecheckbox { label = "ttt_paladin_heal_self (def. 1)", repconvar = "rep_ttt_paladin_heal_self", parent = detproplst }
    detproplst:AddItem(palslfh)

    local trklbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Tracker settings:", parent = detproplst }
    detproplst:AddItem(trklbl)

    local trktime = xlib.makeslider { label = "ttt_tracker_footstep_time (def. 15)", min = 1, max = 60, repconvar = "rep_ttt_tracker_footstep_time", parent = detproplst }
    detproplst:AddItem(trktime)

    local trkcol = xlib.makecheckbox { label = "ttt_tracker_footstep_color (def. 1)", repconvar = "rep_ttt_tracker_footstep_color", parent = detproplst }
    detproplst:AddItem(trkcol)

    local mdmlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Medium settings:", parent = detproplst }
    detproplst:AddItem(mdmlbl)

    local mdmcol = xlib.makecheckbox { label = "ttt_medium_spirit_color (def. 1)", repconvar = "rep_ttt_medium_spirit_color", parent = detproplst }
    detproplst:AddItem(mdmcol)

    local mdmsv = xlib.makecheckbox { label = "ttt_medium_spirit_vision (def. 1)", repconvar = "rep_ttt_medium_spirit_vision", parent = detproplst }
    detproplst:AddItem(mdmsv)

    local mdmdn = xlib.makecheckbox { label = "ttt_medium_dead_notify (def. 1)", repconvar = "rep_ttt_medium_dead_notify", parent = detproplst }
    detproplst:AddItem(mdmdn)

    for _, r in ipairs(external_detectives) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], detproplst)
        end
    end
end

local function AddJesterRoleProperties(gppnl)
    local external_jesters = GetExternalRolesForTeam(JESTER_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_jesters)
    local height = 1375 + GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local jespropclp = vgui.Create("DCollapsibleCategory", gppnl)
    jespropclp:SetSize(390, height)
    jespropclp:SetExpanded(1)
    jespropclp:SetLabel("Jester Properties")

    local jesproplst = vgui.Create("DPanelList", jespropclp)
    jesproplst:SetPos(5, 25)
    jesproplst:SetSize(390, height)
    jesproplst:SetSpacing(5)

    local jestester = xlib.makecheckbox { label = "ttt_jesters_trigger_traitor_testers (def. 1)", repconvar = "rep_ttt_jesters_trigger_traitor_testers", parent = jesproplst }
    jesproplst:AddItem(jestester)

    local jesvtt = xlib.makecheckbox { label = "ttt_jesters_visible_to_traitors (def. 1)", repconvar = "rep_ttt_jesters_visible_to_traitors", parent = jesproplst }
    jesproplst:AddItem(jesvtt)

    local jesvtm = xlib.makecheckbox { label = "ttt_jesters_visible_to_monsters (def. 1)", repconvar = "rep_ttt_jesters_visible_to_monsters", parent = jesproplst }
    jesproplst:AddItem(jesvtm)

    local jesvti = xlib.makecheckbox { label = "ttt_jesters_visible_to_independents (def. 1)", repconvar = "rep_ttt_jesters_visible_to_independents", parent = jesproplst }
    jesproplst:AddItem(jesvti)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jester settings:", parent = jesproplst }
    jesproplst:AddItem(jeslbl)

    local jeswbt = xlib.makecheckbox { label = "ttt_jester_win_by_traitors (def. 1)", repconvar = "rep_ttt_jester_win_by_traitors", parent = jesproplst }
    jesproplst:AddItem(jeswbt)

    local jesnm = xlib.makeslider { label = "ttt_jester_notify_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_jester_notify_mode", parent = jesproplst }
    jesproplst:AddItem(jesnm)

    local jesns = xlib.makecheckbox { label = "ttt_jester_notify_sound (def. 0)", repconvar = "rep_ttt_jester_notify_sound", parent = jesproplst }
    jesproplst:AddItem(jesns)

    local jesnc = xlib.makecheckbox { label = "ttt_jester_notify_confetti (def. 0)", repconvar = "rep_ttt_jester_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(jesnc)

    local swalbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Swapper settings:", parent = jesproplst }
    jesproplst:AddItem(swalbl)

    local swahp = xlib.makeslider { label = "ttt_swapper_respawn_health (def. 100)", min = 1, max = 100, repconvar = "rep_ttt_swapper_respawn_health", parent = jesproplst }
    jesproplst:AddItem(swahp)

    local swawm = xlib.makeslider { label = "ttt_swapper_weapon_mode (def. 1)", min = 0, max = 2, repconvar = "rep_ttt_swapper_weapon_mode", parent = jesproplst }
    jesproplst:AddItem(swawm)

    local swanm = xlib.makeslider { label = "ttt_swapper_notify_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_swapper_notify_mode", parent = jesproplst }
    jesproplst:AddItem(swanm)

    local swans = xlib.makecheckbox { label = "ttt_swapper_notify_sound (def. 0)", repconvar = "rep_ttt_swapper_notify_sound", parent = jesproplst }
    jesproplst:AddItem(swans)

    local swasnc = xlib.makecheckbox { label = "ttt_swapper_notify_confetti (def. 0)", repconvar = "rep_ttt_swapper_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(swasnc)

    local swakhp = xlib.makeslider { label = "ttt_swapper_killer_health (def. 100)", min = 0, max = 100, repconvar = "rep_ttt_swapper_killer_health", parent = jesproplst }
    jesproplst:AddItem(swakhp)

    local clolbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Clown settings:", parent = jesproplst }
    jesproplst:AddItem(clolbl)

    local clobon = xlib.makeslider { label = "ttt_clown_damage_bonus (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_clown_damage_bonus", parent = jesproplst }
    jesproplst:AddItem(clobon)

    local cloac = xlib.makeslider { label = "ttt_clown_activation_credits (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_clown_activation_credits", parent = jesproplst }
    jesproplst:AddItem(cloac)

    local clohwa = xlib.makecheckbox { label = "ttt_clown_hide_when_active (def. 0)", repconvar = "rep_ttt_clown_hide_when_active", parent = jesproplst }
    jesproplst:AddItem(clohwa)

    local cloutwa = xlib.makecheckbox { label = "ttt_clown_use_traps_when_active (def. 0)", repconvar = "rep_ttt_clown_use_traps_when_active", parent = jesproplst }
    jesproplst:AddItem(cloutwa)

    local closti = xlib.makecheckbox { label = "ttt_clown_show_target_icon (def. 0)", repconvar = "rep_ttt_clown_show_target_icon", parent = jesproplst }
    jesproplst:AddItem(closti)

    local clohoa = xlib.makecheckbox { label = "ttt_clown_heal_on_activate (def. 0)", repconvar = "rep_ttt_clown_heal_on_activate", parent = jesproplst }
    jesproplst:AddItem(clohoa)

    local clohbon = xlib.makeslider { label = "ttt_clown_heal_bonus (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_clown_heal_bonus", parent = jesproplst }
    jesproplst:AddItem(clohbon)

    local beglbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Beggar settings:", parent = jesproplst }
    jesproplst:AddItem(beglbl)

    local begrevt = xlib.makeslider { label = "ttt_beggar_reveal_traitor (def. 1)", min = 0, max = 3, repconvar = "rep_ttt_beggar_reveal_traitor", parent = jesproplst }
    jesproplst:AddItem(begrevt)

    local begrevi = xlib.makeslider { label = "ttt_beggar_reveal_innocent (def. 2)", min = 0, max = 3, repconvar = "rep_ttt_beggar_reveal_innocent", parent = jesproplst }
    jesproplst:AddItem(begrevi)

    local begres = xlib.makecheckbox { label = "ttt_beggar_respawn (def. 0)", repconvar = "rep_ttt_beggar_respawn", parent = jesproplst }
    jesproplst:AddItem(begres)

    local begresl = xlib.makeslider { label = "ttt_beggar_respawn_limit (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_beggar_respawn_limit", parent = jesproplst }
    jesproplst:AddItem(begresl)

    local begresd = xlib.makeslider { label = "ttt_beggar_respawn_delay (def. 3)", min = 0, max = 60, repconvar = "rep_ttt_beggar_respawn_delay", parent = jesproplst }
    jesproplst:AddItem(begresd)

    local begnm = xlib.makeslider { label = "ttt_beggar_notify_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_beggar_notify_mode", parent = jesproplst }
    jesproplst:AddItem(begnm)

    local begns = xlib.makecheckbox { label = "ttt_beggar_notify_sound (def. 0)", repconvar = "rep_ttt_beggar_notify_sound", parent = jesproplst }
    jesproplst:AddItem(begns)

    local begnc = xlib.makecheckbox { label = "ttt_beggar_notify_confetti (def. 0)", repconvar = "rep_ttt_beggar_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(begnc)

    local bodlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Bodysnatcher settings:", parent = jesproplst }
    jesproplst:AddItem(bodlbl)

    local bodain = xlib.makecheckbox { label = "ttt_bodysnatchers_are_independent (def. 0)", repconvar = "rep_ttt_bodysnatchers_are_independent", parent = jesproplst }
    jesproplst:AddItem(bodain)

    local boddes = xlib.makecheckbox { label = "ttt_bodysnatcher_destroy_body (def. 0)", repconvar = "rep_ttt_bodysnatcher_destroy_body", parent = jesproplst }
    jesproplst:AddItem(boddes)

    local bodrol = xlib.makecheckbox { label = "ttt_bodysnatcher_show_role (def. 1)", repconvar = "rep_ttt_bodysnatcher_show_role", parent = jesproplst }
    jesproplst:AddItem(bodrol)

    local bodrevt = xlib.makeslider { label = "ttt_bodysnatcher_reveal_traitor (def. 1)", min = 0, max = 2, repconvar = "rep_ttt_bodysnatcher_reveal_traitor", parent = jesproplst }
    jesproplst:AddItem(bodrevt)

    local bodrevinn = xlib.makeslider { label = "ttt_bodysnatcher_reveal_innocent (def. 1)", min = 0, max = 2, repconvar = "rep_ttt_bodysnatcher_reveal_innocent", parent = jesproplst }
    jesproplst:AddItem(bodrevinn)

    local bodrevmon = xlib.makeslider { label = "ttt_bodysnatcher_reveal_monster (def. 1)", min = 0, max = 2, repconvar = "rep_ttt_bodysnatcher_reveal_monster", parent = jesproplst }
    jesproplst:AddItem(bodrevmon)

    local bodrevind = xlib.makeslider { label = "ttt_bodysnatcher_reveal_independent (def. 1)", min = 0, max = 2, repconvar = "rep_ttt_bodysnatcher_reveal_independent", parent = jesproplst }
    jesproplst:AddItem(bodrevind)

    local bodres = xlib.makecheckbox { label = "ttt_bodysnatcher_respawn (def. 0)", repconvar = "rep_ttt_bodysnatcher_respawn", parent = jesproplst }
    jesproplst:AddItem(bodres)

    local bodresl = xlib.makeslider { label = "ttt_bodysnatcher_respawn_limit (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_bodysnatcher_respawn_limit", parent = jesproplst }
    jesproplst:AddItem(bodresl)

    local bodresd = xlib.makeslider { label = "ttt_bodysnatcher_respawn_delay (def. 3)", min = 0, max = 60, repconvar = "rep_ttt_bodysnatcher_respawn_delay", parent = jesproplst }
    jesproplst:AddItem(bodresd)

    local bodnm = xlib.makeslider { label = "ttt_bodysnatcher_notify_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_bodysnatcher_notify_mode", parent = jesproplst }
    jesproplst:AddItem(bodnm)

    local bodns = xlib.makecheckbox { label = "ttt_bodysnatcher_notify_sound (def. 0)", repconvar = "rep_ttt_bodysnatcher_notify_sound", parent = jesproplst }
    jesproplst:AddItem(bodns)

    local bodnc = xlib.makecheckbox { label = "ttt_bodysnatcher_notify_confetti (def. 0)", repconvar = "rep_ttt_bodysnatcher_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(bodnc)

    local boddt = xlib.makeslider { label = "ttt_bodysnatcher_device_time (def. 5)", min = 0, max = 60, repconvar = "rep_ttt_bodysnatcher_device_time", parent = jesproplst }
    jesproplst:AddItem(boddt)

    local goblbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Loot goblin settings:", parent = jesproplst }
    jesproplst:AddItem(goblbl)

    local gobtmr = xlib.makeslider { label = "ttt_lootgoblin_activation_timer (def. 30)", min = 0, max = 120, repconvar = "rep_ttt_lootgoblin_activation_timer", parent = jesproplst }
    jesproplst:AddItem(gobtmr)

    local gobann = xlib.makeslider { label = "ttt_lootgoblin_announce (def. 4)", min = 0, max = 4, repconvar = "rep_ttt_lootgoblin_announce", parent = jesproplst }
    jesproplst:AddItem(gobann)

    local gobsize = xlib.makeslider { label = "ttt_lootgoblin_size (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_lootgoblin_size", parent = jesproplst }
    jesproplst:AddItem(gobsize)

    local gobce = xlib.makecheckbox { label = "ttt_lootgoblin_cackle_enabled (def. 1)", repconvar = "rep_ttt_lootgoblin_cackle_enabled", parent = jesproplst }
    jesproplst:AddItem(gobce)

    local gobcmin = xlib.makeslider { label = "ttt_lootgoblin_cackle_timer_min (def. 4)", min = 0, max = 30, repconvar = "rep_ttt_lootgoblin_cackle_timer_min", parent = jesproplst }
    jesproplst:AddItem(gobcmin)

    local gobcmax = xlib.makeslider { label = "ttt_lootgoblin_cackle_timer_max (def. 12)", min = 0, max = 30, repconvar = "rep_ttt_lootgoblin_cackle_timer_max", parent = jesproplst }
    jesproplst:AddItem(gobcmax)

    local gobwep = xlib.makeslider { label = "ttt_lootgoblin_weapons_dropped (def. 8)", min = 0, max = 10, repconvar = "rep_ttt_lootgoblin_weapons_dropped", parent = jesproplst }
    jesproplst:AddItem(gobwep)

    local gobje = xlib.makecheckbox { label = "ttt_lootgoblin_jingle_enabled (def. 1)", repconvar = "rep_ttt_lootgoblin_jingle_enabled", parent = jesproplst }
    jesproplst:AddItem(gobje)

    local gobsmul = xlib.makeslider { label = "ttt_lootgoblin_speed_mult (def. 1.2)", min = 1, max = 2, decimal = 1, repconvar = "rep_ttt_lootgoblin_speed_mult", parent = jesproplst }
    jesproplst:AddItem(gobsmul)

    local gobsrec = xlib.makeslider { label = "ttt_lootgoblin_sprint_recovery (def. 0.12)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_lootgoblin_sprint_recovery", parent = jesproplst }
    jesproplst:AddItem(gobsrec)

    local gobnm = xlib.makeslider { label = "ttt_lootgoblin_notify_mode (def. 4)", min = 0, max = 4, repconvar = "rep_ttt_lootgoblin_notify_mode", parent = jesproplst }
    jesproplst:AddItem(gobnm)

    local gobns = xlib.makecheckbox { label = "ttt_lootgoblin_notify_sound (def. 1)", repconvar = "rep_ttt_lootgoblin_notify_sound", parent = jesproplst }
    jesproplst:AddItem(gobns)

    local gobnc = xlib.makecheckbox { label = "ttt_lootgoblin_notify_confetti (def. 1)", repconvar = "rep_ttt_lootgoblin_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(gobnc)

    for _, r in ipairs(external_jesters) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], jesproplst)
        end
    end
end

local function AddIndependentRoleProperties(gppnl)
    local external_independents = GetExternalRolesForTeam(INDEPENDENT_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_independents)
    local height = 1135 + GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count) + ((ROLE_MAX - 1) * 20)
    local indpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    indpropclp:SetSize(390, height)
    indpropclp:SetExpanded(1)
    indpropclp:SetLabel("Independent Properties")

    local indproplst = vgui.Create("DPanelList", indpropclp)
    indproplst:SetPos(5, 25)
    indproplst:SetSize(390, height)
    indproplst:SetSpacing(5)

    local indtes = xlib.makecheckbox { label = "ttt_independents_trigger_traitor_testers (def. 0)", repconvar = "rep_ttt_independents_trigger_traitor_testers", parent = indproplst }
    indproplst:AddItem(indtes)

    local indmia = xlib.makecheckbox { label = "ttt_independents_update_scoreboard (def. 0)", repconvar = "rep_ttt_independents_update_scoreboard", parent = indproplst }
    indproplst:AddItem(indmia)

    local drulbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Drunk settings:", parent = indproplst }
    indproplst:AddItem(drulbl)

    local drutim = xlib.makeslider { label = "ttt_drunk_sober_time (def. 180)", min = 0, max = 300, repconvar = "rep_ttt_drunk_sober_time", parent = indproplst }
    indproplst:AddItem(drutim)

    local druchn = xlib.makeslider { label = "ttt_drunk_innocent_chance (def. 0.7)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_drunk_innocent_chance", parent = indproplst }
    indproplst:AddItem(druchn)

    local druar = xlib.makecheckbox { label = "ttt_drunk_any_role (def. 0)", repconvar = "rep_ttt_drunk_any_role", parent = indproplst }
    indproplst:AddItem(druar)

    local druclo = xlib.makecheckbox { label = "ttt_drunk_become_clown (def. 0)", repconvar = "rep_ttt_drunk_become_clown", parent = indproplst }
    indproplst:AddItem(druclo)

    local drunm = xlib.makeslider { label = "ttt_drunk_notify_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_drunk_notify_mode", parent = indproplst }
    indproplst:AddItem(drunm)

    for r = 0, ROLE_MAX do
        if r ~= ROLE_DRUNK and r ~= ROLE_GLITCH then
            local rolestring = ROLE_STRINGS_RAW[r]
            local drucb = xlib.makecheckbox { label = "ttt_drunk_can_be_" .. rolestring .. " (def. 1)", repconvar = "rep_ttt_drunk_can_be_" .. rolestring, parent = indproplst }
            indproplst:AddItem(drucb)
        end
    end

    local oldlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Old Man settings:", parent = indproplst }
    indproplst:AddItem(oldlbl)

    local olddht = xlib.makeslider { label = "ttt_oldman_drain_health_to (def. 0)", min = 0, max = 200, repconvar = "rep_ttt_oldman_drain_health_to", parent = indproplst }
    indproplst:AddItem(olddht)

    local oldadr = xlib.makeslider { label = "ttt_oldman_adrenaline_rush (def. 5)", min = 0, max = 30, repconvar = "rep_ttt_oldman_adrenaline_rush", parent = indproplst }
    indproplst:AddItem(oldadr)

    local oldsho = xlib.makecheckbox { label = "ttt_oldman_adrenaline_shotgun (def. 1)", repconvar = "rep_ttt_oldman_adrenaline_shotgun", parent = indproplst }
    indproplst:AddItem(oldsho)

    local oldshod = xlib.makeslider { label = "ttt_oldman_adrenaline_shotgun_damage (def. 10)", min = 0, max = 100, repconvar = "rep_ttt_oldman_adrenaline_shotgun_damage", parent = indproplst }
    indproplst:AddItem(oldshod)

    local oldram = xlib.makecheckbox { label = "ttt_oldman_adrenaline_ramble (def. 1)", repconvar = "rep_ttt_oldman_adrenaline_ramble", parent = indproplst }
    indproplst:AddItem(oldram)

    local oldsti = xlib.makecheckbox { label = "ttt_oldman_hide_when_active (def. 0)", repconvar = "rep_ttt_oldman_hide_when_active", parent = indproplst }
    indproplst:AddItem(oldsti)

    local killbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Killer settings:", parent = indproplst }
    indproplst:AddItem(killbl)

    local kilken = xlib.makecheckbox { label = "ttt_killer_knife_enabled (def. 1)", repconvar = "rep_ttt_killer_knife_enabled", parent = indproplst }
    indproplst:AddItem(kilken)

    local kilkd = xlib.makeslider { label = "ttt_killer_knife_damage (def. 65)", min = 1, max = 100, repconvar = "rep_ttt_killer_knife_damage", parent = indproplst }
    indproplst:AddItem(kilkd)

    local kilkdel = xlib.makeslider { label = "ttt_killer_knife_delay (def. 0.8)", min = 0.1, max = 3, decimal = 2, repconvar = "rep_ttt_killer_knife_delay", parent = indproplst }
    indproplst:AddItem(kilkdel)

    local kilcen = xlib.makecheckbox { label = "ttt_killer_crowbar_enabled (def. 1)", repconvar = "rep_ttt_killer_crowbar_enabled", parent = indproplst }
    indproplst:AddItem(kilcen)

    local kilcd = xlib.makeslider { label = "ttt_killer_crowbar_damage (def. 20)", min = 1, max = 100, repconvar = "rep_ttt_killer_crowbar_damage", parent = indproplst }
    indproplst:AddItem(kilcd)

    local kilctd = xlib.makeslider { label = "ttt_killer_crowbar_thrown_damage (def. 50)", min = 1, max = 100, repconvar = "rep_ttt_killer_crowbar_thrown_damage", parent = indproplst }
    indproplst:AddItem(kilctd)

    local kilsen = xlib.makecheckbox { label = "ttt_killer_smoke_enabled (def. 1)", repconvar = "rep_ttt_killer_smoke_enabled", parent = indproplst }
    indproplst:AddItem(kilsen)

    local kilstm = xlib.makeslider { label = "ttt_killer_smoke_timer (def. 60)", min = 1, max = 120, repconvar = "rep_ttt_killer_smoke_timer", parent = indproplst }
    indproplst:AddItem(kilstm)

    local kilsti = xlib.makecheckbox { label = "ttt_killer_show_target_icon (def. 1)", repconvar = "rep_ttt_killer_show_target_icon", parent = indproplst }
    indproplst:AddItem(kilsti)

    local kildpe = xlib.makeslider { label = "ttt_killer_damage_penalty (def. 0.75)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_killer_damage_penalty", parent = indproplst }
    indproplst:AddItem(kildpe)

    local kildre = xlib.makeslider { label = "ttt_killer_damage_reduction (def. 0.45)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_killer_damage_reduction", parent = indproplst }
    indproplst:AddItem(kildre)

    local kilwal = xlib.makecheckbox { label = "ttt_killer_warn_all (def. 0)", repconvar = "rep_ttt_killer_warn_all", parent = indproplst }
    indproplst:AddItem(kilwal)

    local kilven = xlib.makecheckbox { label = "ttt_killer_vision_enable (def. 1)", repconvar = "rep_ttt_killer_vision_enable", parent = indproplst }
    indproplst:AddItem(kilven)

    local kilmia = xlib.makecheckbox { label = "ttt_killer_update_scoreboard (def. 1)", repconvar = "rep_ttt_killer_update_scoreboard", parent = indproplst }
    indproplst:AddItem(kilmia)

    local zomlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Zombie settings:", parent = indproplst }
    indproplst:AddItem(zomlbl)

    local zomamon = xlib.makecheckbox { label = "ttt_zombies_are_monsters (def. 0)", repconvar = "rep_ttt_zombies_are_monsters", parent = indproplst }
    indproplst:AddItem(zomamon)

    local zomatra = xlib.makecheckbox { label = "ttt_zombies_are_traitors (def. 0)", repconvar = "rep_ttt_zombies_are_traitors", parent = indproplst }
    indproplst:AddItem(zomatra)

    local zomchance = xlib.makeslider { label = "ttt_zombie_round_chance (def. 0.1)", min = 0, max = 1, decimal = 2, repconvar = "ttt_zombie_round_chance", parent = indproplst }
    indproplst:AddItem(zomchance)

    local zomlen = xlib.makecheckbox { label = "ttt_zombie_leap_enable (def. 1)", repconvar = "rep_ttt_zombie_leap_enable", parent = indproplst }
    indproplst:AddItem(zomlen)

    local zomsen = xlib.makecheckbox { label = "ttt_zombie_spit_enable (def. 1)", repconvar = "rep_ttt_zombie_spit_enable", parent = indproplst }
    indproplst:AddItem(zomsen)

    local zomsti = xlib.makecheckbox { label = "ttt_zombie_show_target_icon (def. 0)", repconvar = "rep_ttt_zombie_show_target_icon", parent = indproplst }
    indproplst:AddItem(zomsti)

    local zomdpe = xlib.makeslider { label = "ttt_zombie_damage_penalty (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_damage_penalty", parent = indproplst }
    indproplst:AddItem(zomdpe)

    local zomdre = xlib.makeslider { label = "ttt_zombie_damage_reduction (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_damage_reduction", parent = indproplst }
    indproplst:AddItem(zomdre)

    local zompow = xlib.makecheckbox { label = "ttt_zombie_prime_only_weapons (def. 1)", repconvar = "rep_ttt_zombie_prime_only_weapons", parent = indproplst }
    indproplst:AddItem(zompow)

    local zompadmg = xlib.makeslider { label = "ttt_zombie_prime_attack_damage (def. 65)", min = 1, max = 100, repconvar = "rep_ttt_zombie_prime_attack_damage", parent = indproplst }
    indproplst:AddItem(zompadmg)

    local zompadel = xlib.makeslider { label = "ttt_zombie_prime_attack_delay (def. 0.7)", min = 0.1, max = 3, decimal = 2, repconvar = "rep_ttt_zombie_prime_attack_delay", parent = indproplst }
    indproplst:AddItem(zompadel)

    local zompsb = xlib.makeslider { label = "ttt_zombie_prime_speed_bonus (def. 0.35)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_prime_speed_bonus", parent = indproplst }
    indproplst:AddItem(zompsb)

    local zompcc = xlib.makeslider { label = "ttt_zombie_prime_convert_chance (def. 1.0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_prime_convert_chance", parent = indproplst }
    indproplst:AddItem(zompcc)

    local zomtadmg = xlib.makeslider { label = "ttt_zombie_thrall_attack_damage (def. 45)", min = 1, max = 100, repconvar = "rep_ttt_zombie_thrall_attack_damage", parent = indproplst }
    indproplst:AddItem(zomtadmg)

    local zomtadel = xlib.makeslider { label = "ttt_zombie_thrall_attack_delay (def. 1.4)", min = 0.1, max = 3, decimal = 2, repconvar = "rep_ttt_zombie_thrall_attack_delay", parent = indproplst }
    indproplst:AddItem(zomtadel)

    local zomtsb = xlib.makeslider { label = "ttt_zombie_thrall_speed_bonus (def. 0.15)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_thrall_speed_bonus", parent = indproplst }
    indproplst:AddItem(zomtsb)

    local zomtcc = xlib.makeslider { label = "ttt_zombie_thrall_convert_chance (def. 1.0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_thrall_convert_chance", parent = indproplst }
    indproplst:AddItem(zomtcc)

    local zomve = xlib.makecheckbox { label = "ttt_zombie_vision_enable (def. 0)", repconvar = "rep_ttt_zombie_vision_enable", parent = indproplst }
    indproplst:AddItem(zomve)

    local mslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Mad Scientist settings:", parent = indproplst }
    indproplst:AddItem(mslbl)

    local msdt = xlib.makeslider { label = "ttt_madscientist_device_time (def. 4)", min = 0, max = 60, repconvar = "rep_ttt_madscientist_device_time", parent = indproplst }
    indproplst:AddItem(msdt)

    for _, r in ipairs(external_independents) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], indproplst)
        end
    end
end

local function AddMonsterRoleProperties(gppnl)
    local external_monsters = GetExternalRolesForTeam(MONSTER_ROLES)
    local role_cvars, num_count, bool_count, text_count = GetExternalRoleConVars(external_monsters)
    local height = GetExternalRolesHeight(role_cvars, num_count, bool_count, text_count)
    local indpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    indpropclp:SetSize(390, height)
    indpropclp:SetExpanded(1)
    indpropclp:SetLabel("Monsters Properties")

    local indproplst = vgui.Create("DPanelList", indpropclp)
    indproplst:SetPos(5, 25)
    indproplst:SetSize(390, height)
    indproplst:SetSpacing(5)

    for _, r in ipairs(external_monsters) do
        if role_cvars[r] then
            AddExternalRoleProperties(r, role_cvars[r], indproplst)
        end
    end
end

local function AddCustomRoleProperties(gppnl)
    local crpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    crpropclp:SetSize(390, 120)
    crpropclp:SetExpanded(1)
    crpropclp:SetLabel("Other Custom Role Properties")

    local crproplst = vgui.Create("DPanelList", crpropclp)
    crproplst:SetPos(5, 25)
    crproplst:SetSize(390, 120)
    crproplst:SetSpacing(5)

    local singdepimp = xlib.makecheckbox { label = "ttt_single_deputy_impersonator (def. 0)", repconvar = "rep_ttt_single_deputy_impersonator", parent = crproplst }
    crproplst:AddItem(singdepimp)

    local depimppadd = xlib.makecheckbox { label = "ttt_deputy_impersonator_promote_any_death (def. 0)", repconvar = "rep_ttt_deputy_impersonator_promote_any_death", parent = crproplst }
    crproplst:AddItem(depimppadd)

    local singdocqua = xlib.makecheckbox { label = "ttt_single_doctor_quack (def. 0)", repconvar = "rep_ttt_single_doctor_quack", parent = crproplst }
    crproplst:AddItem(singdocqua)

    local singmedhyp = xlib.makecheckbox { label = "ttt_single_paramedic_hypnotist (def. 0)", repconvar = "rep_ttt_single_paramedic_hypnotist", parent = crproplst }
    crproplst:AddItem(singmedhyp)

    local singphapar = xlib.makecheckbox { label = "ttt_single_phantom_parasite (def. 0)", repconvar = "rep_ttt_single_phantom_parasite", parent = crproplst }
    crproplst:AddItem(singphapar)

    local singdruclo = xlib.makecheckbox { label = "ttt_single_drunk_clown (def. 0)", repconvar = "rep_ttt_single_drunk_clown", parent = crproplst }
    crproplst:AddItem(singdruclo)
end

local function AddShopRandomizationSettings(lst, role_list)
    for _, r in pairs(role_list) do
        local rolestring = ROLE_STRINGS_RAW[r]
        local percent = xlib.makeslider { label = "ttt_" .. rolestring .. "_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_" .. rolestring .. "_shop_random_percent", parent = lst }
        lst:AddItem(percent)

        local enabled = xlib.makecheckbox { label = "ttt_" .. rolestring .. "_shop_random_enabled (def. 0)", repconvar = "rep_ttt_" .. rolestring .. "_shop_random_enabled", parent = lst }
        lst:AddItem(enabled)
    end
end

local function GetShopSyncCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if (TRAITOR_ROLES[r] and r ~= ROLE_TRAITOR) or (DETECTIVE_ROLES[r] and r ~= ROLE_DETECTIVE) or r == ROLE_ZOMBIE then
            table.insert(cvar_list, "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_sync")
        end
    end
    return cvar_list
end

local function AddShopSyncSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local sync = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(sync)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = sync
        end
    end
end

local function GetShopModeCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if (INDEPENDENT_ROLES[r] and r ~= ROLE_ZOMBIE) or DELAYED_SHOP_ROLES[r] or r == ROLE_MERCENARY then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_mode")
        end
    end
    return cvar_list
end

local function AddShopModeSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local mode = xlib.makeslider { label = c .. " (def. " .. default .. ")", min = 0, max = 4, repconvar = "rep_".. c, parent = lst }
        lst:AddItem(mode)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = mode
        end
    end
end

local function GetShopActiveCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if DELAYED_SHOP_ROLES[r] then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_active_only")
        end
    end
    return cvar_list
end

local function AddShopActiveSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local active = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(active)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = active
        end
    end
end

local function GetShopDelayCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if DELAYED_SHOP_ROLES[r] then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_delay")
        end
    end
    return cvar_list
end

local function AddShopDelaySettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local delay = xlib.makecheckbox { label = c .. " (def. " .. default .. ")", repconvar = "rep_".. c, parent = lst }
        lst:AddItem(delay)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = delay
        end
    end
end

local function AddRoleShop(gppnl)
    local shop_roles = GetShopRoles()
    local traitor_shops = table.IntersectedKeys(TRAITOR_ROLES, shop_roles)
    local traitor_syncs = GetShopSyncCvars(traitor_shops)
    local traitor_modes = GetShopModeCvars(traitor_shops)
    local traitor_actives = GetShopActiveCvars(traitor_shops)
    local traitor_delays = GetShopDelayCvars(traitor_shops)
    local inno_shops = table.IntersectedKeys(INNOCENT_ROLES, shop_roles)
    local inno_syncs = GetShopSyncCvars(inno_shops)
    local inno_modes = GetShopModeCvars(inno_shops)
    local inno_actives = GetShopActiveCvars(inno_shops)
    local inno_delays = GetShopDelayCvars(inno_shops)
    local indep_shops = table.IntersectedKeys(INDEPENDENT_ROLES, shop_roles)
    local indep_syncs = GetShopSyncCvars(indep_shops)
    local indep_modes = GetShopModeCvars(indep_shops)
    local indep_actives = GetShopActiveCvars(indep_shops)
    local indep_delays = GetShopDelayCvars(indep_shops)
    local jester_shops = table.IntersectedKeys(JESTER_ROLES, shop_roles)
    local jester_syncs = GetShopSyncCvars(jester_shops)
    local jester_modes = GetShopModeCvars(jester_shops)
    local jester_actives = GetShopActiveCvars(jester_shops)
    local jester_delays = GetShopDelayCvars(jester_shops)
    local monster_shops = table.IntersectedKeys(MONSTER_ROLES, shop_roles)
    local monster_syncs = GetShopSyncCvars(monster_shops)
    local monster_modes = GetShopModeCvars(monster_shops)
    local monster_actives = GetShopActiveCvars(monster_shops)
    local monster_delays = GetShopDelayCvars(monster_shops)
    local height = 155 + (45 * #traitor_shops) + (20 * #traitor_syncs) + (25 * #traitor_modes) + (20 * #traitor_actives) + (20 * #traitor_delays) +
                        (45 * #inno_shops) + (20 * #inno_syncs) + (25 * #inno_modes) + (20 * #inno_actives) + (20 * #inno_delays) +
                        (45 * #indep_shops) + (20 * #indep_syncs) + (25 * #indep_modes) + (20 * #indep_actives) + (20 * #indep_delays) +
                        (45 * #jester_shops) + (20 * #jester_syncs) + (25 * #jester_modes) + (20 * #jester_actives) + (20 * #jester_delays) +
                        (45 * #monster_shops) + (20 * #monster_syncs) + (25 * #monster_modes) + (20 * #monster_actives) + (20 * #monster_delays)
    local rspnl = vgui.Create("DCollapsibleCategory", gppnl)
    rspnl:SetSize(390, height)
    rspnl:SetExpanded(0)
    rspnl:SetLabel("Role Shop")

    local rslst = vgui.Create("DPanelList", rspnl)
    rslst:SetPos(5, 25)
    rslst:SetSize(390, height)
    rslst:SetSpacing(5)

    local openButton = xlib.makebutton{w=150, label="Open Role Weapons Config", parent=rslst}
    openButton.DoClick=function()
        RunConsoleCommand("ttt_roleweapons")
    end

    local rsfa = xlib.makecheckbox { label = "ttt_shop_for_all (def. 0)", repconvar = "rep_ttt_shop_for_all", parent = rslst }
    rslst:AddItem(rsfa)

    local rsp = xlib.makeslider { label = "ttt_shop_random_percent (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_shop_random_percent", parent = rslst }
    rslst:AddItem(rsp)

    local rspos = xlib.makecheckbox { label = "ttt_shop_random_position (def. 0)", repconvar = "rep_ttt_shop_random_position", parent = rslst }
    rslst:AddItem(rspos)

    local tralbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Traitors:", parent = rslst }
    rslst:AddItem(tralbl)

    AddShopRandomizationSettings(rslst, traitor_shops)
    AddShopSyncSettings(rslst, traitor_syncs)
    AddShopModeSettings(rslst, traitor_modes)
    AddShopActiveSettings(rslst, traitor_actives)
    AddShopDelaySettings(rslst, traitor_delays)

    local innlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Innocents:", parent = rslst }
    rslst:AddItem(innlbl)

    AddShopRandomizationSettings(rslst, inno_shops)
    AddShopSyncSettings(rslst, inno_syncs)
    AddShopModeSettings(rslst, inno_modes)
    AddShopActiveSettings(rslst, inno_actives)
    AddShopDelaySettings(rslst, inno_delays)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jesters:", parent = rslst }
    rslst:AddItem(jeslbl)

    AddShopRandomizationSettings(rslst, jester_shops)
    AddShopSyncSettings(rslst, jester_syncs)
    AddShopModeSettings(rslst, jester_modes)
    AddShopActiveSettings(rslst, jester_actives)
    AddShopDelaySettings(rslst, jester_delays)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Independents:", parent = rslst }
    rslst:AddItem(indlbl)

    AddShopRandomizationSettings(rslst, indep_shops)
    AddShopSyncSettings(rslst, indep_syncs)
    AddShopModeSettings(rslst, indep_modes)
    AddShopActiveSettings(rslst, indep_actives)
    AddShopDelaySettings(rslst, indep_delays)

    local monlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Monsters:", parent = rslst }
    rslst:AddItem(monlbl)

    AddShopRandomizationSettings(rslst, monster_shops)
    AddShopSyncSettings(rslst, monster_syncs)
    AddShopModeSettings(rslst, monster_modes)
    AddShopActiveSettings(rslst, monster_actives)
    AddShopDelaySettings(rslst, monster_delays)
end

local function AddDna(gppnl)
    local gpdnaclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpdnaclp:SetSize(390, 50)
    gpdnaclp:SetExpanded(0)
    gpdnaclp:SetLabel("DNA")

    local gpdnalst = vgui.Create("DPanelList", gpdnaclp)
    gpdnalst:SetPos(5, 25)
    gpdnalst:SetSize(390, 50)
    gpdnalst:SetSpacing(5)

    local dnarange = xlib.makeslider { label = "ttt_killer_dna_range (def. 550)", min = 100, max = 1000, repconvar = "rep_ttt_killer_dna_range", parent = gpdnalst }
    gpdnalst:AddItem(dnarange)

    local dnakbt = xlib.makeslider { label = "ttt_killer_dna_basetime (def. 100)", min = 10, max = 200, repconvar = "rep_ttt_killer_dna_basetime", parent = gpdnalst }
    gpdnalst:AddItem(dnakbt)
end

local function AddVoiceChat(gppnl)
    local gpvcbclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpvcbclp:SetSize(390, 65)
    gpvcbclp:SetExpanded(0)
    gpvcbclp:SetLabel("Voice Chat Battery")

    local gpvcblst = vgui.Create("DPanelList", gpvcbclp)
    gpvcblst:SetPos(5, 25)
    gpvcblst:SetSize(390, 65)
    gpvcblst:SetSpacing(5)

    local gpevd = xlib.makecheckbox { label = "ttt_voice_drain (def. 0)", repconvar = "rep_ttt_voice_drain", parent = gpvcblst }
    gpvcblst:AddItem(gpevd)

    local gpvdn = xlib.makeslider { label = "ttt_voice_drain_normal (def. 0.2)", min = 0.1, max = 1, decimal = 1, repconvar = "rep_ttt_voice_drain_normal", parent = gpvcblst }
    gpvcblst:AddItem(gpvdn)

    local gpvda = xlib.makeslider { label = "ttt_voice_drain_admin (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_admin", parent = gpvcblst }
    gpvcblst:AddItem(gpvda)

    local gpvdr = xlib.makeslider { label = "ttt_voice_drain_recharge (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_recharge", parent = gpvcblst }
    gpvcblst:AddItem(gpvdr)
end

local function AddOtherGameplay(gppnl)
    --Other Gameplay Settings
    local gpogsclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpogsclp:SetSize(390, 200)
    gpogsclp:SetExpanded(0)
    gpogsclp:SetLabel("Other Gameplay Settings")

    local gpogslst = vgui.Create("DPanelList", gpogsclp)
    gpogslst:SetPos(5, 25)
    gpogslst:SetSize(390, 200)
    gpogslst:SetSpacing(5)

    local gpminply = xlib.makeslider { label = "ttt_minimum_players (def. 2)", min = 1, max = 10, repconvar = "rep_ttt_minimum_players", parent = gpogslst }
    gpogslst:AddItem(gpminply)

    local gpprdm = xlib.makecheckbox { label = "ttt_postround_dm (def. 0)", repconvar = "rep_ttt_postround_dm", parent = gpogslst }
    gpogslst:AddItem(gpprdm)

    local gpds = xlib.makecheckbox { label = "ttt_dyingshot (def. 0)", repconvar = "rep_ttt_dyingshot", parent = gpogslst }
    gpogslst:AddItem(gpds)

    local gpnntdp = xlib.makecheckbox { label = "ttt_no_nade_throw_during_prep (def. 0)", repconvar = "rep_ttt_no_nade_throw_during_prep", parent = gpogslst }
    gpogslst:AddItem(gpnntdp)

    local gpwc = xlib.makecheckbox { label = "ttt_weapon_carrying (def. 1)", repconvar = "rep_ttt_weapon_carrying", parent = gpogslst }
    gpogslst:AddItem(gpwc)

    local gpwcr = xlib.makeslider { label = "ttt_weapon_carrying_range (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_weapon_carrying_range", parent = gpogslst }
    gpogslst:AddItem(gpwcr)

    local gpttf = xlib.makecheckbox { label = "ttt_teleport_telefrags (def. 0)", repconvar = "rep_ttt_teleport_telefrags", parent = gpogslst }
    gpogslst:AddItem(gpttf)

    local gprdp = xlib.makecheckbox { label = "ttt_ragdoll_pinning (def. 1)", repconvar = "rep_ttt_ragdoll_pinning", parent = gpogslst }
    gpogslst:AddItem(gprdp)

    local gprdpi = xlib.makecheckbox { label = "ttt_ragdoll_pinning_innocents (def. 0)", repconvar = "rep_ttt_ragdoll_pinning_innocents", parent = gpogslst }
    gpogslst:AddItem(gprdpi)
end

local function AddGameplayModule()
    local gppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    AddTraitorAndDetectiveSettings(gppnl)
    AddSpecialistTraitorSettings(gppnl)
    AddSpecialistInnocentSettings(gppnl)
    AddSpecialistDetectiveSettings(gppnl)
    AddIndependentRoleSettings(gppnl)
    AddMonsterSettings(gppnl)
    AddRoleHealthSettings(gppnl)
    AddTraitorProperties(gppnl)
    AddInnocentProperties(gppnl)
    AddDetectiveProperties(gppnl)
    AddJesterRoleProperties(gppnl)
    AddIndependentRoleProperties(gppnl)
    AddMonsterRoleProperties(gppnl)
    AddCustomRoleProperties(gppnl)
    AddRoleShop(gppnl)
    AddDna(gppnl)
    AddVoiceChat(gppnl)
    AddOtherGameplay(gppnl)

    xgui.hookEvent("onProcessModules", nil, gppnl.processModules)
    xgui.addSubModule("Gameplay", gppnl, nil, "terrortown_settings")
end

local function AddKarmaModule()
    local krmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local krmclp = vgui.Create("DCollapsibleCategory", krmpnl)
    krmclp:SetSize(390, 440)
    krmclp:SetExpanded(1)
    krmclp:SetLabel("Karma")

    local krmlst = vgui.Create("DPanelList", krmclp)
    krmlst:SetPos(5, 25)
    krmlst:SetSize(390, 440)
    krmlst:SetSpacing(5)

    local krmekrm = xlib.makecheckbox { label = "ttt_karma", repconvar = "rep_ttt_karma", parent = krmlst }
    krmlst:AddItem(krmekrm)

    local krmeskrm = xlib.makecheckbox { label = "ttt_karma_strict", repconvar = "rep_ttt_karma_strict", parent = krmlst }
    krmlst:AddItem(krmeskrm)

    local krms = xlib.makeslider { label = "ttt_karma_starting (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_starting", parent = krmlst }
    krmlst:AddItem(krms)

    local krmmx = xlib.makeslider { label = "ttt_karma_max (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_max", parent = krmlst }
    krmlst:AddItem(krmmx)

    local krmr = xlib.makeslider { label = "ttt_karma_ratio (def. 0.001)", min = 0.001, max = 0.009, decimal = 3, repconvar = "rep_ttt_karma_ratio", parent = krmlst }
    krmlst:AddItem(krmr)

    local krmkp = xlib.makeslider { label = "ttt_karma_kill_penalty (def. 15)", min = 1, max = 30, repconvar = "rep_ttt_karma_kill_penalty", parent = krmlst }
    krmlst:AddItem(krmkp)

    local krmri = xlib.makeslider { label = "ttt_karma_round_increment (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_karma_round_increment", parent = krmlst }
    krmlst:AddItem(krmri)

    local krmcb = xlib.makeslider { label = "ttt_karma_clean_bonus (def. 30)", min = 10, max = 100, repconvar = "rep_ttt_karma_clean_bonus", parent = krmlst }
    krmlst:AddItem(krmcb)

    local krmtdmgr = xlib.makeslider { label = "ttt_karma_traitordmg_ratio (def. 0.0003)", min = 0.0001, max = 0.001, decimal = 4, repconvar = "rep_ttt_karma_traitordmg_ratio", parent = krmlst }
    krmlst:AddItem(krmtdmgr)

    local krmtkb = xlib.makeslider { label = "ttt_karma_traitorkill_bonus (def. 40)", min = 10, max = 100, repconvar = "rep_ttt_karma_traitorkill_bonus", parent = krmlst }
    krmlst:AddItem(krmtkb)

    local krmjdmgr = xlib.makeslider { label = "ttt_karma_jesterdmg_ratio (def. 0.5)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_karma_jesterdmg_ratio", parent = krmlst }
    krmlst:AddItem(krmjdmgr)

    local krmjkp = xlib.makeslider { label = "ttt_karma_jesterkill_penalty (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_karma_jesterkill_penalty", parent = krmlst }
    krmlst:AddItem(krmjkp)

    local krmlak = xlib.makecheckbox { label = "ttt_karma_low_autokick (def. 1)", repconvar = "rep_ttt_karma_low_autokick", parent = krmlst }
    krmlst:AddItem(krmlak)

    local krmla = xlib.makeslider { label = "ttt_karma_low_amount (def. 450)", min = 100, max = 1000, repconvar = "rep_ttt_karma_low_amount", parent = krmlst }
    krmlst:AddItem(krmla)

    local krmlab = xlib.makecheckbox { label = "ttt_karma_low_ban (def. 1)", repconvar = "rep_ttt_karma_low_ban", parent = krmlst }
    krmlst:AddItem(krmlab)

    local krmlbm = xlib.makeslider { label = "ttt_karma_low_ban_minutes (def. 60)", min = 10, max = 100, repconvar = "rep_ttt_karma_low_ban_minutes", parent = krmlst }
    krmlst:AddItem(krmlbm)

    local krmpre = xlib.makecheckbox { label = "ttt_karma_persist (def. 0)", repconvar = "rep_ttt_karma_persist", parent = krmlst }
    krmlst:AddItem(krmpre)

    local krmdbs = xlib.makecheckbox { label = "ttt_karma_debugspam (def. 0)", repconvar = "rep_ttt_karma_debugspam", parent = krmlst }
    krmlst:AddItem(krmdbs)

    local krmch = xlib.makeslider { label = "ttt_karma_clean_half (def. 0.25)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_karma_clean_half", parent = krmlst }
    krmlst:AddItem(krmch)

    xgui.hookEvent("onProcessModules", nil, krmpnl.processModules)
    xgui.addSubModule("Karma", krmpnl, nil, "terrortown_settings")
end

local function AddMapModule()
    local mprpnl = xlib.makepanel { w = 415, h = 318, parent = xgui.null }

    local mprpp = vgui.Create("DCollapsibleCategory", mprpnl)
    mprpp:SetSize(390, 50)
    mprpp:SetExpanded(1)
    mprpp:SetLabel("Map-related")

    local mprlst = vgui.Create("DPanelList", mprpp)
    mprlst:SetPos(5, 25)
    mprlst:SetSize(390, 50)
    mprlst:SetSpacing(5)

    local mprwss = xlib.makecheckbox { label = "ttt_use_weapon_spawn_scripts (def. 1)", repconvar = "rep_ttt_use_weapon_spawn_scripts", parent = mprlst }
    mprlst:AddItem(mprwss)

    local mpwsc = xlib.makecheckbox { label = "ttt_weapon_spawn_count (def. 0)", repconvar = "rep_ttt_weapon_spawn_count", parent = mprlst }
    mprlst:AddItem(mpwsc)

    xgui.hookEvent("onProcessModules", nil, mprpnl.processModules)
    xgui.addSubModule("Map-related", mprpnl, nil, "terrortown_settings")
end

local function AddRoleCreditsSlider(role_shops, lst)
    for _, r in ipairs(role_shops) do
        local role_string = ROLE_STRINGS_RAW[r]
        local convar = "ttt_" .. role_string .. "_credits_starting"
        local default = GetReplicatedConVarDefault(convar, "0")
        local slider = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = 0, max = 10, repconvar = "rep_" .. convar, parent = lst }
        lst:AddItem(slider)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = slider
        end
    end
end

local function AddRoleCreditSection(pnl, label, role_list, excludes)
    local credit_roles = GetCreditRoles()
    local role_shops = table.IntersectedKeys(role_list, credit_roles, excludes)
    local cat = vgui.Create("DCollapsibleCategory", pnl)
    cat:SetSize(390, #role_shops * 25)
    cat:SetExpanded(0)
    cat:SetLabel(label .. " Credits")

    local lst = vgui.Create("DPanelList", cat)
    lst:SetPos(5, 25)
    lst:SetSize(390, #role_shops * 25)
    lst:SetSpacing(5)

    AddRoleCreditsSlider(role_shops, lst)
end

local function AddEquipmentCreditsModule()
    local ecpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Traitor Credits
    local credit_roles =  GetCreditRoles()
    local traitor_shops = table.IntersectedKeys(TRAITOR_ROLES, credit_roles, {ROLE_TRAITOR})
    local ectcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ectcclp:SetSize(390, 145 + (25 * #traitor_shops))
    ectcclp:SetExpanded(1)
    ectcclp:SetLabel("Traitor Credits")

    local ectclst = vgui.Create("DPanelList", ectcclp)
    ectclst:SetPos(5, 25)
    ectclst:SetSize(390, 145 + (25 * #traitor_shops))
    ectclst:SetSpacing(5)

    local ectccs = xlib.makeslider { label = "ttt_credits_starting (def. 2)", min = 0, max = 10, repconvar = "rep_ttt_credits_starting", parent = ectclst }
    ectclst:AddItem(ectccs)

    AddRoleCreditsSlider(traitor_shops, ectclst)

    local ectcab = xlib.makecheckbox { label = "ttt_credits_alonebonus (def. 1)", repconvar = "rep_ttt_credits_alonebonus", parent = ectclst }
    ectclst:AddItem(ectcab)

    local ectcap = xlib.makeslider { label = "ttt_credits_award_pct (def. 0.35)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_credits_award_pct", parent = ectclst }
    ectclst:AddItem(ectcap)

    local ectcas = xlib.makeslider { label = "ttt_credits_award_size (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_size", parent = ectclst }
    ectclst:AddItem(ectcas)

    local ectcar = xlib.makeslider { label = "ttt_credits_award_repeat (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_repeat", parent = ectclst }
    ectclst:AddItem(ectcar)

    local ectcdk = xlib.makeslider { label = "ttt_credits_detectivekill (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_detectivekill", parent = ectclst }
    ectclst:AddItem(ectcdk)

    --Detective Credits
    local detective_shops = table.IntersectedKeys(DETECTIVE_ROLES, credit_roles, {ROLE_DETECTIVE})
    local ecdcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecdcclp:SetSize(390, 75 + (25 * #detective_shops))
    ecdcclp:SetExpanded(0)
    ecdcclp:SetLabel("Detective Credits")

    local ecdclst = vgui.Create("DPanelList", ecdcclp)
    ecdclst:SetPos(5, 25)
    ecdclst:SetSize(390, 75 + (25 * #detective_shops))
    ecdclst:SetSpacing(5)

    local ecdccs = xlib.makeslider { label = "ttt_det_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_starting", parent = ecdclst }
    ecdclst:AddItem(ecdccs)

    AddRoleCreditsSlider(detective_shops, ecdclst)

    local ecdctk = xlib.makeslider { label = "ttt_det_credits_traitorkill (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitorkill", parent = ecdclst }
    ecdclst:AddItem(ecdctk)

    local ecdctd = xlib.makeslider { label = "ttt_det_credits_traitordead (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitordead", parent = ecdclst }
    ecdclst:AddItem(ecdctd)

    AddRoleCreditSection(ecpnl, "Jester", JESTER_ROLES)
    AddRoleCreditSection(ecpnl, "Innocent", INNOCENT_ROLES, GetTeamRoles(DETECTIVE_ROLES))
    AddRoleCreditSection(ecpnl, "Independent", INDEPENDENT_ROLES)

    xgui.hookEvent("onProcessModules", nil, ecpnl.processModules)
    xgui.addSubModule("Equipment Credits", ecpnl, nil, "terrortown_settings")
end

local function AddPlayerMovementModule()
    local pmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local pmspp = vgui.Create("DCollapsibleCategory", pmpnl)
    pmspp:SetSize(390, 100)
    pmspp:SetExpanded(1)
    pmspp:SetLabel("Sprint")

    local pmsplst = vgui.Create("DPanelList", pmspp)
    pmsplst:SetPos(5, 25)
    pmsplst:SetSize(390, 100)
    pmsplst:SetSpacing(5)

    local pmspbr = xlib.makeslider { label = "ttt_sprint_bonus_rel (def. 0.4)", min = 0.1, max = 2, decimal = 1, repconvar = "rep_ttt_sprint_bonus_rel", parent = pmsplst }
    pmsplst:AddItem(pmspbr)

    local pmspri = xlib.makeslider { label = "ttt_sprint_regenerate_innocent (def. 0.08)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_innocent", parent = pmsplst }
    pmsplst:AddItem(pmspri)

    local pmsprt = xlib.makeslider { label = "ttt_sprint_regenerate_traitor (def. 0.12)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_traitor", parent = pmsplst }
    pmsplst:AddItem(pmsprt)

    local pmspc = xlib.makeslider { label = "ttt_sprint_consume (def. 0.2)", min = 0.1, max = 5, decimal = 1, repconvar = "rep_ttt_sprint_consume", parent = pmsplst }
    pmsplst:AddItem(pmspc)

    xgui.hookEvent("onProcessModules", nil, pmpnl.processModules)
    xgui.addSubModule("Player Movement", pmpnl, nil, "terrortown_settings")
end

local function AddPropPossessionModule()
    local pppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local ppclp = vgui.Create("DCollapsibleCategory", pppnl)
    ppclp:SetSize(390, 120)
    ppclp:SetExpanded(1)
    ppclp:SetLabel("Prop Possession")

    local pplst = vgui.Create("DPanelList", ppclp)
    pplst:SetPos(5, 25)
    pplst:SetSize(390, 120)
    pplst:SetSpacing(5)

    local ppspc = xlib.makecheckbox { label = "ttt_spec_prop_control  (def. 1)", repconvar = "rep_ttt_spec_prop_control", parent = pplst }
    pplst:AddItem(ppspc)

    local ppspb = xlib.makeslider { label = "ttt_spec_prop_base (def. 8)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_base", parent = pplst }
    pplst:AddItem(ppspb)

    local ppspmp = xlib.makeslider { label = "ttt_spec_prop_maxpenalty (def. -6)", min = -50, max = 0, repconvar = "rep_ttt_spec_prop_maxpenalty", parent = pplst }
    pplst:AddItem(ppspmp)

    local ppspmb = xlib.makeslider { label = "ttt_spec_prop_maxbonus (def. 16)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_maxbonus", parent = pplst }
    pplst:AddItem(ppspmb)

    local ppspf = xlib.makeslider { label = "ttt_spec_prop_force (def. 110)", min = 50, max = 300, repconvar = "rep_ttt_spec_prop_force", parent = pplst }
    pplst:AddItem(ppspf)

    local ppprt = xlib.makeslider { label = "ttt_spec_prop_rechargetime (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_spec_prop_rechargetime", parent = pplst }
    pplst:AddItem(ppprt)

    xgui.hookEvent("onProcessModules", nil, pppnl.processModules)
    xgui.addSubModule("Prop Possession", pppnl, nil, "terrortown_settings")
end

local function AddAdminModule()
    -------------------- Admin-related Module--------------------
    local arpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local arclp = vgui.Create("DCollapsibleCategory", arpnl)
    arclp:SetSize(390, 120)
    arclp:SetExpanded(1)
    arclp:SetLabel("Admin-related")

    local arlst = vgui.Create("DPanelList", arclp)
    arlst:SetPos(5, 25)
    arlst:SetSize(390, 120)
    arlst:SetSpacing(5)

    local aril = xlib.makeslider { label = "ttt_idle_limit (def. 180)", min = 50, max = 300, repconvar = "rep_ttt_idle_limit", parent = arlst }
    arlst:AddItem(aril)

    local arnck = xlib.makecheckbox { label = "ttt_namechange_kick (def. 1)", repconvar = "rep_ttt_namechange_kick", parent = arlst }
    arlst:AddItem(arnck)

    local arncbt = xlib.makeslider { label = "ttt_namechange_bantime (def. 10)", min = 0, max = 60, repconvar = "rep_ttt_namechange_bantime", parent = arlst }
    arlst:AddItem(arncbt)

    xgui.hookEvent("onProcessModules", nil, arpnl.processModules)
    xgui.addSubModule("Admin-related", arpnl, nil, "terrortown_settings")
end

local function AddMiscModule()
    -------------------- Miscellaneous Module--------------------
    local miscpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local bempnl = vgui.Create("DCollapsibleCategory", miscpnl)
    bempnl:SetSize(390, 100)
    bempnl:SetExpanded(1)
    bempnl:SetLabel("Better Equipment Menu")

    local bemlst = vgui.Create("DPanelList", bempnl)
    bemlst:SetPos(5, 25)
    bemlst:SetSize(390, 100)
    bemlst:SetSpacing(5)

    local bemac = xlib.makecheckbox { label = "ttt_bem_allow_change (def. 1)", repconvar = "rep_ttt_bem_allow_change", parent = bemlst }
    bemlst:AddItem(bemac)

    local bemcol = xlib.makeslider { label = "ttt_bem_sv_cols (def. 4)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_cols", parent = bemlst }
    bemlst:AddItem(bemcol)

    local bemrow = xlib.makeslider { label = "ttt_bem_sv_rows (def. 5)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_rows", parent = bemlst }
    bemlst:AddItem(bemrow)

    local bemsize = xlib.makeslider { label = "ttt_bem_sv_size (def. 64)", min = 16, max = 128, repconvar = "rep_ttt_bem_sv_size", parent = bemlst }
    bemlst:AddItem(bemsize)

    local miscclp = vgui.Create("DCollapsibleCategory", miscpnl)
    miscclp:SetSize(390, 340)
    miscclp:SetExpanded(1)
    miscclp:SetLabel("Miscellaneous")

    local misclst = vgui.Create("DPanelList", miscclp)
    misclst:SetPos(5, 25)
    misclst:SetSize(390, 340)
    misclst:SetSpacing(5)

    local miscdh = xlib.makecheckbox { label = "ttt_detective_hats (def. 0)", repconvar = "rep_ttt_detective_hats", parent = misclst }
    misclst:AddItem(miscdh)

    local miscpcm = xlib.makeslider { label = "ttt_playercolor_mode (def. 1)", min = 0, max = 3, repconvar = "rep_ttt_playercolor_mode", parent = misclst }
    misclst:AddItem(miscpcm)

    local miscrc = xlib.makecheckbox { label = "ttt_ragdoll_collide (def. 0)", repconvar = "rep_ttt_ragdoll_collide", parent = misclst }
    misclst:AddItem(miscrc)

    local miscbs = xlib.makecheckbox { label = "ttt_bots_are_spectators (def. 0)", repconvar = "rep_ttt_bots_are_spectators", parent = misclst }
    misclst:AddItem(miscbs)

    local miscdpw = xlib.makecheckbox { label = "ttt_debug_preventwin (def. 0)", repconvar = "rep_ttt_debug_preventwin", parent = misclst }
    misclst:AddItem(miscdpw)

    local miscdlk = xlib.makecheckbox { label = "ttt_debug_logkills (def. 1)", repconvar = "rep_ttt_debug_logkills", parent = misclst }
    misclst:AddItem(miscdlk)

    local miscdlr = xlib.makecheckbox { label = "ttt_debug_logroles (def. 1)", repconvar = "rep_ttt_debug_logroles", parent = misclst }
    misclst:AddItem(miscdlr)

    local misclv = xlib.makecheckbox { label = "ttt_locational_voice (def. 0)", repconvar = "rep_ttt_locational_voice", parent = misclst }
    misclst:AddItem(misclv)

    local miscdj = xlib.makecheckbox { label = "ttt_allow_discomb_jump (def. 0)", repconvar = "rep_ttt_allow_discomb_jump", parent = misclst }
    misclst:AddItem(miscdj)

    local miscswi = xlib.makeslider { label = "ttt_spawn_wave_interval (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_spawn_wave_interval", parent = misclst }
    misclst:AddItem(miscswi)

    local misccu = xlib.makecheckbox { label = "ttt_crowbar_unlocks (def. 1)", repconvar = "rep_ttt_crowbar_unlocks", parent = misclst }
    misclst:AddItem(misccu)

    local misccp = xlib.makeslider { label = "ttt_crowbar_pushforce (def. 395)", min = 0, max = 10000, repconvar = "rep_ttt_crowbar_pushforce", parent = misclst }
    misclst:AddItem(misccp)

    local miscsd = xlib.makecheckbox { label = "ttt_scoreboard_deaths (def. 0)", repconvar = "rep_ttt_scoreboard_deaths", parent = misclst }
    misclst:AddItem(miscsd)

    local miscss = xlib.makecheckbox { label = "ttt_scoreboard_score (def. 0)", repconvar = "rep_ttt_scoreboard_score", parent = misclst }
    misclst:AddItem(miscss)

    local miscrstlbl = xlib.makelabel { label = "ttt_round_summary_tabs (def. summary,hilite,events,scores)", parent = misclst }
    misclst:AddItem(miscrstlbl)
    local miscrsttb = xlib.maketextbox { repconvar = "rep_ttt_round_summary_tabs", enableinput = true, parent = misclst }
    misclst:AddItem(miscrsttb)

    --Disable Features
    local dfclp = vgui.Create("DCollapsibleCategory", miscpnl)
    dfclp:SetSize(390, 50)
    dfclp:SetExpanded(1)
    dfclp:SetLabel("Disable Features")

    local dflst = vgui.Create("DPanelList", dfclp)
    dflst:SetPos(5, 25)
    dflst:SetSize(390, 50)
    dflst:SetSpacing(5)

    local dfdh = xlib.makecheckbox { label = "ttt_disable_headshots (def. 0)", repconvar = "rep_ttt_disable_headshots", parent = dflst }
    dflst:AddItem(dfdh)

    local dfdmw = xlib.makecheckbox { label = "ttt_disable_mapwin (def. 0)", repconvar = "rep_ttt_disable_mapwin", parent = dflst }
    dflst:AddItem(dfdmw)

    xgui.hookEvent("onProcessModules", nil, miscpnl.processModules)
    xgui.addSubModule("Miscellaneous", miscpnl, nil, "terrortown_settings")
end

hook.Add("InitPostEntity", "CustomRolesLocalLoad", function()
    AddRoundStructureModule()
    AddGameplayModule()
    AddKarmaModule()
    AddMapModule()
    AddEquipmentCreditsModule()
    AddPlayerMovementModule()
    AddPropPossessionModule()
    AddAdminModule()
    AddMiscModule()

    -- Request missing cvar data, if we have any
    if table.Count(missing_cvars) > 0 then
        net.Receive("ULX_CRCVarRequest", function()
            local results = net.ReadTable()

            for cv, data in pairs(results) do
                -- Make sure each of these actually has the control reference
                local control = missing_cvars[cv]
                if control and type(control) ~= "boolean" then
                    -- Update whichever portions were sent back from the server
                    if data.d then
                        control:SetText(cv .. " (def. " .. data.d .. ")")
                    end

                    if data.m and control.SetMin then
                        control:SetMin(data.m)
                    end

                    if data.x and control.SetMax then
                        control:SetMax(data.x)
                    end

                    -- Make sure everything is the correct size now that we changed things
                    if control.Label then
                        control.Label:SizeToContents()
                    end
                    control:SizeToContents()
                end
            end
        end)

        -- Convert from a lookup table to an indexed table
        local net_table = {}
        for k, _ in pairs(missing_cvars) do
            table.insert(net_table, k)
        end

        net.Start("ULX_CRCVarRequest")
        net.WriteTable(net_table)
        net.SendToServer()
    end
end)