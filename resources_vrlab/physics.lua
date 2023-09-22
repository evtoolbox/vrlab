-- Copyright (C) 2023 EligoVision Ltd.
-- File: PhysicsContext.lua

local logger = set_lua_logger("vrlab.PhysicsContext")

PhysicsContext = class("PhysicsContext")
	:field("collisionConfiguration")
	:field("dispatcher")
	:field("pairCache")
	:field("constraintSolver")
	:field("world")

	:field("simulationTime")

	:field("actorShape")
	:field("actorEyeHeight")
	:field("actorMotionState")
:done()

function PhysicsContext:_construct()

	self.collisionConfiguration	= bt.DefaultCollisionConfiguration()
	self.dispatcher				= bt.CollisionDispatcher(self.collisionConfiguration)
	self.pairCache				= bt.AxisSweep3(bt.Vector3(-100.0, -100.0, -100.0), bt.Vector3(100.0, 100.0, 100.0))
	self.constraintSolver		= bt.SequentialImpulseConstraintSolver()
	self.world					= bt.DiscreteDynamicsWorld(self.dispatcher, self.pairCache, self.constraintSolver, self.collisionConfiguration)
	self.world:setGravity(bt.Vector3(0.0, 0.0, -9.8))

	-- Actor Shape
	local capsuleRadius, capsuleHeight = 0.4, 1.0	-- The total height is height + 2*radius,
	self.actorShape = bt.CapsuleShapeZ(capsuleRadius, capsuleHeight)
	self.actorEyeHeight = 0.80		-- 1.70 (floor to eye)

--	self:addActor(self.actorCapsuleShape, self.eye:x(), self.eye:y(), self.eye:z())
end

	-- Add actor's collision shape at x,y,z coordinates
function PhysicsContext:addActor(x, y, z)
	if self.actorMotionState then
		logger:warn("Cannot add actor: already added!")
		return
	end

	local actorTransform = bt.Transform.getIdentity()
	actorTransform:setOrigin(bt.Vector3(x, y, z))

	self.actorMotionState = bt.DefaultMotionState(actorTransform)
	self.actorRigidBody = bt.RigidBody(70.0, self.actorMotionState, self.actorShape, bt.Vector3(0.0015, 0.0015, 0.0015))
	self.actorRigidBody:setAngularFactor(bt.Vector3(0, 0, 0))
	self.actorRigidBody:setDamping(0, 0)
	self.actorRigidBody:setFriction(0.0)
	self.actorRigidBody:setSleepingThresholds(0, 0)
	self.actorRigidBody:setRestitution(0.1)
end



function PhysicsContext:frame(time)
	local dt = time - (self.simulationTime or time)
	self.world:stepSimulation(dt, 10, math.min(dt, 1/30))
	self.simulationTime = time

	-- self:updateActor()
end
