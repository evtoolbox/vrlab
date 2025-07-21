
-- NOTE: Working on DrawTreadPerContext and SingleThreaded threading models
-- Prevent ugly transparency
function transparencySinglePass(node)
	local ss1 = osg.StateSet()
	ss1:setAttributeAndModes(osg.ColorMask(false, false, false, false))
	ss1:setAttributeAndModes(osg.Depth(osg.Depth.LESS, 0.0, 1.0, true))

	local ss2 = osg.StateSet()
	ss2:setAttributeAndModes(osg.ColorMask(true, true, true, true))
	ss2:setAttributeAndModes(osg.Depth(osg.Depth.EQUAL, 0.0, 1.0, false))

	node:setCullCallback(osg.NodeCallback(function(node, nv)
		local cv = cast(nv, osgUtil.CullVisitor)	-- TODO: asCullVisitor
		cv:pushStateSet(ss1)
		node:traverse(cv)
		cv:popStateSet()
		cv:pushStateSet(ss2)
		node:traverse(cv)
		cv:popStateSet()

		return false
	end))
end

return {
    transparencySinglePass    = transparencySinglePass
}
