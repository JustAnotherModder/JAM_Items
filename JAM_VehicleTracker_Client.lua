local JVH = JAM.VehicleTracker

function JVH:Start()
	if not self or not ESX then return; end
	while not ESX.IsPlayerLoaded do Citizen.Wait(0); end
	self:Update()
end

function JVH:Update()
	while true do
		Citizen.Wait(0)
		tick = (tick or 0) + 1
		if tick % 100 == 0 then
			if self.TrackingVehicle then
				local vehPos = GetEntityCoords(self.TrackingVehicle)
				SetNewWaypoint(vehPos.x, vehPos.y)
				SetGpsActive(false)
			end
		end
	end
end

RegisterNetEvent('JVH:InitiateTracking')
AddEventHandler('JVH:InitiateTracking', function(...) 
	local plyPed = GetPlayerPed(PlayerId())
	local plyPos = GetEntityCoords(plyPed)
	local closestVeh = ESX.Game.GetClosestVehicle(plyPos)
	if not closestVeh then print("Couldn't find vehicle."); return; end
	local vehPos = GetEntityCoords(closestVeh)
	if JUtils:GetVecDist(plyPos, vehPos) < JVH.DistToPlace then JVH.TrackingVehicle = closestVeh; end
end)

Citizen.CreateThread(function(...) JVH:Start(); end)

