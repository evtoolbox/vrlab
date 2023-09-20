-- EV Toolbox 3.4.11 required

-- NOTE: VR Manipulator tuning

local manipulatorReactor	= reactorController:getReactorByName("manipulator_vr")

-- NOTE: bus, vrHeadset are global

local leftController = vrHeadset:getControllerInput(DeviceType.CONTROLLER_LEFT)
local rightController = vrHeadset:getControllerInput(DeviceType.CONTROLLER_RIGHT)


local lastRotateDirection = 0.0
local rotStep = 30.0	-- (degrees)
local rotLeft, rotRight = osg.Quat(), osg.Quat()
rotLeft:makeRotate(rotStep*math.pi/180.0, manipulatorReactor._homeUp)
rotRight:makeRotate(-rotStep*math.pi/180, manipulatorReactor._homeUp)


local time
bus:subscribe(function()
	local dt = time and (evi.getCurrentTimeNs() - time)*1e-9 or 0.0
	time = evi.getCurrentTimeNs()

	local ltp = leftController[DeviceButton.JOYSTICK].touchPosition
	local rtp = rightController[DeviceButton.JOYSTICK].touchPosition

	-- Position or shift (right controller's joystick)
	if ltp then
		local shift = osg.Vec3(ltp:x(), 0.0, -ltp:y())*dt*1.0
		manipulatorReactor.moveEye = manipulatorReactor.moveEye + manipulatorReactor:getMatrix():getRotate()*shift
		manipulatorReactor.moveEye:z(0.0)		-- Fix height
	end

	-- Turning or rotation (right controller's joystick)
	if rtp then
		local r = rtp:x()
		if r == 0.0 then
			lastRotateDirection = 0.0
		else
			if r > 0.75 and lastRotateDirection <= 0.0 then
				manipulatorReactor.moveRotation = manipulatorReactor.moveRotation*rotRight
				lastRotateDirection = r
			elseif r < -0.75 and lastRotateDirection >= 0.0 then
				manipulatorReactor.moveRotation = manipulatorReactor.moveRotation*rotLeft
				lastRotateDirection = r
			end
		end
	end

	manipulatorReactor:updateHomeTransformation()
end)

