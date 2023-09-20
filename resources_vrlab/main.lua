
-- Some graphics tuning: enable back face cull, disable lighting

local scene = reactorController:getReactorByName("Scene")
local sceneStateSet = scene.node:getOrCreateStateSet()
sceneStateSet:setAttributeAndModes(osg.CullFace(osg.CullFace.BACK))
sceneStateSet:setMode(GLenum.GL_LIGHTING, osg.StateAttribute.OFF)
sceneStateSet:setMode(GLenum.GL_LIGHT0, osg.StateAttribute.OFF)

require "laboratory.lua"
