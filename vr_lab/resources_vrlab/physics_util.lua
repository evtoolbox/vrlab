-- Copyright (C) 2023 EligoVision Ltd.
-- File: physics_util.lua

local logger = set_lua_logger("vrlab.physics_util")

local function createCollisionShape(node, createDebugNode)
	local compoundShape = bt.CompoundShape()
	local osgCompositeShape = createDebugNode and osg.CompositeShape()

	local findCollisionObjectsVisitor = osg.NodeVisitor(osg.NodeVisitor.TRAVERSE_ALL_CHILDREN)
	findCollisionObjectsVisitor:setApplyGeometryCb(function(geometry)
		local name = geometry:getName()
		logger:info("Found collision object: '", name, "'")

		local bb = geometry:getBoundingBox()
		local v1, v2 = bb:min(), bb:max()

		local pnp = geometry:getParentalNodePaths(node):at(0)
		local internalMatrix = osg.computeLocalToWorld(pnp)

		-- v1, v2 = v1*internalMatrix, v2*internalMatrix

		local dims = (v2 - v1)/2
		local center = v1 + dims
		dims:x(math.abs(dims:x()))
		dims:y(math.abs(dims:y()))
		dims:z(math.abs(dims:z()))
		-- logger:debug("dims = " .. dims:x(), ", ", dims:y(), ", ", dims:z())

		center = center*internalMatrix
		local rotation = internalMatrix:getRotate()
		local dbgRotation = rotation

		local collisionShape, dgbShape

		-- Different shapes
		if string.find(name, "CylinderX") then
			logger:info("Suppose this is CylinderX!")
			collisionShape = bt.CylinderShapeX(bt.osg2bt(dims))

			if osgCompositeShape then
				-- Debug visualization
				local radius, height = dims:y(), dims:x()*2
				local r = osg.Quat()
				r:makeRotate(math.pi/2, osg.Vec3(0.0, 1.0, 0.0))

				dbgShape = osg.Cylinder(center, radius, height)
				dbgRotation = r*dbgRotation
			end
		elseif string.find(name, "Cylinder") then
			logger:info("Suppose this is CylinderZ!")
			collisionShape = bt.CylinderShapeZ(bt.osg2bt(dims))

			if osgCompositeShape then
				-- Debug visualization
				local radius, height = dims:x(), dims:z()*2
				dbgShape = osg.Cylinder(center, radius, height)
			end
		elseif string.find(name, "Sphere") then
			logger:info("Suppose this is Sphere!")
			local radius = dims:x()
			collisionShape = bt.SphereShape(radius)

			if osgCompositeShape then
				-- Debug visualization
				dbgShape = osg.Sphere(center, radius)
				dbgRotation = nil		-- not rotation
			end
		elseif string.find(name, "Capsule") then
			logger:info("Suppose this is CapsuleZ!")
			local radius = dims:x()
			local height = (dims:z() - radius)*2
			collisionShape = bt.CapsuleShapeZ(radius, height)

			if osgCompositeShape then
				-- Debug visualization
				dbgShape = osg.Capsule(center, radius, height)
			end
		else
			logger:info("Suppose this is Box")
			collisionShape = bt.BoxShape(bt.osg2bt(dims))

			if osgCompositeShape then
				-- Debug visualization
				dbgShape = osg.Box(center, 1.0)
				dbgShape:setHalfLengths(dims)
			end
		end

		compoundShape:addChildShape(bt.Transform(bt.osg2bt(rotation), bt.osg2bt(center)), collisionShape)
		if dbgShape then
			if dbgRotation then
				dbgShape:setRotation(dbgRotation)
			end
			osgCompositeShape:addChild(dbgShape)
		end
	end)

	node:accept(findCollisionObjectsVisitor)

	return compoundShape, osgCompositeShape
end

function createCollisionObject(worldMatrix, compoundShape, debugShapeDrawable)

	local rb = bt.RigidBody(0.0, nil, compoundShape, bt.Vector3(0.0015, 0.0015, 0.0015))
	rb:setRestitution(0.0)
	if worldMatrix then
		rb:setWorldTransform(bt.osg2bt(worldMatrix))
	end

	local drawableTransform
	if debugShapeDrawable then
		drawableTransform = osg.MatrixTransform()
		if worldMatrix then
			drawableTransform:setMatrix(worldMatrix)
		end

		local r, g, b = math.random(0, 100)/100.0, math.random(0, 100)/100.0, math.random(0, 100)/100.0

		local ss = drawableTransform:getOrCreateStateSet()
		local uniform = osg.Uniform.Vec4f("ev_MaterialDiffuse", osg.Vec4(r, g, b, 0.75))
		ss:addUniform(uniform)
		ss:setMode(GLenum.GL_LIGHTING, osg.StateAttribute.ON)
		ss:setMode(GLenum.GL_LIGHT0, bit_or(osg.StateAttribute.ON, osg.StateAttribute.PROTECTED))
		ss:setMode(GLenum.GL_BLEND, osg.StateAttribute.ON)

		drawableTransform:addChild(debugShapeDrawable)
	end

    return rb, drawableTransform
end

local function createShapeDrawable(shape)
	if not shape then
		logger:warn("Cannot create ShapeDrawable")
		return
	end

	local debugShapeDrawable = osg.ShapeDrawable(shape)
	debugShapeDrawable:setColorArray(nil)
	debugShapeDrawable:setUseVertexBufferObjects(true)
	debugShapeDrawable:setUseVertexArrayObject(true)

	return debugShapeDrawable
end

return {
    createCollisionShape    = createCollisionShape
,   createCollisionObject   = createCollisionObject
,   createShapeDrawable     = createShapeDrawable
}
