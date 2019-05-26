JAM.NightVision = {}
local JNV = JAM.NightVision
JNV.ESX = JAM.ESX

JNV.EnableKey = "F3"
JNV.EnableNV  = 0

function JNV:Start()
	while not ESX.IsPlayerLoaded() do Citizen.Wait(0); end
	self:Update()
end

function JNV:Update()
	while true do
		Citizen.Wait(0)
		local hotkey = IsControlJustPressed(0, JUtils.Keys[self.EnableKey]) or IsDisabledControlJustPressed(0, JUtils.Keys[self.EnableKey])
		if hotkey then self:ToggleNightvision(); end
	end
end

function JNV:ToggleNightvision()
	local plyPed = GetPlayerPed(PlayerId())
	local mask = GetPedDrawableVariation(plyPed, 1)
	if mask == 132 or mask == "132" then
		self.EnableNV = self.EnableNV + 1
		if self.EnableNV > 2 then self.EnableNV = 0; end

		local str = "Nightvision : "
		if self.EnableNV == 0 then
			SetNightvision(false)
			SetSeethrough(false)
			ESX.ShowNotification(str .. "Disabled.")
		elseif self.EnableNV == 1 then
			SetNightvision(true)
			SetSeethrough(false)
			ESX.ShowNotification(str .. "NightVision.")
		elseif self.EnableNV == 2 then
			SetNightvision(false)
			SetSeethrough(true)
			ESX.ShowNotification(str .. "Thermal.")
		end
	end
end

Citizen.CreateThread(function(...) JNV:Update(...); end)