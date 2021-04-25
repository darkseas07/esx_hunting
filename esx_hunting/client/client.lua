local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
ESX = nil
local PlayerData = {}
local Animals = {}
local Peds = {}
local playerPedId = nil
local onAction = false
local timer = 1000

Citizen.CreateThread(function()
	while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Wait(0) end
    while ESX.GetPlayerData().job == nil do Wait(0) end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

local isMenuOpen = false


local options = {
	{label = "Geyik derisi sat", value = "sell_deer_skin"},
	{label = "Geyik eti sat", value = "sell_deer_meat"}
}


function HuntingMenu()
	isMenuOpen = true
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'general_menu',{
		title = "Hunting Panel v1.0",
		align = "top-left",
		elements = options
	}, function (data, menu) -- Select item
		menu.close()
		if data.current.value == "sell_deer_skin" then
			getNPC("sell_deer_skin")
		elseif data.current.value == "sell_deer_meat" then
			getNPC("sell_deer_meat")
		end
	end,
	function (data,menu) -- Close menu
		menu.close()
	end)
end

-- Creating NPCs
Citizen.CreateThread(function()
	Citizen.Wait(5)
	
	for i=0, (#Config.Locations / 2) do
		RequestModel(Config.Ped.hash)
		while not HasModelLoaded(Config.Ped.hash) do
			Citizen.Wait(100)
		end
		local ped = CreatePed(Config.Ped.type, Config.Ped.hash, Config.Locations[i].x, Config.Locations[i].y, Config.Locations[i].z - 1.0, Config.Locations[i].head, Config.Ped.isNetwork, Config.Ped.netMissionEntity)
		
		SetPedCanPlayAmbientAnims(ped, true)
		SetPedCanPlayAmbientBaseAnims(ped, true)
		SetPedAsEnemy(ped, false)
		TaskStartScenarioInPlace(ped, "WORLD_DEER_GRAZING", -1, true)
		SetPedSeeingRange(ped, 100.0)
		SetPedHearingRange(ped, 100.0)
		SetPedDiesInWater(ped, true)
		SetPedDiesWhenInjured(ped, true)
		TaskSmartFleePed(ped, GetPlayerPed(-1), 100.0, -1)
		table.insert(Animals, {
			pId = ped,
			bId = blip,
			isCollected = false
		})
	end

	
end)

-- is there a NPC nearby?
Citizen.CreateThread(function()
 	while true do
 		Citizen.Wait(5)
		playerPedId = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPedId)
		for i = 0, #Animals do
			if Animals[i] ~= nil then
				local pedCoords = GetEntityCoords(Animals[i].pId)
				if GetDistanceBetweenCoords(playerCoords, pedCoords) < 1.0 then		
					if IsPedDeadOrDying(Animals[i].pId, true) then
						Draw3DText2(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "~g~[E] ~s~Geyiğin derisini ve etini al.")
						local _, weaponHash = GetCurrentPedWeapon(playerPedId, true)
						if IsControlPressed(1, Keys["E"]) and not onAction and not IsPedInAnyVehicle(playerPedId, false) and weaponHash == -538741184 then
							onAction = true
							ESX.TriggerServerCallback("hunting:check:hasKnife", function(state)
								if state then
									TriggerEvent("mythic_progressbar:client:progress",
										{
											name = "cutDeer",
											duration = 7000,
											label = "Geyiğin derisi ayıklanıyor ve eti kesiliyor!",
											useWhileDead = false,
											canCancel = true,
											controlDisables = {
												disableMovement = true,
												disableCarMovement = true,
												disableMouse = false,
												disableCombat = true,
											},
											animation = {
												animDict = "melee@knife@streamed_core",
												anim = "ground_attack_on_spot",
											}
										},function(status)
										if not status then
											ESX.TriggerServerCallback("hunting:give:item", function(state)
												if state then
													exports['mythic_notify']:DoHudText('inform', 'Geyiği başarıyla ayıkladın.')
													DeletePed(Animals[i].pId)
													Animals[i].isCollected = true
													onAction = false
												end
											end)
										else
											TriggerEvent('mythic_notify:client:SendAlert', 
											{
												type = 'error', 
												text = 'Deri ayıklama ve et kesme işini iptal ettiniz!',
												length = 2000
											})
											onAction = false
										end
									end)
								else
									exports['mythic_notify']:DoHudText('error', 'Elinde bıçak bulunması gereklidir!')
									onAction = false
								end
							end)
						end
					end
				end
			end
		end
 	end
 end)

 -- Creating NPCs
Citizen.CreateThread(function()
	Citizen.Wait(5)
	for k,v in pairs(Config.Peds) do
		RequestModel(v.hash)
		while not HasModelLoaded(v.hash) do
			Citizen.Wait(100)
		end
		local ped = CreatePed(v.type, v.hash, v.x, v.y, v.z - 1.0, v.head, v.isNetwork, v.netMissionEntity)
		local blip = AddBlipForEntity(ped)
		
		for i = 0, 11 do
			if v.vars and v.vars ~= nil then
				if v.vars[i] ~= nil then SetPedComponentVariation(ped, i, v.vars[i].did, v.vars[i].tid, v.vars[i].pid) end
			end
		end
		SetBlipAsFriendly(blip, true)
		SetBlipSprite(blip, 536)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Kasap - "..v.blip_name)
		EndTextCommandSetBlipName(blip)
		SetBlipAsShortRange(blip, true)
		SetEntityCanBeDamaged(ped, false)
		SetEntityInvincible(ped, true)
		SetBlockingOfNonTemporaryEvents(ped, true)
		CanPedInCombatSeeTarget(ped, false)
		SetPedCanRagdoll(ped, false)
		SetPedCanRagdollFromPlayerImpact(ped, false)
		SetPedRagdollOnCollision(ped, false)
		SetPedCanPlayAmbientAnims(ped, false)
		SetPedCanPlayAmbientBaseAnims(ped, false)
		SetPedCanPlayGestureAnims(ped, false)
		SetPedCanPlayInjuredAnims(ped, false)
		SetPedCanPlayVisemeAnims(ped, false, false)
		SetPedCanUseAutoConversationLookat(ped, false)
		SetPedCanPeekInCover(ped, false)
		SetPedCanBeTargetted(ped, false)
		SetPedCanBeTargettedByPlayer(ped, PlayerPedId(), false)
		SetPedCanCowerInCover(ped, false)
		SetPedCanBeDraggedOut(ped, false)
		FreezeEntityPosition(ped, true)
		TaskStandStill(ped, -1)
		SetPedKeepTask(ped, true)
		table.insert(Peds, {
			pName = v.ped_name,
			jName = v.job_name,
			pId = ped,
			bId = blip
		})
	end
end)

-- is there a NPC nearby?
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
	   playerPedId = PlayerPedId()
	   local playerCoords = GetEntityCoords(playerPedId)
	   for i = 0, #Peds do
		   if Peds[i] ~= nil then
			   local pedCoords = GetEntityCoords(Peds[i].pId)
			   if GetDistanceBetweenCoords(playerCoords, pedCoords) < 1.0 then
				   Draw3DText2(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, "~g~[E] ~s~"..Peds[i].pName)
				   if IsControlPressed(1, Keys["E"]) and not onAction and not IsPedInAnyVehicle(playerPedId, false) then
						HuntingMenu()
				   end
			   elseif GetDistanceBetweenCoords(playerCoords, pedCoords) < 2.5 then
				   Draw3DText2(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, Peds[i].pName)
			   end
		   end
	   end
	end
end)

function getNPC(jobName)
	if jobName == "sell_deer_skin" then
		ESX.UI.Menu.CloseAll()
		TriggerEvent('mythic_notify:client:SendAlert', 
		{
			type = 'inform', 
			text = 'Satmak istediğiniz geyik deri miktarını giriniz.',
			length = 5000
		})
		DisplayOnscreenKeyboard(1, "", "", "Geyik derisi miktarını giriniz!", "", "", "", 31)
		while UpdateOnscreenKeyboard() == 0 do
			DisableAllControlActions(0)
			Wait(0)
		end
		if GetOnscreenKeyboardResult() then
			val = GetOnscreenKeyboardResult()
		end
		val = tonumber(val)
		if val == 0 then exports['mythic_notify']:DoHudText('error', 'Miktarı 0 giremezsin!') onAction = false return end
		if val ~= "" and type(val) == "number" then
			ESX.TriggerServerCallback("hunting:check:deer_skin", function(state)
				if state then
					TriggerEvent("mythic_progressbar:client:progress",
						{
							name = "sellSkin",
							duration = 15000,
							label = "Geyik derisi satılıyor!",
							useWhileDead = false,
							canCancel = true,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							},
						},function(status)
						if not status then
							ESX.TriggerServerCallback("hunting:sell:deer_skin", function(state) 
								if state then
									exports['mythic_notify']:DoHudText('inform', 'Geyik derileri başarıyla satıldı.')
									onAction = false
								end
							end)
						else
							TriggerEvent('mythic_notify:client:SendAlert', 
							{
								type = 'error', 
								text = 'Geyik derisi satmayı iptal ettiniz!',
								length = 2000
							})
							onAction = false
						end
					end)
				else
					exports['mythic_notify']:DoHudText('error', 'Yanlış miktar girdin!')
					onAction = false
				end
			end, val)
		else
			TriggerEvent('mythic_notify:client:SendAlert', 
			{ 
				type = 'error', 
				text = 'Miktar boş olamaz veya miktarı sayı girmelisin!', 
				length = 3000
			})
			onAction = false
		end
	elseif jobName == "sell_deer_meat" then
		ESX.UI.Menu.CloseAll()
		TriggerEvent('mythic_notify:client:SendAlert', 
		{
			type = 'inform', 
			text = 'Satmak istediğiniz geyik eti miktarını giriniz.',
			length = 5000
		})
		DisplayOnscreenKeyboard(1, "", "", "Geyik eti miktarını giriniz!", "", "", "", 31)
		while UpdateOnscreenKeyboard() == 0 do
			DisableAllControlActions(0)
			Wait(0)
		end
		if GetOnscreenKeyboardResult() then
			val = GetOnscreenKeyboardResult()
		end
		val = tonumber(val)
		if val == 0 then exports['mythic_notify']:DoHudText('error', 'Miktarı 0 giremezsin!') onAction = false return end
		if val ~= "" and type(val) == "number" then
			ESX.TriggerServerCallback("hunting:check:deer_meat", function(state)
				if state then
					TriggerEvent("mythic_progressbar:client:progress",
						{
							name = "sellSkin",
							duration = 15000,
							label = "Geyik eti satılıyor!",
							useWhileDead = false,
							canCancel = true,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							},
						},function(status)
						if not status then
							ESX.TriggerServerCallback("hunting:sell:deer_meat", function(state) 
								if state then
									exports['mythic_notify']:DoHudText('inform', 'Geyik etleri başarıyla satıldı.')
									onAction = false
								end
							end)
						else
							TriggerEvent('mythic_notify:client:SendAlert', 
							{
								type = 'error', 
								text = 'Geyik eti satmayı iptal ettiniz!',
								length = 2000
							})
							onAction = false
						end
					end)
				else
					exports['mythic_notify']:DoHudText('error', 'Yanlış miktar girdin!')
					onAction = false
				end
			end, val)
		else
			TriggerEvent('mythic_notify:client:SendAlert', 
			{ 
				type = 'error', 
				text = 'Miktar boş olamaz veya miktarı sayı girmelisin!', 
				length = 3000
			})
			onAction = false
		end
	end
end

-- Check Animals
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
		for i=1, #Animals do
			if Animals[i] ~= nil then
				if Animals[i].isCollected then
					Citizen.Wait(5)
					RequestModel(Config.Ped.hash)
					while not HasModelLoaded(Config.Ped.hash) do
						Citizen.Wait(100)
					end
					local ind = math.random(#Config.Locations)
					local ped = CreatePed(Config.Ped.type, Config.Ped.hash, Config.Locations[ind].x, Config.Locations[ind].y, Config.Locations[ind].z - 1.0, Config.Locations[ind].head, Config.Ped.isNetwork, Config.Ped.netMissionEntity)
						
					SetPedCanPlayAmbientAnims(ped, true)
					SetPedCanPlayAmbientBaseAnims(ped, true)
					SetPedAsEnemy(ped, false)
					TaskStartScenarioInPlace(ped, "WORLD_DEER_GRAZING", -1, true)
					SetPedSeeingRange(ped, 100.0)
					SetPedHearingRange(ped, 100.0)
					SetPedDiesInWater(ped, true)
					SetPedDiesWhenInjured(ped, true)
					TaskSmartFleePed(ped, GetPlayerPed(-1), 100.0, -1)
					table.insert(Animals, {
						pId = ped,
						bId = blip,
						isCollected = false
					})
					table.remove(Animals, i)
				end
			end
		end
		Citizen.Wait(timer)
	end
end)


-- Draw Text
function Draw3DText2(x, y, z, text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	local px,py,pz = table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

	local scale = (1 / dist) *1
	local fov = (1 / GetGameplayCamFov()) * 100
		local scale = 1.2

	if onScreen then
		SetTextScale(0.0 * scale, 0.25 * scale)
		SetTextFont(0)
		SetTextProportional(1)
		-- SetTextScale(0.0, 0.55)
		SetTextColour(255, 255, 255, 255)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextEdge(2, 0, 0, 0, 150)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x, _y)
		local factor = (string.len(text)) / 370
		--DrawRect(_x, _y + 0.0125, 0.030 + factor, 0.03, 41, 11, 41, 100)
		DrawRect(_x, _y + 0.0125, 0.030 + factor, 0.03, 0, 0, 0, 100)
	end
end

-- on resource stop 
AddEventHandler("onResourceStop", function(resourceName)
  	if (GetCurrentResourceName() ~= resourceName) then
    	return
  	end
	for i = 0, #Animals  do
		if Animals and Animals[i] ~= nil then
			DeletePed(Animals[i].pId)
		end
	end

	for i = 0, #Peds  do
		if Peds and Peds[i] ~= nil then
			DeletePed(Peds[i].pId)
		end
	end
	Animals = {}
	Peds = {}
	playerPedId = nil
end)