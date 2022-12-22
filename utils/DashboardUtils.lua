DashboardUtils = {}

function DashboardUtils.createVanillaNodes(vehicle, savegame)
	local spec = vehicle.spec_DashboardLive
	
	local vehFile = savegame.xmlFile
	local vehKey = savegame.key
	local xmlPath = vehFile:getString(vehKey.."#filename")
	
	local i3dLibPath = "utils\DBL_MeshLibrary"
	local i3dLibFile = "DBL_MeshLibary.i3d"
	
	-- Inject extended Dashboard Emitters into Vanilla Vehicles
	dbgprint("createVanillaNodes : vehicle: "..vehicle:getName(), 2)
	dbgprint("createVanillaNodes : vehicle's filename: "..xmlPath, 2)
	
	local xmlFile = XMLFile.loadIfExists("VanillaDashboards", spec.vanillaDashboardsFile, "Dashboard")
	if xmlFile ~= nil then
		dbgprint("createVanillaNodes : reading file", 2)
		local i = 0
		while true do
			local xmlRootPath = string.format("vanillaDashboards.vehicleDashboard(%d)", i)
			if not xmlFile:hasProperty(xmlRootPath) then break end
			dbgprint("createVanillaNodes : xmlRootPath: "..tostring(xmlRootPath), 2)
			
			local vanillaFile = xmlFile:getString(xmlRootPath .. "#fileName")
			dbgprint("createVanillaNodes : vanillaFile: "..tostring(vanillaFile), 2)
			
			if vanillaFile == xmlPath then
				dbgprint("createVanillaNodes : found vehicle in vanillaDashboards", 2)
								
				local n = 0
				while true do
					local xmlNodePath = xmlRootPath .. string.format(".nodes.node(%d)", n)
					if not xmlFile:hasProperty(xmlNodePath) then break end
					
					local nodeName = xmlFile:getString(xmlNodePath .. "#name")
					if nodeName == nil then
						Logging.xmlWarning(xmlFile, "No node name given, setting to 'dashboardLive'")
						nodeName = "dashboardLive"
					end
					
					local rootNodeName = xmlFile:getString(xmlNodePath .. "#rootNode")
					if rootNodeName == nil then
						Logging.xmlWarning(xmlFile, "No root node given, setting to 0>0")
						rootNodeName = "0>0"
					end

					local nx, ny, nz = 0, 0, 0
					local moveTo = xmlFile:getVector(xmlNodePath .. "#moveTo")
					if moveTo ~= nil then
						nx, ny, nz = unpack(moveTo)
					else
						Logging.xmlWarning(xmlFile, "No node translation given, setting to 0 0 0")
					end

					local rx, ry, rz = 0, 0, 0
					local rotate = xmlFile:getVector(xmlNodePath .. "#rotate")
					if rotate ~= nil then
						rx, ry, rz = unpack(rotate)
					else
						Logging.xmlWarning(xmlFile, "No node translation given, setting to 0 0 0")
					end
					
					dbgprint("nodeName: "..tostring(nodeName), 2)
					dbgprint("rootNodeName: "..tostring(rootNodeName), 2)
					dbgprint(string.format("moveTo: %f %f %f", nx, ny, nz), 2)
					dbgprint(string.format("rotate: %f %f %f", rx, ry, rz), 2)
					
					-- function LicensePlates:linkPlates()
						-- local spec = self.spec_licensePlates

						-- for _, wrapper in ipairs(spec.licensePlates) do
							-- local i3d = g_i3DManager:loadSharedI3DFile(LicensePlates.I3D, LicensePlates.DIRECTORY, false, false)
							-- local index = wrapper.isSmall and "0|0|1" or "0|0|0"

							-- wrapper.i3d = I3DUtil.indexToObject(i3d, index)

							-- -- apply position data
							-- setTranslation(wrapper.i3d, wrapper.translation[1], wrapper.translation[2], wrapper.translation[3])
							-- setRotation(wrapper.i3d, math.rad(wrapper.rotation[1]), math.rad(wrapper.rotation[2]), math.rad(wrapper.rotation[3]))
							-- link(wrapper.linkNode, wrapper.i3d)

							-- -- i3d can not be used again because index is strange
							-- delete(i3d)
						-- end
					-- end
					
					local symbolsI3D = g_i3DManager:loadSharedI3DFile(i3dLibPath.."/"..i3dLibFile, false, false)
					local symbolIndex = "0|1" -- to be loaded from xmlFile
					
					local dashboardSymbol = I3DUtil.indexToObject(symbolsI3D, symbolIndex)
					
					
					local tgNode = createTransformGroup(nodeName)
					dbgprint("rootNode: "..tostring(rootNode), 2)
					dbgprint("tgNode: "..tostring(tgNode), 2)
										
					link(rootNode, tgNode) 
					setTranslation(tgNode, nx, ny, nz)
					setRotation(tgNode, rx, ry, rz)
					
					--local dblEmitter = Debug2DArea.new(true, true, {1, 0, 0, 1}, false)
					--local dblEmitter = DebugCube.new()
					--dblEmitter:createWithNode(tgNode, 0.1, 0.1, 0.1)
					--spec.emitter = dblEmitter
					--spec.emitterNode = tgNode
					
					n = n + 1
				end
			end
			i = i + 1
		end
	end
end

-- Giant's stuff adopted to read xml-value before any schema is usable
local function loadDashboardGroupFromXML(vehicle, xmlFile, key, group)
    group.name = xmlFile:getString(key .. "#name")
    if group.name == nil then
        Logging.xmlWarning(self.xmlFile, "Missing name for dashboard group '%s'", key)
        return false
    end

    if vehicle:getDashboardGroupByName(group.name) ~= nil then
        Logging.xmlWarning(self.xmlFile, "Duplicated dashboard group name '%s' for group '%s'", group.name, key)
        return false
    end

    group.isActive = false

    return true
end

function DashboardUtils.createVanillaGroups(vehicle, savegame)
	dbgprint("createVanillaGroups : started", 2)
	local vehFile = savegame.xmlFile
	local vehKey = savegame.key
	local xmlPath = vehFile:getString(vehKey.."#filename")
	
	local spec = vehicle.spec_DashboardLive
	local specDb = vehicle.spec_dashboard
	
	local xmlFile = XMLFile.loadIfExists("VanillaDashboards", spec.vanillaDashboardsFile, "Dashboard")
	
	dbgprint_r(xmlFile.schema, 4, 3)
	
	local i = 0
	while xmlFile ~= nil do
		local xmlRootPath = string.format("vanillaDashboards.vehicleDashboard(%d)", i)
		dbgprint("createVanillaGroups : xmlRootPath: "..tostring(xmlRootPath), 2)
	
		if not xmlFile:hasProperty(xmlRootPath) then 
			break 
		end
	
		local vanillaFile = xmlFile:getString(xmlRootPath .. "#fileName")
		dbgprint("createVanillaGroups : vanillaFile: "..tostring(vanillaFile), 2)
	
		if vanillaFile == xmlPath then
			dbgprint("createVanillaGroups : found vehicle in vanillaDashboards", 2)

			-- Own stuff inserted and Giant's stuff reused: Load Dashboard groups into vanilla vehicles
			local n = 0
			while true do
				local baseKey = string.format("%s.groups.group(%d)", xmlRootPath, n)
				dbgprint("createVanillaGroups : baseKey "..baseKey, 2)
	
				if not xmlFile:hasProperty(baseKey) then
					break
				end

				local group = {}
				dbgprint("loadDashboardGroupFromXML : trying to read dashboard group", 2)
				--if vehicle:loadDashboardGroupFromXML(xmlFile, baseKey, group) then
				--	dbgprint("createVanillaGroups : DashboardGroupLoaded: basekey="..tostring(baseKey).." / group="..tostring(group.name), 2)
				--	specDb.groups[group.name] = group
				--	table.insert(specDb.sortedGroups, group)
				--	specDb.hasGroups = true
				--else
				--	dbgprint("loadDashboardGroupFromXML : no dashboard group loaded", 2)
				--end

				n = n + 1
			end
		end
		i = i + 1
	end
end

function DashboardUtils.createVanillaDashboards(vehicle, savegame)
	dbgprint("createVanillaDashboards : started", 2)
	local vehFile = savegame.xmlFile
	local vehKey = savegame.key
	local xmlPath = vehFile:getString(vehKey.."#filename")
	
	local spec = vehicle.spec_DashboardLive
	local specDb = vehicle.spec_dashboard
	
	local xmlFile = XMLFile.loadIfExists("VanillaDashboards", spec.vanillaDashboardsFile, "Dashboard")
	
	local i = 0
	while xmlFile ~= nil do
		local xmlRootPath = string.format("vanillaDashboards.vehicleDashboard(%d)", i)
		dbgprint("createVanillaDashboards : xmlRootPath: "..tostring(xmlRootPath), 2)
	
		if not xmlFile:hasProperty(xmlRootPath) then 
			break 
		end
	
		local vanillaFile = xmlFile:getString(xmlRootPath .. "#fileName")
		dbgprint("createVanillaDashboards : vanillaFile: "..tostring(vanillaFile), 2)
	
		if vanillaFile == xmlPath then
			dbgprint("createVanillaDashboards : found vehicle in vanillaDashboards", 2)

			-- Own stuff inserted and Giant's stuff reused: Load Dashboard groups into vanilla vehicles
			--local n = 0
			--while true do
				local baseKey = string.format("%s.default", xmlRootPath, n)
				dbgprint("createVanillaDashboards : baseKey "..baseKey, 2)
				vehicle:loadDashboardsFromXML(xmlFile, baseKey, dashboardData)
    			dbgprint("createVanillaDashboards : loadDashboardsFromXml executed for vanilla", 2)
				--n = n + 1
			--end
		end
		i = i + 1
	end
end