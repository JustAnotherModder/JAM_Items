JAM.SecuritySurveillance = {}
local JSS = JAM.SecuritySurveillance
JSS.ESX = JAM.ESX

JSS.CamOffsetX 		= 0.0
JSS.CamOffsetY 		= 0.0
JSS.CamOffsetZ 		= 1.0

JSS.CamHeadingClamp = 45.0
JSS.CamPitchClamp	= 45.0

JSS.CamHeightClamp = 3.0

JSS.CamMoveSpeed 	= 0.05
JSS.CamRotSpeed		= 1.0

function JSS:Start()
	if not self or not ESX or not JUtils then print("JAM.SecuritySystem:Start() : Error : Couldn't find something."); return; end
	while not ESX.IsPlayerLoaded() do Citizen.Wait(0); end

	self:Update()
end

function JSS:Update()
	while true do
		Citizen.Wait(0)
		self:TrackInput()
        if self.CreatedCamera then self:ShowInstructions(); end
	end
end

function JSS:ShowInstructions()
    local instructions = CreateInstuctionScaleform("instructional_buttons", self.PlacingCamera)
    DrawScaleformMovieFullscreen(instructions, 255, 255, 255, 255, 0)
end

function JSS:TrackInput()
    local dotKey        = IsControlJustPressed( 0, JUtils.Keys[ '.' ] ) or IsDisabledControlJustPressed( 0, JUtils.Keys[ '.' ] ) 
    local commaKey      = IsControlJustPressed( 0, JUtils.Keys[ ',' ] ) or IsDisabledControlJustPressed( 0, JUtils.Keys[ ',' ] ) 
    local gKey          = IsControlJustPressed( 0, JUtils.Keys[ 'F5' ] ) or IsDisabledControlJustPressed( 0, JUtils.Keys[ 'F5' ] ) 
    local hKey          = IsControlJustPressed( 0, JUtils.Keys[ 'F6' ] ) or IsDisabledControlJustPressed( 0, JUtils.Keys[ 'F6' ] ) 

    if self.WatchingCamera and not self.PlacingCamera then
        if dotKey then self:SwitchCamera(true); end
        if commaKey then self:SwitchCamera(false); end
        if hKey then self:CloseCamera(); end
    elseif self.PlacingCamera and not self.WatchingCamera then
        if hKey then 
            self:CloseCamera()
            TriggerServerEvent('JSS:AddCamera')
        end
        if gKey then self:PlaceCamera(); end
    elseif not self.WatchingCamera and not self.PlacingCamera then
        if hKey then self:CloseCamera(); end
        if gKey then self:CheckCameras(); end
    end

	if self.PlacingCamera and self.CreatedCamera then
        local keys = {
            left     = IsControlPressed( 0, JUtils.Keys[ 'LEFT' ] )  or IsDisabledControlPressed( 0, JUtils.Keys[ 'LEFT' ] ) , 
            right    = IsControlPressed( 0, JUtils.Keys[ 'RIGHT' ] ) or IsDisabledControlPressed( 0, JUtils.Keys[ 'RIGHT' ] ) ,
            up       = IsControlPressed( 0, JUtils.Keys[ 'UP' ] )    or IsDisabledControlPressed( 0, JUtils.Keys[ 'UP' ] ) ,
            down     = IsControlPressed( 0, JUtils.Keys[ 'DOWN' ] )  or IsDisabledControlPressed( 0, JUtils.Keys[ 'DOWN' ] ) ,    
            z        = IsControlPressed( 0, JUtils.Keys[ 'Z' ] )     or IsDisabledControlPressed( 0, JUtils.Keys[ 'Z' ] ) ,
            x        = IsControlPressed( 0, JUtils.Keys[ 'X' ] )     or IsDisabledControlPressed( 0, JUtils.Keys[ 'X' ] ) ,
        }

		if keys.left or keys.right or keys.up or keys.down or keys.z or keys.x then
            self:MoveCamera(keys)
        end
	end
end

function JSS:CheckCameras()
    if not self.CameraPositions or self.PlacingCamera or self.WatchingCamera or self.CreatedCamera then return; end
    local pos = self.CameraPositions[1].pos
    local rot = self.CameraPositions[1].rot
    SetFocusArea(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z)
    self.WatchingCamera = self:ChangeSecurityCamera(pos, rot)
end

function JSS:PositionCamera()
    local plyPed = GetPlayerPed(PlayerId())
    local plyPos = GetEntityCoords(plyPed)
    FreezeEntityPosition(plyPed, true)

    self.PlacingCamera = { pos = vector3(plyPos.x + self.CamOffsetX, plyPos.y + self.CamOffsetY, plyPos.z + self.CamOffsetZ), rot = GetEntityRotation(plyPed) }
 
    SetFocusArea(self.PlacingCamera.pos.x, self.PlacingCamera.pos.y, self.PlacingCamera.pos.z, self.PlacingCamera.pos.x, self.PlacingCamera.pos.y, self.PlacingCamera.pos.z)
    self:ChangeSecurityCamera(self.PlacingCamera.pos, self.PlacingCamera.rot)
end

RegisterNetEvent('JSS:PositionCamera')
AddEventHandler('JSS:PositionCamera', function(...) JSS:PositionCamera(...); end)

function JSS:PlaceCamera()
    if not self.PlacingCamera or not self.CreatedCamera then return; end
    self.CameraPositions = self.CameraPositions or {}
    table.insert(self.CameraPositions, { pos = GetCamCoord(self.CreatedCamera), rot = GetCamRot(self.CreatedCamera) } )
    self:CloseCamera()
end

function JSS:SwitchCamera(forward)
    if not self.CameraPositions or not self.CreatedCamera or #self.CameraPositions <= 1 then return; end

    local curCam        
    for k,v in pairs(self.CameraPositions) do
        if v.pos == GetCamCoord(self.CreatedCamera) then 
            curCam = k
            break
        end
    end

    local newCam
    if forward then
        if curCam == #self.CameraPositions then newCam = self.CameraPositions[1]
        else newCam = self.CameraPositions[curCam + 1]
        end
        SetFocusArea(newCam.pos.x, newCam.pos.y, newCam.pos.z, newCam.pos.x, newCam.pos.y, newCam.pos.z)
        self:ChangeSecurityCamera(newCam.pos, newCam.rot)
        self.WatchingCamera = newCam
    else        
        if curCam == 1 then newCam = self.CameraPositions[#self.CameraPositions]
        else newCam = self.CameraPositions[curCam - 1]
        end
        SetFocusArea(newCam.pos.x, newCam.pos.y, newCam.pos.z, newCam.pos.x, newCam.pos.y, newCam.pos.z)
        self:ChangeSecurityCamera(newCam.pos, newCam.rot)
        self.WatchingCamera = newCam
    end
end

function JSS:ChangeSecurityCamera(pos, rot)
    if self.CreatedCamera then
        DestroyCam(self.CreatedCamera, 0)
        self.CreatedCamera = false
    end

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, rot.x, rot.y, rot.z, 2)
    RenderScriptCams(1, 0, 0, 1, 1)
    SetTimecycleModifier("scanline_cam_cheap")
    SetTimecycleModifierStrength(2.0)

    self.CreatedCamera = cam
    return self.CreatedCamera
end

function JSS:CloseCamera()
    if not self.CreatedCamera then return; end
    if self.PlacingCamera then self.PlacingCamera = false; end
    if self.WatchingCamera then self.WatchingCamera = false; end

    local plyPed = GetPlayerPed(PlayerId())

    DestroyCam(self.CreatedCamera, 0)
    RenderScriptCams(0, 0, 1, 1, 1)
    ClearTimecycleModifier("scanline_cam_cheap")
    SetFocusEntity(plyPed)
    FreezeEntityPosition(plyPed, false)

    self.CreatedCamera = false
end

function JSS:MoveCamera(keys)
	if not self or not self.CreatedCamera then return; end

	local rot = GetCamRot(self.CreatedCamera, 0)
	local pos = GetCamCoord(self.CreatedCamera)

	if keys.right then    
        rot = vector3(rot.x, rot.y, rot.z - self.CamRotSpeed)
    end

	if keys.left then
        rot = vector3(rot.x, rot.y, rot.z + self.CamRotSpeed)
    end

	if keys.down then
		rot = vector3(math.max(rot.x - self.CamRotSpeed, -self.CamPitchClamp), rot.y, rot.z)
    end

	if keys.up then
		rot = vector3(math.min(rot.x + self.CamRotSpeed, self.CamPitchClamp), rot.y, rot.z)
	end

	if keys.z then
		pos = vector3(pos.x, pos.y, math.max(pos.z - self.CamMoveSpeed, self.PlacingCamera.pos.z))
	elseif keys.x then
		pos = vector3(pos.x, pos.y, math.min(pos.z + self.CamMoveSpeed, self.PlacingCamera.pos.z + self.CamHeightClamp))
	end

	SetCamCoord(self.CreatedCamera, pos)
	SetCamRot(self.CreatedCamera, rot,0)
end

function CreateInstuctionScaleform(scaleform, placing)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    if placing then
        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(0)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'F6' ], true))
        InstructionButtonMessage("Close")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(1)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'F5' ], true))
        InstructionButtonMessage("Place")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(2)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'Z' ], true))
        InstructionButtonMessage("Height -")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(3)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'X' ], true))
        InstructionButtonMessage("Height +")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(4)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'DOWN' ], true))
        InstructionButtonMessage("Down")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(5)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'UP' ], true))
        InstructionButtonMessage("Up")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(6)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'RIGHT' ], true))
        InstructionButtonMessage("Right")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(7)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'LEFT' ], true))
        InstructionButtonMessage("Left")
        PopScaleformMovieFunctionVoid()
    else    
        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(0)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ '.' ], true))
        InstructionButtonMessage("Next")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(1)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ ',' ], true))
        InstructionButtonMessage("Previous")
        PopScaleformMovieFunctionVoid()

        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(2)
        InstructionButton(GetControlInstructionalButton(1, JUtils.Keys[ 'F6' ], true))
        InstructionButtonMessage("Close")
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function InstructionButton(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

function InstructionButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

Citizen.CreateThread(function(...) JSS:Start(...); end)