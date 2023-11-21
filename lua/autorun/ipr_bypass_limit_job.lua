----------- // SCRIPT BY INJ3
----------- // SCRIPT BY INJ3
----------- // SCRIPT BY INJ3
---- // https://steamcommunity.com/id/Inj3/

--- Configuration / (Restart your server if you add new groups.)
local ipr = {
        ["Chef Pizza"] = { --- This is an example. // Add name of your job that will not be affected by the job limit.
            limit_reached = {
                ["superadmin"] = 0, --- '0' has no limit to access a job if it's full.
                ["vip"] = 1, --- Add an extra slot to your job for the specified group.
                ["admin"] = 1,
            }
        },

        ["Commissaire"] = { --- This is an example.
            limit_reached = {
                ["superadmin"] = 0,
                ["vip"] = 1,
                ["admin"] = 5,
            }
        },

        ["Vendeur d'armes"] = { --- This is an example.
            limit_reached = {
                ["superadmin"] = 0,
                ["vip"] = 1,
                ["admin"] = 2,
                ["vip +"] = 2,
            }
        },
}
---

---- // Do not touch the code below at the risk of breaking the gamemode ! 
if (CLIENT) then
    ipr_ovr_jb = ipr_ovr_jb or {}

    function ipr_ovr_jb.f_maxjob(t) --- function for the F4 menu, check the description on github to know how it works (if '-1' you have not correctly added the player table RPExtraTeams !)
        return (t and (t.max_fk or t.max)) or -1
    end

    local function ipr_init_func()
        local ipr_player = LocalPlayer()
        if not IsValid(ipr_player) then
            return
        end

        local ipr_grp = ipr_player:GetUserGroup()
        if (not ipr_ovr_jb.grp or (ipr_grp ~= ipr_ovr_jb.grp)) then

            for _, t in ipairs(RPExtraTeams) do
                if (t.max_fk) then
                    t.max = t.max_fk
                    t.max_fk = nil
                end

                local ipr_n = ipr[t.name]
                if not ipr_n then
                   continue
                end
                local ipr_g = ipr_n.limit_reached[ipr_grp]
                if not ipr_g then
                   continue
                end

                t.max_fk = t.max
                t.max = (ipr_g == 0) and 0 or t.max + ipr_g
            end

            ipr_ovr_jb.grp = ipr_grp
        end
    end

    net.Receive("ipr_update_job_ov", ipr_init_func)
    hook.Add("InitPostEntity", "ipr_override_darkrp_job", ipr_init_func)
else   
    local function ipr_check(j, n, g)
        for t, f in pairs(j) do
            if (t ~= n) then
               continue
            end
            for p in pairs(f.limit_reached) do
                if (p ~= g) then
                   continue
                end
                return true
            end
            break
        end
        return false
    end

    local function ipr_init_func()
        local ipr_meta, ipr_meta_n = FindMetaTable("Player"), {["ChangeTeam"] = true, ["changeTeam"] = true}

        do
            local function ipr_update_call(p)
                net.Start("ipr_update_job_ov")
                net.Send(p)
            end

            local ipr_cache, ipr_act = ipr_meta.SetUserGroup, "ipr_ovr_job_up"
            ipr_meta.SetUserGroup = function(s, str)
                local ipr_ac = s:SteamID64()

                if timer.Exists(ipr_act ..ipr_ac) then
                    timer.Remove(ipr_act ..ipr_ac)
                end
                timer.Create(ipr_act ..ipr_ac, 0.2, 1, function()
                    if IsValid(s) then
                        ipr_update_call(s)
                    end
                end)

                ipr_cache(s, str)
            end
        end

        for n in pairs(ipr_meta) do
            if not ipr_meta_n[n] then
               continue
            end
            local ipr_cache = ipr_meta[n]
            ipr_meta[n] = function(s, id, f, v, g)
                local ipr_t, ipr_grp = team.GetName(id), s:GetUserGroup()

                if (not f and ipr_check(ipr, ipr_t, ipr_grp)) then
                    local ipr_f = ipr[ipr_t].limit_reached[ipr_grp]

                    for _, t in ipairs(RPExtraTeams) do
                        if (t.name ~= ipr_t) then
                            continue
                        end
                        local tbl_cache = t.max
                        t.max = (ipr_f == 0) and 0 or t.max + ipr_f

                        ipr_cache(s, id, f, v, g)
                        t.max = tbl_cache
                        break                        
                    end
                    return
                end
                ipr_cache(s, id, f, v, g)
            end
        end
    end

    util.AddNetworkString("ipr_update_job_ov")
    hook.Add("InitPostEntity", "ipr_override_darkrp_job", ipr_init_func)
    print("Bypass Job limit DarkRP v2.1 by Inj3 loaded !")
end
