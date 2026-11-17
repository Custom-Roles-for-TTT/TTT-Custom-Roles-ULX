--Terrortown settings module for ULX GUI
--Defines ttt cvar limits and ttt specific settings for the ttt gamemode.

local terrortown_settings = xlib.makepanel { parent = xgui.null }

xlib.makelabel { x = 5, y = 5, w = 600, wordwrap = true, label = "Trouble in Terrorist Town ULX Commands XGUI module originally created by: Bender180", parent = terrortown_settings }
xlib.makelabel { x = 2, y = 345, w = 600, wordwrap = true, label = "The settings above DO NOT SAVE when the server changes maps, is restarted or crashes. They are for easy access only", parent = terrortown_settings }

xlib.makelabel { x = 5, y = 230, w = 160, wordwrap = true, label = "Note to sever owners: to restrict this panel allow or deny permission to xgui_gmsettings.", parent = terrortown_settings }
xlib.makelabel { x = 5, y = 275, w = 160, wordwrap = true, label = "All settings listed are explained here: https://custom-roles-for-ttt .github.io/TTT-Custom-Roles", parent = terrortown_settings }
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
    local shop_roles = {}

    if GetConVar("ttt_shop_for_all"):GetBool() then
        for role = 0, ROLE_MAX do
            shop_roles[role] = true
        end
    else
        shop_roles = table.Copy(SHOP_ROLES)
        for role, _ in pairs(SHOP_ROLES) do
            if ROLE_BLOCK_SHOP_CONVARS[role] then
                shop_roles[role] = false
            end
        end
    end

    return shop_roles
end

local function GetCreditRoles()
    local shop_roles = GetShopRoles()
    -- Add any roles that have credits but don't have a shop to the full list
    local shopless_credit_roles = table.ToLookup(table.UnionedKeys(CAN_LOOT_CREDITS_ROLES, ROLE_STARTING_CREDITS))
    return table.ToLookup(table.UnionedKeys(shop_roles, shopless_credit_roles))
end

local function SortRolesByName(roles)
    table.sort(roles, function(a, b) return ROLE_STRINGS[a] < ROLE_STRINGS[b] end)
end

local function GetSortedTeamRoles(role_team, exclude)
    local roles = GetTeamRoles(role_team, exclude)
    SortRolesByName(roles)
    return roles
end

local function GetAllSortedRoles()
    local roles = {}
    for role = 0, ROLE_MAX do
        table.insert(roles, role)
    end
    SortRolesByName(roles)
    return roles
end

local function AddToList(element, list, leftIndent)
    leftIndent = leftIndent or 0

    element:Dock(TOP)
    element:DockMargin(leftIndent, 5, 0, 0)
    list:Add(element)
end

local function AddRoundStructureModule()
    local rspnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local rspapclp = vgui.Create("DCollapsibleCategory", rspnl)
    rspapclp:SetLabel("Preparation and Post-Round")
    rspapclp:SetExpanded(true)
    rspnl:Add(rspapclp)

    local rspaplst = vgui.Create("DListLayout", rspapclp)
    rspapclp:SetContents(rspaplst)
    rspaplst:DockMargin(5, 0, 0, 0)
    rspapclp:SetPaintBackground(true)

    local prept = xlib.makeslider { label = "ttt_preptime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_preptime_seconds", parent = rspaplst }
    AddToList(prept, rspaplst)

    local fprept = xlib.makeslider { label = "ttt_firstpreptime (def. 60)", min = 1, max = 120, repconvar = "rep_ttt_firstpreptime", parent = rspaplst }
    AddToList(fprept, rspaplst)

    local pstt = xlib.makeslider { label = "ttt_posttime_seconds (def. 30)", min = 1, max = 120, repconvar = "rep_ttt_posttime_seconds", parent = rspaplst }
    AddToList(pstt, rspaplst)

    --Round Length
    local rsrlclp = vgui.Create("DCollapsibleCategory", rspnl)
    rsrlclp:SetLabel("Round Length")
    rsrlclp:SetExpanded(false)
    rspnl:Add(rsrlclp)

    local rsrllst = vgui.Create("DListLayout", rsrlclp)
    rsrlclp:SetContents(rsrllst)
    rsrllst:DockMargin(5, 0, 0, 0)
    rsrlclp:SetPaintBackground(true)

    local hstmd = xlib.makecheckbox { label = "ttt_haste (def. 1)", repconvar = "rep_ttt_haste", parent = rsrllst }
    AddToList(hstmd, rsrllst)

    local hstsm = xlib.makeslider { label = "ttt_haste_starting_minutes (def. 5)", min = 1, max = 60, repconvar = "rep_ttt_haste_starting_minutes", parent = rsrllst }
    AddToList(hstsm, rsrllst)

    local hstmpd = xlib.makeslider { label = "ttt_haste_minutes_per_death (def. 0.5)", min = 0.1, max = 9, decimal = 2, repconvar = "rep_ttt_haste_minutes_per_death", parent = rsrllst }
    AddToList(hstmpd, rsrllst)

    local rtm = xlib.makeslider { label = "ttt_roundtime_minutes (def. 10)", min = 1, max = 60, repconvar = "rep_ttt_roundtime_minutes", parent = rsrllst }
    AddToList(rtm, rsrllst)

    local tlwd = xlib.makecheckbox { label = "ttt_roundtime_win_draw (def. 0)", repconvar = "rep_ttt_roundtime_win_draw", parent = rsrllst }
    AddToList(tlwd, rsrllst)

    --Map Switching and Voting
    local msavclp = vgui.Create("DCollapsibleCategory", rspnl)
    msavclp:SetLabel("Map Switching and Voting")
    msavclp:SetExpanded(false)
    rspnl:Add(msavclp)

    local msavlst = vgui.Create("DListLayout", msavclp)
    msavclp:SetContents(msavlst)
    msavlst:DockMargin(5, 0, 0, 0)
    msavclp:SetPaintBackground(true)

    local rndl = xlib.makeslider { label = "ttt_round_limit (def. 6)", min = 1, max = 100, repconvar = "rep_ttt_round_limit", parent = msavlst }
    AddToList(rndl, msavlst)

    local rndtlm = xlib.makeslider { label = "ttt_time_limit_minutes (def. 75)", min = 1, max = 150, repconvar = "rep_ttt_time_limit_minutes", parent = msavlst }
    AddToList(rndtlm, msavlst)

    xgui.hookEvent("onProcessModules", nil, rspnl.processModules)
    xgui.addSubModule("Round Structure", rspnl, nil, "terrortown_settings")
end

local function AddTraitorAndDetectiveSettings(gppnl)
    local gptdcclp = vgui.Create("DCollapsibleCategory", gppnl)
    gptdcclp:SetLabel("Traitor and Detective Settings")
    gptdcclp:SetExpanded(false)
    gppnl:Add(gptdcclp)

    local gptdlst = vgui.Create("DListLayout", gptdcclp)
    gptdcclp:SetContents(gptdlst)
    gptdlst:DockMargin(5, 0, 0, 0)
    gptdcclp:SetPaintBackground(true)

    local tpercet = xlib.makeslider { label = "ttt_traitor_pct (def. 0.25)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_traitor_pct", parent = gptdlst }
    AddToList(tpercet, gptdlst)

    local tmax = xlib.makeslider { label = "ttt_traitor_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_traitor_max", parent = gptdlst }
    AddToList(tmax, gptdlst)

    local dpercet = xlib.makeslider { label = "ttt_detective_pct (def. 0.13)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_detective_pct", parent = gptdlst }
    AddToList(dpercet, gptdlst)

    local dmax = xlib.makeslider { label = "ttt_detective_max (def. 32)", min = 1, max = 80, repconvar = "rep_ttt_detective_max", parent = gptdlst }
    AddToList(dmax, gptdlst)

    local dmp = xlib.makeslider { label = "ttt_detective_min_players (def. 10)", min = 1, max = 50, repconvar = "rep_ttt_detective_min_players", parent = gptdlst }
    AddToList(dmp, gptdlst)

    local dkm = xlib.makeslider { label = "ttt_detective_karma_min (def. 600)", min = 1, max = 1000, repconvar = "rep_ttt_detective_karma_min", parent = gptdlst }
    AddToList(dkm, gptdlst)
end

local function AddDefaultRoleSettings(lst, role_list)
    for _, r in pairs(role_list) do
        if not ROLE_BLOCK_SPAWN_CONVARS[r] then
            local role_string = ROLE_STRINGS_RAW[r]
            local enabled = xlib.makecheckbox { label = "ttt_" .. role_string .. "_enabled (def. 0)", repconvar = "rep_ttt_" .. role_string .. "_enabled", parent = lst }
            AddToList(enabled, lst)

            local spawn_weight = xlib.makeslider { label = "ttt_" .. role_string .. "_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_" .. role_string .. "_spawn_weight", parent = lst }
            AddToList(spawn_weight, lst)

            local min_players = xlib.makeslider { label = "ttt_" .. role_string .. "_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_" .. role_string .. "_min_players", parent = lst }
            AddToList(min_players, lst)
        end
    end
end

local function AddSpecialistTraitorSettings(gppnl)
    local traitor_roles = table.ExcludedKeys(TRAITOR_ROLES, {ROLE_TRAITOR})
    SortRolesByName(traitor_roles)
    local spawnable_role_count = 0
    for _, role in pairs(traitor_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end

    local sptraclp = vgui.Create("DCollapsibleCategory", gppnl)
    sptraclp:SetLabel("Specialist Traitor Settings")
    sptraclp:SetExpanded(false)
    gppnl:Add(sptraclp)

    local sptralst = vgui.Create("DListLayout", sptraclp)
    sptraclp:SetContents(sptralst)
    sptralst:DockMargin(5, 0, 0, 0)
    sptraclp:SetPaintBackground(true)

    local stpercet = xlib.makeslider { label = "ttt_special_traitor_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_pct", parent = sptralst }
    AddToList(stpercet, sptralst)

    local stchance = xlib.makeslider { label = "ttt_special_traitor_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_chance", parent = sptralst }
    AddToList(stchance, sptralst)

    AddDefaultRoleSettings(sptralst, traitor_roles)
end

local function AddSpecialistDetectiveSettings(gppnl)
    local det_roles = table.ExcludedKeys(DETECTIVE_ROLES, {ROLE_DETECTIVE})
    SortRolesByName(det_roles)
    local spawnable_role_count = 0
    for _, role in pairs(det_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end

    local spdetclp = vgui.Create("DCollapsibleCategory", gppnl)
    spdetclp:SetLabel("Specialist Detective Settings")
    spdetclp:SetExpanded(false)
    gppnl:Add(spdetclp)

    local spdetlst = vgui.Create("DListLayout", spdetclp)
    spdetclp:SetContents(spdetlst)
    spdetlst:DockMargin(5, 0, 0, 0)
    spdetclp:SetPaintBackground(true)

    local sdpercet = xlib.makeslider { label = "ttt_special_detective_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_pct", parent = spdetlst }
    AddToList(sdpercet, spdetlst)

    local sdchance = xlib.makeslider { label = "ttt_special_detective_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_detective_chance", parent = spdetlst }
    AddToList(sdchance, spdetlst)

    AddDefaultRoleSettings(spdetlst, det_roles)
end

local function AddSpecialistInnocentSettings(gppnl)
    local inno_roles = table.ExcludedKeys(INNOCENT_ROLES, table.Add({ROLE_INNOCENT}, GetTeamRoles(DETECTIVE_ROLES)))
    SortRolesByName(inno_roles)
    local spawnable_role_count = 0
    for _, role in pairs(inno_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end

    local spinnclp = vgui.Create("DCollapsibleCategory", gppnl)
    spinnclp:SetLabel("Specialist Innocent Settings")
    spinnclp:SetExpanded(false)
    gppnl:Add(spinnclp)

    local spinnlst = vgui.Create("DListLayout", spinnclp)
    spinnclp:SetContents(spinnlst)
    spinnlst:DockMargin(5, 0, 0, 0)
    spinnclp:SetPaintBackground(true)

    local sipercet = xlib.makeslider { label = "ttt_special_innocent_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_pct", parent = spinnlst }
    AddToList(sipercet, spinnlst)

    local sichance = xlib.makeslider { label = "ttt_special_innocent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_chance", parent = spinnlst }
    AddToList(sichance, spinnlst)

    AddDefaultRoleSettings(spinnlst, inno_roles)
end

local function AddIndependentRoleSettings(gppnl)
    local indep_roles = GetSortedTeamRoles(INDEPENDENT_ROLES)
    local jester_roles = GetSortedTeamRoles(JESTER_ROLES)
    local spawnable_role_count = 0
    for _, role in pairs(indep_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end
    for _, role in pairs(jester_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end

    local indclp = vgui.Create("DCollapsibleCategory", gppnl)
    indclp:SetLabel("Independent Role Settings")
    indclp:SetExpanded(false)
    gppnl:Add(indclp)

    local indlst = vgui.Create("DListLayout", indclp)
    indclp:SetContents(indlst)
    indlst:DockMargin(5, 0, 0, 0)
    indclp:SetPaintBackground(true)

    local indjeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = indlst }
    AddToList(indjeslbl, indlst)

    local singlejind = xlib.makecheckbox { label = "ttt_single_jester_independent (def. 1)", repconvar = "rep_ttt_single_jester_independent", parent = indlst }
    AddToList(singlejind, indlst)

    local singlejindmp = xlib.makeslider { label = "ttt_single_jester_independent_max_players (def. 0)", min = 0, max = 32, repconvar = "rep_ttt_single_jester_independent_max_players", parent = indlst }
    AddToList(singlejindmp, indlst)

    local multjind = xlib.makecheckbox { label = "ttt_multiple_jesters_independents (def. 0)", repconvar = "rep_ttt_multiple_jesters_independents", parent = indlst }
    AddToList(multjind, indlst)

    local jindpct = xlib.makeslider { label = "ttt_jester_independent_pct (def. 0.13)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_independent_pct", parent = indlst }
    AddToList(jindpct, indlst)

    local jindmax = xlib.makeslider { label = "ttt_jester_independent_max (def. 2)", min = 0, max = 16, repconvar = "rep_ttt_jester_independent_max", parent = indlst }
    AddToList(jindmax, indlst)

    local jindchance = xlib.makeslider { label = "ttt_jester_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_independent_chance", parent = indlst }
    AddToList(jindchance, indlst)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Independent settings:", parent = indlst }
    AddToList(indlbl, indlst)

    local indchance = xlib.makeslider { label = "ttt_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_independent_chance", parent = indlst }
    AddToList(indchance, indlst)

    AddDefaultRoleSettings(indlst, indep_roles)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jester settings:", parent = indlst }
    AddToList(jeslbl, indlst)

    local jeschance = xlib.makeslider { label = "ttt_jester_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_jester_chance", parent = indlst }
    AddToList(jeschance, indlst)

    AddDefaultRoleSettings(indlst, jester_roles)
end

local function AddMonsterSettings(gppnl)
    local monster_roles = GetSortedTeamRoles(MONSTER_ROLES)
    local spawnable_role_count = 0
    for _, role in pairs(monster_roles) do
        if not ROLE_BLOCK_SPAWN_CONVARS[role] then
            spawnable_role_count = spawnable_role_count + 1
        end
    end

    local monclp = vgui.Create("DCollapsibleCategory", gppnl)
    monclp:SetLabel("Monster Role Settings")
    monclp:SetExpanded(false)
    gppnl:Add(monclp)

    local monlst = vgui.Create("DListLayout", monclp)
    monclp:SetContents(monlst)
    monlst:DockMargin(5, 0, 0, 0)
    monclp:SetPaintBackground(true)

    local monmax = xlib.makeslider { label = "ttt_monster_max (def. 1)", min = 0, max = 80, repconvar = "rep_ttt_monster_max", parent = monlst }
    AddToList(monmax, monlst)

    local monpercet = xlib.makeslider { label = "ttt_monster_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_pct", parent = monlst }
    AddToList(monpercet, monlst)

    local monchance = xlib.makeslider { label = "ttt_monster_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_chance", parent = monlst }
    AddToList(monchance, monlst)

    AddDefaultRoleSettings(monlst, monster_roles)
end

local function AddGroupedRoleSettings(gppnl)
    local grpclp = vgui.Create("DCollapsibleCategory", gppnl)
    grpclp:SetLabel("Grouped Role Settings")
    grpclp:SetExpanded(false)
    gppnl:Add(grpclp)

    local grplst = vgui.Create("DListLayout", grpclp)
    grpclp:SetContents(grplst)
    grplst:DockMargin(5, 0, 0, 0)
    grpclp:SetPaintBackground(true)

    local enabled = xlib.makecheckbox { label = "ttt_twins_enabled (def. 0)", repconvar = "rep_ttt_twins_enabled", parent = grplst }
    AddToList(enabled, grplst)

    local spawn_chance = xlib.makeslider { label = "ttt_twins_spawn_chance (def. 0.1)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_twins_spawn_chance", parent = grplst }
    AddToList(spawn_chance, grplst)

    local min_players = xlib.makeslider { label = "ttt_twins_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_twins_min_players", parent = grplst }
    AddToList(min_players, grplst)
end

local function AddRoleHealthSettings(gppnl)
    local modifiable_health_role_count = 0
    for role = 0, ROLE_MAX do
        if not ROLE_BLOCK_HEALTH_CONVARS[role] then
            modifiable_health_role_count = modifiable_health_role_count + 1
        end
    end

    local rolehealthclp = vgui.Create("DCollapsibleCategory", gppnl)
    rolehealthclp:SetLabel("Role Health Settings")
    rolehealthclp:SetExpanded(false)
    gppnl:Add(rolehealthclp)

    local rolehealthlst = vgui.Create("DListLayout", rolehealthclp)
    rolehealthclp:SetContents(rolehealthlst)
    rolehealthlst:DockMargin(5, 0, 0, 0)
    rolehealthclp:SetPaintBackground(true)

    for _, role in ipairs(GetAllSortedRoles()) do
        if not ROLE_BLOCK_HEALTH_CONVARS[role] then
            local rolestring = ROLE_STRINGS_RAW[role]
            local convar = "ttt_" .. rolestring .. "_starting_health"
            local default = GetReplicatedConVarDefault(convar, "100")
            local starthealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = -1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
            AddToList(starthealth, rolehealthlst)

            -- Save the control so it can be updated later
            if missing_cvars[convar] then
                missing_cvars[convar] = starthealth
            end

            convar = "ttt_" .. rolestring .. "_max_health"
            default = GetReplicatedConVarDefault(convar, "100")
            local maxhealth = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = -1, max = 200, repconvar = "rep_" .. convar, parent = rolehealthlst }
            AddToList(maxhealth, rolehealthlst)

            -- Save the control so it can be updated later
            if missing_cvars[convar] then
                missing_cvars[convar] = maxhealth
            end
        end
    end
end

local function GetRoleConVars(team_list)
    local role_cvars = {}
    for _, r in ipairs(team_list) do
        if not ROLE_CONVARS[r] then continue end

        local valid_convars = {}
        for _, cvar in ipairs(ROLE_CONVARS[r]) do
            if cvar.type == ROLE_CONVAR_TYPE_NUM then
                table.insert(valid_convars, cvar)
            elseif cvar.type == ROLE_CONVAR_TYPE_BOOL then
                table.insert(valid_convars, cvar)
            elseif cvar.type == ROLE_CONVAR_TYPE_TEXT then
                table.insert(valid_convars, cvar)
            elseif cvar.type == ROLE_CONVAR_TYPE_DROPDOWN then
                table.insert(valid_convars, cvar)
            else
                ErrorNoHalt("WARNING: Role (" .. r .. ") tried to register a convar with an unknown type: " .. tostring(cvar.type))
            end
        end

        table.sort(valid_convars, function(a, b) return a.cvar < b.cvar end)
        role_cvars[r] = valid_convars
    end
    return role_cvars
end

local function AddRoleProperties(role, role_cvars, list)
    local rolestring = ROLE_STRINGS[role]
    local label = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = rolestring .. " settings:", parent = list }
    AddToList(label, list)

    for _, c in ipairs(role_cvars) do
        local name = c.cvar
        if c.type == ROLE_CONVAR_TYPE_TEXT then
            local textlabel = xlib.makelabel { label = name, parent = list }
            AddToList(textlabel, list)
            local textbox = xlib.maketextbox { repconvar = "rep_" .. name, enableinput = true, parent = list }
            AddToList(textbox, list)
        elseif c.type == ROLE_CONVAR_TYPE_DROPDOWN then
            local default = GetReplicatedConVarDefault(name, "0")
            local combolabel = xlib.makelabel { label = name .. " (def. " .. default .. ")", parent = list }
            AddToList(combolabel, list)
            local combobox = xlib.makecombobox { repconvar = "rep_" .. name, isNumberConvar = c.isNumeric, numOffset = c.numericOffset, choices = c.choices , parent = list }
            AddToList(combobox, list)

            -- Save the text label so the default value can be updated later
            if missing_cvars[name] then
                missing_cvars[name] = combolabel
            end
        else
            local default = GetReplicatedConVarDefault(name, "0")
            local control
            if c.type == ROLE_CONVAR_TYPE_NUM then
                local min = GetReplicatedConVarMin(name, 0)
                local max = GetReplicatedConVarMax(name, 1)
                local decimal = c.decimal or 0

                control = xlib.makeslider { label = name .. " (def. " .. default .. ")", min = min, max = max, decimal = decimal, repconvar = "rep_" .. name, parent = list }
            elseif c.type == ROLE_CONVAR_TYPE_BOOL then
                control = xlib.makecheckbox { label = name .. " (def. " .. default .. ")", repconvar = "rep_" .. name, parent = list }
            end

            AddToList(control, list)

            -- Save the control so it can be updated later
            if missing_cvars[name] then
                missing_cvars[name] = control
            end
        end
    end
end

local function AddTraitorProperties(gppnl)
    local traitor_roles = GetSortedTeamRoles(TRAITOR_ROLES)
    local role_cvars = GetRoleConVars(traitor_roles)

    local trapropclp = vgui.Create("DCollapsibleCategory", gppnl)
    trapropclp:SetLabel("Traitor Properties")
    trapropclp:SetExpanded(false)
    gppnl:Add(trapropclp)

    local traproplst = vgui.Create("DListLayout", trapropclp)
    trapropclp:SetContents(traproplst)
    traproplst:DockMargin(5, 0, 0, 0)
    trapropclp:SetPaintBackground(true)

    local tralbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = traproplst }
    AddToList(tralbl, traproplst)

    local travis = xlib.makecheckbox { label = "ttt_traitors_vision_enabled (def. 0)", repconvar = "rep_ttt_traitors_vision_enabled", parent = traproplst }
    AddToList(travis, traproplst)

    for _, r in ipairs(traitor_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], traproplst)
        end
    end
end

local function AddDetectiveProperties(gppnl)
    local detective_roles = GetSortedTeamRoles(DETECTIVE_ROLES)
    local role_cvars = GetRoleConVars(detective_roles)

    local detpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    detpropclp:SetLabel("Detective Properties")
    detpropclp:SetExpanded(false)
    gppnl:Add(detpropclp)

    local detproplst = vgui.Create("DListLayout", detpropclp)
    detpropclp:SetContents(detproplst)
    detproplst:DockMargin(5, 0, 0, 0)
    detpropclp:SetPaintBackground(true)

    local detlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = detproplst }
    AddToList(detlbl, detproplst)

    local detsch = xlib.makecheckbox { label = "ttt_detectives_search_only (def. 1)", repconvar = "rep_ttt_detectives_search_only", parent = detproplst }
    AddToList(detsch, detproplst)

    for _, dataType in ipairs(CORPSE_ICON_TYPES) do
        local detschtype = xlib.makecheckbox { label = "ttt_detectives_search_only_" .. dataType .. " (def. 0)", repconvar = "rep_ttt_detectives_search_only_" .. dataType, parent = detproplst }
        AddToList(detschtype, detproplst)
    end

    local detcce = xlib.makeslider { label = "ttt_detectives_corpse_call_expiration (def. 45)", min = 0, max = 180, repconvar = "rep_ttt_detectives_corpse_call_expiration", parent = detproplst }
    AddToList(detcce, detproplst)

    local detdlo = xlib.makecheckbox { label = "ttt_detectives_disable_looting (def. 0)", repconvar = "rep_ttt_detectives_disable_looting", parent = detproplst }
    AddToList(detdlo, detproplst)

    local dethsmlbl = xlib.makelabel { label = "ttt_detectives_hide_special_mode (def. 0)", parent = detproplst }
    AddToList(dethsmlbl, detproplst)
    local dethsmcb = xlib.makecombobox { repconvar = "rep_ttt_detectives_hide_special_mode", isNumberConvar = true, choices = { "Show role to everyone", "Show ? icon to everyone", "Show ? icon to everyone but player" }, parent = detproplst }
    AddToList(dethsmcb, detproplst)

    local detge = xlib.makecheckbox { label = "ttt_detectives_glow_enabled (def. 0)", repconvar = "rep_ttt_detectives_glow_enabled", parent = detproplst }
    AddToList(detge, detproplst)

    local detsdal = xlib.makecheckbox { label = "ttt_special_detectives_armor_loadout (def. 1)", repconvar = "rep_ttt_special_detectives_armor_loadout", parent = detproplst }
    AddToList(detsdal, detproplst)

    local prsrch = xlib.makecheckbox { label = "ttt_all_search_postround (def. 1)", repconvar = "rep_ttt_all_search_postround", parent = detproplst }
    AddToList(prsrch, detproplst)

    local bnsrch = xlib.makecheckbox { label = "ttt_all_search_binoc (def. 0)", repconvar = "rep_ttt_all_search_binoc", parent = detproplst }
    AddToList(bnsrch, detproplst)

    local dnasrch = xlib.makecheckbox { label = "ttt_all_search_dnascanner (def. 0)", repconvar = "rep_ttt_all_search_dnascanner", parent = detproplst }
    AddToList(dnasrch, detproplst)

    for _, r in ipairs(detective_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], detproplst)
        end
    end
end

local function AddInnocentProperties(gppnl)
    local innocent_roles = GetSortedTeamRoles(INNOCENT_ROLES, DETECTIVE_ROLES)
    local role_cvars = GetRoleConVars(innocent_roles)

    local innpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    innpropclp:SetLabel("Innocent Properties")
    innpropclp:SetExpanded(false)
    gppnl:Add(innpropclp)

    local innproplst = vgui.Create("DListLayout", innpropclp)
    innpropclp:SetContents(innproplst)
    innproplst:DockMargin(5, 0, 0, 0)
    innpropclp:SetPaintBackground(true)

    for _, r in ipairs(innocent_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], innproplst)
        end
    end
end

local function AddJesterRoleProperties(gppnl)
    local jester_roles = GetSortedTeamRoles(JESTER_ROLES)
    local role_cvars = GetRoleConVars(jester_roles)

    local jespropclp = vgui.Create("DCollapsibleCategory", gppnl)
    jespropclp:SetLabel("Jester Properties")
    jespropclp:SetExpanded(false)
    gppnl:Add(jespropclp)

    local jesproplst = vgui.Create("DListLayout", jespropclp)
    jespropclp:SetContents(jesproplst)
    jesproplst:DockMargin(5, 0, 0, 0)
    jespropclp:SetPaintBackground(true)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = jesproplst }
    AddToList(jeslbl, jesproplst)

    local jestester = xlib.makecheckbox { label = "ttt_jesters_trigger_traitor_testers (def. 1)", repconvar = "rep_ttt_jesters_trigger_traitor_testers", parent = jesproplst }
    AddToList(jestester, jesproplst)

    local jesvtt = xlib.makecheckbox { label = "ttt_jesters_visible_to_traitors (def. 1)", repconvar = "rep_ttt_jesters_visible_to_traitors", parent = jesproplst }
    AddToList(jesvtt, jesproplst)

    local jesvtm = xlib.makecheckbox { label = "ttt_jesters_visible_to_monsters (def. 1)", repconvar = "rep_ttt_jesters_visible_to_monsters", parent = jesproplst }
    AddToList(jesvtm, jesproplst)

    for _, r in ipairs(jester_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], jesproplst)
        end
    end
end

local function AddIndependentRoleProperties(gppnl)
    local independent_roles = GetSortedTeamRoles(INDEPENDENT_ROLES)
    local role_cvars = GetRoleConVars(independent_roles)

    local indpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    indpropclp:SetLabel("Independent Properties")
    indpropclp:SetExpanded(false)
    gppnl:Add(indpropclp)

    local indproplst = vgui.Create("DListLayout", indpropclp)
    indpropclp:SetContents(indproplst)
    indproplst:DockMargin(5, 0, 0, 0)
    indpropclp:SetPaintBackground(true)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Shared settings:", parent = indproplst }
    AddToList(indlbl, indproplst)

    local indtes = xlib.makecheckbox { label = "ttt_independents_trigger_traitor_testers (def. 0)", repconvar = "rep_ttt_independents_trigger_traitor_testers", parent = indproplst }
    AddToList(indtes, indproplst)

    for _, r in ipairs(independent_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], indproplst)
        end
    end
end

local function AddMonsterRoleProperties(gppnl)
    local monster_roles = GetSortedTeamRoles(MONSTER_ROLES)
    local role_cvars = GetRoleConVars(monster_roles)

    local monpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    monpropclp:SetLabel("Monster Properties")
    monpropclp:SetExpanded(false)
    gppnl:Add(monpropclp)

    local monproplst = vgui.Create("DListLayout", monpropclp)
    monpropclp:SetContents(monproplst)
    monproplst:DockMargin(5, 0, 0, 0)
    monpropclp:SetPaintBackground(true)

    for _, r in ipairs(monster_roles) do
        if role_cvars[r] then
            AddRoleProperties(r, role_cvars[r], monproplst)
        end
    end
end

local function AddCustomRoleProperties(gppnl)
    local crpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    crpropclp:SetLabel("Custom Roles Properties")
    crpropclp:SetExpanded(false)
    gppnl:Add(crpropclp)

    local crproplst = vgui.Create("DListLayout", crpropclp)
    crpropclp:SetContents(crproplst)
    crproplst:DockMargin(5, 0, 0, 0)
    crpropclp:SetPaintBackground(true)

    local rolePacksButton = xlib.makebutton{ w = 150, label = "Open Role Packs Config", parent = crproplst }
    rolePacksButton.DoClick = function()
        RunConsoleCommand("ttt_rolepacks")
    end
    AddToList(rolePacksButton, crproplst)

    local roleBlocksButton = xlib.makebutton{ w = 150, label = "Open Role Blocks Config", parent = crproplst }
    roleBlocksButton.DoClick = function()
        RunConsoleCommand("ttt_roleblocks")
    end
    AddToList(roleBlocksButton, crproplst)

    local depimppad = xlib.makecheckbox { label = "ttt_deputy_impersonator_promote_any_death (def. 0)", repconvar = "rep_ttt_deputy_impersonator_promote_any_death", parent = crproplst }
    AddToList(depimppad, crproplst)

    local depimpsp = xlib.makecheckbox { label = "ttt_deputy_impersonator_start_promoted (def. 0)", repconvar = "rep_ttt_deputy_impersonator_start_promoted", parent = crproplst }
    AddToList(depimpsp, crproplst)
end

local function AddShopRandomizationSettings(lst, role_list)
    for _, r in pairs(role_list) do
        local rolestring = ROLE_STRINGS_RAW[r]
        local percent = xlib.makeslider { label = "ttt_" .. rolestring .. "_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_" .. rolestring .. "_shop_random_percent", parent = lst }
        AddToList(percent, lst)

        local enabled = xlib.makecheckbox { label = "ttt_" .. rolestring .. "_shop_random_enabled (def. 0)", repconvar = "rep_ttt_" .. rolestring .. "_shop_random_enabled", parent = lst }
        AddToList(enabled, lst)
    end
end

local function HasShopSync(role)
    return (TRAITOR_ROLES[role] and role ~= ROLE_TRAITOR) or (DETECTIVE_ROLES[role] and role ~= ROLE_DETECTIVE) or ROLE_HAS_SHOP_SYNC[role]
end

local function GetShopSyncCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        if HasShopSync(r) then
            table.insert(cvar_list, "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_sync")
        end
    end
    return cvar_list
end

local function AddShopSyncSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "-1")
        local synclbl = xlib.makelabel { label = c .. " (def. " .. default .. ")", parent = lst }
        AddToList(synclbl, lst)
        local synccb = xlib.makecombobox { repconvar = "rep_" .. c, isNumberConvar = true, numOffset = 2, choices = { "Use default", "Disable", "Enable" }, parent = lst }
        AddToList(synccb, lst)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = sync
        end
    end
end

local function GetShopModeCvars(role_list)
    local cvar_list = {}
    for _, r in pairs(role_list) do
        -- Roles don't get both sync and mode
        if (INDEPENDENT_ROLES[r] or DELAYED_SHOP_ROLES[r] or ROLE_HAS_SHOP_MODE[r]) and not HasShopSync(r) then
            table.insert(cvar_list,  "ttt_" .. ROLE_STRINGS_RAW[r] .. "_shop_mode")
        end
    end
    return cvar_list
end

local function AddShopModeSettings(lst, cvar_list)
    for _, c in pairs(cvar_list) do
        local default = GetReplicatedConVarDefault(c, "0")
        local modelbl = xlib.makelabel { label = c .. " (def. " .. default .. ")", parent = lst }
        AddToList(modelbl, lst)
        local modecb = xlib.makecombobox { repconvar = "rep_" .. c, isNumberConvar = true, choices = { "Disable", "Union of Detective and Traitor", "Intersect of Detective and Traitor", "Detective", "Traitor" }, parent = lst }
        AddToList(modecb, lst)

        -- Save the label so the default can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = modelbl
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
        AddToList(active, lst)

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
        AddToList(delay, lst)

        -- Save the control so it can be updated later
        if missing_cvars[c] then
            missing_cvars[c] = delay
        end
    end
end

local function AddTeamShop(label, roles, shop_roles, parent)
    local lbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = label, parent = parent }
    AddToList(lbl, parent)

    local shops = table.IntersectedKeys(roles, shop_roles)
    SortRolesByName(shops)
    AddShopRandomizationSettings(parent, shops)
    AddShopSyncSettings(parent, GetShopSyncCvars(shops))
    AddShopModeSettings(parent, GetShopModeCvars(shops))
    AddShopActiveSettings(parent, GetShopActiveCvars(shops))
    AddShopDelaySettings(parent, GetShopDelayCvars(shops))
end

local function AddRoleShop(gppnl)
    local rspnl = vgui.Create("DCollapsibleCategory", gppnl)
    rspnl:SetLabel("Role Shop")
    rspnl:SetExpanded(false)
    gppnl:Add(rspnl)

    local rslst = vgui.Create("DListLayout", rspnl)
    rspnl:SetContents(rslst)
    rslst:DockMargin(5, 0, 0, 0)
    rspnl:SetPaintBackground(true)

    local roleWeaponsButton = xlib.makebutton{ w = 150, label = "Open Role Weapons Config", parent = rslst }
    roleWeaponsButton.DoClick = function()
        RunConsoleCommand("ttt_roleweapons")
    end
    AddToList(roleWeaponsButton, rslst)

    local rsfa = xlib.makecheckbox { label = "ttt_shop_for_all (def. 0)", repconvar = "rep_ttt_shop_for_all", parent = rslst }
    AddToList(rsfa, rslst)

    local rsp = xlib.makeslider { label = "ttt_shop_random_percent (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_shop_random_percent", parent = rslst }
    AddToList(rsp, rslst)

    local rspos = xlib.makecheckbox { label = "ttt_shop_random_position (def. 0)", repconvar = "rep_ttt_shop_random_position", parent = rslst }
    AddToList(rspos, rslst)

    local rsdeft = xlib.makecheckbox { label = "ttt_traitors_shop_sync_default (def. 0)", repconvar = "ttt_traitors_shop_sync_default", parent = rslst }
    AddToList(rsdeft, rslst)

    local rsdefd = xlib.makecheckbox { label = "ttt_detectives_shop_sync_default (def. 0)", repconvar = "ttt_detectives_shop_sync_default", parent = rslst }
    AddToList(rsdefd, rslst)

    local shop_roles = GetShopRoles()
    AddTeamShop("Traitors:", TRAITOR_ROLES, shop_roles, rslst)
    AddTeamShop("Innocents:", INNOCENT_ROLES, shop_roles, rslst)
    AddTeamShop("Jesters:", JESTER_ROLES, shop_roles, rslst)
    AddTeamShop("Independents:", INDEPENDENT_ROLES, shop_roles, rslst)
    AddTeamShop("Monsters:", MONSTER_ROLES, shop_roles, rslst)
end

local function AddDna(gppnl)
    local gpdnaclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpdnaclp:SetLabel("DNA")
    gpdnaclp:SetExpanded(false)
    gppnl:Add(gpdnaclp)

    local gpdnalst = vgui.Create("DListLayout", gpdnaclp)
    gpdnaclp:SetContents(gpdnalst)
    gpdnalst:DockMargin(5, 0, 0, 0)
    gpdnaclp:SetPaintBackground(true)

    local dnarange = xlib.makeslider { label = "ttt_killer_dna_range (def. 550)", min = 100, max = 1000, repconvar = "rep_ttt_killer_dna_range", parent = gpdnalst }
    AddToList(dnarange, gpdnalst)

    local dnakbt = xlib.makeslider { label = "ttt_killer_dna_basetime (def. 100)", min = 10, max = 200, repconvar = "rep_ttt_killer_dna_basetime", parent = gpdnalst }
    AddToList(dnakbt, gpdnalst)

    local dnasdl = xlib.makecheckbox { label = "ttt_dna_scan_detectives_loadout (def. 0)", repconvar = "rep_ttt_dna_scan_detectives_loadout", parent = gpdnalst }
    AddToList(dnasdl, gpdnalst)

    local dnasid = xlib.makecheckbox { label = "ttt_dna_scan_on_dialog (def. 1)", repconvar = "rep_ttt_dna_scan_on_dialog", parent = gpdnalst }
    AddToList(dnasid, gpdnalst)

    local dnasodod = xlib.makecheckbox { label = "ttt_dna_scan_only_drop_on_death (def. 0)", repconvar = "rep_ttt_dna_scan_only_drop_on_death", parent = gpdnalst }
    AddToList(dnasodod, gpdnalst)
end

local function AddDevices(gppnl)
    local gpdvcclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpdvcclp:SetLabel("Devices")
    gpdvcclp:SetExpanded(false)
    gppnl:Add(gpdvcclp)

    local gpdvclst = vgui.Create("DListLayout", gpdvcclp)
    gpdvcclp:SetContents(gpdvclst)
    gpdvclst:DockMargin(5, 0, 0, 0)
    gpdvcclp:SetPaintBackground(true)

    local dvcdoh = xlib.makecheckbox { label = "ttt_damage_own_healthstation (def. 0)", repconvar = "rep_ttt_damage_own_healthstation", parent = gpdvclst }
    AddToList(dvcdoh, gpdvclst)

    local dvcdob = xlib.makecheckbox { label = "ttt_damage_own_bombstation (def. 0)", repconvar = "rep_ttt_damage_own_bombstation", parent = gpdvclst }
    AddToList(dvcdob, gpdvclst)

    local dvcbeod = xlib.makecheckbox { label = "ttt_bombstation_explode_on_destroy (def. 1)", repconvar = "rep_ttt_bombstation_explode_on_destroy", parent = gpdvclst }
    AddToList(dvcbeod, gpdvclst)
end

local function AddVoiceChat(gppnl)
    local gpvcbclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpvcbclp:SetLabel("Voice Chat Battery")
    gpvcbclp:SetExpanded(false)
    gppnl:Add(gpvcbclp)

    local gpvcblst = vgui.Create("DListLayout", gpvcbclp)
    gpvcbclp:SetContents(gpvcblst)
    gpvcblst:DockMargin(5, 0, 0, 0)
    gpvcbclp:SetPaintBackground(true)

    local gpevd = xlib.makecheckbox { label = "ttt_voice_drain (def. 0)", repconvar = "rep_ttt_voice_drain", parent = gpvcblst }
    AddToList(gpevd, gpvcblst)

    local gpvdn = xlib.makeslider { label = "ttt_voice_drain_normal (def. 0.2)", min = 0.1, max = 1, decimal = 1, repconvar = "rep_ttt_voice_drain_normal", parent = gpvcblst }
    AddToList(gpvdn, gpvcblst)

    local gpvda = xlib.makeslider { label = "ttt_voice_drain_admin (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_admin", parent = gpvcblst }
    AddToList(gpvda, gpvcblst)

    local gpvdr = xlib.makeslider { label = "ttt_voice_drain_recharge (def. 0.05)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_voice_drain_recharge", parent = gpvcblst }
    AddToList(gpvdr, gpvcblst)
end

local function AddOtherGameplay(gppnl)
    local gpogsclp = vgui.Create("DCollapsibleCategory", gppnl)
    gpogsclp:SetLabel("Other Gameplay Settings")
    gpogsclp:SetExpanded(false)
    gppnl:Add(gpogsclp)

    local gpogslst = vgui.Create("DListLayout", gpogsclp)
    gpogsclp:SetContents(gpogslst)
    gpogslst:DockMargin(5, 0, 0, 0)
    gpogsclp:SetPaintBackground(true)

    local gpminply = xlib.makeslider { label = "ttt_minimum_players (def. 2)", min = 1, max = 10, repconvar = "rep_ttt_minimum_players", parent = gpogslst }
    AddToList(gpminply, gpogslst)

    local gpprdm = xlib.makecheckbox { label = "ttt_postround_dm (def. 0)", repconvar = "rep_ttt_postround_dm", parent = gpogslst }
    AddToList(gpprdm, gpogslst)

    local gpds = xlib.makecheckbox { label = "ttt_dyingshot (def. 0)", repconvar = "rep_ttt_dyingshot", parent = gpogslst }
    AddToList(gpds, gpogslst)

    local gpnntdp = xlib.makecheckbox { label = "ttt_no_nade_throw_during_prep (def. 0)", repconvar = "rep_ttt_no_nade_throw_during_prep", parent = gpogslst }
    AddToList(gpnntdp, gpogslst)

    local gpwc = xlib.makecheckbox { label = "ttt_weapon_carrying (def. 1)", repconvar = "rep_ttt_weapon_carrying", parent = gpogslst }
    AddToList(gpwc, gpogslst)

    local gpwcr = xlib.makeslider { label = "ttt_weapon_carrying_range (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_weapon_carrying_range", parent = gpogslst }
    AddToList(gpwcr, gpogslst)

    local gpttf = xlib.makecheckbox { label = "ttt_teleport_telefrags (def. 0)", repconvar = "rep_ttt_teleport_telefrags", parent = gpogslst }
    AddToList(gpttf, gpogslst)

    local gprdp = xlib.makecheckbox { label = "ttt_ragdoll_pinning (def. 1)", repconvar = "rep_ttt_ragdoll_pinning", parent = gpogslst }
    AddToList(gprdp, gpogslst)

    local gprdpi = xlib.makecheckbox { label = "ttt_ragdoll_pinning_innocents (def. 0)", repconvar = "rep_ttt_ragdoll_pinning_innocents", parent = gpogslst }
    AddToList(gprdpi, gpogslst)

    local gpdne = xlib.makecheckbox { label = "ttt_death_notifier_enabled (def. 1)", repconvar = "rep_ttt_death_notifier_enabled", parent = gpogslst }
    AddToList(gpdne, gpogslst)

    local gpdnsr = xlib.makecheckbox { label = "ttt_death_notifier_show_role (def. 1)", repconvar = "rep_ttt_death_notifier_show_role", parent = gpogslst }
    AddToList(gpdnsr, gpogslst)

    local gpdnst = xlib.makecheckbox { label = "ttt_death_notifier_show_team (def. 0)", repconvar = "rep_ttt_death_notifier_show_team", parent = gpogslst }
    AddToList(gpdnst, gpogslst)

    local gpcmolbl = xlib.makelabel { label = "ttt_color_mode_override (def. none)", parent = gpogslst }
    AddToList(gpcmolbl, gpogslst)
    local gpcmocb = xlib.makecombobox { repconvar = "rep_ttt_color_mode_override", isNumberConvar = false, choices = { "none", "default", "simple", "protan", "deutan", "tritan" }, parent = gpogslst }
    AddToList(gpcmocb, gpogslst)

    local gpssr = xlib.makecheckbox { label = "ttt_spectators_see_roles (def. 0)", repconvar = "rep_ttt_spectators_see_roles", parent = gpogslst }
    AddToList(gpssr, gpogslst)
end

local function AddGameplayModule()
    local gppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    AddTraitorAndDetectiveSettings(gppnl)
    AddSpecialistTraitorSettings(gppnl)
    AddSpecialistDetectiveSettings(gppnl)
    AddSpecialistInnocentSettings(gppnl)
    AddIndependentRoleSettings(gppnl)
    AddMonsterSettings(gppnl)
    AddGroupedRoleSettings(gppnl)
    AddRoleHealthSettings(gppnl)
    AddTraitorProperties(gppnl)
    AddDetectiveProperties(gppnl)
    AddInnocentProperties(gppnl)
    AddJesterRoleProperties(gppnl)
    AddIndependentRoleProperties(gppnl)
    AddMonsterRoleProperties(gppnl)
    AddCustomRoleProperties(gppnl)
    AddRoleShop(gppnl)
    AddDna(gppnl)
    AddDevices(gppnl)
    AddVoiceChat(gppnl)
    AddOtherGameplay(gppnl)

    xgui.hookEvent("onProcessModules", nil, gppnl.processModules)
    xgui.addSubModule("Gameplay", gppnl, nil, "terrortown_settings")
end

local function AddKarmaModule()
    local krmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local krmclp = vgui.Create("DCollapsibleCategory", krmpnl)
    krmclp:SetLabel("Karma")
    krmclp:SetExpanded(true)
    krmpnl:Add(krmclp)

    local krmlst = vgui.Create("DListLayout", krmclp)
    krmclp:SetContents(krmlst)
    krmlst:DockMargin(5, 0, 0, 0)
    krmclp:SetPaintBackground(true)

    local krmekrm = xlib.makecheckbox { label = "ttt_karma", repconvar = "rep_ttt_karma", parent = krmlst }
    AddToList(krmekrm, krmlst)

    local krmeskrm = xlib.makecheckbox { label = "ttt_karma_strict", repconvar = "rep_ttt_karma_strict", parent = krmlst }
    AddToList(krmeskrm, krmlst)

    local krms = xlib.makeslider { label = "ttt_karma_starting (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_starting", parent = krmlst }
    AddToList(krms, krmlst)

    local krmmx = xlib.makeslider { label = "ttt_karma_max (def. 1000)", min = 500, max = 2000, repconvar = "rep_ttt_karma_max", parent = krmlst }
    AddToList(krmmx, krmlst)

    local krmr = xlib.makeslider { label = "ttt_karma_ratio (def. 0.001)", min = 0.001, max = 0.009, decimal = 3, repconvar = "rep_ttt_karma_ratio", parent = krmlst }
    AddToList(krmr, krmlst)

    local krmkp = xlib.makeslider { label = "ttt_karma_kill_penalty (def. 15)", min = 1, max = 30, repconvar = "rep_ttt_karma_kill_penalty", parent = krmlst }
    AddToList(krmkp, krmlst)

    local krmri = xlib.makeslider { label = "ttt_karma_round_increment (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_karma_round_increment", parent = krmlst }
    AddToList(krmri, krmlst)

    local krmcb = xlib.makeslider { label = "ttt_karma_clean_bonus (def. 30)", min = 10, max = 100, repconvar = "rep_ttt_karma_clean_bonus", parent = krmlst }
    AddToList(krmcb, krmlst)

    local krmtdmgr = xlib.makeslider { label = "ttt_karma_traitordmg_ratio (def. 0.0003)", min = 0.0001, max = 0.001, decimal = 4, repconvar = "rep_ttt_karma_traitordmg_ratio", parent = krmlst }
    AddToList(krmtdmgr, krmlst)

    local krmtkb = xlib.makeslider { label = "ttt_karma_traitorkill_bonus (def. 40)", min = 10, max = 100, repconvar = "rep_ttt_karma_traitorkill_bonus", parent = krmlst }
    AddToList(krmtkb, krmlst)

    local krmjdmgr = xlib.makeslider { label = "ttt_karma_jesterdmg_ratio (def. 0.5)", min = 0.01, max = 1, decimal = 2, repconvar = "rep_ttt_karma_jesterdmg_ratio", parent = krmlst }
    AddToList(krmjdmgr, krmlst)

    local krmjkp = xlib.makeslider { label = "ttt_karma_jesterkill_penalty (def. 50)", min = 10, max = 100, repconvar = "rep_ttt_karma_jesterkill_penalty", parent = krmlst }
    AddToList(krmjkp, krmlst)

    local krmlak = xlib.makecheckbox { label = "ttt_karma_low_autokick (def. 1)", repconvar = "rep_ttt_karma_low_autokick", parent = krmlst }
    AddToList(krmlak, krmlst)

    local krmla = xlib.makeslider { label = "ttt_karma_low_amount (def. 450)", min = 100, max = 1000, repconvar = "rep_ttt_karma_low_amount", parent = krmlst }
    AddToList(krmla, krmlst)

    local krmlab = xlib.makecheckbox { label = "ttt_karma_low_ban (def. 1)", repconvar = "rep_ttt_karma_low_ban", parent = krmlst }
    AddToList(krmlab, krmlst)

    local krmlbm = xlib.makeslider { label = "ttt_karma_low_ban_minutes (def. 60)", min = 10, max = 100, repconvar = "rep_ttt_karma_low_ban_minutes", parent = krmlst }
    AddToList(krmlbm, krmlst)

    local krmpre = xlib.makecheckbox { label = "ttt_karma_persist (def. 0)", repconvar = "rep_ttt_karma_persist", parent = krmlst }
    AddToList(krmpre, krmlst)

    local krmdbs = xlib.makecheckbox { label = "ttt_karma_debugspam (def. 0)", repconvar = "rep_ttt_karma_debugspam", parent = krmlst }
    AddToList(krmdbs, krmlst)

    local krmch = xlib.makeslider { label = "ttt_karma_clean_half (def. 0.25)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_karma_clean_half", parent = krmlst }
    AddToList(krmch, krmlst)

    xgui.hookEvent("onProcessModules", nil, krmpnl.processModules)
    xgui.addSubModule("Karma", krmpnl, nil, "terrortown_settings")
end

local function AddMapModule()
    local mprpnl = xlib.makepanel { w = 415, h = 318, parent = xgui.null }

local lst = vgui.Create("DListLayout", mprpnl)
    lst:SetSize(415, 315)
    lst:DockPadding(0, 0, 0, 2)

    local mprpp = vgui.Create("DCollapsibleCategory", lst)
    mprpp:SetLabel("Map-related")
    mprpp:SetExpanded(true)
    lst:Add(mprpp)

    local mprlst = vgui.Create("DListLayout", mprpp)
    mprpp:SetContents(mprlst)
    mprlst:DockMargin(5, 0, 0, 0)
    mprpp:SetPaintBackground(true)

    local mprwss = xlib.makecheckbox { label = "ttt_use_weapon_spawn_scripts (def. 1)", repconvar = "rep_ttt_use_weapon_spawn_scripts", parent = mprlst }
    AddToList(mprwss, mprlst)

    local mpwsc = xlib.makecheckbox { label = "ttt_weapon_spawn_count (def. 0)", repconvar = "rep_ttt_weapon_spawn_count", parent = mprlst }
    AddToList(mpwsc, mprlst)

    xgui.hookEvent("onProcessModules", nil, mprpnl.processModules)
    xgui.addSubModule("Map-related", mprpnl, nil, "terrortown_settings")
end

local function AddRoleCreditsSlider(role_shops, lst)
    for _, r in ipairs(role_shops) do
        local role_string = ROLE_STRINGS_RAW[r]
        local convar = "ttt_" .. role_string .. "_credits_starting"
        local default = GetReplicatedConVarDefault(convar, "0")
        local slider = xlib.makeslider { label = convar .. " (def. " .. default .. ")", min = 0, max = 10, repconvar = "rep_" .. convar, parent = lst }
        AddToList(slider, lst)

        -- Save the control so it can be updated later
        if missing_cvars[convar] then
            missing_cvars[convar] = slider
        end
    end
end

local function AddRoleCreditSection(pnl, label, role_list, excludes)
    local cat = vgui.Create("DCollapsibleCategory", pnl)
    cat:SetLabel(label .. " Credits")
    cat:SetExpanded(false)
    pnl:Add(cat)

    local lst = vgui.Create("DListLayout", cat)
    cat:SetContents(lst)
    lst:DockMargin(5, 0, 0, 0)
    cat:SetPaintBackground(true)

    local credit_roles = GetCreditRoles()
    local role_shops = table.IntersectedKeys(role_list, credit_roles, excludes)
    SortRolesByName(role_shops)

    AddRoleCreditsSlider(role_shops, lst)
end

local function AddEquipmentCreditsModule()
    local ecpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Traitor Credits
    local credit_roles =  GetCreditRoles()
    local traitor_shops = table.IntersectedKeys(TRAITOR_ROLES, credit_roles, {ROLE_TRAITOR})
    SortRolesByName(traitor_shops)

    local ectcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ectcclp:SetLabel("Traitor Credits")
    ectcclp:SetExpanded(true)
    ecpnl:Add(ectcclp)

    local ectclst = vgui.Create("DListLayout", ectcclp)
    ectcclp:SetContents(ectclst)
    ectclst:DockMargin(5, 0, 0, 0)
    ectcclp:SetPaintBackground(true)

    local ectcct = xlib.makeslider { label = "ttt_traitors_credits_timer (def. 0)", min = 0, max = 240, repconvar = "rep_ttt_traitors_credits_timer", parent = ectclst }
    AddToList(ectcct, ectclst)

    local ectccs = xlib.makeslider { label = "ttt_credits_starting (def. 2)", min = 0, max = 10, repconvar = "rep_ttt_credits_starting", parent = ectclst }
    AddToList(ectccs, ectclst)

    AddRoleCreditsSlider(traitor_shops, ectclst)

    local ectcab = xlib.makecheckbox { label = "ttt_credits_alonebonus (def. 1)", repconvar = "rep_ttt_credits_alonebonus", parent = ectclst }
    AddToList(ectcab, ectclst)

    local ectcap = xlib.makeslider { label = "ttt_credits_award_pct (def. 0.35)", min = 0.01, max = 0.9, decimal = 2, repconvar = "rep_ttt_credits_award_pct", parent = ectclst }
    AddToList(ectcap, ectclst)

    local ectcas = xlib.makeslider { label = "ttt_credits_award_size (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_size", parent = ectclst }
    AddToList(ectcas, ectclst)

    local ectcar = xlib.makeslider { label = "ttt_credits_award_repeat (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_award_repeat", parent = ectclst }
    AddToList(ectcar, ectclst)

    local ectcdk = xlib.makeslider { label = "ttt_credits_detectivekill (def. 1)", min = 0, max = 5, repconvar = "rep_ttt_credits_detectivekill", parent = ectclst }
    AddToList(ectcdk, ectclst)

    --Detective Credits
    local detective_shops = table.IntersectedKeys(DETECTIVE_ROLES, credit_roles, {ROLE_DETECTIVE})
    SortRolesByName(detective_shops)
    local ecdcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecdcclp:SetSize(390, 170 + (25 * #detective_shops))
    ecdcclp:SetExpanded(0)
    ecdcclp:SetLabel("Detective Credits")

    local ecdclst = vgui.Create("DPanelList", ecdcclp)
    ecdclst:SetPos(5, 25)
    ecdclst:SetSize(390, 170 + (25 * #detective_shops))
    ecdclst:SetSpacing(5)

    local ecdcct = xlib.makeslider { label = "ttt_detectives_credits_timer (def. 0)", min = 0, max = 240, repconvar = "rep_ttt_detectives_credits_timer", parent = ecdclst }
    AddToList(ecdcct, ecdclst)

    local ecdcsc = xlib.makeslider { label = "ttt_detectives_search_credits (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_detectives_search_credits", parent = ecdclst }
    AddToList(ecdcsc, ecdclst)

    local ecdcscf = xlib.makecheckbox { label = "ttt_detectives_search_credits_friendly (def. 0)", repconvar = "rep_ttt_detectives_search_credits_friendly", parent = ecdclst }
    AddToList(ecdcscf, ecdclst)

    local ecdcscs = xlib.makecheckbox { label = "ttt_detectives_search_credits_share (def. 0)", repconvar = "rep_ttt_detectives_search_credits_share", parent = ecdclst }
    AddToList(ecdcscs, ecdclst)

    local ecdccs = xlib.makeslider { label = "ttt_det_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_starting", parent = ecdclst }
    AddToList(ecdccs, ecdclst)

    AddRoleCreditsSlider(detective_shops, ecdclst)

    local ecdctk = xlib.makeslider { label = "ttt_det_credits_traitorkill (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitorkill", parent = ecdclst }
    AddToList(ecdctk, ecdclst)

    local ecdctd = xlib.makeslider { label = "ttt_det_credits_traitordead (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitordead", parent = ecdclst }
    AddToList(ecdctd, ecdclst)

    AddRoleCreditSection(ecpnl, "Jester", JESTER_ROLES)
    AddRoleCreditSection(ecpnl, "Innocent", INNOCENT_ROLES, GetTeamRoles(DETECTIVE_ROLES))
    AddRoleCreditSection(ecpnl, "Independent", INDEPENDENT_ROLES)

    xgui.hookEvent("onProcessModules", nil, ecpnl.processModules)
    xgui.addSubModule("Equipment Credits", ecpnl, nil, "terrortown_settings")
end

local function AddPlayerMovementModule()
    local pmpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local pmspp = vgui.Create("DCollapsibleCategory", pmpnl)
    pmspp:SetLabel("Sprint")
    pmspp:SetExpanded(true)
    pmpnl:Add(pmspp)

    local pmsplst = vgui.Create("DListLayout", pmspp)
    pmspp:SetContents(pmsplst)
    pmsplst:DockMargin(5, 0, 0, 0)
    pmspp:SetPaintBackground(true)

    local pmspe = xlib.makecheckbox { label = "ttt_sprint_enabled  (def. 1)", repconvar = "rep_ttt_sprint_enabled", parent = pmsplst }
    AddToList(pmspe, pmsplst)

    local pmspbr = xlib.makeslider { label = "ttt_sprint_bonus_rel (def. 0.4)", min = 0.1, max = 2, decimal = 1, repconvar = "rep_ttt_sprint_bonus_rel", parent = pmsplst }
    AddToList(pmspbr, pmsplst)

    local pmsprd = xlib.makeslider { label = "ttt_sprint_regenerate_delay (def. 0)", min = 0, max = 60, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_delay", parent = pmsplst }
    AddToList(pmsprd, pmsplst)

    local pmspri = xlib.makeslider { label = "ttt_sprint_regenerate_innocent (def. 0.08)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_innocent", parent = pmsplst }
    AddToList(pmspri, pmsplst)

    local pmsprt = xlib.makeslider { label = "ttt_sprint_regenerate_traitor (def. 0.12)", min = 0.01, max = 2, decimal = 2, repconvar = "rep_ttt_sprint_regenerate_traitor", parent = pmsplst }
    AddToList(pmsprt, pmsplst)

    local pmspc = xlib.makeslider { label = "ttt_sprint_consume (def. 0.2)", min = 0.1, max = 5, decimal = 1, repconvar = "rep_ttt_sprint_consume", parent = pmsplst }
    AddToList(pmspc, pmsplst)

    xgui.hookEvent("onProcessModules", nil, pmpnl.processModules)
    xgui.addSubModule("Player Movement", pmpnl, nil, "terrortown_settings")
end

local function AddPropPossessionModule()
    local pppnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local ppclp = vgui.Create("DCollapsibleCategory", pppnl)
    ppclp:SetLabel("Prop Possession")
    ppclp:SetExpanded(true)
    pppnl:Add(ppclp)

    local pplst = vgui.Create("DListLayout", ppclp)
    ppclp:SetContents(pplst)
    pplst:DockMargin(5, 0, 0, 0)
    ppclp:SetPaintBackground(true)

    local ppspc = xlib.makecheckbox { label = "ttt_spec_prop_control  (def. 1)", repconvar = "rep_ttt_spec_prop_control", parent = pplst }
    AddToList(ppspc, pplst)

    local ppspb = xlib.makeslider { label = "ttt_spec_prop_base (def. 8)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_base", parent = pplst }
    AddToList(ppspb, pplst)

    local ppspmp = xlib.makeslider { label = "ttt_spec_prop_maxpenalty (def. -6)", min = -50, max = 0, repconvar = "rep_ttt_spec_prop_maxpenalty", parent = pplst }
    AddToList(ppspmp, pplst)

    local ppspmb = xlib.makeslider { label = "ttt_spec_prop_maxbonus (def. 16)", min = 0, max = 50, repconvar = "rep_ttt_spec_prop_maxbonus", parent = pplst }
    AddToList(ppspmb, pplst)

    local ppspf = xlib.makeslider { label = "ttt_spec_prop_force (def. 110)", min = 50, max = 300, repconvar = "rep_ttt_spec_prop_force", parent = pplst }
    AddToList(ppspf, pplst)

    local ppprt = xlib.makeslider { label = "ttt_spec_prop_rechargetime (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_spec_prop_rechargetime", parent = pplst }
    AddToList(ppprt, pplst)

    xgui.hookEvent("onProcessModules", nil, pppnl.processModules)
    xgui.addSubModule("Prop Possession", pppnl, nil, "terrortown_settings")
end

local function AddAdminModule()
    -------------------- Admin-related Module--------------------
    local arpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local arclp = vgui.Create("DCollapsibleCategory", arpnl)
    arclp:SetLabel("Admin-related")
    arclp:SetExpanded(true)
    arpnl:Add(arclp)

    local arlst = vgui.Create("DListLayout", arclp)
    arclp:SetContents(arlst)
    arlst:DockMargin(5, 0, 0, 0)
    arclp:SetPaintBackground(true)

    local aril = xlib.makeslider { label = "ttt_idle_limit (def. 180)", min = 50, max = 300, repconvar = "rep_ttt_idle_limit", parent = arlst }
    AddToList(aril, arlst)

    local arnck = xlib.makecheckbox { label = "ttt_namechange_kick (def. 1)", repconvar = "rep_ttt_namechange_kick", parent = arlst }
    AddToList(arnck, arlst)

    local arncbt = xlib.makeslider { label = "ttt_namechange_bantime (def. 10)", min = 0, max = 60, repconvar = "rep_ttt_namechange_bantime", parent = arlst }
    AddToList(arncbt, arlst)

    xgui.hookEvent("onProcessModules", nil, arpnl.processModules)
    xgui.addSubModule("Admin-related", arpnl, nil, "terrortown_settings")
end

local function AddMiscModule()
    -------------------- Miscellaneous Module--------------------
    local miscpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    local bempnl = vgui.Create("DCollapsibleCategory", miscpnl)
    bempnl:SetLabel("Better Equipment Menu")
    bempnl:SetExpanded(true)
    miscpnl:Add(bempnl)

    local bemlst = vgui.Create("DListLayout", bempnl)
    bempnl:SetContents(bemlst)
    bemlst:DockMargin(5, 0, 0, 0)
    bempnl:SetPaintBackground(true)

    local bemac = xlib.makecheckbox { label = "ttt_bem_allow_change (def. 1)", repconvar = "rep_ttt_bem_allow_change", parent = bemlst }
    AddToList(bemac, bemlst)

    local bemcol = xlib.makeslider { label = "ttt_bem_sv_cols (def. 4)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_cols", parent = bemlst }
    AddToList(bemcol, bemlst)

    local bemrow = xlib.makeslider { label = "ttt_bem_sv_rows (def. 5)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_rows", parent = bemlst }
    AddToList(bemrow, bemlst)

    local bemsize = xlib.makeslider { label = "ttt_bem_sv_size (def. 64)", min = 16, max = 128, repconvar = "rep_ttt_bem_sv_size", parent = bemlst }
    AddToList(bemsize, bemlst)

    local miscclp = vgui.Create("DCollapsibleCategory", miscpnl)
    miscclp:SetLabel("Miscellaneous")
    miscclp:SetExpanded(true)
    miscpnl:Add(miscclp)

    local misclst = vgui.Create("DListLayout", miscclp)
    miscclp:SetContents(misclst)
    misclst:DockMargin(5, 0, 0, 0)
    miscclp:SetPaintBackground(true)

    local miscdh = xlib.makecheckbox { label = "ttt_detective_hats (def. 0)", repconvar = "rep_ttt_detective_hats", parent = misclst }
    AddToList(miscdh, misclst)

    local miscpcmlbl = xlib.makelabel { label = "ttt_playercolor_mode (def. 1)", parent = misclst }
    AddToList(miscpcmlbl, misclst)
    local miscpcmcb = xlib.makecombobox { repconvar = "rep_ttt_playercolor_mode", isNumberConvar = true, choices = {"None", "Serious", "All", "Random"}, parent = misclst }
    AddToList(miscpcmcb, misclst)

    local miscrc = xlib.makecheckbox { label = "ttt_ragdoll_collide (def. 0)", repconvar = "rep_ttt_ragdoll_collide", parent = misclst }
    AddToList(miscrc, misclst)

    local miscbs = xlib.makecheckbox { label = "ttt_bots_are_spectators (def. 0)", repconvar = "rep_ttt_bots_are_spectators", parent = misclst }
    AddToList(miscbs, misclst)

    local miscdpw = xlib.makecheckbox { label = "ttt_debug_preventwin (def. 0)", repconvar = "rep_ttt_debug_preventwin", parent = misclst }
    AddToList(miscdpw, misclst)

    local miscdlk = xlib.makecheckbox { label = "ttt_debug_logkills (def. 1)", repconvar = "rep_ttt_debug_logkills", parent = misclst }
    AddToList(miscdlk, misclst)

    local miscdlr = xlib.makecheckbox { label = "ttt_debug_logroles (def. 1)", repconvar = "rep_ttt_debug_logroles", parent = misclst }
    AddToList(miscdlr, misclst)

    local misclv = xlib.makecheckbox { label = "ttt_locational_voice (def. 0)", repconvar = "rep_ttt_locational_voice", parent = misclst }
    AddToList(misclv, misclst)

    local miscdj = xlib.makecheckbox { label = "ttt_allow_discomb_jump (def. 0)", repconvar = "rep_ttt_allow_discomb_jump", parent = misclst }
    AddToList(miscdj, misclst)

    local miscswi = xlib.makeslider { label = "ttt_spawn_wave_interval (def. 0)", min = 0, max = 30, repconvar = "rep_ttt_spawn_wave_interval", parent = misclst }
    AddToList(miscswi, misclst)

    local misccu = xlib.makecheckbox { label = "ttt_crowbar_unlocks (def. 1)", repconvar = "rep_ttt_crowbar_unlocks", parent = misclst }
    AddToList(misccu, misclst)

    local misccp = xlib.makeslider { label = "ttt_crowbar_pushforce (def. 395)", min = 0, max = 10000, repconvar = "rep_ttt_crowbar_pushforce", parent = misclst }
    AddToList(misccp, misclst)

    local miscsd = xlib.makecheckbox { label = "ttt_scoreboard_deaths (def. 0)", repconvar = "rep_ttt_scoreboard_deaths", parent = misclst }
    AddToList(miscsd, misclst)

    local miscss = xlib.makecheckbox { label = "ttt_scoreboard_score (def. 0)", repconvar = "rep_ttt_scoreboard_score", parent = misclst }
    AddToList(miscss, misclst)

    local miscrstlbl = xlib.makelabel { label = "ttt_round_summary_tabs (def. summary,hilite,events,scores)", parent = misclst }
    AddToList(miscrstlbl, misclst)
    local miscrsttb = xlib.maketextbox { repconvar = "rep_ttt_round_summary_tabs", enableinput = true, parent = misclst }
    AddToList(miscrsttb, misclst)

    local miscse = xlib.makecheckbox { label = "ttt_smokegrenade_extinguish (def. 1)", repconvar = "rep_ttt_smokegrenade_extinguish", parent = misclst }
    AddToList(miscse, misclst)

    local miscplc = xlib.makecheckbox { label = "ttt_player_set_color (def. 1)", repconvar = "rep_ttt_player_set_color", parent = misclst }
    AddToList(miscplc, misclst)

    local miscwto = xlib.makecheckbox { label = "ttt_weapon_transfer_ownership (def. 0)", repconvar = "rep_ttt_weapon_transfer_ownership", parent = misclst }
    AddToList(miscwto, misclst)

    local miscscs = xlib.makecheckbox { label = "ttt_spectator_corpse_search (def. 1)", repconvar = "rep_ttt_spectator_corpse_search", parent = misclst }
    AddToList(miscscs, misclst)

    local misccsac = xlib.makecheckbox { label = "ttt_corpse_search_auto_confirm (def. 1)", repconvar = "rep_ttt_corpse_search_auto_confirm", parent = misclst }
    AddToList(misccsac, misclst)

    local misccsns = xlib.makecheckbox { label = "ttt_corpse_search_not_shared (def. 0)", repconvar = "rep_ttt_corpse_search_not_shared", parent = misclst }
    AddToList(misccsns, misclst)

    local misccsttid = xlib.makecheckbox { label = "ttt_corpse_search_team_text_independent (def. 0)", repconvar = "rep_ttt_corpse_search_team_text_independent", parent = misclst }
    AddToList(misccsttid, misclst)

    local misccsttin = xlib.makecheckbox { label = "ttt_corpse_search_team_text_innocent (def. 0)", repconvar = "rep_ttt_corpse_search_team_text_innocent", parent = misclst }
    AddToList(misccsttin, misclst)

    local misccsttj = xlib.makecheckbox { label = "ttt_corpse_search_team_text_jester (def. 0)", repconvar = "rep_ttt_corpse_search_team_text_jester", parent = misclst }
    AddToList(misccsttj, misclst)

    local misccsttm = xlib.makecheckbox { label = "ttt_corpse_search_team_text_monster (def. 0)", repconvar = "rep_ttt_corpse_search_team_text_monster", parent = misclst }
    AddToList(misccsttm, misclst)

    local misccsttt = xlib.makecheckbox { label = "ttt_corpse_search_team_text_traitor (def. 0)", repconvar = "rep_ttt_corpse_search_team_text_traitor", parent = misclst }
    AddToList(misccsttt, misclst)

    local misccskttid = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_independent (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_independent", parent = misclst }
    AddToList(misccskttid, misclst)

    local misccskttin = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_innocent (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_innocent", parent = misclst }
    AddToList(misccskttin, misclst)

    local misccskttj = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_jester (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_jester", parent = misclst }
    AddToList(misccskttj, misclst)

    local misccskttm = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_monster (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_monster", parent = misclst }
    AddToList(misccskttm, misclst)

    local misccskttt = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_traitor (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_traitor", parent = misclst }
    AddToList(misccskttt, misclst)

    local misccskttp = xlib.makecheckbox { label = "ttt_corpse_search_killer_team_text_plain (def. 0)", repconvar = "rep_ttt_corpse_search_killer_team_text_plain", parent = misclst }
    AddToList(misccskttp, misclst)

    --Disable Features
    local dfclp = vgui.Create("DCollapsibleCategory", miscpnl)
    dfclp:SetLabel("Disable Features")
    dfclp:SetExpanded(true)
    miscpnl:Add(dfclp)

    local dflst = vgui.Create("DListLayout", dfclp)
    dfclp:SetContents(dflst)
    dfclp:SetPaintBackground(true)

    local dfdh = xlib.makecheckbox { label = "ttt_disable_headshots (def. 0)", repconvar = "rep_ttt_disable_headshots", parent = dflst }
    AddToList(dfdh, dflst)

    local dfdmw = xlib.makecheckbox { label = "ttt_disable_mapwin (def. 0)", repconvar = "rep_ttt_disable_mapwin", parent = dflst }
    AddToList(dfdmw, dflst)

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
end)

local opened = false
xgui.hookEvent("onOpen", nil, function()
    if not LocalPlayer():IsAdmin() and not LocalPlayer():IsSuperAdmin() then return end
    if opened then return end
    opened = true

    -- Request missing cvar data, if we have any
    if table.Count(missing_cvars) <= 0 then return end

    print("[CR4TTT ULX] Requesting missing information...")

    -- Convert from a lookup table to an indexed table
    local net_table = {}
    for k, _ in pairs(missing_cvars) do
        table.insert(net_table, k)
    end

    local cvarJSON = util.TableToJSON(net_table)
    local compressedString = util.Compress(cvarJSON)
    local compressedLen = #compressedString
    net.Start("ULX_CRCVarRequest")
        net.WriteUInt(compressedLen, 16)
        net.WriteData(compressedString, compressedLen)
    net.SendToServer()
end, "CR4TTTULXOpen")

local compressedCvars = {}
net.Receive("ULX_CRCVarPart", function()
    local len = net.ReadUInt(16)
    local idx = net.ReadUInt(16)
    compressedCvars[idx] = net.ReadData(len)
end)

net.Receive("ULX_CRCVarComplete", function()
    print("[CR4TTT ULX] Final part received, reloading...")

    local cvarCount = table.Count(compressedCvars)
    local compressedString = ""
    for idx = 1, cvarCount do
        compressedString = compressedString .. compressedCvars[idx]
    end

    local cvarJSON = util.Decompress(compressedString)
    local results = util.JSONToTable(cvarJSON)

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

    -- Reload the modules since by this time its usually loaded already
    xgui.processModules()

    -- Reset the tables to save space
    compressedCvars = {}
    table.Empty(missing_cvars)

    print("[CR4TTT ULX] Reload complete")
end)