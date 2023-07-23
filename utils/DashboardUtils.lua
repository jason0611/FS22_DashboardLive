DashboardUtils = {}

-- Vanilla Integration POC --

function DashboardUtils.createVanillaNodes(vehicle, xmlVanillaFile, xmlModFile)
	local spec = vehicle.spec_DashboardLive
	
	if vehicle.xmlFile == nil then return false end
	local xmlPath = vehicle.xmlFile.filename
	
	local i3dLibPath = DashboardLive.MOD_PATH.."utils/DBL_MeshLibary"
	local i3dLibFile = "DBL_MeshLibary.i3d"
	local i3dMinimapFile = "DBL_minimap_plane.i3d"
	
	-- Inject extended Dashboard Symbols into Vanilla Vehicles
	dbgprint("createVanillaNodes : vehicle: "..vehicle:getName(), 2)
	dbgprint("createVanillaNodes : vehicle's filename: "..xmlPath, 2)
	
	for xmlPart, xmlFile in pairs({xmlVanillaFile ,xmlModFile}) do
		dbgprint("createVanillaNodes : Step "..tostring(xmlPart)..": "..tostring(xmlFile.filename), 2)
	
		if xmlFile ~= nil then
			dbgprint("createVanillaNodes : reading file", 2)
			local i = 0
			while true do
				local xmlRootPath = string.format("vanillaDashboards.vanillaDashboard(%d)", i)
				if not xmlFile:hasProperty(xmlRootPath) then break end
				dbgprint("createVanillaNodes : xmlRootPath: "..tostring(xmlRootPath), 2)
			
				local vanillaFile = xmlFile:getString(xmlRootPath .. "#fileName")
				dbgprint("createVanillaNodes : vanillaFile: "..tostring(vanillaFile), 2)
			
				if vanillaFile == xmlPath then
					dbgprint("createVanillaNodes : found vehicle in "..tostring(xmlFile.objectName), 2)
								
					local n = 0
					while true do
						local xmlNodePath = xmlRootPath .. string.format(".nodes.node(%d)", n)
						if not xmlFile:hasProperty(xmlNodePath) then break end
					
						local nodeName = xmlFile:getString(xmlNodePath .. "#name")
						if nodeName == nil then
							Logging.xmlWarning(xmlFile, "No node name given, setting to 'dashboardLive'")
							nodeName = "dashboardLive"
						end
					
						local node = xmlFile:getString(xmlNodePath .. "#node")
						if node == nil then
							Logging.xmlWarning(xmlFile, "No root node given, setting to 0>0")
							node = "0>0"
						end
					
						local index = xmlFile:getString(xmlNodePath .. "#symbol")
						if index == nil then
							Logging.xmlWarning(xmlFile, "No symbol given, setting to 0|1")
							index = "0|1"
						elseif index == "map" then
							index = "0"
							i3dLibFile = i3dMinimapFile
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
						
						local sx, sy, sz = 1, 1, 1
						local scale = xmlFile:getVector(xmlNodePath .. "#scale")
						if scale ~= nil then 
							sx, sy, sz = unpack(scale)
						else
							Logging.xmlWarning(xmlFile, "No node scale given, setting to 1 1 1")
						end
					
						dbgprint("nodeName: "..tostring(nodeName), 2)
						dbgprint("node: "..tostring(node), 2)
						dbgprint(string.format("moveTo: %f %f %f", nx, ny, nz), 2)
						dbgprint(string.format("rotate: %f %f %f", rx, ry, rz), 2)
					
						local i3d = g_i3DManager:loadSharedI3DFile(i3dLibPath.."/"..i3dLibFile, false, false)
						local symbol = I3DUtil.indexToObject(i3d, index)
						local linkNode = I3DUtil.indexToObject(vehicle.components, node, vehicle.i3dMappings)
		
						setTranslation(symbol, nx, ny, nz)
						setRotation(symbol, math.rad(rx), math.rad(ry), math.rad(rz))
						setScale(symbol, sx, sy, sz)
		
						link(linkNode, symbol)
						g_i3DManager:releaseSharedI3DFile(i3d, false)
						delete(i3d)
		
						if xmlPart == 1 then 
							spec.vanillaIntegration = i
						elseif xmlPart == 2 then
							spec.modIntegration = i
						end
						n = n + 1
					end
				end
				i = i + 1
			end
		end
	end
end

function DashboardUtils.createEditorNode(vehicle, node, symbolIndex, createMinimap)
	local spec = vehicle.spec_DashboardLive
	
	local i3dLibPath = DashboardLive.MOD_PATH.."utils/DBL_MeshLibary"
	local i3dLibFile
	local index
	if createMinimap == true then
	   i3dLibFile = "DBL_minimap_plane.i3d"
	   index = "0"
	else
	   i3dLibFile = "DBL_MeshLibary.i3d"
	   index = "0|"..tostring(symbolIndex)
	end
					
	local i3d = g_i3DManager:loadSharedI3DFile(i3dLibPath.."/"..i3dLibFile, false, false)
	local symbol = I3DUtil.indexToObject(i3d, index)
	local linkNode = I3DUtil.indexToObject(vehicle.components, node, vehicle.i3dMappings)
		
	setTranslation(symbol, DashboardLive.xTrans, DashboardLive.yTrans, DashboardLive.zTrans)
	setRotation(symbol, math.rad(DashboardLive.xRot), math.rad(DashboardLive.yRot), math.rad(DashboardLive.zRot))
	setScale(symbol, DashboardLive.xScl, DashboardLive.yScl, DashboardLive.zScl)
		
	link(linkNode, symbol)
	
	DashboardLive.editNode = node
	DashboardLive.editSymbol = symbol
	DashboardLive.editSymbolIndex = index
	g_i3DManager:releaseSharedI3DFile(i3d, false)
	delete(i3d)
end

--[[
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

--]]