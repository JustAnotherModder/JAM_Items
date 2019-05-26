ESX.RegisterUsableItem('jamtracker', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return; end
	xPlayer.removeInventoryItem('jamtracker', 1)
 	TriggerClientEvent('JVH:InitiateTracking', source)
end)