ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("hunting:check:hasKnife", function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local hasKnife = false

	for i = 1, #inventory do
		if inventory[i].name == "WEAPON_SWITCHBLADE" and inventory[i].count > 0 then
			hasKnife = true
		end
	end

	if hasKnife then cb(hasKnife)
	else cb(hasKnife)
	end

end)

ESX.RegisterServerCallback("hunting:give:item", function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local countSkin = 0
	local countMeat = 0
	for i = 1, #inventory do
		if inventory[i].name == "deer_skin" and inventory[i].count > 0 then
			countSkin = inventory[i].count
		end
		if  inventory[i].name == "deer_meat" and inventory[i].count > 0 then
			countMeat = inventory[i].count
		end
	end
	
	if countSkin < Config.DeerSkinMaxCount then
		xPlayer.addInventoryItem("deer_skin", 1)		
	end

	if countSkin < Config.DeerMeatMaxCount then
		xPlayer.addInventoryItem("deer_meat", 2)
	end

	cb(true)
end)


ESX.RegisterServerCallback("hunting:check:deer_skin", function(source, cb, val)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local countSkin = 0
	for i = 1, #inventory do
		if inventory[i].name == "deer_skin" and inventory[i].count > 0 then
			countSkin = inventory[i].count
		end
	end

	if countSkin >= val then
		cb(true)
	else
		cb(false)
	end	
end)

ESX.RegisterServerCallback("hunting:check:deer_meat", function(source, cb, val)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local countSkin = 0
	for i = 1, #inventory do
		if inventory[i].name == "deer_meat" and inventory[i].count > 0 then
			countSkin = inventory[i].count
		end
	end

	if countSkin >= val then
		cb(true)
	else
		cb(false)
	end	
end)



ESX.RegisterServerCallback("hunting:sell:deer_skin", function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local countSkin = 0
	for i = 1, #inventory do
		if inventory[i].name == "deer_skin" and inventory[i].count > 0 then
			countSkin = inventory[i].count
		end
	end

	local max = countSkin * Config.GivenMoney

	xPlayer.removeInventoryItem("deer_skin", countSkin)
	xPlayer.addMoney(max)
	cb(true)
end)

ESX.RegisterServerCallback("hunting:sell:deer_meat", function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local inventory = xPlayer.inventory
	local countSkin = 0
	for i = 1, #inventory do
		if inventory[i].name == "deer_meat" and inventory[i].count > 0 then
			countSkin = inventory[i].count
		end
	end

	local max = countSkin * Config.GivenMoney

	xPlayer.removeInventoryItem("deer_skin", countSkin)
	xPlayer.addMoney(max)
	cb(true)
end)


ESX.RegisterUsableItem('deer_meat', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)

	xPlayer.removeInventoryItem('deer_meat', 1)

	TriggerClientEvent('esx_status:add', source, 'hunger', 400000)
	TriggerClientEvent('esx_basicneeds:onEat', source)
	TriggerClientEvent('esx:showNotification', source, " Geyik eti tükketin! x1")
end)