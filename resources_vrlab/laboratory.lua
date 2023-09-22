-- EV Toolbox 3.4.11 required

require "physics.lua"

local DEBUG_PHYSICS = true

local logger = set_lua_logger("vrlab.laboratory")

local physicsCtx = PhysicsContext()
local physicsUtil = require("physics_util.lua")
local graphicsUtil = require("graphics_util.lua")

local sceneGroup = reactorController:getReactorByName("Scene").node

-- add collision (physical) objects
do
	local planeObject = bt.CollisionObject()
	planeObject:setCollisionShape(bt.StaticPlaneShape(bt.Vector3(0.0, 0.0, 1.0), 0.0))
	planeObject:setFriction(1.0)
	physicsCtx.world:addCollisionObject(planeObject)

	local envCollisionNode = reactorController:getReactorByName("environment/collision")
	local envCollisionShape, debugCollisionShape = physicsUtil.createCollisionShape(envCollisionNode.node, DEBUG_PHYSICS)
	local envCollisionObject, debugCollisionNode = physicsUtil.createCollisionObject(nil, envCollisionShape, DEBUG_PHYSICS and physicsUtil.createShapeDrawable(debugCollisionShape))

	physicsCtx.world:addCollisionObject(envCollisionObject)
	if debugCollisionNode then
		sceneGroup:addChild(debugCollisionNode)
	end
end


-- playing with chemical stuff test
local g_ObjectsData = {
	bowl			= { mass = 0.1	, transform = nil, rb = nil, motionState = nil }
,	flask			= { mass = 0.05	, transform = nil, rb = nil, motionState = nil }
,	flask_mix		= { mass = 0.05	, transform = nil, rb = nil, motionState = nil }
,	glass			= { mass = 0.05	, transform = nil, rb = nil, motionState = nil }
,	heating_flask	= { mass = 0.05	, transform = nil, rb = nil, motionState = nil }
,	injector		= { mass = 0.05	, transform = nil, rb = nil, motionState = nil }
,	mixing_spoon	= { mass = 0.02	, transform = nil, rb = nil, motionState = nil }
,	pincet			= { mass = 0.02	, transform = nil, rb = nil, motionState = nil }
,	pipetka			= { mass = 0.01	, transform = nil, rb = nil, motionState = nil }
,	stick			= { mass = 0.01	, transform = nil, rb = nil, motionState = nil }
,	tube			= { mass = 0.02	, transform = nil, rb = nil, motionState = nil }
,	voronka			= { mass = 0.02	, transform = nil, rb = nil, motionState = nil }
}

do
	local function getObjectData(name)
		logger:info("Loading '", name, "' object...")
		local model				= reactorController:getReactorByName("obj/" .. name .. "/model").node
		local collisionModel	= reactorController:getReactorByName("obj/" .. name .. "/collision").node
		local collisionShape, debugCollisionShape = physicsUtil.createCollisionShape(collisionModel, DEBUG_PHYSICS)
		local collisionObject, debugCollisionNode = physicsUtil.createCollisionObject(nil, collisionShape, DEBUG_PHYSICS and physicsUtil.createShapeDrawable(debugCollisionShape))

		return model, collisionObject, debugCollisionNode
	end

	for name, obj in pairs(g_ObjectsData) do
		local m, rb, dbg = getObjectData(name)
		m:show()

		m:getOrCreateStateSet():setMode(GLenum.GL_CULL_FACE, osg.StateAttribute.OFF)
		m:getOrCreateStateSet():setMode(GLenum.GL_LIGHTING, osg.StateAttribute.ON)
		m:getOrCreateStateSet():setMode(GLenum.GL_LIGHT0, osg.StateAttribute.ON)
		graphicsUtil.transparencySinglePass(m)

		local rbTransform = bt.Transform.getIdentity()
		rbTransform:setOrigin(bt.Vector3(0.0, 0.0, 1.75))
		rbTransform:setRotation(bt.Quaternion(bt.Vector3(0.0, 1.0, 0.0), math.random(0, 100)/100.0*math.pi))

		obj.transform = osg.MatrixTransform()
		obj.transform:setMatrix(bt.bt2osg(rbTransform))
		obj.transform:addChild(m)
		if dbg then
			obj.transform:addChild(dbg)
		end

		obj.motionState = bt.DefaultMotionState(rbTransform)

		rb:setMassProps(obj.mass, bt.Vector3(0.002, 0.002, 0.002))
		rb:setAngularFactor(2.0)
		rb:setDamping(0.01, 0.01)
		rb:setFriction(0.95)
		rb:setRollingFriction(0.0075)
		rb:setSpinningFriction(0.0075)

		rb:setMotionState(obj.motionState)

		physicsCtx.world:addRigidBody(rb)
		obj.rb = rb

		sceneGroup:addChild(obj.transform)
	end
end

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


local initialTestTransform = bt.Transform.getIdentity()
initialTestTransform:setOrigin(bt.Vector3(0.0, 0.0, 2.0))
initialTestTransform:setRotation(bt.Quaternion(bt.Vector3(0.0, 1.0, 0.0), math.random(0, 100)/100.0*math.pi))

local rigidBodyTransform = bt.Transform.getIdentity()

local time
bus:subscribe(function()
	local dt = time and (evi.getCurrentTimeNs()*1e-9 - time) or 0.0
	time = evi.getCurrentTimeNs()*1e-9			-- nanoseconds to seconds

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

	physicsCtx:frame(time)

	for name, obj in pairs(g_ObjectsData) do
		if obj.rb:isActive() then
			obj.motionState:getWorldTransform(rigidBodyTransform)
			obj.transform:setMatrix(bt.bt2osg(rigidBodyTransform))
		else
			-- test (remove it)
			-- logger:error("Reactivation test!")
			obj.motionState:setWorldTransform(initialTestTransform)
			obj.rb:setWorldTransform(initialTestTransform)
			obj.rb:activate(true)
		end
	end

end)
