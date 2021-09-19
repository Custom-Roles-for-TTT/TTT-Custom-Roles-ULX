util.AddNetworkString("ULX_CRCVarRequest")

local function CreateReplicatedWritableCvar(convar)
    ULib.replicatedWritableCvar(convar, "rep_" .. convar, GetConVar(convar):GetString(), false, false, "xgui_gmsettings")
end

local function AddRoleCreditConVar(role)
    -- Add explicit ROLE_INNOCENT exclusion here in case shop-for-all is enabled
    if not DEFAULT_ROLES[role] or role == ROLE_INNOCENT then
        local rolestring = ROLE_STRINGS_RAW[role]
        CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_credits_starting")
    end
end

local function AddRoleShopConVars(role)
    local rolestring = ROLE_STRINGS_RAW[role]
    CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_shop_random_percent")
    CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_shop_random_enabled")

    AddRoleCreditConVar(role)

    local sync_cvar = "ttt_" .. rolestring .. "_shop_sync"
    if ConVarExists(sync_cvar) then
        CreateReplicatedWritableCvar(sync_cvar)
    end

    local mode_cvar = "ttt_" .. rolestring .. "_shop_mode"
    if ConVarExists(mode_cvar) then
        CreateReplicatedWritableCvar(mode_cvar)
    end

    local active_cvar = "ttt_" .. rolestring .. "_shop_active_only"
    if ConVarExists(active_cvar) then
        CreateReplicatedWritableCvar(active_cvar)
    end

    local delay_cvar = "ttt_" .. rolestring .. "_shop_delay"
    if ConVarExists(delay_cvar) then
        CreateReplicatedWritableCvar(delay_cvar)
    end
end

local function init()
    if GetConVar("gamemode"):GetString() == "terrortown" then --Only execute the following code if it's a terrortown gamemode
        --Preparation and post-round
        CreateReplicatedWritableCvar("ttt_preptime_seconds")
        CreateReplicatedWritableCvar("ttt_firstpreptime")
        CreateReplicatedWritableCvar("ttt_posttime_seconds")

        --Round length
        CreateReplicatedWritableCvar("ttt_haste")
        CreateReplicatedWritableCvar("ttt_haste_starting_minutes")
        CreateReplicatedWritableCvar("ttt_haste_minutes_per_death")
        CreateReplicatedWritableCvar("ttt_roundtime_minutes")

        --map switching and voting
        CreateReplicatedWritableCvar("ttt_round_limit")
        CreateReplicatedWritableCvar("ttt_time_limit_minutes")

        --traitor and detective counts
        CreateReplicatedWritableCvar("ttt_traitor_pct")
        CreateReplicatedWritableCvar("ttt_traitor_max")
        CreateReplicatedWritableCvar("ttt_detective_pct")
        CreateReplicatedWritableCvar("ttt_detective_max")
        CreateReplicatedWritableCvar("ttt_detective_min_players")
        CreateReplicatedWritableCvar("ttt_detective_karma_min")

        --role spawn parameters
        CreateReplicatedWritableCvar("ttt_special_traitor_pct")
        CreateReplicatedWritableCvar("ttt_special_traitor_chance")
        CreateReplicatedWritableCvar("ttt_special_innocent_pct")
        CreateReplicatedWritableCvar("ttt_special_innocent_chance")
        CreateReplicatedWritableCvar("ttt_special_detective_pct")
        CreateReplicatedWritableCvar("ttt_special_detective_chance")
        CreateReplicatedWritableCvar("ttt_independent_chance")
        CreateReplicatedWritableCvar("ttt_jester_chance")
        CreateReplicatedWritableCvar("ttt_monster_pct")
        CreateReplicatedWritableCvar("ttt_monster_chance")

        for role = 0, ROLE_MAX do
            local rolestring = ROLE_STRINGS_RAW[role]
            if not DEFAULT_ROLES[role] then
                CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_enabled")
                CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_spawn_weight")
                CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_min_players")
            end
            CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_starting_health")
            CreateReplicatedWritableCvar("ttt_" .. rolestring .. "_max_health")

            if role ~= ROLE_DRUNK and role ~= ROLE_GLITCH then
                CreateReplicatedWritableCvar("ttt_drunk_can_be_" .. rolestring)
            end
        end

        --traitor properties
        CreateReplicatedWritableCvar("ttt_traitor_vision_enable")
        CreateReplicatedWritableCvar("ttt_impersonator_damage_penalty")
        CreateReplicatedWritableCvar("ttt_impersonator_use_detective_icon")
        CreateReplicatedWritableCvar("ttt_impersonator_without_detective")
        CreateReplicatedWritableCvar("ttt_hypnotist_device_loadout")
        CreateReplicatedWritableCvar("ttt_hypnotist_device_shop")
        CreateReplicatedWritableCvar("ttt_hypnotist_convert_detectives")
        CreateReplicatedWritableCvar("ttt_assassin_show_target_icon")
        CreateReplicatedWritableCvar("ttt_assassin_target_vision_enable")
        CreateReplicatedWritableCvar("ttt_assassin_next_target_delay")
        CreateReplicatedWritableCvar("ttt_assassin_target_damage_bonus")
        CreateReplicatedWritableCvar("ttt_assassin_wrong_damage_penalty")
        CreateReplicatedWritableCvar("ttt_assassin_failed_damage_penalty")
        CreateReplicatedWritableCvar("ttt_assassin_shop_roles_last")
        CreateReplicatedWritableCvar("ttt_vampires_are_monsters")
        CreateReplicatedWritableCvar("ttt_vampires_are_independent")
        CreateReplicatedWritableCvar("ttt_vampire_show_target_icon")
        CreateReplicatedWritableCvar("ttt_vampire_damage_reduction")
        CreateReplicatedWritableCvar("ttt_vampire_convert_enable")
        CreateReplicatedWritableCvar("ttt_vampire_drain_enable")
        CreateReplicatedWritableCvar("ttt_vampire_drain_first")
        CreateReplicatedWritableCvar("ttt_vampire_fang_timer")
        CreateReplicatedWritableCvar("ttt_vampire_fang_dead_timer")
        CreateReplicatedWritableCvar("ttt_vampire_fang_heal")
        CreateReplicatedWritableCvar("ttt_vampire_fang_overheal")
        CreateReplicatedWritableCvar("ttt_vampire_prime_death_mode")
        CreateReplicatedWritableCvar("ttt_vampire_prime_only_convert")
        CreateReplicatedWritableCvar("ttt_vampire_vision_enable")
        CreateReplicatedWritableCvar("ttt_quack_fake_cure_mode")
        CreateReplicatedWritableCvar("ttt_parasite_infection_time")
        CreateReplicatedWritableCvar("ttt_parasite_infection_transfer")
        CreateReplicatedWritableCvar("ttt_parasite_infection_transfer_reset")
        CreateReplicatedWritableCvar("ttt_parasite_infection_suicide_mode")
        CreateReplicatedWritableCvar("ttt_parasite_respawn_mode")
        CreateReplicatedWritableCvar("ttt_parasite_respawn_health")
        CreateReplicatedWritableCvar("ttt_parasite_announce_infection")
        CreateReplicatedWritableCvar("ttt_parasite_cure_mode")

        --innocent properties
        CreateReplicatedWritableCvar("ttt_glitch_mode")
        CreateReplicatedWritableCvar("ttt_glitch_use_traps")
        CreateReplicatedWritableCvar("ttt_phantom_respawn_health")
        CreateReplicatedWritableCvar("ttt_phantom_weaker_each_respawn")
        CreateReplicatedWritableCvar("ttt_phantom_announce_death")
        CreateReplicatedWritableCvar("ttt_phantom_killer_smoke")
        CreateReplicatedWritableCvar("ttt_phantom_killer_footstep_time")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_power_max")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_power_rate")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_move_cost")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_attack_cost")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_jump_cost")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_drop_cost")
        CreateReplicatedWritableCvar("ttt_phantom_killer_haunt_without_body")
        CreateReplicatedWritableCvar("ttt_revenger_radar_timer")
        CreateReplicatedWritableCvar("ttt_revenger_damage_bonus")
        CreateReplicatedWritableCvar("ttt_revenger_drain_health_to")
        CreateReplicatedWritableCvar("ttt_deputy_damage_penalty")
        CreateReplicatedWritableCvar("ttt_deputy_use_detective_icon")
        CreateReplicatedWritableCvar("ttt_deputy_without_detective")
        CreateReplicatedWritableCvar("ttt_veteran_damage_bonus")
        CreateReplicatedWritableCvar("ttt_veteran_full_heal")
        CreateReplicatedWritableCvar("ttt_veteran_heal_bonus")
        CreateReplicatedWritableCvar("ttt_veteran_announce")
        CreateReplicatedWritableCvar("ttt_paramedic_device_loadout")
        CreateReplicatedWritableCvar("ttt_paramedic_device_shop")
        CreateReplicatedWritableCvar("ttt_paramedic_defib_as_innocent")

        --detective properties
        CreateReplicatedWritableCvar("ttt_detective_search_only")
        CreateReplicatedWritableCvar("ttt_detective_disable_looting")
        CreateReplicatedWritableCvar("ttt_all_search_postround")
        CreateReplicatedWritableCvar("ttt_all_search_binoc")
        CreateReplicatedWritableCvar("ttt_paladin_aura_radius")
        CreateReplicatedWritableCvar("ttt_paladin_damage_reduction")
        CreateReplicatedWritableCvar("ttt_paladin_heal_rate")
        CreateReplicatedWritableCvar("ttt_paladin_protect_self")
        CreateReplicatedWritableCvar("ttt_paladin_heal_self")
        CreateReplicatedWritableCvar("ttt_tracker_footstep_time")
        CreateReplicatedWritableCvar("ttt_tracker_footstep_color")
        CreateReplicatedWritableCvar("ttt_medium_spirit_color")

        --jester properties
        CreateReplicatedWritableCvar("ttt_jesters_trigger_traitor_testers")
        CreateReplicatedWritableCvar("ttt_jesters_visible_to_traitors")
        CreateReplicatedWritableCvar("ttt_jesters_visible_to_monsters")
        CreateReplicatedWritableCvar("ttt_jesters_visible_to_independents")
        CreateReplicatedWritableCvar("ttt_jester_win_by_traitors")
        CreateReplicatedWritableCvar("ttt_jester_notify_mode")
        CreateReplicatedWritableCvar("ttt_jester_notify_sound")
        CreateReplicatedWritableCvar("ttt_jester_notify_confetti")
        CreateReplicatedWritableCvar("ttt_swapper_respawn_health")
        CreateReplicatedWritableCvar("ttt_swapper_weapon_mode")
        CreateReplicatedWritableCvar("ttt_swapper_notify_mode")
        CreateReplicatedWritableCvar("ttt_swapper_notify_sound")
        CreateReplicatedWritableCvar("ttt_swapper_notify_confetti")
        CreateReplicatedWritableCvar("ttt_swapper_killer_health")
        CreateReplicatedWritableCvar("ttt_clown_damage_bonus")
        CreateReplicatedWritableCvar("ttt_clown_activation_credits")
        CreateReplicatedWritableCvar("ttt_clown_hide_when_active")
        CreateReplicatedWritableCvar("ttt_clown_show_target_icon")
        CreateReplicatedWritableCvar("ttt_clown_heal_on_activate")
        CreateReplicatedWritableCvar("ttt_clown_heal_bonus")
        CreateReplicatedWritableCvar("ttt_clown_shop_active_only")
        CreateReplicatedWritableCvar("ttt_clown_shop_delay")
        CreateReplicatedWritableCvar("ttt_beggar_reveal_traitor")
        CreateReplicatedWritableCvar("ttt_beggar_reveal_innocent")
        CreateReplicatedWritableCvar("ttt_beggar_respawn")
        CreateReplicatedWritableCvar("ttt_beggar_respawn_delay")
        CreateReplicatedWritableCvar("ttt_beggar_notify_mode")
        CreateReplicatedWritableCvar("ttt_beggar_notify_sound")
        CreateReplicatedWritableCvar("ttt_beggar_notify_confetti")
        CreateReplicatedWritableCvar("ttt_bodysnatchers_are_independent")
        CreateReplicatedWritableCvar("ttt_bodysnatcher_destroy_body")
        CreateReplicatedWritableCvar("ttt_bodysnatcher_show_role")

        --independent properties
        CreateReplicatedWritableCvar("ttt_independents_trigger_traitor_testers")
        CreateReplicatedWritableCvar("ttt_drunk_sober_time")
        CreateReplicatedWritableCvar("ttt_drunk_innocent_chance")
        CreateReplicatedWritableCvar("ttt_drunk_any_role")
        CreateReplicatedWritableCvar("ttt_drunk_become_clown")
        CreateReplicatedWritableCvar("ttt_drunk_notify_mode")
        CreateReplicatedWritableCvar("ttt_oldman_drain_health_to")
        CreateReplicatedWritableCvar("ttt_oldman_adrenaline_rush")
        CreateReplicatedWritableCvar("ttt_oldman_adrenaline_shotgun")
        CreateReplicatedWritableCvar("ttt_killer_knife_enabled")
        CreateReplicatedWritableCvar("ttt_killer_smoke_enabled")
        CreateReplicatedWritableCvar("ttt_killer_smoke_timer")
        CreateReplicatedWritableCvar("ttt_killer_show_target_icon")
        CreateReplicatedWritableCvar("ttt_killer_damage_penalty")
        CreateReplicatedWritableCvar("ttt_killer_damage_reduction")
        CreateReplicatedWritableCvar("ttt_killer_warn_all")
        CreateReplicatedWritableCvar("ttt_killer_vision_enable")
        CreateReplicatedWritableCvar("ttt_zombies_are_monsters")
        CreateReplicatedWritableCvar("ttt_zombies_are_traitors")
        CreateReplicatedWritableCvar("ttt_zombie_round_chance")
        CreateReplicatedWritableCvar("ttt_zombie_spit_enable")
        CreateReplicatedWritableCvar("ttt_zombie_leap_enable")
        CreateReplicatedWritableCvar("ttt_zombie_show_target_icon")
        CreateReplicatedWritableCvar("ttt_zombie_damage_penalty")
        CreateReplicatedWritableCvar("ttt_zombie_damage_reduction")
        CreateReplicatedWritableCvar("ttt_zombie_prime_only_weapons")
        CreateReplicatedWritableCvar("ttt_zombie_prime_attack_damage")
        CreateReplicatedWritableCvar("ttt_zombie_prime_attack_delay")
        CreateReplicatedWritableCvar("ttt_zombie_prime_speed_bonus")
        CreateReplicatedWritableCvar("ttt_zombie_prime_convert_chance")
        CreateReplicatedWritableCvar("ttt_zombie_thrall_attack_damage")
        CreateReplicatedWritableCvar("ttt_zombie_thrall_attack_delay")
        CreateReplicatedWritableCvar("ttt_zombie_thrall_speed_bonus")
        CreateReplicatedWritableCvar("ttt_zombie_thrall_convert_chance")
        CreateReplicatedWritableCvar("ttt_zombie_vision_enable")

        --other custom role properties
        CreateReplicatedWritableCvar("ttt_single_deputy_impersonator")
        CreateReplicatedWritableCvar("ttt_deputy_impersonator_promote_any_death")
        CreateReplicatedWritableCvar("ttt_single_doctor_quack")
        CreateReplicatedWritableCvar("ttt_single_paramedic_hypnotist")
        CreateReplicatedWritableCvar("ttt_single_phantom_parasite")
        CreateReplicatedWritableCvar("ttt_single_jester_independent")

        --external role properties
        if ROLE_MAX >= ROLE_EXTERNAL_START then
            for role = ROLE_EXTERNAL_START, ROLE_MAX do
                if EXTERNAL_ROLE_CONVARS[role] then
                    for _, cvar in ipairs(EXTERNAL_ROLE_CONVARS[role]) do
                        CreateReplicatedWritableCvar(cvar.cvar)
                    end
                end
            end
        end

        --shop configs
        CreateReplicatedWritableCvar("ttt_shop_for_all")
        CreateReplicatedWritableCvar("ttt_shop_random_percent")
        CreateReplicatedWritableCvar("ttt_shop_random_position")
        local shop_roles = GetTeamRoles(SHOP_ROLES)
        for _, role in ipairs(shop_roles) do
            AddRoleShopConVars(role)
        end
        --add any convar replications that are missing once shop-for-all is enabled
        cvars.AddChangeCallback("ttt_shop_for_all", function(convar, oldValue, newValue)
            if tobool(newValue) then
                for role = 0, ROLE_MAX do
                    if not table.HasValue(shop_roles, role) then
                        AddRoleShopConVars(role)
                    end
                end
            end
        end)

        --replicate the starting credit convar for all roles that have credits but don't have a shop
        local shopless_credit_roles = table.ExcludedKeys(EXTERNAL_ROLE_STARTING_CREDITS, shop_roles)
        for _, role in ipairs(shopless_credit_roles) do
            AddRoleCreditConVar(role)
        end

        --dna
        CreateReplicatedWritableCvar("ttt_killer_dna_range")
        CreateReplicatedWritableCvar("ttt_killer_dna_basetime")

        --voicechat battery
        CreateReplicatedWritableCvar("ttt_voice_drain")
        CreateReplicatedWritableCvar("ttt_voice_drain_normal")
        CreateReplicatedWritableCvar("ttt_voice_drain_admin")
        CreateReplicatedWritableCvar("ttt_voice_drain_recharge")

        --other gameplay settings
        CreateReplicatedWritableCvar("ttt_minimum_players")
        CreateReplicatedWritableCvar("ttt_postround_dm")
        CreateReplicatedWritableCvar("ttt_dyingshot")
        CreateReplicatedWritableCvar("ttt_no_nade_throw_during_prep")
        CreateReplicatedWritableCvar("ttt_weapon_carrying")
        CreateReplicatedWritableCvar("ttt_weapon_carrying_range")
        CreateReplicatedWritableCvar("ttt_teleport_telefrags")
        CreateReplicatedWritableCvar("ttt_ragdoll_pinning")
        CreateReplicatedWritableCvar("ttt_ragdoll_pinning_innocents")

        --karma
        CreateReplicatedWritableCvar("ttt_karma")
        CreateReplicatedWritableCvar("ttt_karma_strict")
        CreateReplicatedWritableCvar("ttt_karma_starting")
        CreateReplicatedWritableCvar("ttt_karma_max")
        CreateReplicatedWritableCvar("ttt_karma_ratio")
        CreateReplicatedWritableCvar("ttt_karma_kill_penalty")
        CreateReplicatedWritableCvar("ttt_karma_round_increment")
        CreateReplicatedWritableCvar("ttt_karma_clean_bonus")
        CreateReplicatedWritableCvar("ttt_karma_traitordmg_ratio")
        CreateReplicatedWritableCvar("ttt_karma_traitorkill_bonus")
        CreateReplicatedWritableCvar("ttt_karma_jesterdmg_ratio")
        CreateReplicatedWritableCvar("ttt_karma_jesterkill_penalty")
        CreateReplicatedWritableCvar("ttt_karma_low_autokick")
        CreateReplicatedWritableCvar("ttt_karma_low_amount")
        CreateReplicatedWritableCvar("ttt_karma_low_ban")
        CreateReplicatedWritableCvar("ttt_karma_low_ban_minutes")
        CreateReplicatedWritableCvar("ttt_karma_persist")
        CreateReplicatedWritableCvar("ttt_karma_debugspam")
        CreateReplicatedWritableCvar("ttt_karma_clean_half")

        --map related
        CreateReplicatedWritableCvar("ttt_use_weapon_spawn_scripts")
        CreateReplicatedWritableCvar("ttt_weapon_spawn_count")

        --traitor credits
        CreateReplicatedWritableCvar("ttt_credits_starting")
        CreateReplicatedWritableCvar("ttt_credits_alonebonus")
        CreateReplicatedWritableCvar("ttt_credits_award_pct")
        CreateReplicatedWritableCvar("ttt_credits_award_size")
        CreateReplicatedWritableCvar("ttt_credits_award_repeat")
        CreateReplicatedWritableCvar("ttt_credits_detectivekill")

        --detective credits
        CreateReplicatedWritableCvar("ttt_det_credits_starting")
        CreateReplicatedWritableCvar("ttt_det_credits_traitorkill")
        CreateReplicatedWritableCvar("ttt_det_credits_traitordead")

        --other role credits are handled in the shop convar section so they can be dynamically created if shop-for-all is enabled

        --sprint
        CreateReplicatedWritableCvar("ttt_sprint_bonus_rel")
        CreateReplicatedWritableCvar("ttt_sprint_regenerate_innocent")
        CreateReplicatedWritableCvar("ttt_sprint_regenerate_traitor")
        CreateReplicatedWritableCvar("ttt_sprint_consume")

        --bem
        CreateReplicatedWritableCvar("ttt_bem_allow_change")
        CreateReplicatedWritableCvar("ttt_bem_sv_cols")
        CreateReplicatedWritableCvar("ttt_bem_sv_rows")
        CreateReplicatedWritableCvar("ttt_bem_sv_size")

        --prop possession
        CreateReplicatedWritableCvar("ttt_spec_prop_control")
        CreateReplicatedWritableCvar("ttt_spec_prop_base")
        CreateReplicatedWritableCvar("ttt_spec_prop_maxpenalty")
        CreateReplicatedWritableCvar("ttt_spec_prop_maxbonus")
        CreateReplicatedWritableCvar("ttt_spec_prop_force")
        CreateReplicatedWritableCvar("ttt_spec_prop_rechargetime")

        --admin related
        CreateReplicatedWritableCvar("ttt_idle_limit")
        CreateReplicatedWritableCvar("ttt_namechange_kick")
        CreateReplicatedWritableCvar("ttt_namechange_bantime")

        --misc
        CreateReplicatedWritableCvar("ttt_detective_hats")
        CreateReplicatedWritableCvar("ttt_playercolor_mode")
        CreateReplicatedWritableCvar("ttt_ragdoll_collide")
        CreateReplicatedWritableCvar("ttt_bots_are_spectators")
        CreateReplicatedWritableCvar("ttt_debug_preventwin")
        CreateReplicatedWritableCvar("ttt_debug_logkills")
        CreateReplicatedWritableCvar("ttt_debug_logroles")
        CreateReplicatedWritableCvar("ttt_locational_voice")
        CreateReplicatedWritableCvar("ttt_allow_discomb_jump")
        CreateReplicatedWritableCvar("ttt_spawn_wave_interval")
        CreateReplicatedWritableCvar("ttt_crowbar_unlocks")
        CreateReplicatedWritableCvar("ttt_crowbar_pushforce")

        --disable features
        CreateReplicatedWritableCvar("ttt_disable_headshots")
        CreateReplicatedWritableCvar("ttt_disable_mapwin")
    end
end

xgui.addSVModule("terrortown", init)

net.Receive("ULX_CRCVarRequest", function(len, ply)
    local missing_cvars = net.ReadTable()
    local cvar_data = {}
    for _, cv in ipairs(missing_cvars) do
        local convar = GetConVar(cv)
        if convar then
            cvar_data[cv] = {
                d = convar:GetDefault(),
                m = convar:GetMin(),
                x = convar:GetMax()
            }
        end
    end

    net.Start("ULX_CRCVarRequest")
    net.WriteTable(cvar_data)
    net.Send(ply)
end)