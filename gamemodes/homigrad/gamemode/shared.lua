DeriveGamemode("sandbox")

GM.Name = "Homigrad"
GM.Author = "Homigrad community"
GM.Email = "N/A"
GM.Website = "N/A"
GM.TeamBased = true

include("loader.lua")

local start = SysTime()
print("\tstart homigrad gamemode.")

GM.includeDir("homigrad/gamemode/game/")

hg.LoadModes()

print("\tend homigrad gamemode for " .. math.Round(SysTime() - start,4) .. "s")

function GM:CreateTeams()
	team.SetUp(1,"Join Game",Color(255,0,0))
	team.SetUp(2,"Team Two",Color(0,0,255))
	team.SetUp(3,"Team Three",Color(0,255,0))

	team.MaxTeams = 3
end

function OpposingTeam(team)
	if team == 1 then return 2 elseif team == 2 then return 1 end
end

function ReadPoint(point)
	if TypeID(point) == TYPE_VECTOR then
		return {point,Angle(0,0,0)}
	elseif type(point) == "table" then
		if type(point[2]) == "number" then
			point[3] = point[2]
			point[2] = Angle(0,0,0)
		end

		return point
	end
end

local team_GetPlayers = team.GetPlayers

function PlayersInGame()
    local newTbl = {}

    for i,ply in pairs(team_GetPlayers(1)) do table.insert(newTbl, ply) end
    for i,ply in pairs(team_GetPlayers(2)) do table.insert(newTbl, ply) end
    for i,ply in pairs(team_GetPlayers(3)) do table.insert(newTbl, ply) end

    return newTbl
end

function PlayersDead(noTraitors)
    local newTbl = PlayersInGame()
	local tbl2 = {}

    for i, ply in pairs(newTbl) do
		if noTraitors and ply.roleT then continue end
		if ply:Alive() then continue end

		table.insert(tbl2, ply)
	end

	return tbl2
end

function PlayersAlive()
    local newTbl = PlayersInGame()
	local tbl2 = {}

    for i, ply in pairs(newTbl) do
		if not ply:Alive() then continue end

		table.insert(tbl2, ply)
	end

	return tbl2
end
