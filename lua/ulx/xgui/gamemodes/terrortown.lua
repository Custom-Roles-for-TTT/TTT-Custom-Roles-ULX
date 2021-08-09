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

terrortown_settings.catList.OnRowSelected = function(self, LineID, Line)
    local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel
    if nPanel ~= terrortown_settings.curPanel then
        nPanel:SetZPos(0)
        xlib.addToAnimQueue("pnlSlide", { panel = nPanel, startx = -435, starty = 0, endx = 0, endy = 0, setvisible = true })
        if terrortown_settings.curPanel then
            terrortown_settings.curPanel:SetZPos(-1)
            xlib.addToAnimQueue(terrortown_settings.curPanel.SetVisible, terrortown_settings.curPanel, false)
        end
        xlib.animQueue_start()
        terrortown_settings.curPanel = nPanel
    else
        xlib.addToAnimQueue("pnlSlide", { panel = nPanel, startx = 0, starty = 0, endx = -435, endy = 0, setvisible = false })
        self:ClearSelection()
        terrortown_settings.curPanel = nil
        xlib.animQueue_start()
    end
    if nPanel.onOpen then nPanel.onOpen() end --If the panel has it, call a function when it's opened
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

    local hstmpd = xlib.makeslider { label = "ttt_haste_minutes_per_death (def. 0.5)", min = 0.1, max = 9, decimal = 1, repconvar = "rep_ttt_haste_minutes_per_death", parent = rsrllst }
    rsrllst:AddItem(hstmpd)

    local rtm = xlib.makeslider { label = "ttt_roundtime_minutes (def. 10)", min = 1, max = 60, repconvar = "rep_ttt_roundtime_minutes", parent = rsrllst }
    rsrllst:AddItem(rtm)

    --Map Switching and Voting
    local msavclp = vgui.Create("DCollapsibleCategory", rspnl)
    msavclp:SetSize(390, 95)
    msavclp:SetExpanded(0)
    msavclp:SetLabel("Map Switching and Voting")

    local msavlst = vgui.Create("DPanelList", msavclp)
    msavlst:SetPos(5, 25)
    msavlst:SetSize(390, 95)
    msavlst:SetSpacing(5)

    local rndl = xlib.makeslider { label = "ttt_round_limit (def. 6)", min = 1, max = 100, repconvar = "rep_ttt_round_limit", parent = msavlst }
    msavlst:AddItem(rndl)

    local rndtlm = xlib.makeslider { label = "ttt_time_limit_minutes (def. 75)", min = 1, max = 150, repconvar = "rep_ttt_time_limit_minutes", parent = msavlst }
    msavlst:AddItem(rndtlm)

    local rndawm = xlib.makecheckbox { label = "ttt_always_use_mapcycle (def. 0)", repconvar = "rep_ttt_always_use_mapcycle", parent = msavlst }
    msavlst:AddItem(rndawm)

    local rndawmtxt = xlib.makelabel { wordwrap = true, label = "This does nothing but since its included in TTT it's here.", parent = msavlst }
    msavlst:AddItem(rndawmtxt)

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

local function AddSpecialistTraitorSettings(gppnl)
    local sptraclp = vgui.Create("DCollapsibleCategory", gppnl)
    sptraclp:SetSize(390, 470)
    sptraclp:SetExpanded(1)
    sptraclp:SetLabel("Specialist Traitor Settings")

    local sptralst = vgui.Create("DPanelList", sptraclp)
    sptralst:SetPos(5, 25)
    sptralst:SetSize(390, 470)
    sptralst:SetSpacing(5)

    local stpercet = xlib.makeslider { label = "ttt_special_traitor_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_pct", parent = sptralst }
    sptralst:AddItem(stpercet)

    local stchance = xlib.makeslider { label = "ttt_special_traitor_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_traitor_chance", parent = sptralst }
    sptralst:AddItem(stchance)

    local hashyp = xlib.makecheckbox { label = "ttt_hypnotist_enabled (def. 0)", repconvar = "rep_ttt_hypnotist_enabled", parent = sptralst }
    sptralst:AddItem(hashyp)

    local weighthyp = xlib.makeslider { label = "ttt_hypnotist_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_hypnotist_spawn_weight", parent = sptralst }
    sptralst:AddItem(weighthyp)

    local minhyp = xlib.makeslider { label = "ttt_hypnotist_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_hypnotist_min_players", parent = sptralst }
    sptralst:AddItem(minhyp)

    local hasimp = xlib.makecheckbox { label = "ttt_impersonator_enabled (def. 0)", repconvar = "rep_ttt_impersonator_enabled", parent = sptralst }
    sptralst:AddItem(hasimp)

    local weightimp = xlib.makeslider { label = "ttt_impersonator_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_impersonator_spawn_weight", parent = sptralst }
    sptralst:AddItem(weightimp)

    local minimp = xlib.makeslider { label = "ttt_impersonator_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_impersonator_min_players", parent = sptralst }
    sptralst:AddItem(minimp)

    local hasasn = xlib.makecheckbox { label = "ttt_assassin_enabled (def. 0)", repconvar = "rep_ttt_assassin_enabled", parent = sptralst }
    sptralst:AddItem(hasasn)

    local weightasn = xlib.makeslider { label = "ttt_assassin_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_assassin_spawn_weight", parent = sptralst }
    sptralst:AddItem(weightasn)

    local minasn = xlib.makeslider { label = "ttt_assassin_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_assassin_min_players", parent = sptralst }
    sptralst:AddItem(minasn)

    local hasvam = xlib.makecheckbox { label = "ttt_vampire_enabled (def. 0)", repconvar = "rep_ttt_vampire_enabled", parent = sptralst }
    sptralst:AddItem(hasvam)

    local weightvam = xlib.makeslider { label = "ttt_vampire_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_vampire_spawn_weight", parent = sptralst }
    sptralst:AddItem(weightvam)

    local minvam = xlib.makeslider { label = "ttt_vampire_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_vampire_min_players", parent = sptralst }
    sptralst:AddItem(minvam)

    local hasqua = xlib.makecheckbox { label = "ttt_quack_enabled (def. 0)", repconvar = "rep_ttt_quack_enabled", parent = sptralst }
    sptralst:AddItem(hasqua)

    local weightqua = xlib.makeslider { label = "ttt_quack_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_quack_spawn_weight", parent = sptralst }
    sptralst:AddItem(weightqua)

    local minqua = xlib.makeslider { label = "ttt_quack_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_quack_min_players", parent = sptralst }
    sptralst:AddItem(minqua)

    local haspar = xlib.makecheckbox { label = "ttt_parasite_enabled (def. 0)", repconvar = "rep_ttt_parasite_enabled", parent = sptralst }
    sptralst:AddItem(haspar)

    local weightpar = xlib.makeslider { label = "ttt_parasite_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_parasite_spawn_weight", parent = sptralst }
    sptralst:AddItem(weightpar)

    local minpar = xlib.makeslider { label = "ttt_parasite_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_parasite_min_players", parent = sptralst }
    sptralst:AddItem(minpar)
end

local function AddSpecialistInnocentSettings(gppnl)
    local spinnclp = vgui.Create("DCollapsibleCategory", gppnl)
    spinnclp:SetSize(390, 540)
    spinnclp:SetExpanded(1)
    spinnclp:SetLabel("Specialist Innocent Settings")

    local spinnlst = vgui.Create("DPanelList", spinnclp)
    spinnlst:SetPos(5, 25)
    spinnlst:SetSize(390, 540)
    spinnlst:SetSpacing(5)

    local sipercet = xlib.makeslider { label = "ttt_special_innocent_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_pct", parent = spinnlst }
    spinnlst:AddItem(sipercet)

    local sichance = xlib.makeslider { label = "ttt_special_innocent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_special_innocent_chance", parent = spinnlst }
    spinnlst:AddItem(sichance)

    local hasgli = xlib.makecheckbox { label = "ttt_glitch_enabled (def. 0)", repconvar = "rep_ttt_glitch_enabled", parent = spinnlst }
    spinnlst:AddItem(hasgli)

    local weightgli = xlib.makeslider { label = "ttt_glitch_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_glitch_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightgli)

    local mingli = xlib.makeslider { label = "ttt_glitch_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_glitch_min_players", parent = spinnlst }
    spinnlst:AddItem(mingli)

    local haspha = xlib.makecheckbox { label = "ttt_phantom_enabled (def. 0)", repconvar = "rep_ttt_phantom_enabled", parent = spinnlst }
    spinnlst:AddItem(haspha)

    local weightpha = xlib.makeslider { label = "ttt_phantom_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_phantom_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightpha)

    local minpha = xlib.makeslider { label = "ttt_phantom_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_phantom_min_players", parent = spinnlst }
    spinnlst:AddItem(minpha)

    local hasrev = xlib.makecheckbox { label = "ttt_revenger_enabled (def. 0)", repconvar = "rep_ttt_revenger_enabled", parent = spinnlst }
    spinnlst:AddItem(hasrev)

    local weightrev = xlib.makeslider { label = "ttt_revenger_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_revenger_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightrev)

    local minrev = xlib.makeslider { label = "ttt_revenger_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_revenger_min_players", parent = spinnlst }
    spinnlst:AddItem(minrev)

    local hasdep = xlib.makecheckbox { label = "ttt_deputy_enabled (def. 0)", repconvar = "rep_ttt_deputy_enabled", parent = spinnlst }
    spinnlst:AddItem(hasdep)

    local weightdep = xlib.makeslider { label = "ttt_deputy_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_deputy_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightdep)

    local mindep = xlib.makeslider { label = "ttt_deputy_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_mercenary_min_players", parent = spinnlst }
    spinnlst:AddItem(mindep)

    local hasmer = xlib.makecheckbox { label = "ttt_mercenary_enabled (def. 0)", repconvar = "rep_ttt_mercenary_enabled", parent = spinnlst }
    spinnlst:AddItem(hasmer)

    local weightmer = xlib.makeslider { label = "ttt_mercenary_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_mercenary_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightmer)

    local minmer = xlib.makeslider { label = "ttt_mercenary_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_mercenary_min_players", parent = spinnlst }
    spinnlst:AddItem(minmer)

    local hasvet = xlib.makecheckbox { label = "ttt_veteran_enabled (def. 0)", repconvar = "rep_ttt_veteran_enabled", parent = spinnlst }
    spinnlst:AddItem(hasvet)

    local weightvet = xlib.makeslider { label = "ttt_veteran_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_veteran_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightvet)

    local minvet = xlib.makeslider { label = "ttt_veteran_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_veteran_min_players", parent = spinnlst }
    spinnlst:AddItem(minvet)

    local hasdoc = xlib.makecheckbox { label = "ttt_doctor_enabled (def. 0)", repconvar = "rep_ttt_doctor_enabled", parent = spinnlst }
    spinnlst:AddItem(hasdoc)

    local weightdoc = xlib.makeslider { label = "ttt_doctor_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_doctor_spawn_weight", parent = spinnlst }
    spinnlst:AddItem(weightdoc)

    local mindoc = xlib.makeslider { label = "ttt_doctor_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_doctor_min_players", parent = spinnlst }
    spinnlst:AddItem(mindoc)
end

local function AddIndependentRoleSettings(gppnl)
    local indclp = vgui.Create("DCollapsibleCategory", gppnl)
    indclp:SetSize(390, 650)
    indclp:SetExpanded(1)
    indclp:SetLabel("Independent Role Settings")

    local indlst = vgui.Create("DPanelList", indclp)
    indlst:SetPos(5, 25)
    indlst:SetSize(390, 650)
    indlst:SetSpacing(5)

    local indchance = xlib.makeslider { label = "ttt_independent_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_independent_chance", parent = indlst }
    indlst:AddItem(indchance)

    local hasjes = xlib.makecheckbox { label = "ttt_jester_enabled (def. 0)", repconvar = "rep_ttt_jester_enabled", parent = indlst }
    indlst:AddItem(hasjes)

    local weightjes = xlib.makeslider { label = "ttt_jester_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_jester_spawn_weight", parent = indlst }
    indlst:AddItem(weightjes)

    local minjes = xlib.makeslider { label = "ttt_jester_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_jester_min_players", parent = indlst }
    indlst:AddItem(minjes)

    local hasswa = xlib.makecheckbox { label = "ttt_swapper_enabled (def. 0)", repconvar = "rep_ttt_swapper_enabled", parent = indlst }
    indlst:AddItem(hasswa)

    local weightswa = xlib.makeslider { label = "ttt_swapper_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_swapper_spawn_weight", parent = indlst }
    indlst:AddItem(weightswa)

    local minswa = xlib.makeslider { label = "ttt_swapper_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_swapper_min_players", parent = indlst }
    indlst:AddItem(minswa)

    local hasclo = xlib.makecheckbox { label = "ttt_clown_enabled (def. 0)", repconvar = "rep_ttt_clown_enabled", parent = indlst }
    indlst:AddItem(hasclo)

    local weightclo = xlib.makeslider { label = "ttt_clown_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_clown_spawn_weight", parent = indlst }
    indlst:AddItem(weightclo)

    local minclo = xlib.makeslider { label = "ttt_clown_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_clown_min_players", parent = indlst }
    indlst:AddItem(minclo)

    local hasbeg = xlib.makecheckbox { label = "ttt_beggar_enabled (def. 0)", repconvar = "rep_ttt_beggar_enabled", parent = indlst }
    indlst:AddItem(hasbeg)

    local weightbeg = xlib.makeslider { label = "ttt_beggar_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_beggar_spawn_weight", parent = indlst }
    indlst:AddItem(weightbeg)

    local minbeg = xlib.makeslider { label = "ttt_beggar_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_beggar_min_players", parent = indlst }
    indlst:AddItem(minbeg)

    local hasbod = xlib.makecheckbox { label = "ttt_bodysnatcher_enabled (def. 0)", repconvar = "rep_ttt_bodysnatcher_enabled", parent = indlst }
    indlst:AddItem(hasbod)

    local weightbod = xlib.makeslider { label = "ttt_bodysnatcher_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_bodysnatcher_spawn_weight", parent = indlst }
    indlst:AddItem(weightbod)

    local minbod = xlib.makeslider { label = "ttt_bodysnatcher_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_bodysnatcher_min_players", parent = indlst }
    indlst:AddItem(minbod)

    local hasdru = xlib.makecheckbox { label = "ttt_drunk_enabled (def. 0)", repconvar = "rep_ttt_drunk_enabled", parent = indlst }
    indlst:AddItem(hasdru)

    local weightdru = xlib.makeslider { label = "ttt_drunk_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_drunk_spawn_weight", parent = indlst }
    indlst:AddItem(weightdru)

    local mindru = xlib.makeslider { label = "ttt_drunk_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_drunk_min_players", parent = indlst }
    indlst:AddItem(mindru)

    local hasold = xlib.makecheckbox { label = "ttt_oldman_enabled (def. 0)", repconvar = "rep_ttt_oldman_enabled", parent = indlst }
    indlst:AddItem(hasold)

    local weightold = xlib.makeslider { label = "ttt_oldman_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_oldman_spawn_weight", parent = indlst }
    indlst:AddItem(weightold)

    local minold = xlib.makeslider { label = "ttt_oldman_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_oldman_min_players", parent = indlst }
    indlst:AddItem(minold)

    local haskil = xlib.makecheckbox { label = "ttt_killer_enabled (def. 0)", repconvar = "rep_ttt_killer_enabled", parent = indlst }
    indlst:AddItem(haskil)

    local weightkil = xlib.makeslider { label = "ttt_killer_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_killer_spawn_weight", parent = indlst }
    indlst:AddItem(weightkil)

    local minkil = xlib.makeslider { label = "ttt_killer_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_killer_min_players", parent = indlst }
    indlst:AddItem(minkil)

    local haszom = xlib.makecheckbox { label = "ttt_zombie_enabled (def. 0)", repconvar = "rep_ttt_zombie_enabled", parent = indlst }
    indlst:AddItem(haszom)

    local weightzom = xlib.makeslider { label = "ttt_zombie_spawn_weight (def. 1)", min = 1, max = 10, repconvar = "rep_ttt_zombie_spawn_weight", parent = indlst }
    indlst:AddItem(weightzom)

    local minzom = xlib.makeslider { label = "ttt_zombie_min_players (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_zombie_min_players", parent = indlst }
    indlst:AddItem(minzom)
end

local function AddMonsterSettings(gppnl)
    local monclp = vgui.Create("DCollapsibleCategory", gppnl)
    monclp:SetSize(390, 50)
    monclp:SetExpanded(1)
    monclp:SetLabel("Monster Settings")

    local monlst = vgui.Create("DPanelList", monclp)
    monlst:SetPos(5, 25)
    monlst:SetSize(390, 50)
    monlst:SetSpacing(5)

    local monpercet = xlib.makeslider { label = "ttt_monster_pct (def. 0.33)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_pct", parent = monlst }
    monlst:AddItem(monpercet)

    local monchance = xlib.makeslider { label = "ttt_monster_chance (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_monster_chance", parent = monlst }
    monlst:AddItem(monchance)

end

local function AddRoleHealthSettings(gppnl)
    local rolehealthclp = vgui.Create("DCollapsibleCategory", gppnl)
    rolehealthclp:SetSize(390, ROLE_MAX * 52)
    rolehealthclp:SetExpanded(1)
    rolehealthclp:SetLabel("Role Health Settings")

    local rolehealthlst = vgui.Create("DPanelList", rolehealthclp)
    rolehealthlst:SetPos(5, 25)
    rolehealthlst:SetSize(390, ROLE_MAX * 52)
    rolehealthlst:SetSpacing(5)

    for role = 0, ROLE_MAX do
        local health = "100"
        if role == ROLE_OLDMAN then health = "1"
        elseif role == ROLE_KILLER then health = "150" end
        local starthealth = xlib.makeslider { label = "ttt_" .. ROLE_STRINGS_RAW[role] .. "_starting_health (def. " .. health ..")", min = 1, max = 200, repconvar = "rep_ttt_" .. ROLE_STRINGS[role] .. "_starting_health", parent = rolehealthlst }
        rolehealthlst:AddItem(starthealth)

        local maxhealth = xlib.makeslider { label = "ttt_" .. ROLE_STRINGS_RAW[role] .. "_max_health (def. " .. health ..")", min = 1, max = 200, repconvar = "rep_ttt_" .. ROLE_STRINGS[role] .. "_max_health", parent = rolehealthlst }
        rolehealthlst:AddItem(maxhealth)
    end
end

local function AddTraitorProperties(gppnl)
    local trapropclp = vgui.Create("DCollapsibleCategory", gppnl)
    trapropclp:SetSize(390, 705)
    trapropclp:SetExpanded(1)
    trapropclp:SetLabel("Traitor Properties")

    local traproplst = vgui.Create("DPanelList", trapropclp)
    traproplst:SetPos(5, 25)
    traproplst:SetSize(390, 705)
    traproplst:SetSpacing(5)

    local travis = xlib.makecheckbox { label = "ttt_traitor_vision_enable (def. 0)", repconvar = "rep_ttt_traitor_vision_enable", parent = traproplst }
    traproplst:AddItem(travis)

    local implbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Impersonator settings:", parent = traproplst }
    traproplst:AddItem(implbl)

    local imppen = xlib.makeslider { label = "ttt_impersonator_damage_penalty (def. 0)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_impersonator_damage_penalty", parent = traproplst }
    traproplst:AddItem(imppen)

    local impudi = xlib.makecheckbox { label = "ttt_impersonator_use_detective_icon (def. 1)", repconvar = "rep_ttt_impersonator_use_detective_icon", parent = traproplst }
    traproplst:AddItem(impudi)

    local asnlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Assassin settings:", parent = traproplst }
    traproplst:AddItem(asnlbl)

    local asntgt = xlib.makecheckbox { label = "ttt_assassin_show_target_icon (def. 0)", repconvar = "rep_ttt_assassin_show_target_icon", parent = traproplst }
    traproplst:AddItem(asntgt)

    local asntgtdelay = xlib.makeslider { label = "ttt_assassin_next_target_delay (def. 5)", min = 0, max = 10, repconvar = "rep_ttt_assassin_next_target_delay", parent = traproplst }
    traproplst:AddItem(asntgtdelay)

    local asntdb = xlib.makeslider { label = "ttt_assassin_target_damage_bonus (def. 1)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_target_damage_bonus", parent = traproplst }
    traproplst:AddItem(asntdb)

    local asnwdp = xlib.makeslider { label = "ttt_assassin_wrong_damage_penalty (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_wrong_damage_penalty", parent = traproplst }
    traproplst:AddItem(asnwdp)

    local asnfdp = xlib.makeslider { label = "ttt_assassin_failed_damage_penalty (def. 0.5)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_assassin_failed_damage_penalty", parent = traproplst }
    traproplst:AddItem(asnfdp)

    local asnsrl = xlib.makecheckbox { label = "ttt_assassin_shop_roles_last (def. 0)", repconvar = "rep_ttt_assassin_shop_roles_last", parent = traproplst }
    traproplst:AddItem(asnsrl)

    local vamlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Vampire settings:", parent = traproplst }
    traproplst:AddItem(vamlbl)

    local vamatra = xlib.makecheckbox { label = "ttt_vampires_are_monsters (def. 0)", repconvar = "rep_ttt_vampires_are_monsters", parent = traproplst }
    traproplst:AddItem(vamatra)

    local vamcen = xlib.makecheckbox { label = "ttt_vampire_convert_enable (def. 0)", repconvar = "rep_ttt_vampire_convert_enable", parent = traproplst }
    traproplst:AddItem(vamcen)

    local vamden = xlib.makecheckbox { label = "ttt_vampire_drain_enable (def. 1)", repconvar = "rep_ttt_vampire_drain_enable", parent = traproplst }
    traproplst:AddItem(vamden)

    local vamft = xlib.makeslider { label = "ttt_vampire_fang_timer (def. 5)", min = 1, max = 30, repconvar = "rep_ttt_vampire_fang_timer", parent = traproplst }
    traproplst:AddItem(vamft)

    local vamfh = xlib.makeslider { label = "ttt_vampire_fang_heal (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_vampire_fang_heal", parent = traproplst }
    traproplst:AddItem(vamfh)

    local vamfoh = xlib.makeslider { label = "ttt_vampire_fang_overheal (def. 25)", min = 0, max = 100, repconvar = "rep_ttt_vampire_fang_overheal", parent = traproplst }
    traproplst:AddItem(vamfoh)

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

    local parlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Parasite settings:", parent = traproplst }
    traproplst:AddItem(parlbl)

    local partim = xlib.makeslider { label = "ttt_parasite_infection_time (def. 90)", min = 0, max = 300, repconvar = "rep_ttt_parasite_infection_time", parent = traproplst }
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
end

local function AddInnocentProperties(gppnl)
    local innpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    innpropclp:SetSize(390, 700)
    innpropclp:SetExpanded(1)
    innpropclp:SetLabel("Innocent Properties")

    local innproplst = vgui.Create("DPanelList", innpropclp)
    innproplst:SetPos(5, 25)
    innproplst:SetSize(390, 700)
    innproplst:SetSpacing(5)

    local detlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Detective settings:", parent = innproplst }
    innproplst:AddItem(detlbl)

    local detsch = xlib.makecheckbox { label = "ttt_detective_search_only (def. 1)", repconvar = "rep_ttt_detective_search_only", parent = innproplst }
    innproplst:AddItem(detsch)

    local prsrch = xlib.makecheckbox { label = "ttt_all_search_postround (def. 1)", repconvar = "rep_ttt_all_search_postround", parent = innproplst }
    innproplst:AddItem(prsrch)

    local glilbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Glitch settings:", parent = innproplst }
    innproplst:AddItem(glilbl)

    local glimo = xlib.makeslider { label = "ttt_glitch_mode (def. 0)", min = 0, max = 2, repconvar = "rep_ttt_glitch_mode", parent = innproplst }
    innproplst:AddItem(glimo)

    local phalbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Phantom settings:", parent = innproplst }
    innproplst:AddItem(phalbl)

    local phrh = xlib.makeslider { label = "ttt_phantom_respawn_health (def. 50)", min = 1, max = 100, repconvar = "rep_ttt_phantom_respawn_health", parent = innproplst }
    innproplst:AddItem(phrh)

    local phwer = xlib.makecheckbox { label = "ttt_phantom_weaker_each_respawn (def. 0)", repconvar = "rep_ttt_phantom_weaker_each_respawn", parent = innproplst }
    innproplst:AddItem(phwer)

    local phks = xlib.makecheckbox { label = "ttt_phantom_killer_smoke (def. 0)", repconvar = "rep_ttt_phantom_killer_smoke", parent = innproplst }
    innproplst:AddItem(phks)

    local phad = xlib.makecheckbox { label = "ttt_phantom_announce_death (def. 0)", repconvar = "rep_ttt_phantom_announce_death", parent = innproplst }
    innproplst:AddItem(phad)

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

    local phkft = xlib.makeslider { label = "ttt_phantom_killer_footstep_time (def. 0)", min = 1, max = 60, repconvar = "rep_ttt_phantom_killer_footstep_time", parent = innproplst }
    innproplst:AddItem(phkft)

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

    local doclbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Doctor settings:", parent = innproplst }
    innproplst:AddItem(doclbl)

    local docmode = xlib.makeslider { label = "ttt_doctor_mode (def. 0)", min = 0, max = 1, repconvar = "rep_ttt_doctor_mode", parent = innproplst }
    innproplst:AddItem(docmode)
end

local function AddJesterRoleProperties(gppnl)
    local jespropclp = vgui.Create("DCollapsibleCategory", gppnl)
    jespropclp:SetSize(390, 720)
    jespropclp:SetExpanded(1)
    jespropclp:SetLabel("Jester Properties")

    local jesproplst = vgui.Create("DPanelList", jespropclp)
    jesproplst:SetPos(5, 25)
    jesproplst:SetSize(390, 720)
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

    local closti = xlib.makecheckbox { label = "ttt_clown_show_target_icon (def. 0)", repconvar = "rep_ttt_clown_show_target_icon", parent = jesproplst }
    jesproplst:AddItem(closti)

    local clohoa = xlib.makecheckbox { label = "ttt_clown_heal_on_activate (def. 0)", repconvar = "rep_ttt_clown_heal_on_activate", parent = jesproplst }
    jesproplst:AddItem(clohoa)

    local closao = xlib.makecheckbox { label = "ttt_clown_shop_active_only (def. 1)", repconvar = "rep_ttt_clown_shop_active_only", parent = jesproplst }
    jesproplst:AddItem(closao)

    local closd = xlib.makecheckbox { label = "ttt_clown_shop_delay (def. 0)", repconvar = "rep_ttt_clown_shop_delay", parent = jesproplst }
    jesproplst:AddItem(closd)

    local beglbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Beggar settings:", parent = jesproplst }
    jesproplst:AddItem(beglbl)

    local begrevt = xlib.makeslider { label = "ttt_beggar_reveal_traitor (def. 1)", min = 0, max = 3, repconvar = "rep_ttt_beggar_reveal_traitor", parent = jesproplst }
    jesproplst:AddItem(begrevt)

    local begrevi = xlib.makeslider { label = "ttt_beggar_reveal_innocent (def. 2)", min = 0, max = 3, repconvar = "rep_ttt_beggar_reveal_innocent", parent = jesproplst }
    jesproplst:AddItem(begrevi)

    local begres = xlib.makecheckbox { label = "ttt_beggar_respawn (def. 0)", repconvar = "rep_ttt_beggar_respawn", parent = jesproplst }
    jesproplst:AddItem(begres)

    local begresd = xlib.makeslider { label = "ttt_beggar_respawn_delay (def. 3)", min = 0, max = 30, repconvar = "rep_ttt_beggar_respawn_delay", parent = jesproplst }
    jesproplst:AddItem(begresd)

    local begns = xlib.makecheckbox { label = "ttt_beggar_notify_sound (def. 0)", repconvar = "rep_ttt_beggar_notify_sound", parent = jesproplst }
    jesproplst:AddItem(begns)

    local begnc = xlib.makecheckbox { label = "ttt_beggar_notify_confetti (def. 0)", repconvar = "rep_ttt_beggar_notify_confetti", parent = jesproplst }
    jesproplst:AddItem(begnc)

    local bodlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Bodysnatcher settings:", parent = jesproplst }
    jesproplst:AddItem(bodlbl)

    local boddes = xlib.makecheckbox { label = "ttt_bodysnatcher_destroy_body (def. 0)", repconvar = "rep_ttt_bodysnatcher_destroy_body", parent = jesproplst }
    jesproplst:AddItem(boddes)

    local bodrol = xlib.makecheckbox { label = "ttt_bodysnatcher_show_role (def. 1)", repconvar = "rep_ttt_bodysnatcher_show_role", parent = jesproplst }
    jesproplst:AddItem(bodrol)
end

local function AddIndependentRoleProperties(gppnl)
    local indpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    indpropclp:SetSize(390, 705)
    indpropclp:SetExpanded(1)
    indpropclp:SetLabel("Independent Properties")

    local indproplst = vgui.Create("DPanelList", indpropclp)
    indproplst:SetPos(5, 25)
    indproplst:SetSize(390, 705)
    indproplst:SetSpacing(5)

    local indtes = xlib.makecheckbox { label = "ttt_independents_trigger_traitor_testers (def. 0)", repconvar = "rep_ttt_independents_trigger_traitor_testers", parent = indproplst }
    indproplst:AddItem(indtes)

    local drulbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Drunk settings:", parent = indproplst }
    indproplst:AddItem(drulbl)

    local drutim = xlib.makeslider { label = "ttt_drunk_sober_time (def. 180)", min = 0, max = 300, repconvar = "rep_ttt_drunk_sober_time", parent = indproplst }
    indproplst:AddItem(drutim)

    local druchn = xlib.makeslider { label = "ttt_drunk_innocent_chance (def. 0.7)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_drunk_innocent_chance", parent = indproplst }
    indproplst:AddItem(druchn)

    local oldlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Old Man settings:", parent = indproplst }
    indproplst:AddItem(oldlbl)

    local olddht = xlib.makeslider { label = "ttt_oldman_drain_health_to (def. 0)", min = 0, max = 200, repconvar = "rep_ttt_oldman_drain_health_to", parent = indproplst }
    indproplst:AddItem(olddht)

    local killbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Killer settings:", parent = indproplst }
    indproplst:AddItem(killbl)

    local kilken = xlib.makecheckbox { label = "ttt_killer_knife_enabled (def. 1)", repconvar = "rep_ttt_killer_knife_enabled", parent = indproplst }
    indproplst:AddItem(kilken)

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

    local zomtadmg = xlib.makeslider { label = "ttt_zombie_thrall_attack_damage (def. 45)", min = 1, max = 100, repconvar = "rep_ttt_zombie_thrall_attack_damage", parent = indproplst }
    indproplst:AddItem(zomtadmg)

    local zomtadel = xlib.makeslider { label = "ttt_zombie_thrall_attack_delay (def. 1.4)", min = 0.1, max = 3, decimal = 2, repconvar = "rep_ttt_zombie_thrall_attack_delay", parent = indproplst }
    indproplst:AddItem(zomtadel)

    local zomtsb = xlib.makeslider { label = "ttt_zombie_thrall_speed_bonus (def. 0.15)", min = 0, max = 1, decimal = 2, repconvar = "rep_ttt_zombie_thrall_speed_bonus", parent = indproplst }
    indproplst:AddItem(zomtsb)

    local zomve = xlib.makecheckbox { label = "ttt_zombie_vision_enable (def. 0)", repconvar = "rep_ttt_zombie_vision_enable", parent = indproplst }
    indproplst:AddItem(zomve)
end

local function AddCustomRoleProperties(gppnl)
    local crpropclp = vgui.Create("DCollapsibleCategory", gppnl)
    crpropclp:SetSize(390, 40)
    crpropclp:SetExpanded(1)
    crpropclp:SetLabel("Other Custom Role Properties")

    local crproplst = vgui.Create("DPanelList", crpropclp)
    crproplst:SetPos(5, 25)
    crproplst:SetSize(390, 40)
    crproplst:SetSpacing(5)

    local singdepimp = xlib.makecheckbox { label = "ttt_single_deputy_impersonator (def. 0)", repconvar = "rep_ttt_single_deputy_impersonator", parent = crproplst }
    crproplst:AddItem(singdepimp)

    local singdocqua = xlib.makecheckbox { label = "ttt_single_doctor_quack (def. 0)", repconvar = "rep_ttt_single_doctor_quack", parent = crproplst }
    crproplst:AddItem(singdocqua)
end

local function AddRoleShop(gppnl)
    local rspnl = vgui.Create("DCollapsibleCategory", gppnl)
    rspnl:SetSize(390, 980)
    rspnl:SetExpanded(0)
    rspnl:SetLabel("Role Shop")

    local rslst = vgui.Create("DPanelList", rspnl)
    rslst:SetPos(5, 25)
    rslst:SetSize(390, 980)
    rslst:SetSpacing(5)

    local rsp = xlib.makeslider { label = "ttt_shop_random_percent (def. 50)", min = 0, max = 100, repconvar = "rep_ttt_shop_random_percent", parent = rslst }
    rslst:AddItem(rsp)

    local rspos = xlib.makecheckbox { label = "ttt_shop_random_position (def. 0)", repconvar = "rep_ttt_shop_random_position", parent = rslst }
    rslst:AddItem(rspos)

    local tralbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Traitors:", parent = rslst }
    rslst:AddItem(tralbl)

    local rsptra = xlib.makeslider { label = "ttt_traitor_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_traitor_shop_random_percent", parent = rslst }
    rslst:AddItem(rsptra)

    local rsetra = xlib.makecheckbox { label = "ttt_traitor_shop_random_enabled (def. 0)", repconvar = "rep_ttt_traitor_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsetra)

    local rsphyp = xlib.makeslider { label = "ttt_hypnotist_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_hypnotist_shop_random_percent", parent = rslst }
    rslst:AddItem(rsphyp)

    local rsehyp = xlib.makecheckbox { label = "ttt_hypnotist_shop_random_enabled (def. 0)", repconvar = "rep_ttt_hypnotist_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsehyp)

    local rspimp = xlib.makeslider { label = "ttt_impersonator_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_impersonator_shop_random_percent", parent = rslst }
    rslst:AddItem(rspimp)

    local rseimp = xlib.makecheckbox { label = "ttt_impersonator_shop_random_enabled (def. 0)", repconvar = "rep_ttt_impersonator_shop_random_enabled", parent = rslst }
    rslst:AddItem(rseimp)

    local rspasn = xlib.makeslider { label = "ttt_assassin_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_assassin_shop_random_percent", parent = rslst }
    rslst:AddItem(rspasn)

    local rseasn = xlib.makecheckbox { label = "ttt_assassin_shop_random_enabled (def. 0)", repconvar = "rep_ttt_assassin_shop_random_enabled", parent = rslst }
    rslst:AddItem(rseasn)

    local rspvam = xlib.makeslider { label = "ttt_vampire_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_vampire_shop_random_percent", parent = rslst }
    rslst:AddItem(rspvam)

    local rsevam = xlib.makecheckbox { label = "ttt_vampire_shop_random_enabled (def. 0)", repconvar = "rep_ttt_vampire_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsevam)

    local rspqua = xlib.makeslider { label = "ttt_quack_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_quack_shop_random_percent", parent = rslst }
    rslst:AddItem(rspqua)

    local rsequa = xlib.makecheckbox { label = "ttt_quack_shop_random_enabled (def. 0)", repconvar = "rep_ttt_quack_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsequa)

    local rsppar = xlib.makeslider { label = "ttt_parasite_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_parasite_shop_random_percent", parent = rslst }
    rslst:AddItem(rsppar)

    local rsepar = xlib.makecheckbox { label = "ttt_parsite_shop_random_enabled (def. 0)", repconvar = "rep_ttt_parsite_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsepar)

    local rshsync = xlib.makecheckbox { label = "ttt_hypnotist_shop_sync (def. 0)", repconvar = "rep_ttt_hypnotist_shop_sync", parent = rslst }
    rslst:AddItem(rshsync)

    local rsisync = xlib.makecheckbox { label = "ttt_impersonator_shop_sync (def. 0)", repconvar = "rep_ttt_impersonator_shop_sync", parent = rslst }
    rslst:AddItem(rsisync)

    local rsasync = xlib.makecheckbox { label = "ttt_assassin_shop_sync (def. 0)", repconvar = "rep_ttt_assassin_shop_sync", parent = rslst }
    rslst:AddItem(rsasync)

    local rsvsync = xlib.makecheckbox { label = "ttt_vampire_shop_sync (def. 0)", repconvar = "rep_ttt_vampire_shop_sync", parent = rslst }
    rslst:AddItem(rsvsync)

    local rszsync = xlib.makecheckbox { label = "ttt_zombie_shop_sync (def. 0)", repconvar = "rep_ttt_zombie_shop_sync", parent = rslst }
    rslst:AddItem(rszsync)

    local rsqsync = xlib.makecheckbox { label = "ttt_quack_shop_sync (def. 0)", repconvar = "rep_ttt_quack_shop_sync", parent = rslst }
    rslst:AddItem(rsqsync)

    local rspsync = xlib.makecheckbox { label = "ttt_parasite_shop_sync (def. 0)", repconvar = "rep_ttt_parasite_shop_sync", parent = rslst }
    rslst:AddItem(rspsync)

    local innlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Innocents:", parent = rslst }
    rslst:AddItem(innlbl)

    local rspdet = xlib.makeslider { label = "ttt_detective_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_detective_shop_random_percent", parent = rslst }
    rslst:AddItem(rspdet)

    local rsedet = xlib.makecheckbox { label = "ttt_detective_shop_random_enabled (def. 0)", repconvar = "rep_ttt_detective_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsedet)

    local rspdep = xlib.makeslider { label = "ttt_deputy_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_deputy_shop_random_percent", parent = rslst }
    rslst:AddItem(rspdep)

    local rsedep = xlib.makecheckbox { label = "ttt_deputy_shop_random_enabled (def. 0)", repconvar = "rep_ttt_deputy_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsedep)

    local rspmer = xlib.makeslider { label = "ttt_mercenary_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_mercenary_shop_random_percent", parent = rslst }
    rslst:AddItem(rspmer)

    local rsemer = xlib.makecheckbox { label = "ttt_mercenary_shop_random_enabled (def. 0)", repconvar = "rep_ttt_mercenary_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsemer)

    local rsmmode = xlib.makeslider { label = "ttt_mercenary_shop_mode (def. 2)", min = 0, max = 4, repconvar = "rep_ttt_mercenary_shop_mode", parent = rslst }
    rslst:AddItem(rsmmode)

    local jeslbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Jesters:", parent = rslst }
    rslst:AddItem(jeslbl)

    local rspjes = xlib.makeslider { label = "ttt_jester_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_jester_shop_random_percent", parent = rslst }
    rslst:AddItem(rspjes)

    local rsejes = xlib.makecheckbox { label = "ttt_jester_shop_random_enabled (def. 0)", repconvar = "rep_ttt_jester_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsejes)

    local rspswa = xlib.makeslider { label = "ttt_swapper_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_swapper_shop_random_percent", parent = rslst }
    rslst:AddItem(rspswa)

    local rseswa = xlib.makecheckbox { label = "ttt_swapper_shop_random_enabled (def. 0)", repconvar = "rep_ttt_swapper_shop_random_enabled", parent = rslst }
    rslst:AddItem(rseswa)

    local rspclo = xlib.makeslider { label = "ttt_clown_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_clown_shop_random_percent", parent = rslst }
    rslst:AddItem(rspclo)

    local rseclo = xlib.makecheckbox { label = "ttt_clown_shop_random_enabled (def. 0)", repconvar = "rep_ttt_clown_shop_random_enabled", parent = rslst }
    rslst:AddItem(rseclo)

    local rscmode = xlib.makeslider { label = "ttt_clown_shop_mode (def. 0)", min = 0, max = 4, repconvar = "rep_ttt_clown_shop_mode", parent = rslst }
    rslst:AddItem(rscmode)

    local indlbl = xlib.makelabel { wordwrap = true, font = "DermaDefaultBold", label = "Independents:", parent = rslst }
    rslst:AddItem(indlbl)

    local rspkil = xlib.makeslider { label = "ttt_killer_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_killer_shop_random_percent", parent = rslst }
    rslst:AddItem(rspkil)

    local rsekil = xlib.makecheckbox { label = "ttt_killer_shop_random_enabled (def. 0)", repconvar = "rep_ttt_killer_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsekil)

    local rspzom = xlib.makeslider { label = "ttt_zombie_shop_random_percent (def. 0)", min = 0, max = 100, repconvar = "rep_ttt_zombie_shop_random_percent", parent = rslst }
    rslst:AddItem(rspzom)

    local rsezom = xlib.makecheckbox { label = "ttt_zombie_shop_random_enabled (def. 0)", repconvar = "rep_ttt_zombie_shop_random_enabled", parent = rslst }
    rslst:AddItem(rsezom)

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
    AddIndependentRoleSettings(gppnl)
    AddMonsterSettings(gppnl)
    AddRoleHealthSettings(gppnl)
    AddTraitorProperties(gppnl)
    AddInnocentProperties(gppnl)
    AddJesterRoleProperties(gppnl)
    AddIndependentRoleProperties(gppnl)
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

local function AddEquipmentCreditsModule()
    local ecpnl = xlib.makelistlayout { w = 415, h = 318, parent = xgui.null }

    --Traitor Credits
    local ectcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ectcclp:SetSize(390, 290)
    ectcclp:SetExpanded(1)
    ectcclp:SetLabel("Traitor Credits")

    local ectclst = vgui.Create("DPanelList", ectcclp)
    ectclst:SetPos(5, 25)
    ectclst:SetSize(390, 290)
    ectclst:SetSpacing(5)

    local ectccs = xlib.makeslider { label = "ttt_credits_starting (def. 2)", min = 0, max = 10, repconvar = "rep_ttt_credits_starting", parent = ectclst }
    ectclst:AddItem(ectccs)

    local ecthcs = xlib.makeslider { label = "ttt_hypnotist_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_hypnotist_credits_starting", parent = ectclst }
    ectclst:AddItem(ecthcs)

    local ectics = xlib.makeslider { label = "ttt_impersonator_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_impersonator_credits_starting", parent = ectclst }
    ectclst:AddItem(ectics)

    local ectacs = xlib.makeslider { label = "ttt_assassin_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_assassin_credits_starting", parent = ectclst }
    ectclst:AddItem(ectacs)

    local ecvccs = xlib.makeslider { label = "ttt_vampire_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_vampire_credits_starting", parent = ectclst }
    ectclst:AddItem(ecvccs)

    local ecqacs = xlib.makeslider { label = "ttt_quack_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_quack_credits_starting", parent = ectclst }
    ectclst:AddItem(ecqacs)

    local ecpccs = xlib.makeslider { label = "ttt_parasite_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_parasite_credits_starting", parent = ectclst }
    ectclst:AddItem(ecpccs)

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
    local ecdcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecdcclp:SetSize(390, 75)
    ecdcclp:SetExpanded(0)
    ecdcclp:SetLabel("Detective Credits")

    local ecdclst = vgui.Create("DPanelList", ecdcclp)
    ecdclst:SetPos(5, 25)
    ecdclst:SetSize(390, 75)
    ecdclst:SetSpacing(5)

    local ecdccs = xlib.makeslider { label = "ttt_det_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_starting", parent = ecdclst }
    ecdclst:AddItem(ecdccs)

    local ecdctk = xlib.makeslider { label = "ttt_det_credits_traitorkill (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitorkill", parent = ecdclst }
    ecdclst:AddItem(ecdctk)

    local ecdctd = xlib.makeslider { label = "ttt_det_credits_traitordead (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_det_credits_traitordead", parent = ecdclst }
    ecdclst:AddItem(ecdctd)

    --Jester Credits
    local ecjcclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecjcclp:SetSize(390, 50)
    ecjcclp:SetExpanded(0)
    ecjcclp:SetLabel("Jester Credits")

    local ecjclst = vgui.Create("DPanelList", ecjcclp)
    ecjclst:SetPos(5, 25)
    ecjclst:SetSize(390, 50)
    ecjclst:SetSpacing(5)

    local ecjccs = xlib.makeslider { label = "ttt_jester_credits_starting (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_jester_credits_starting", parent = ecjclst }
    ecjclst:AddItem(ecjccs)

    local ecsccs = xlib.makeslider { label = "ttt_swapper_credits_starting (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_swapper_credits_starting", parent = ecjclst }
    ecjclst:AddItem(ecsccs)

    --Other Credits
    local ecocclp = vgui.Create("DCollapsibleCategory", ecpnl)
    ecocclp:SetSize(390, 75)
    ecocclp:SetExpanded(0)
    ecocclp:SetLabel("Other Credits")

    local ecoclst = vgui.Create("DPanelList", ecocclp)
    ecoclst:SetPos(5, 25)
    ecoclst:SetSize(390, 75)
    ecoclst:SetSpacing(5)

    local ecmccs = xlib.makeslider { label = "ttt_mercenary_credits_starting (def. 1)", min = 0, max = 10, repconvar = "rep_ttt_mercenary_credits_starting", parent = ecoclst }
    ecoclst:AddItem(ecmccs)

    local eckccs = xlib.makeslider { label = "ttt_killer_credits_starting (def. 2)", min = 0, max = 10, repconvar = "rep_ttt_killer_credits_starting", parent = ecoclst }
    ecoclst:AddItem(eckccs)

    local eczccs = xlib.makeslider { label = "ttt_zombie_credits_starting (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_zombie_credits_starting", parent = ecoclst }
    ecoclst:AddItem(eczccs)

    local ecdccs = xlib.makeslider { label = "ttt_doctor_credits_starting (def. 0)", min = 0, max = 10, repconvar = "rep_ttt_doctor_credits_starting", parent = ecoclst }
    ecoclst:AddItem(ecdccs)

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

    local bemrow = xlib.makeslider { label = "ttt_ttt_bem_sv_rows (def. 5)", min = 1, max = 10, repconvar = "rep_ttt_bem_sv_rows", parent = bemlst }
    bemlst:AddItem(bemrow)

    local bemsize = xlib.makeslider { label = "ttt_bem_sv_size (def. 64)", min = 16, max = 128, repconvar = "rep_ttt_bem_sv_size", parent = bemlst }
    bemlst:AddItem(bemsize)

    local miscclp = vgui.Create("DCollapsibleCategory", miscpnl)
    miscclp:SetSize(390, 250)
    miscclp:SetExpanded(1)
    miscclp:SetLabel("Miscellaneous")

    local misclst = vgui.Create("DPanelList", miscclp)
    misclst:SetPos(5, 25)
    misclst:SetSize(390, 250)
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

    xgui.hookEvent("onProcessModules", nil, miscpnl.processModules)
    xgui.addSubModule("Miscellaneous", miscpnl, nil, "terrortown_settings")
end


AddRoundStructureModule()
AddGameplayModule()
AddKarmaModule()
AddMapModule()
AddEquipmentCreditsModule()
AddPlayerMovementModule()
AddPropPossessionModule()
AddAdminModule()
AddMiscModule()