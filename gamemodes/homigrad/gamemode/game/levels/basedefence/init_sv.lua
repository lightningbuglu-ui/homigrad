local npcs = {
    "npc_combine_s",
}

local NPC_MODEL = "models/combine_soldier.mdl"

function basedefence.SpawnGred()
    for i,point in pairs(ReadDataMap("basedefencegred")) do
        local ent = ents.Create("gred_emp_dshk")
        ent:SetPos(point[1])
		ent:SetAngles(point[2])
		ent:Spawn()
    end

    for i,point in pairs(ReadDataMap("basedefencegred_ammo")) do
        local ent = ents.Create("gred_ammobox")
        ent:SetPos(point[1])
		ent:SetAngles(point[2])
		ent:Spawn()
    end

    for i,point in pairs(ReadDataMap("gred_simfphys_brdm2")) do
        local ent = ents.Create("gred_simfphys_brdm2")
        ent:SetPos(point[1])
		ent:SetAngles(point[2])
		ent:Spawn()
    end
end

local models = {}
for i = 1,9 do models[#models + 1] = "models/player/group03/male_0" .. i .. ".mdl" end
for i = 1,6 do models[#models + 1] = "models/player/group03/female_0" .. i .. ".mdl" end

basedefence.models = models

function basedefence.StartRoundSV()
    tdm.RemoveItems()

	roundTimeStart = CurTime()
	roundTime = 60 * (2 + math.min(#player.GetAll() / 4,2))

    local players = PlayersInGame()
    for i,ply in pairs(players) do ply:SetTeam(1) end

    local spawnsT,spawnsCT = tdm.SpawnsTwoCommand()
    local botsspawns = ReadDataMap("basedefencebots")
    table.Merge(botsspawns,ReadDataMap("blue"))

    local playerspawns = ReadDataMap("basedefenceplayerspawns")
    local boxspawn = ReadDataMap("boxspawn")

    basedefence.SpawnGred()

    if #botsspawns == 0 then botsspawns = spawnsCT end
    if #playerspawns == 0 then playerspawns = spawnsT end
    if #boxspawn == 0 then boxspawn = spawnsT end

    tdm.SpawnCommand(team.GetPlayers(1),playerspawns)

    local count,countBox = 0,0

    timer.Create("BD_npcwave", 60, 0, function()
        local plys = team.GetPlayers(1)
        if #plys == 0 or #botsspawns == 0 then return end

        for i = 1,#botsspawns - count do
            local bot = ents.Create(table.Random(npcs))
            if not IsValid(bot) then continue end

            -- npc_combine_s does not always receive its model when spawned by
            -- custom gamemode code. Set it before and after Spawn so the
            -- networked model is available to clients immediately.
            bot:SetModel(NPC_MODEL)

            local point = ReadPoint(botsspawns[math.random(#botsspawns)])
            if not point then
                bot:Remove()
                continue
            end

            bot:SetPos(point[1])
            bot:Spawn()
            bot:Activate()
            bot:SetModel(NPC_MODEL)

            local wep = ents.Create("weapon_sar2")
            if IsValid(wep) then
                wep:Spawn()
                bot:PickupWeapon(wep)
            end

            count = count + 1
            bot:UpdateEnemyMemory(plys[math.random(#plys)],bot:GetPos())

            local botIndex = bot:EntIndex()
            timer.Create("botsupdatemem" .. botIndex,20,0,function()
                if not IsValid(bot) then
                    timer.Remove("botsupdatemem" .. botIndex)
                    return
                end

                local currentPlayers = team.GetPlayers(1)
                if #currentPlayers > 0 then
                    local ply = currentPlayers[math.random(#currentPlayers)]
                    if IsValid(ply) then bot:UpdateEnemyMemory(ply,ply:GetPos()) end
                end
            end)

            bot:CallOnRemove("botdead",function()
                count = math.max(count - 1, 0)
                timer.Remove("botsupdatemem" .. botIndex)
            end)
        end

        for i = 1, #boxspawn - countBox do
            local box = ents.Create("prop_physics")
            box:SetModel("models/props_junk/wood_crate001a.mdl")

            local point = ReadPoint(boxspawn[math.random(#boxspawn)])
            if not point then
                box:Remove()
                continue
            end

            box:SetPos(point[1] + Vector(0,0,50))
            box:Spawn()

            countBox = countBox + 1
            box:CallOnRemove("boxdead",function() countBox = math.max(countBox - 1, 0) end)
        end
    end)

    tdm.CenterInit()

    return data
end

function basedefence.RoundEndCheck()
    tdm.Center()
    
    local Alive = tdm.GetCountLive(team.GetPlayers(1))

    if Alive == 0 then EndRound() return end

	if roundTimeStart + roundTime - CurTime() <= 0 then
        EndRound(1)
	end
end

function basedefence.EndRound(winner)
    if winner == 1 then
        PrintMessage(3,"Комбайны отступают.")
    else
        PrintMessage(3,"Комбайны нейтрализовали группу повстанцев.")
    end

    if timer.Exists("BD_npcwave") then timer.Remove("BD_npcwave") end
end

local wepeno = {
    "weapon_mp7",
    "weapon_sar2"
}

function basedefence.PlayerSpawn2(ply,teamID)
    if teamID == 2 then return end

	ply:SetModel(basedefence.models[math.random(#basedefence.models)])
    ply:SetPlayerColor(Color(math.random(55,165),math.random(55,165),math.random(55,165)):ToVector())

    ply:Give("weapon_hands")
    ply:Give("weapon_kabar")

    local wep = ply:Give("weapon_hk_usp")
    wep:SetClip1(wep:GetMaxClip1())
    ply:SetAmmo(wep:GetMaxClip1() * 3,wep:GetPrimaryAmmoType())

    local wep = ply:Give(table.Random(wepeno))
    wep:SetClip1(wep:GetMaxClip1())
    ply:SetAmmo(wep:GetMaxClip1() * 3,wep:GetPrimaryAmmoType())

    if math.random(3) == 3 then ply:Give("weapon_hammer") end

	if math.random(1,4) == 4 then ply:Give("adrenaline") end
	if math.random(1,4) == 4 then ply:Give("painkiller") end
	if math.random(1,4) == 4 then ply:Give("medkit") end
	if math.random(1,4) == 4 then ply:Give("med_band_big") end
	if math.random(1,4) == 4 then ply:Give("morphine") end

	local r = math.random(1,3)
	ply:Give(r == 1 and "food_fishcan" or r == 2 and "food_spongebob_home" or r == 3 and "food_lays")

	if math.random(1,3) == 3 then ply:Give("food_monster") end
	if math.random(1,5) == 5 then ply:Give("weapon_bat") end
end

function basedefence.PlayerInitialSpawn(ply) ply:SetTeam(1) end

function basedefence.PlayerCanJoinTeam(ply,teamID)
	if teamID == 3 then ply:ChatPrint("пашол нахуй") return false end
    if teamID == 2 then
        ply:ChatPrint("пашол нахуй")

        return false
    end

    return true
end

function basedefence.PlayerDeath(ply,inf,att) return false end

function basedefence.SpectateNPC(ply,npc)
    if npc:GetClass() == "npc_combine_s" then
        ply:SetTeam(2)
        ply:Spawn()
        ply:SetPos(npc:GetPos())
        npc:Remove()

        ply:SetPlayerClass("combine")

		for i,ent in pairs(ents.GetAll())do
            if ent:IsNPC() then
                ent:AddEntityRelationship(ply,D_LI,99)
            end
        end
    end
end
