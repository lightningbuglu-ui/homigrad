local red,green,white = Color(255,0,0),Color(0,255,0),Color(240,240,240)
local specColor = Color(155,155,155)
local whiteAdd = Color(255,255,255,5)
local unmutedicon = Material( "icon32/unmuted.png", "noclamp smooth" )
local mutedicon = Material( "icon32/muted.png", "noclamp smooth" )

local function ReadMuteStatusPlayers()
	return util.JSONToTable(file.Read("homigrad_mute.txt","DATA") or "") or {}
end

MutePlayers = ReadMuteStatusPlayers()

local function SaveMuteStatusPlayer(ply,value)
	if value == false then value = nil end
	MutePlayers[ply:SteamID()] = value
	file.Write("homigrad_mute.txt",util.TableToJSON(MutePlayers))
end

local function corter(a,b)
	return a:Team() < b:Team()
end

local grtodown = Material( "vgui/gradient-u" )
local grtoup = Material( "vgui/gradient-d" )
local grtoright = Material( "vgui/gradient-l" )
local grtoleft = Material( "vgui/gradient-r" )

muteallspectate = muteallspectate
mutealllives = mutealllives

local colorSpec = Color(155,155,155)
local colorRed = Color(205,55,55)
local colorGreen = Color(55,205,55)

ScoreboardRed = colorRed
ScoreboardSpec = colorSpec
ScoreboardGreen = colorGreen
ScoreboardBlack = Color(0,0,0,200)

ScoreboardList = ScoreboardList or {}

local function timeSort(a,b)
	local time1 = math.floor(CurTime() - (a.TimeStart or 0) + (a.Time or 0))
	local time2 = math.floor(CurTime() - (b.TimeStart or 0) + (b.Time or 0))

	return time1 > time2
end

hook.Add("Player Death","mutedead",function(ply)
	if muteAlldead and (not LocalPlayer():Alive() or ply:Team() == 1002) then
		ply:SetMuted(true)
	end
end)

hook.Add("Player Spawn","unmutealive",function(ply)
	if muteall then return end

	if muteAlldead then
		ply:SetMuted(MutePlayers[ply:SteamID()])
	end
end)

local function ToggleScoreboard(toggle)
	if toggle then
        if IsValid(HomigradScoreboard) then return end

		showRoundInfo = CurTime() + 2.5

		local scrw,scrh = ScrW(),ScrH()

		HomigradScoreboard = vgui.Create("DFrame")
		HomigradScoreboard:SetTitle("")
		HomigradScoreboard:SetSize(scrw*.7,scrh*.9)
		HomigradScoreboard:Center()
		HomigradScoreboard:ShowCloseButton(false)
		HomigradScoreboard:SetDraggable(false)
        HomigradScoreboard:MakePopup()
        HomigradScoreboard:SetKeyboardInputEnabled(false)
		ScoreboardList[HomigradScoreboard] = true

		local wheelY = 0
		local animWheelUp,animWheelDown = 0,0

		function HomigradScoreboard:Sort()
			local teams = {}
			local lives,deads = {},{}

			for ply in pairs(self.players) do
				ply.last = nil

				local teamID = ply:Team()
				teams[teamID] = teams[teamID] or {{},{}}
				teamID = teams[teamID]

				if ply:Alive() then
					teamID[1][#teamID[1] + 1] = ply
				else
					teamID[2][#teamID[2] + 1] = ply
				end
			end

			for teamID,list in pairs(teams) do
				table.sort(list[1],timeSort)
				table.sort(list[2],timeSort)
			end

			local sort = {}

			local func = TableRound().ScoreboardSort
			if func then
				func(sort)
			else
				for teamID,team in pairs(teams) do
					for i,ply in pairs(team[1]) do sort[#sort + 1] = ply end
					for i,ply in pairs(team[2]) do sort[#sort + 1] = ply end

					local last = team[1][#team[1]]
					if last then
						local func = TableRound().Scoreboard_DrawLast
						if func and func(last) ~= nil then continue end

						last.last = #team[1]
					end

					last = team[2][#team[2]]
					if last then
						local func = TableRound().Scoreboard_DrawLast
						if func and func(last) ~= nil then continue end

						last.last = #team[2]
					end
				end
			end

			self.sort = sort
		end

		HomigradScoreboard.players = {}
		HomigradScoreboard.delaySort = 0
		HomigradScoreboard.Paint = function(self,w,h)

			surface.SetDrawColor(15,15,15,200)
			surface.DrawRect(0,0,w,h)

			draw.SimpleText("Status","HomigradFont",100,15,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("Name","HomigradFont",w / 2,15,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

			draw.SimpleText("Homigrad","HomigradFontLarge",w / 2,h / 2,Color(155,155,165,50),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("Role","HomigradFont",w - 300,15,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("Ping","HomigradFont",w - 200,15,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("Team","HomigradFont",w - 100,15,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			draw.SimpleText("Players: " .. table.Count(player.GetAll()),"HomigradFont",15,h - 25,green,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			local tick = math.Round(1 / engine.ServerFrameTime())
			draw.SimpleText("Server Tickrate: " .. tick,"HomigradFont",w - 15,h - 25,tick <= 35 and red or green,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)

			local players = self.players
			for i,ply in player.Iterator() do
				if not players[ply] then self:AddPlayer(ply) self:Sort() end
			end

			for ply,panel in pairs(players) do
				if IsValid(ply) then continue end

				players[ply] = nil
				panel:Remove()

				self:Sort()
			end

			if self.delaySort < CurTime() then
				self.delaySort = CurTime() + 1 / 10

				self:Sort()
			end

			surface.SetMaterial(grtodown)
			surface.SetDrawColor(125,125,155,math.min(animWheelUp * 255,10))
			surface.DrawTexturedRect(0,0,w,animWheelUp)

			surface.SetMaterial(grtoup)
			surface.SetDrawColor(125,125,155,math.min(animWheelDown * 255,10))
			surface.DrawTexturedRect(0,h - animWheelDown,w,animWheelDown)

			local lerp = math.max(FrameTime() / (1 / 60) * 0.1,0)
			animWheelUp = Lerp(lerp,animWheelUp,0)
			animWheelDown = Lerp(lerp,animWheelDown,0)

			local yPos = -wheelY
			local sort = self.sort
			for i,ply in pairs(sort) do
				ply:SetMuted(MutePlayers[ply:SteamID()])

				if muteall then ply:SetMuted(true) end

				if muteAlldead and not ply:Alive() and (not LocalPlayer():Alive() or ply:Team() == 1002) then ply:SetMuted(true) end

				local panel = players[ply]
				panel:SetPos(0,yPos)
				yPos = yPos + panel:GetTall() + 1
			end
		end

		local panelPlayers = vgui.Create("Panel",HomigradScoreboard)
		panelPlayers:SetPos(0,30)
		panelPlayers:SetSize(HomigradScoreboard:GetWide(),HomigradScoreboard:GetTall() - 90)
		function panelPlayers:Paint(w,h) end

		function HomigradScoreboard:OnMouseWheeled(wheel)
			local count = table.Count(self.players)
			local limit = count * 50 + count - panelPlayers:GetTall()

			if limit > 0 then
				wheelY = wheelY - math.Clamp(wheel,-1,1) * 50

				if wheelY < 0 then
					animWheelUp = animWheelUp + 132
					wheelY = 0
				elseif wheelY > limit then
					wheelY = limit
					animWheelDown = animWheelDown + 32
				end
			end
		end

		function HomigradScoreboard:AddPlayer(ply)
			if ply:Team() == 1002 then return end

			local playerPanel = vgui.Create("DButton",panelPlayers)
			self.players[ply] = playerPanel
			playerPanel:SetText("")
			playerPanel:SetPos(0,0)
			playerPanel:SetSize(HomigradScoreboard:GetWide(),50)
			playerPanel.DoClick = function()
				local playerMenu = vgui.Create("DMenu")
				playerMenu:SetPos(input.GetCursorPos())
				playerMenu:AddOption("Copy SteamID", function()
					SetClipboardText(ply:SteamID())
					LocalPlayer():ChatPrint("SteamID " .. ply:Name() .. " copied! (" .. ply:SteamID() .. ")")
				end)
				playerMenu:AddOption("Open Steam Profile", function()
					ply:ShowProfile()
				end)
				playerMenu:AddOption("Go To", function()
					LocalPlayer():ConCommand("ulx goto $" .. ply:UserID())
				end)
				playerMenu:AddOption("Bring", function()
					LocalPlayer():ConCommand("ulx bring $" .. ply:UserID())
				end)
				playerMenu:MakePopup()

				ScoreboardList[playerMenu] = true
			end

			local name1 = ply:Name()
			local team = ply:Team()
			local alive
			local alivecol
			local colorAdd

			local func = TableRound().Scoreboard_Status
			if func then alive,alivecol,colorAdd = func(ply) end

			if not func or (func and alive == true) then
				if LocalPlayer():Team() == 1002 or not LocalPlayer():Alive() then
					if ply:Alive() then
						alive = "Alive"
						alivecol = colorGreen
					elseif ply:Team() == 1002 then
						alive = "Spectating"
						alivecol = colorSpec
					else
						alive = "Dead"
						alivecol = colorRed
						colorAdd = colorRed
					end
				elseif ply:Team() == 1002 then
					alive = "Spectating"
					alivecol = colorSpec
				else
					alive = "Unknown"
					alivecol = colorSpec
					colorAdd = colorSpec
				end
			end

			playerPanel.Paint = function(self,w,h)
				surface.SetDrawColor(playerPanel:IsHovered() and 122 or 0,playerPanel:IsHovered() and 122 or 0,playerPanel:IsHovered() and 122 or 0,100)
				surface.DrawRect(0,0,w,h)

				if colorAdd then
					surface.SetDrawColor(colorAdd.r,colorAdd.g,colorAdd.b,5)
					surface.DrawRect(0,0,w,h)
				end

				if ply == LocalPlayer() then
					draw.RoundedBox(0,0,0,w,h,whiteAdd)
				end

				if alive ~= "Unknown" and ply.last then
					draw.SimpleText(ply.last,"HomigradFont",25,h / 2,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				end

				draw.SimpleText(alive,"HomigradFont",100,h / 2,alivecol,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				draw.SimpleText(name1,"HomigradFont",w / 2,h / 2,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				
				local userGroupDisplay = {
					owner = {name = "Owner", color = Color(0,242,255)},
					servermanager = {name = "Server Manager", color = Color(255, 25, 25)}, 
					superadmin = {name = "Head Administrator", color = Color(255,223,0)},
					admin = {name = "Administrator", color = Color(50, 255, 50)},
					operator = {name = "Moderator", color = Color(75, 200, 75)},
					tmod = {name = "Trial Mod", color = Color(75, 150, 70)},
					sponsor = {name = "Sponsor", color = Color(77, 201, 255)},
					supporterplus = {name = "Supporter+", color = Color(255, 159, 62)},
					supporter = {name = "Supporter", color = Color(241, 196, 15)},
					regular = {name = "Regular", color = Color(0,150,220)},
					user = {name = "User", color = Color(125, 125, 125)}
				}

				local function GetDisplayNameAndColor(usergroup)
					return userGroupDisplay[usergroup] and userGroupDisplay[usergroup].name or usergroup,
						userGroupDisplay[usergroup] and userGroupDisplay[usergroup].color or color_white
				end

				local displayName, displayColor = GetDisplayNameAndColor(ply:GetUserGroup())
				draw.SimpleText(displayName, "HomigradFont", w - 300, h / 2, displayColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ply:Ping(),"HomigradFont",w - 200,h / 2,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

				local name,color = ply:PlayerClassEvent("TeamName")
				if not name then
					name,color = TableRound().GetTeamName(ply)
					name = name or "Spectator"
					color = color or ScoreboardSpec
				end

				draw.SimpleText(name,"HomigradFont",w - 100,h / 2,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end

			if ply ~= LocalPlayer() then
				local button = vgui.Create("DButton",playerPanel)
				button:SetSize(32,32)
				button:SetText("")
				local h = playerPanel:GetTall() / 2 - 32 / 2
				button:SetPos(playerPanel:GetWide() - playerPanel:GetTall() / 2 - 32 / 2,h)

				function button:Paint(w,h)
					surface.SetMaterial(ply:IsMuted() and mutedicon or unmutedicon)
					surface.SetDrawColor(255,255,255,255)
					surface.DrawTexturedRect(0,0,w,h)
				end

				function button:DoClick()
					ply:SetMuted(not ply:IsMuted())
					SaveMuteStatusPlayer(ply,ply:IsMuted())
				end
			end
		end

		local button = SB_CreateButton(HomigradScoreboard)
		button:SetSize(30,30)
		button:SetPos(HomigradScoreboard:GetWide() / 2 - button:GetWide() / 2,HomigradScoreboard:GetTall() - 15 - button:GetTall())
		button.text = "S"
		function button:DoClick()
			OpenHomigradMenu()
            HomigradScoreboard:Remove()
		end

		local muteAll = SB_CreateButton(HomigradScoreboard)
		muteAll:SetSize(175,30)
		muteAll:SetPos(-muteAll:GetWide() - 35 + HomigradScoreboard:GetWide() / 2,HomigradScoreboard:GetTall() - 45)
		muteAll.text = "Mute Everyone"

		function muteAll:Paint(w,h)
			self.textColor = not muteall and green or red
			SB_PaintButton(self,w,h)
		end

		function muteAll:DoClick() muteall = not muteall end

		local muteAllDead = SB_CreateButton(HomigradScoreboard)
		muteAllDead:SetSize(175,30)
		muteAllDead:SetPos(35 + HomigradScoreboard:GetWide() / 2,HomigradScoreboard:GetTall() - 45)
		muteAllDead.text = "Mute All Dead"

		function muteAllDead:Paint(w,h)
			self.textColor = not muteAlldead and green or red
			SB_PaintButton(self,w,h)
		end

		function muteAllDead:DoClick() muteAlldead = not muteAlldead end

		local func = TableRound().ScoreboardBuild

		if func then
			func(HomigradScoreboard,ScoreboardList)
		end
	else
		ToggleScoreboard_Override = nil
		
		if IsValid(HomigradScoreboard) then
			HomigradScoreboard:Close()
		end

		for panel in pairs(ScoreboardList) do
			if not IsValid(panel) then continue end

			if panel.Close then panel:Close() else panel:Remove() end
		end 
	end
end

hook.Add("ScoreboardShow","HomigradOpenScoreboard",function()
	ToggleScoreboard(true)

	return false
end)

hook.Add("ScoreboardHide","HomigradHideScoreboard",function()
	if ToggleScoreboard_Override then return end

	ToggleScoreboard(false)
end)

net.Receive("close_tab",function(len)
	ToggleScoreboard(false)
end)

hook.Add("HUDDrawScoreBoard","spectatorwarning",function()  
    if LocalPlayer():Team() == 1002 then
        draw.DrawText("You are currently in Spectator Mode.", "HomigradFontSmall", ScrW() / 2, ScrH() /1.2 ,
            Color(255, 255, 255,255), TEXT_ALIGN_CENTER)
		draw.DrawText("To Join in next round, please press F2 and select 'Join Game'!", "HomigradFontBigger", ScrW() / 2, ScrH() /1.15 ,
            Color(255, 255, 255,255), TEXT_ALIGN_CENTER)
    end
end)

ToggleScoreboard(false)
