DashboardUtils = {}

function DashboardUtils.createVanillaNodes(vehicle, savegame)
	local spec = vehicle.spec_DashboardLive
	
	local vehFile = savegame.xmlFile
	local vehKey = savegame.key
	local xmlPath = vehFile:getString(vehKey.."#filename")
	
	-- Inject extended Dashboard Emitters into Vanilla Vehicles
	dbgprint("onPreLoad : vehicle: "..vehicle:getName(), 2)
	dbgprint("onPreLoad : vehicle's filename: "..xmlPath, 2)
	
	local xmlFile = XMLFile.loadIfExists("VanillaDashboards", spec.vanillaDashboardsFile, "vanillaDashboards")
	if xmlFile ~= nil then
		dbgprint("onPreLoad : xmlFile found!", 2)
		local i = 0
		while true do
			local xmlRootPath = string.format("vanillaDashboards.vehicleDashboard(%d)", i)
			dbgprint("onPreLoad : xmlRootPath: "..tostring(xmlRootPath), 2)
			if not xmlFile:hasProperty(xmlRootPath) then break end
			local vanillaFile = xmlFile:getValue(xmlRootPath.."#fileName")
			dbgprint("onPreLoad : vanillaFile: "..tostring(vanillaFile), 2)
			if vanillaFile == xmlPath then
				dbgprint("onPreload : found vehicle in vanillaDashboards", 2)
				-- createNodes
				local n = 0
				while true do
					local xmlNodePath = xmlRootPath .. string.format(".nodes.node(%d)", n)
					if not xmlFile:hasProperty(xmlNodePath) then break end
					local nodeName = xmlFile:getValue(xmlNodePath .. "#name")
					if nodeName == nil then
						Logging.xmlWarning(xmlFile, "No node name given, setting to 'dashboardLive'")
						nodeName = "dashboardLive"
					end
					local nodeRoot = xmlFile:getValue(xmlNodePath .. "#root")
					if nodeRoot == nil then
						Logging.xmlWarning(xmlFile, "No root node given, setting to 0>0")
						nodeRoot = vehicle.rootNode
					end
					local nx, ny, nz = xmlFile:getValue(xmlNodePath .. "#moveTo")
					--local nx, ny, nz
					--local moveTo = xmlFile:getVector(xmlNodePath .. "#moveTo")
					--if moveTo ~= nil then
					--	nx, ny, nz = moveTo[1], moveTo[2], moveTo[3]
					--else
					--	Logging.xmlWarning(xmlFile, "No node translation given, setting to 0 0 0")
					--	nx, ny, nz = 0, 0, 0
					--end
					local rx, ry, rz = xmlFile:getValue(xmlNodePath .. "#rotate")
					--local rx, ry, rz 
					--local rotate = xmlFile:getVector(xmlNodePath .. "#rotate")
					--if rotate ~= nil then
					--	rx, ry, rz = rotate[1], rotate[2], rotate[3]
					--else
					--	Logging.xmlWarning(xmlFile, "No node translation given, setting to 0 0 0")
					--	rx, ry, rz = 0, 0, 0
					--end
					dbgprint("node: "..tostring(node), 2)
					dbgprint("root: "..tostring(nodeRoot), 2)
					dbgprint(string.format("moveTo: %d %d %d", nx, ny, nz), 2)
					dbgprint(string.format("rotate: %d %d %d", rx, ry, rz), 2)
					
					local node = createTransformGroup(nodeName)
					-- TODO: nodeRoot in einen korrekten Node-Verweis umwandeln (I3D-Manager?)
					link(nodeRoot, node) 
					setTranslation(node, nx, ny, nz)
					setRotation(node, rx, ry, rz)
					
					n = n + 1
				end
			end
			i = i + 1
		end
	end
end