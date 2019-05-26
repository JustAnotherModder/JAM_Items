JAM.SecuritySurveillance = {}
local JSS = JAM.SecuritySurveillance
JSS.ESX = JAM.ESX

RegisterNetEvent('JSS:AddCamera')
AddEventHandler('JSS:AddCamera', function(...) 
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addInventoryItem('jamcam', 1)
end)

ESX.RegisterUsableItem('jamcam', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return; end
	xPlayer.removeInventoryItem('jamcam', 1)
 	TriggerClientEvent('JSS:PositionCamera', source)
end)