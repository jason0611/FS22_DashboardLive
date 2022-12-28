--
-- Dashboard Extension for FS22
--
-- Jason06 / Glowins Modschmiede
--
DashboardLive = {}

if DashboardLive.MOD_NAME == nil then
	DashboardLive.MOD_NAME = g_currentModName
	DashboardLive.MOD_PATH = g_currentModDirectory
end
source(DashboardLive.MOD_PATH.."tools/gmsDebug.lua")
GMSDebug:init(DashboardLive.MOD_NAME, true, 2)
GMSDebug:enableConsoleCommands("dblDebug")

source(DashboardLive.MOD_PATH.."utils/DashboardUtils.lua")

-- DashboardLive Editor
DashboardLive.xTrans, DashboardLive.yTrans, DashboardLive.zTrans = 0, 0, 0
DashboardLive.xRot, DashboardLive.yRot, DashboardLive.zRot = 0, 0, 0
DashboardLive.editScale = 1
DashboardLive.editIndex = 1
DashboardLive.editNode = ""
DashboardLive.editSymbol = nil
DashboardLive.editSymbolIndex = ""
DashboardLive.editMode = false

DashboardLive.vanillaSchema = nil

-- Standards / Basics

function DashboardLive.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Dashboard, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations)
end

function DashboardLive.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dbl", "DashboardLive command")
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#op", "DashboardLive operator")
	schema:register(XMLValueType.INT, Dashboard.GROUP_XML_KEY .. "#page", "DashboardLive page")
	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#dblActiveWithoutImplement", "return 'true' without implement")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblAttacherJointIndices")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblSelection")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblSelectionGroup")
	schema:register(XMLValueType.INT, Dashboard.GROUP_XML_KEY .. "#dblRidgeMarker", "Ridgemarker state")
	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#dblAWI", "return 'true' without implement")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblAJI")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblS")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblSG")
	schema:register(XMLValueType.INT, Dashboard.GROUP_XML_KEY .. "#dblRM", "Ridgemarker state")
	dbgprint("initSpecialization : DashboardLive group options registered", 2)
	
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.dashboard.dashboardLive", "base fillLevel fillType vca hlm gps gps_lane gps_width proseed selector")
	DashboardLive.DBL_XML_KEY = "vehicle.dashboard.dashboardLive.dashboard(?)"
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#cmd", "DashboardLive command")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#joints")
	schema:register(XMLValueType.VECTOR_N, DashboardLive.DBL_XML_KEY .. "#selection")
	schema:register(XMLValueType.VECTOR_N, DashboardLive.DBL_XML_KEY .. "#selectionGroup")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#state", "state")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#trailer", "Trailer number")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#option", "Option")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#factor", "Factor")
	dbgprint("initSpecialization : DashboardLive element options registered", 2)
	
	DashboardLive.vanillaSchema = XMLSchema.new("vanillaIntegration")
	
	Dashboard.registerDashboardXMLPaths(DashboardLive.vanillaSchema, "vanillaDashboards.vanillaDashboard(?).dashboardLive", "base vca gps")
	DashboardLive.DBL_Vanilla_XML_KEY = "vanillaDashboards.vanillaDashboard(?).dashboardLive.dashboard(?)"
	
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#cmd", "DashboardLive command")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#joints")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#state", "state")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#option", "Option")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#factor", "Factor")
	dbgprint("initSpecialization : vanillaSchema element options registered", 2)
end

function DashboardLive.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", DashboardLive)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", DashboardLive)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", DashboardLive)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", DashboardLive)
end

function DashboardLive.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", DashboardLive.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", DashboardLive.getIsDashboardGroupActive)
end

function DashboardLive:onPreLoad(savegame)
	self.spec_DashboardLive = self["spec_"..DashboardLive.MOD_NAME..".DashboardLive"]
	local spec = self.spec_DashboardLive
end

function DashboardLive:onLoad(savegame)
	local spec = self.spec_DashboardLive
	
	-- management data
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.actPage = 1
	spec.maxPage = 1
	spec.groups = {}
	spec.groups[1] = true
	spec.updateTimer = 0
	
	-- zoom data
	spec.zoomed = false
	spec.zoomPressed = false
	spec.zoomPerm = false
	
	-- selector data
	spec.selectorActive = 0
	
	-- engine data
	spec.motorTemperature = 20
	spec.fanEnabled = false
	spec.fanEnabledLast = false
	spec.lastFuelUsage = 0
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
	
	-- Integrate vanilla dashboards
	DashboardLive.vanillaIntegrationXML = DashboardLive.MOD_PATH.."xml/vanillaDashboards.xml"
	DashboardLive.vanillaIntegrationXMLFile = XMLFile.loadIfExists("VanillaDashboards", DashboardLive.vanillaIntegrationXML, DashboardLive.vanillaSchema)
	if DashboardLive.vanillaIntegrationXMLFile ~= nil then
		DashboardUtils.createVanillaNodes(self, DashboardLive.vanillaIntegrationXMLFile)
	end
	
	-- Load and initialize Dashboards from XML
	if self.loadDashboardsFromXML ~= nil then
		local dashboardData
		dbgprint("onLoad : loadDashboardsFromXML", 2)
        -- base
        dashboardData = {	
        					valueTypeToLoad = "base",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveBase,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesBase
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <base>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        -- fillLevel
        dashboardData = {	
        					valueTypeToLoad = "fillLevel",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveFillLevel,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesFillLevel
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        -- fillType
        dashboardData = {	
        					valueTypeToLoad = "fillType",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveFillLevel,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesFillType
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        -- vca
        dashboardData = {	
        					valueTypeToLoad = "vca",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveVCA,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesVCA
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <vca>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
		-- hlm
        dashboardData = {	
        					valueTypeToLoad = "hlm",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveHLM,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesHLM
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
		-- gps
        dashboardData = {	
        					valueTypeToLoad = "gps",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveGPS,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesGPS
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <gps>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
		-- gpsLane
        dashboardData = {	
        					valueTypeToLoad = "gpsLane",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveGPSLane,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesGPSNumbers
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
		-- gpsWidth
        dashboardData = {	
        					valueTypeToLoad = "gpsWidth",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveGPSWidth,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesGPSNumbers
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)

		
		-- ps
        dashboardData = {	
        					valueTypeToLoad = "proSeed",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLivePS,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesPS
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
		-- selection
        dashboardData = {	
        					valueTypeToLoad = "selection",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveSelection,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesSelection
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
        -- print
        dashboardData = {	
        					valueTypeToLoad = "print",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLivePrint,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesPrint
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
    end
end

function DashboardLive:onPostLoad(savegame)
    local spec = self.spec_DashboardLive
	dbgprint("onPostLoad: "..self:getName(), 2)

	-- Check if Mod GuidanceSteering exists
	spec.modGuidanceSteeringFound = self.spec_globalPositioningSystem ~= nil
	
	-- Check if Mod VCA exists
	spec.modVCAFound = self.vcaGetState ~= nil
	
	-- Check if Mod EV exists
	spec.modEVFound = FS22_EnhancedVehicle ~= nil and FS22_EnhancedVehicle.FS22_EnhancedVehicle ~= nil and FS22_EnhancedVehicle.FS22_EnhancedVehicle.onActionCall ~= nil
	
	-- Check if Mod SpeedControl exists
	spec.modSpeedControlFound = FS22_SpeedControl ~= nil and FS22_SpeedControl.SpeedControl ~= nil
	
	--Check if Mod HeadlandManagement exists
	spec.modHLMFound = self.spec_HeadlandManagement ~= nil
	
    local dashboard = self.spec_dashboard
    for _, group in pairs(dashboard.groups) do
    	if group.dblPage ~= nil then
    		spec.maxPage = math.max(spec.maxPage, group.dblPage)
    		spec.groups[group.dblPage] = true
    		dbgprint("onPostLoad : maxPage set to "..tostring(spec.maxPage), 2)
    	else
    		dbgprint("onPostLoad : no pages found in group "..group.name, 2)
    	end
    end
end

-- Network stuff to synchronize engine data not synced by the game itself

function DashboardLive:onReadStream(streamId, connection)
	local spec = self.spec_DashboardLive
	spec.motorTemperature = streamReadFloat32(streamId)
	spec.fanEnabled = streamReadBool(streamId)
	spec.lastFuelUsage = streamReadFloat32(streamId)
	spec.lastDefUsage = streamReadFloat32(streamId)
	spec.lastAirUsage = streamReadFloat32(streamId)
end

function DashboardLive:onWriteStream(streamId, connection)
	local spec = self.spec_DashboardLive
	streamWriteFloat32(streamId, spec.motorTemperature)
	streamWriteBool(streamId, spec.fanEnabled)
	streamWriteFloat32(streamId, spec.lastFuelUsage)
	streamWriteFloat32(streamId, spec.lastDefUsage)
	streamWriteFloat32(streamId, spec.lastAirUsage)
end
	
function DashboardLive:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamReadBool(streamId) then
			spec.motorTemperature = streamReadFloat32(streamId)
			spec.fanEnabled = streamReadBool(streamId)
			spec.lastFuelUsage = streamReadFloat32(streamId)
			spec.lastDefUsage = streamReadFloat32(streamId)
			spec.lastAirUsage = streamReadFloat32(streamId)
		end
	end
end

function DashboardLive:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, spec.motorTemperature)
			streamWriteBool(streamId, spec.fanEnabled)
			streamWriteFloat32(streamId, spec.lastFuelUsage)
			streamWriteFloat32(streamId, spec.lastDefUsage)
			streamWriteFloat32(streamId, spec.lastAirUsage)
			self.spec_motorized.motorTemperature.valueSend = spec.motorTemperature
		end
	end
end

-- inputBindings / inputActions
	
function DashboardLive:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 4)
	if self.isClient then
		local spec = self.spec_DashboardLive
		DashboardLive.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil then 
			local actionEventId
			local sk = spec.maxPage > 1
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_PAGEUP', self, DashboardLive.CHANGEPAGE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, sk)
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_PAGEDN', self, DashboardLive.CHANGEPAGE, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventTextVisibility(actionEventId, sk)
		end	
		_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZOOM', self, DashboardLive.ZOOM, false, true, true, true, nil)	
		_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZOOM_PERM', self, DashboardLive.ZOOM, false, true, false, true, nil)	
		
		if DashboardLive.editMode and DashboardLive.editSymbol ~= nil and self:getIsActiveForInput(true) and spec ~= nil then 
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XUP', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XDN', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YUP', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YDN', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZUP', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZDN', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XR', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XL', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YR', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YL', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZR', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZL', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_SCALEIN', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_SCALEOUT', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
			_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_PRINTOUT', self, DashboardLive.PRINTSYMBOL, false, true, false, true, nil)				
		end	
		
	end
end

function DashboardLive:CHANGEPAGE(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("CHANGEPAGE", 4)
	local spec = self.spec_DashboardLive
	if actionName == "DBL_PAGEUP" then
		local pageNum = spec.actPage + 1
		while not spec.groups[pageNum] do
			pageNum = pageNum + 1
			if pageNum > spec.maxPage then pageNum = 1 end
		end
		spec.actPage = pageNum
		dbgprint("CHANGEPAGE : NewPage = "..spec.actPage, 2)
	end
	if actionName == "DBL_PAGEDN" then
		local pageNum = spec.actPage - 1
		while not spec.groups[pageNum] do
			pageNum = pageNum - 1
			if pageNum < 1 then pageNum = spec.maxPage end
		end
		spec.actPage = pageNum
		dbgprint("CHANGEPAGE : NewPage = "..spec.actPage, 2)
	end
end

function DashboardLive:ZOOM(actionName, keyStatus, arg3, arg4, arg5)
	dbgprint("ZOOM", 4)
	local spec = self.spec_DashboardLive
	if actionName == "DBL_ZOOM_PERM" then
		spec.zoomPerm = not spec.zoomPerm
	end
	spec.zoomPressed = true
end

-- Dashboard Editor Mode

function DashboardLive:startEditorMode(node, index)
	if node ~= nil and index ~= nil then
		DashboardUtils.createEditorNode(g_currentMission.controlledVehicle, tostring(node), tonumber(index))
		DashboardLive.editMode = true
	else
		if DashboardLive.editSymbol ~= nil then
			setVisibility(DashboardLive.editSymbol, false)
		end
		DashboardLive.editSymbol = nil
		DashboardLive.editMode = false
	end
end
addConsoleCommand("dblEditorMode", "Glowins Mod Smithery: Enable Editor Mode: dblEditorMode [<node>]", "startEditorMode", DashboardLive)

function DashboardLive:MOVESYMBOL(actionName, keyStatus)
	dbgprint("MOVESYMBOL", 4)
	if DashboardLive.editSymbol == nil then return end

	if actionName == "DBL_XUP" then
		DashboardLive.xTrans = DashboardLive.xTrans - 0.0001
		dbgprint("xTrans: "..tostring(DashboardLive.xTrans), 2)
	elseif actionName == "DBL_XDN" then
		DashboardLive.xTrans = DashboardLive.xTrans + 0.0001
		dbgprint("xTrans: "..tostring(DashboardLive.xTrans), 2)
	elseif actionName == "DBL_YUP" then
		DashboardLive.yTrans = DashboardLive.yTrans + 0.0001
		dbgprint("yTrans: "..tostring(DashboardLive.yTrans), 2)
	elseif actionName == "DBL_YDN" then
		DashboardLive.yTrans = DashboardLive.yTrans - 0.0001
		dbgprint("yTrans: "..tostring(DashboardLive.yTrans), 2)
	elseif actionName == "DBL_ZUP" then
		DashboardLive.zTrans = DashboardLive.zTrans + 0.0001
		dbgprint("zTrans: "..tostring(DashboardLive.zTrans), 2)
	elseif actionName == "DBL_ZDN" then
		DashboardLive.zTrans = DashboardLive.zTrans - 0.0001
		dbgprint("zTrans: "..tostring(DashboardLive.zTrans), 2)
	elseif actionName == "DBL_XR" then
		DashboardLive.xRot = DashboardLive.xRot + 1
		dbgprint("xRot: "..tostring(DashboardLive.xRot), 2)
	elseif actionName == "DBL_XL" then
		DashboardLive.xRot = DashboardLive.xRot - 1
		dbgprint("xRot: "..tostring(DashboardLive.xRot), 2)
	elseif actionName == "DBL_YR" then
		DashboardLive.yRot = DashboardLive.yRot + 1
		dbgprint("yRot: "..tostring(DashboardLive.yRot), 2)
	elseif actionName == "DBL_YL" then
		DashboardLive.yRot = DashboardLive.yRot - 1
		dbgprint("yRot: "..tostring(DashboardLive.yRot), 2)
	elseif actionName == "DBL_ZR" then
		DashboardLive.zRot = DashboardLive.zRot + 1
		dbgprint("zRot: "..tostring(DashboardLive.zRot), 2)
	elseif actionName == "DBL_ZL" then
		DashboardLive.zRot = DashboardLive.zRot - 1
		dbgprint("zRot: "..tostring(DashboardLive.zRot), 2)
	elseif actionName == "DBL_SCALEIN" then
		DashboardLive.editScale = DashboardLive.editScale + 0.001
		dbgprint("scale: "..tostring(DashboardLive.editScale), 2)
	elseif actionName == "DBL_SCALEOUT" then
		DashboardLive.editScale = DashboardLive.editScale - 0.001
		dbgprint("scale: "..tostring(DashboardLive.editScale), 2)
	end
	setTranslation(DashboardLive.editSymbol, DashboardLive.xTrans, DashboardLive.yTrans, DashboardLive.zTrans)
	setRotation(DashboardLive.editSymbol, math.rad(DashboardLive.xRot), math.rad(DashboardLive.yRot), math.rad(DashboardLive.zRot))
	setScale(DashboardLive.editSymbol, DashboardLive.editScale, DashboardLive.editScale, DashboardLive.editScale)
end

function DashboardLive:PRINTSYMBOL(actionName, keyStatus)
	print("DashboardLive Editor Printout:")
	print("==============================")
	print("Vehicle: "..self:getName())
	local xmlPath
	if self.xmlFile ~= nil then
		xmlPath = self.xmlFile.filename
	end
	print("Vehicle XML-Path: "..tostring(xmlPath))
	print("Reference node: "..tostring(DashboardLive.editNode))
	print("x_trans = "..tostring(DashboardLive.xTrans))
	print("y_trans = "..tostring(DashboardLive.yTrans))
	print("z_trans = "..tostring(DashboardLive.zTrans))
	print("x_rot = "..tostring(DashboardLive.xRot))
	print("y_rot = "..tostring(DashboardLive.yRot))
	print("z_rot = "..tostring(DashboardLive.zRot))
	print("scale = "..tostring(DashboardLive.editScale))
	if xmlPath == nil then return end
	print("==============================")
	print("<vanillaDashboard name=\""..tostring(self:getName()).."\" fileName=\""..tostring(xmlPath).."\" >")
	print("	<nodes>")
	print("		<node name=\"<set a name here>\" node=\""..DashboardLive.editNode.."\" symbol=\""..DashboardLive.editSymbolIndex.."\" moveTo=\""..tostring(DashboardLive.xTrans).." "..tostring(DashboardLive.yTrans).." "..tostring(DashboardLive.zTrans).."\" rotate=\""..tostring(DashboardLive.xRot).." "..tostring(DashboardLive.yRot).." "..tostring(DashboardLive.zRot).."\" scale=\""..tostring(DashboardLive.editScale).."\"/>")
	print("	</nodes>")
	print("</vanillaDashboard")
	print("==============================")
end



-- Main script
-- ===========

-- Debug stuff

function DashboardLive:onPostAttachImplement(implement, x, jointDescIndex)
	-- implement - attacherJoint
	dbgprint("Implement "..implement:getFullName().." attached to "..self:getFullName().." at index "..tostring(jointDescIndex), 2)
	if implement.getAllowsLowering ~= nil then
		dbgprint("Implement is lowerable: "..tostring(implement:getAllowsLowering()), 2)
	end
	if implement.spec_pickup ~= nil then
		dbgprint("Implement has pickup", 2)
	end
	dbgprint_r(implement, 4, 0)
end

-- Supporting functions

local function trim(text, textLength)
	local l = string.len(text)
	if l == textLength then
		return text
	elseif l < textLength then
		local diff = textLength - l
		local newText = string.rep(" ", math.floor(diff/2))..text..string.rep(" ", math.floor(diff/2))
		if string.len(newText) < textLength then
			newText = newText .. " "
		end
		return newText
	elseif l > textLength then
		return string.sub(text, 1, textLength)
	end
end

local function findSpecialization(device, specName)
	if device ~= nil and device[specName] ~= nil then
		return device[specName]
	elseif device.getAttachedImplements ~= nil then
		local implements = device:getAttachedImplements()
		for _,implement in pairs(implements) do
			local device = implement.object
			local spec = findSpecialization(device, specName)
			if spec ~= nil then 
				return spec 
			end
		end
	else 
		return nil
	end
end

local function findSpecializationImplement(device, specName)
	if device ~= nil and device[specName] ~= nil then
		return device
	elseif device.getAttachedImplements ~= nil then
		local implements = device:getAttachedImplements()
		for _,implement in pairs(implements) do
			local device = findSpecializationImplement(implement.object, specName)
			if device ~= nil then 
				return device 
			end
		end
	else 
		return nil
	end
end

local function findPTOStatus(device)
	if device ~= nil and device.getIsPowerTakeOffActive ~= nil and device:getIsPowerTakeOffActive() then
		return true
	elseif device.getAttachedImplements ~= nil then
		local implements = device:getAttachedImplements()
		for _,implement in pairs(implements) do
			local device = implement.object
			return findPTOStatus(device)
		end
		return false
	else 
		return false
	end
end

local function getAttachedStatus(vehicle, element, mode, default)
	
	if element.dblAttacherJointIndices == nil then
		if element.attacherJointIndices ~= nil then
			element.dblAttacherJointIndices = element.attacherJointIndices
		else
			Logging.xmlWarning(vehicle.xmlFile, "No attacherJointIndex given for DashboardLive attacher command "..tostring(mode))
			return false
		end
	end
	
	local joints 
	if type(element.dblAttacherJointIndices) == "number" then
		joints = {}
		joints[1] = element.dblAttacherJointIndices
	elseif type(element.dblAttacherJointIndices) == "table" then
		joints = element.dblAttacherJointIndices
	else
		joints = string.split(element.dblAttacherJointIndices, " ")
	end
	local result = default or false
	local noImplement = true
	
    for _, jointIndex in ipairs(joints) do
    	dbgprint("jointIndex: "..tostring(tonumber(jointIndex)), 4)
    	local implement = vehicle:getImplementFromAttacherJointIndex(tonumber(jointIndex)) 
    	dbgprint("implement: "..tostring(implement), 4)
    	dbgprint_r(implement, 4, 1)
    	if implement ~= nil then
    		noImplement = false
    		local foldable = implement.object.spec_foldable ~= nil and implement.object.spec_foldable.foldingParts ~= nil and #implement.object.spec_foldable.foldingParts > 0
            if mode == "raised" then
            	result = implement.object.getIsLowered ~= nil and not implement.object:getIsLowered() or false
            	dbgprint(implement.object:getFullName().." raised: "..tostring(result), 4)
            elseif mode == "lowered" then
            	result = implement.object.getIsLowered ~= nil and implement.object:getIsLowered() or false
            	dbgprint(implement.object:getFullName().." lowered: "..tostring(result), 4)
            elseif mode == "lowerable" then
				result = (implement.object.getAllowsLowering ~= nil and implement.object:getAllowsLowering()) or implement.object.spec_pickup ~= nil or false
				dbgprint(implement.object:getFullName().." lowerable: "..tostring(result), 4)
			elseif mode == "pto" then
				return findPTOStatus(implement.object)
            elseif mode == "foldable" then
				result = foldable or false
				dbgprint(implement.object:getFullName().." foldable: "..tostring(result), 4)
			elseif mode == "folded" then
            	result = foldable and implement.object.getIsUnfolded ~= nil and not implement.object:getIsUnfolded() or false
            	dbgprint(implement.object:getFullName().." folded: "..tostring(result), 4)
            elseif mode == "unfolded" then
            	result = foldable and implement.object.getIsUnfolded ~= nil and implement.object:getIsUnfolded() or false
            	dbgprint(implement.object:getFullName().." unfolded: "..tostring(result), 4)
            elseif mode == "ridgeMarker" then
            	local specRM = findSpecialization(implement.object, "spec_ridgeMarker")
            	result = specRM ~= nil and specRM.ridgeMarkerState or 0
            elseif mode == "disconnected" then
            	dbgprint("AttacherJoint #"..tostring(jointIndex).." not disonnected", 4)
            end
        end
        dbgprint("result / noImplement: "..tostring(result).." / "..tostring(noImplement), 4)
    end
    if mode == "disconnected" and noImplement then
        result = true
        dbgprint("Disconnected!", 4)
    end
    dbgprint("ReturnValue: "..tostring(result), 4)
    return result
end

-- recursive search through all attached vehicles including rootVehicle
-- usage: call getIndexOfActiveImplement(rootVehicle)

local function getIndexOfActiveImplement(rootVehicle, level)
	
	local level = level or 1
	local returnVal = 0
	local returnSign = 1
	
	if not rootVehicle:getIsActiveForInput() and rootVehicle.spec_attacherJoints ~= nil and rootVehicle.spec_attacherJoints.attacherJoints ~= nil then
	
		for _,impl in pairs(rootVehicle.spec_attacherJoints.attachedImplements) do
			
			-- called from rootVehicle
			if level == 1 then
				local jointDescIndex = impl.jointDescIndex
				local jointDesc = rootVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]
				local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
				local _, _, lz = worldToLocal(rootVehicle.steeringAxleNode, wx, wy, wz)
				if lz > 0 then 
					returnSign = 1
				else 
					returnSign = -1
				end 
			end
			
			if impl.object:getIsActiveForInput() then
				returnVal = level
			else
				returnVal = getIndexOfActiveImplement(impl.object, level+1)
			end
			-- found active implement? --> exit recursion
			if returnVal ~= 0 then break end
		
		end		
	end

	return returnVal * returnSign
end

	
local function getFillLevel(device, ftType)
	dbgprint("getFillLevel", 4)
	local fillLevel = {abs = nil, pct = nil, max = nil}
	if device.spec_fillUnit ~= nil then -- only if device has got a fillUnit
		local fillUnits = device:getFillUnits()
		for i,_ in pairs(fillUnits) do
			local ftIndex = device:getFillUnitFillType(i)
			local ftCategory = g_fillTypeManager.categoryNameToFillTypes[ftType]
			if ftIndex == g_fillTypeManager.nameToIndex[ftType] or ftCategory ~= nil and ftCategory[ftIndex] or ftType == "ALL" then
				if fillLevel.pct == nil then fillLevel.pct, fillLevel.abs, fillLevel.max = 0, 0, 0 end
				fillLevel.pct = fillLevel.pct + device:getFillUnitFillLevelPercentage(i)
				fillLevel.abs = fillLevel.abs + device:getFillUnitFillLevel(i)
				fillLevel.max = fillLevel.max + device:getFillUnitCapacity(i)
			end
		end
	end
	return fillLevel
end

-- returns fillLevel {pct, abs, max}
-- param vehicle - vehicle reference
-- param ftIndex - index of fillVolume: 1 - root/first trailer/implement, 2 - first/second trailer/implement, 3 - root/first and first/second trailer or implement
-- param ftType  - fillType

local function getFillLevelStatus(vehicle, ftIndex, ftType)
	dbgprint("getFillLevelStatus", 4)
	local spec = vehicle.spec_DashboardLive
	local fillLevel = {abs = nil, pct = nil, max = nil}
	
	if ftType == nil then ftType = "ALL" end
	
	if ftType ~= "ALL" and g_fillTypeManager.nameToIndex[ftType] == nil and g_fillTypeManager.nameToCategoryIndex[ftType] == nil then
		Logging.xmlWarning(vehicle.xmlFile, "Given fillType "..tostring(ftType).." not known!")
		return fillLevel
	end
	
	-- root vehicle	
	if ftIndex == 0 then
		dbgprint("getFillLevelStatus : root vehicle", 4)
		fillLevel = getFillLevel(vehicle, ftType)
	end
	
	-- if no attacherJoint exists we are ready here
	if vehicle.spec_attacherJoints == nil then return fillLevel end
	
	-- implements 
	
	-- first volume
	local allImplements = vehicle:getAttachedImplements()
	if ftIndex == 1 then	
		dbgprint("getFillLevelStatus : first attached vehicle", 4)
		for _, implement in pairs(allImplements) do
			fillLevel = getFillLevel(implement.object, ftType)
		end
	end

	-- second volume
	if ftIndex == 2 then
		dbgprint("getFillLevelStatus : second attached vehicle", 4)
		for _, implement in pairs(allImplements) do
			if implement.object.spec_attacherJoints ~= nil then
				local allSubImplements = implement.object:getAttachedImplements()
				for _, subImplement in pairs(allSubImplements) do
					fillLevel = getFillLevel(subImplement.object, ftType)
				end
			end
		end
	end
	--dbgrenderTable(fillLevel, 1 + 5 * ftIndex, 3)
	return fillLevel
end

-- GROUPS

function DashboardLive:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
        dbgprint("loadDashboardGroupFromXML : superfunc failed for group "..tostring(group.name), 2)
        return false
    end
    dbgprint("loadDashboardGroupFromXML : group: "..tostring(group.name), 2)
    
    group.dblCommand = xmlFile:getValue(key .. "#dbl")
    dbgprint("loadDashboardGroupFromXML : dblCommand: "..tostring(group.dblCommand), 2)
	
	if group.dblCommand == "page" then
		group.dblPage = xmlFile:getValue(key .. "#page")
		dbgprint("loadDashboardGroupFromXML : page: "..tostring(group.dblPage), 2)
	end
	
	group.dblOperator = xmlFile:getValue(key .. "#op", "and")
	dbgprint("loadDashboardGroupFromXML : dblOperator: "..tostring(group.dblOperator), 2)
	
	local dblActiveWithoutImplement = xmlFile:getValue(key.. "#dblActiveWithoutImplement", false)
	if dblActiveWithoutImplement == nil then
		dblActiveWithoutImplement = xmlFile:getValue(key.. "#dblAWI", false)
	end
	group.dblActiveWithoutImplement = dblActiveWithoutImplement
	dbgprint("loadDashboardGroupFromXML : dblActiveWithoutImplement: "..tostring(group.dblActiveWithoutImplement), 2)
	
	local dblAttacherJointIndices = xmlFile:getValue(key .. "#dblAttacherJointIndices")
	if dblAttacherJointIndices == nil then
		dblAttacherJointIndices = xmlFile:getValue(key .. "#dblAJI")
	end
	group.dblAttacherJointIndices = dblAttacherJointIndices
	dbgprint("loadDashboardGroupFromXML : dblAttacherJointIndices: "..tostring(group.dblAttacherJointIndices), 2)
	
	local dblSelection = xmlFile:getValue(key .. "#dblSelection")
	if dblSelection == nil then
		dblSelection = xmlFile:getValue(key .. "#dblS")
	end
	group.dblSelection = dblSelection
	dbgprint("loadDashboardGroupFromXML : dblSelection: "..tostring(group.dblSelection), 2)
	
	local dblSelectionGroup = xmlFile:getValue(key .. "#dblSelectionGroup")
	if dblSelectionGroup == nil then
		dblSelectionGroup = xmlFile:getValue(key .. "#dblSG")
	end
	group.dblSelectionGroup = dblSelectionGroup
	dbgprint("loadDashboardGroupFromXML : dblSelectionGroup: "..tostring(group.dblSelectionGroup), 2)
	
	local dblRidgeMarker = xmlFile:getValue(key .. "#dblRidgeMarker")
	if dblRidgeMarker == nil then
		dblRidgeMarker = xmlFile:getValue(key .. "#dblRM")
	end
	dbgprint("loadDashboardGroupFromXML : dblRidgeMarker: "..tostring(group.dblRidgeMarker), 2)
    
    return true
end

function DashboardLive:getIsDashboardGroupActive(superFunc, group)
    local spec = self.spec_DashboardLive
    local specCS = self.spec_crabSteering
    local specWM = self.spec_workMode
    local specRM = self.spec_ridgeMarker
    
	local returnValue = false
	
	-- command given?
	if group.dblCommand == nil then 
		return superFunc(self, group)

	-- page
	elseif group.dblCommand == "page" and group.dblPage ~= nil then 
		returnValue = spec.actPage == group.dblPage
	
	-- vanilla game selector
	elseif group.dblCommand == "base_selector" and group.dblSelection ~= nil then
		local dblOpt = group.dblSelection
		local selectorActive = false
		if type(dblOpt) == "number" and dblOpt == -100 then
			returnValue = spec.selectorActive < 0
		elseif type(dblOpt) == "number" and dblOpt == 100 then
			returnValue = spec.selectorActive > 0
		else
			for _,selector in ipairs(dblOpt) do
				if selector == spec.selectorActive then selectorActive = true end
			end
			returnValue = selectorActive
		end
		
	-- vanilla game selector group
	elseif group.dblCommand == "base_selectorGroup" then
		local dblOpt = group.dblSelectionGroup
		local groupActive = false
		if dblOpt ~= "" then
			for _,selGroup in ipairs(dblOpt) do
				if selGroup == spec.selectorGroup then groupActive = true end
			end
		end
		returnValue = groupActive
		
	-- vanilla game implements
	elseif group.dblCommand == "base_disconnected" then
		returnValue = getAttachedStatus(self, group, "disconnected")
	
	elseif group.dblCommand == "base_lifted" then
		returnValue = getAttachedStatus(self, group, "raised", group.dblActiveWithoutImplement)
		
	elseif group.dblCommand == "base_lowered" then
		returnValue = getAttachedStatus(self, group, "lowered", group.dblActiveWithoutImplement)
	
	elseif group.dblCommand == "base_lowerable" then
		returnValue = getAttachedStatus(self, group, "lowerable", group.dblActiveWithoutImplement)
	
	elseif group.dblCommand == "base_pto" then
		returnValue = getAttachedStatus(self, group, "pto", group.dblActiveWithoutImplement)
	
	elseif group.dblCommand == "base_foldable" then
		returnValue = getAttachedStatus(self, group, "foldable", group.dblActiveWithoutImplement)
	
	elseif group.dblCommand == "base_folded" then
		returnValue = getAttachedStatus(self, group, "folded", group.dblActiveWithoutImplement)	
	
	elseif group.dblCommand == "base_unfolded" then
		returnValue = getAttachedStatus(self, group, "unfolded", group.dblActiveWithoutImplement)	
		
	elseif specCS ~= nil and group.dblCommand == "base_steering" then
		local dblOpt = group.dblOption
		if dblOpt == "" or tonumber(dblOpt) == nil then
			Logging.xmlWarning(vehicle.xmlFile, "No steering mode number given for DashboardLive steering command")
			return false
		end
		returnValue = specCS.state == tonumber(dblOpt)

	elseif specWM ~= nil and group.dblCommand == "base_swath" then
		local dblOpt = group.dblOption
		if dblOpt == "" or tonumber(dblOpt) == nil then
			Logging.xmlWarning(vehicle.xmlFile, "No work mode number given for DashboardLive swath command")
			return false
		end
		returnValue = specWM.state == tonumber(dblOpt)
		
	-- vanilla game ridgeMarker
	elseif specRM ~= nil and group.dblCommand == "base_ridgeMarker" then
		returnValue = group.dblRidgeMarker == specRM.ridgeMarkerState
		
	-- VCA / EV
	elseif group.dblCommand == "vca_park" or group.dblCommand == "ev_park" then
		returnValue = (spec.modVCAFound and self:vcaGetState("handbrake"))
					or(spec.modEVFound and self.vData.is[13])
	
	elseif group.dblCommand == "vca_diff_front" or group.dblCommand == "ev_diff_front" then
		returnValue = (spec.modVCAFound and self:vcaGetState("diffLockFront"))
					or(spec.modEVFound and self.vData.is[1])
	
	elseif group.dblCommand == "vca_diff_back" or group.dblCommand == "ev_diff_back"then
		returnValue = (spec.modVCAFound and self:vcaGetState("diffLockBack"))
					or(spec.modEVFound and self.vData.is[2])
	
	elseif group.dblCommand == "vca_diff" or group.dblCommand == "ev_diff" then
		returnValue = (spec.modVCAFound and (self:vcaGetState("diffLockFront") or self:vcaGetState("diffLockBack")))
					or(spec.modEVFound and (self.vData.is[1] or self.vData.is[2]))
	
	elseif group.dblCommand == "vca_diff_awd" or group.dblCommand == "ev_diff_awd" then
		returnValue = (spec.modVCAFound and self:vcaGetState("diffLockAWD"))
					or(spec.modEVFound and self.vData.is[3]==1)
		
	elseif group.dblCommand == "vca_diff_awdF" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffFrontAdv")
	
	-- VCA / keep speed
	elseif group.dblCommand == "vca_ks" then
		returnValue = spec.modVCAFound and self:vcaGetState("ksIsOn")
	
	-- Headland Management
	elseif group.dblCommand == "hlm_active_field" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn and not self.spec_HeadlandManagement.isActive
	
	elseif group.dblCommand == "hlm_active_headland" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn and self.spec_HeadlandManagement.isActive
	
	elseif group.dblCommand == "hlm_on" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn
		
	-- Guidance Steering
	elseif group.dblCommand == "gps_on" then
		local gsSpec = self.spec_globalPositioningSystem
		local hlmSpec = self.spec_HeadlandManagement
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceIsActive
		returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0) 
		returnValue = returnValue or (hlmSpec ~= nil and hlmSpec.exists and hlmSpec.isOn and hlmSpec.contour ~= 0)

	elseif group.dblCommand == "gps_active" then
		local gsSpec = self.spec_globalPositioningSystem
		local hlmSpec = self.spec_HeadlandManagement
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive
		returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapIsOn")) 
		returnValue = returnValue or (spec.modEVFound and self.vData.is[5])
		returnValue = returnValue or (hlmSpec ~= nil and hlmSpec.exists and hlmSpec.isOn and not hlmSpec.isActive and hlmSpec.contour ~= 0 and not contourSetActive)
		
	elseif group.dblCommand == "gps_lane+" then
		local spec = self.spec_DashboardLive
		local gsSpec = self.spec_globalPositioningSystem
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceIsActive
		returnValue = returnValue and gsSpec.guidanceData ~= nil and gsSpec.guidanceData.currentLane ~= nil and gsSpec.guidanceData.currentLane >= 0	

	elseif group.dblCommand == "gps_lane-" then
		local spec = self.spec_DashboardLive
		local gsSpec = self.spec_globalPositioningSystem
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceIsActive
		returnValue = returnValue and gsSpec.guidanceData ~= nil and gsSpec.guidanceData.currentLane ~= nil and gsSpec.guidanceData.currentLane < 0	
	end
	
    if group.dblOperator == "and" or group.dblCommand == "page" then 
    	return superFunc(self, group) and returnValue
    else
    	return superFunc(self, group) or returnValue
    end
end

-- ELEMENTS

-- base fillLevel fillType vca hlm gps gps_lane gps_width proseed selector

-- readAttributes
-- base
function DashboardLive.getDBLAttributesBase(self, xmlFile, key, dashboard)
	dashboard.dblCommand = xmlFile:getValue(key .. "#cmd")
    dbgprint("getDBLAttributesBase : command: "..tostring(dashboard.dblCommand), 2)
    if dashboard.dblCommand == nil then 
    	Logging.xmlWarning(self.xmlFile, "No '#cmd' given for valueType 'base'")
    	return false
    end
    
    dashboard.dblAttacherJointIndices = xmlFile:getValue(key .. "#joints")
	dbgprint("getDBLAttributesBase : joints: "..tostring(dashboard.dblAttacherJointIndices), 2)

	dashboard.dblState = xmlFile:getValue(key .. "#state") -- swath state, ridgemarker state
	dbgprint("getDBLAttributesBase : state: "..tostring(dashboard.dblState), 2)
	
	dashboard.dblOption = xmlFile:getValue(key .. "#option") -- nil or 'default'
	dbgprint("getDBLAttributesBase : option: "..tostring(dashboard.dblOption), 2)
	
	return true
end
-- fillLevel
function DashboardLive.getDBLAttributesFillLevel(self, xmlFile, key, dashboard)
	dashboard.dblTrailer = xmlFile:getValue(key .. "#trailer") -- trailer
	dbgprint("getDBLAttributesFillLevel : trailer: "..tostring(dashboard.dblTrailer), 2)
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "") -- empty=absolut or "percent"
    dbgprint("getDBLAttributesFillLevel : option: "..tostring(dashboard.dblOption), 2)
    if dashboard.dblOption == "percent" then
    	dashboard.minFunc = 0
    	dashboard.maxFunc = 1
	end
	return true
end
-- fillType
function DashboardLive.getDBLAttributesFillType(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#trailer") -- trailer
	dbgprint("getDBLAttributesFillType : trailer: "..tostring(dashboard.dblRidgeMarker), 2)
	if dashboard.dblOption == nil then 
    	Logging.xmlWarning(self.xmlFile, "No '#trailer' given for valueType 'fillType'")
    	return false
    end
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "") -- empty or wanted fillType
    dbgprint("getDBLAttributesFillType : option: "..tostring(dashboard.dblCommand), 2)

	return true
end
--vca
function DashboardLive.getDBLAttributesVCA(self, xmlFile, key, dashboard)
	dashboard.dblCommand = xmlFile:getValue(key .. "#cmd")
    dbgprint("getDBLAttributesVCA : cmd: "..tostring(dashboard.dblCommand), 2)
    if dashboard.dblCommand == nil then 
    	Logging.xmlWarning(self.xmlFile, "No '#cmd' given for valueType 'vca'")
    	return false
    end

	return true
end
--HLM
function DashboardLive.getDBLAttributesHLM(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#option")
    dbgprint("getDBLAttributesHLM : option: "..tostring(dashboard.dblOption), 2)

    return true
end
--  gps
function DashboardLive.getDBLAttributesGPS(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "on") -- 'on' or 'active'
    dbgprint("getDBLAttributesGPS : option: "..tostring(dashboard.dblOption), 2)

	return true
end
function DashboardLive.getDBLAttributesGPSNumbers(self, xmlFile, key, dashboard)
	dashboard.dblFactor = xmlFile:getValue(key .. "#factor", "1")
    dbgprint("getDBLAttributesNumbers : factor: "..tostring(dashboard.dblFactor), 2)

	return true
end
-- ps
function DashboardLive.getDBLAttributesPS(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "mode")
	dashboard.dblState = xmlFile:getValue(key .. "#state", "")
    dbgprint("getDBLAttributesPS : option: "..tostring(dashboard.dblOption).." / state: "..tostring(dashboard.dblState), 2)

	return true
end
-- selector
function DashboardLive.getDBLAttributesSelection(self, xmlFile, key, dashboard)
	dashboard.dblSelection = xmlFile:getValue(key .. "#selection")
	dbgprint("getDBLAttributesSelection : selection: "..tostring(dashboard.dblSelection), 2)
	
	dashboard.dblSelectionGroup = xmlFile:getValue(key .. "#selectionGroup")
	dbgprint("getDBLAttributesSelection : selectionGroup: "..tostring(dashboard.dblSelectionGroup), 2)
	
	if dashboard.dblSelection == nil and dashboard.dblSelectionGroup == nil then 
		Logging.xmlWarning(self.xmlFile, "Neither '#selection' nor '#selectionGroup' given for valueType 'selector'")
		return false
	end
	if dashboard.dblSelection ~= nil and dashboard.dblSelectionGroup ~= nil then 
		Logging.xmlWarning(self.xmlFile, "'#selection' and '#selectionGroup' given for valueType 'selector'")
		return false
	end
	
	return true
end
-- print
function DashboardLive.getDBLAttributesPrint(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "")
	dbgprint("getDBLAttributePrint : option: "..tostring(dashboard.dblOption), 2)
	
	return true
end

-- get states

function DashboardLive.getDashboardLiveBase(self, dashboard)
	dbgprint("getDashboardLiveBase : dblCommand: "..tostring(dashboard.dblCommand), 4)
	if dashboard.dblCommand ~= nil then
		local spec = self.spec_DashboardLive
		local specWM = self.spec_workMode
		local specRM = self.spec_ridgeMarker
		local c, j, s, o = dashboard.dblCommand, dashboard.dblAttacherJointIndices, dashboard.dblState, dashboard.dblOption
		
		-- joint states
		if c == "disconnected" then
			return getAttachedStatus(self, dashboard, "disconnected")
	
		elseif c == "lifted" then
			return getAttachedStatus(self, dashboard, "raised", o == "default")
	
		elseif c == "lowered" then
			return getAttachedStatus(self, dashboard, "lowered", o == "default")

		elseif c == "lowerable" then
			return getAttachedStatus(self, dashboard, "lowerable", o == "default")

		elseif c == "pto" then
			return getAttachedStatus(self, dashboard, "pto", o == "default")

		elseif c == "foldable" then
			return getAttachedStatus(self, dashboard, "foldable", o == "default")

		elseif c == "folded" then
			return getAttachedStatus(self, dashboard, "folded", o == "default")

		elseif c == "unfolded" then
			return getAttachedStatus(self, dashboard, "unfolded", o == "default")

		elseif specWM ~= nil and c == "swath" then
			if s == "" or tonumber(s) == nil then
				Logging.xmlWarning(vehicle.xmlFile, "No swath state number given for DashboardLive swath command")
				return false
			end
			return specWM.state == tonumber(s)
	
		-- ridgeMarker
		elseif c == "ridgeMarker" then
			if s == "" or tonumber(s) == nil then
				Logging.xmlWarning(self.xmlFile, "No ridgeMarker state given for DashboardLive ridgeMarker command")
				return 0
			end
			return getAttachedStatus(self, dashboard, "ridgeMarker") == tonumber(s)
		end
	end
	
	return false
end
	
function DashboardLive.getDashboardLiveFillLevel(self, dashboard)
	dbgprint("getDashboardLiveFillLevel : trailer, option: "..tostring(dashboard.dblTrailer)..", "..tostring(dashboard.dblOption), 4)

	local spec = self.spec_DashboardLive
	local o, t = dashboard.dblOption, dashboard.dblTrailer

	if t ~= nil then
		local maxValue, pctValue, absValue
		local fillLevel = getFillLevelStatus(self, t)
		dbgprint_r(fillLevel, 4, 2)
		if fillLevel.abs == nil then 
			maxValue, absValue, pctValue = 0, 0, 0
		else
			maxValue, absValue, pctValue = fillLevel.max, fillLevel.abs, fillLevel.pct
		end

		dbgrender("maxValue: "..tostring(maxValue), 1 + t * 4, 3)
		dbgrender("absValue: "..tostring(absValue), 2 + t * 4, 3)
		dbgrender("pctValue: "..tostring(pctValue), 3 + t * 4, 3)

		if o == "percent" then
			return pctValue * 100
		else
			return absValue
		end
	end
	
	return false
end

function DashboardLive.getDashboardLiveVCA(self, dashboard)
	dbgprint("getDashboardLiveVCA : dblCommand: "..tostring(dashboard.dblCommand), 4)
	if dashboard.dblCommand ~= nil then
		local spec = self.spec_DashboardLive
		local c = dashboard.dblCommand

		if c == "park" or c == "park" then
			if (spec.modVCAFound and self:vcaGetState("handbrake")) or (spec.modEVFound and self.vData.is[13]) then 
				return true
			else 
				return false
			end
		elseif c == "diff_front" or c == "diff_front" then
			return (spec.modVCAFound and self:vcaGetState("diffLockFront")) or (spec.modEVFound and self.vData.is[1])
	
		elseif c == "diff_back" or c == "diff_back"then
			return (spec.modVCAFound and self:vcaGetState("diffLockBack")) or (spec.modEVFound and self.vData.is[2])
	
		elseif c == "diff" or c == "diff" then
			return (spec.modVCAFound and (self:vcaGetState("diffLockFront") or self:vcaGetState("diffLockBack"))) 
					or (spec.modEVFound and (self.vData.is[1] or self.vData.is[2]))
	
		elseif c == "diff_awd" or c == "diff_awd" then
			return (spec.modVCAFound and self:vcaGetState("diffLockAWD")) or (spec.modEVFound and self.vData.is[3]==1)
		
		elseif c == "diff_awdF" then
			return spec.modVCAFound and self:vcaGetState("diffFrontAdv")
	
		elseif c == "ks" then
			return spec.modVCAFound and self:vcaGetState("ksIsOn")
		end
	end
	
	return false
end

function DashboardLive.getDashboardLiveHLM(self, dashboard)
	dbgprint("getDashboardLiveHLM : dblOption: "..tostring(dashboard.dblOption), 4)
		local spec = self.spec_DashboardLive
		local specHLM = self.spec_HeadlandManagement
		
		local o = dashboard.dblOption

		if specHLM ~= nil and specHLM.exists then
			if o == "field" then
				return specHLM.isOn and not specHLM.isActive
			elseif o == "headland" then
				return specHLM.isOn and specHLM.isActive
			else
				return specHLM.isOn
			end
		end	
	return false
end

function DashboardLive.getDashboardLiveGPS(self, dashboard)
	dbgprint("getDashboardLiveGPS : dblOption: "..tostring(dashboard.dblOption), 4)
	local spec = self.spec_DashboardLive
	local specGS = self.spec_globalPositioningSystem
	local specHLM = self.spec_HeadlandManagement
	local o = dashboard.dblOption
	
	if spec.modGuidanceSteeringFound and specGS ~= nil then
		if o == "on" then
			local returnValue = specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0) 
			returnValue = returnValue or (specHLM ~= nil and specHLM.exists and specHLM.isOn and specHLM.contour ~= 0)
			return returnValue
		
		elseif o == "active" then
			local returnValue = specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceSteeringIsActive
			returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapIsOn")) 
			returnValue = returnValue or (spec.modEVFound and self.vData.is[5])
			returnValue = returnValue or (specHLM ~= nil and specHLM.exists and specHLM.isOn and not specHLM.isActive and specHLM.contour ~= 0 and not specHLM.contourSetActive)
			return returnValue
	
		elseif o == "lane+" then
			local returnValue = specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil and specGS.guidanceData.currentLane >= 0	
			return returnValue

		elseif o == "lane-" then
			local returnValue = specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil and specGS.guidanceData.currentLane < 0
			return returnValue
		end	
	end
	
	return false
end

function DashboardLive.getDashboardLiveGPSLane(self, dashboard)
	dbgprint("getDashboardLiveGPS : dblOption: "..tostring(dashboard.dblOption), 4)
	local spec = self.spec_DashboardLive
	local specGS = self.spec_globalPositioningSystem
	
	local factor = dashboard.dblFactor or 1
	if spec.modGuidanceSteeringFound and specGS ~= nil and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil then
		return math.abs(specGS.guidanceData.currentLane) * factor
	else
		return 0
	end
end

function DashboardLive.getDashboardLiveGPSWidth(self, dashboard)
	dbgprint("getDashboardLiveGPSWidth : dblOption: "..tostring(dashboard.dblOption), 4)
	local spec = self.spec_DashboardLive
	local specGS = self.spec_globalPositioningSystem
	
	local factor = dashboard.dblFactor or 1
	if spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0 then 
		return self.spec_vca.snapDistance * factor
	end
	if spec.modGuidanceSteeringFound and specGS ~= nil and specGS.guidanceData ~= nil and specGS.guidanceData.width ~= nil then
		return specGS.guidanceData.width * factor
	else
		return 0
	end
end
		
function DashboardLive.getDashboardLivePS(self, dashboard)
	dbgprint("getDashboardLivePS : running", 4)
	local o, s = dashboard.dblOption, dashboard.dblState
	local specPS = findSpecialization(self, "spec_proSeedTramLines")
	local specSE = findSpecialization(self, "spec_proSeedSowingExtension")
	if specPS ~= nil and specSE ~= nil then
		if o == "mode" then
			if tonumber(s) ~= nil then
				return specPS.tramLineMode == tonumber(s)
			elseif FS22_proSeed ~= nil and FS22_proSeed.ProSeedTramLines ~= nil then
				local mode = specPS.tramLineMode
				local text = FS22_proSeed.ProSeedTramLines.TRAMLINE_MODE_TO_KEY[mode]
				return trim(g_i18n.modEnvironments["FS22_proSeed"]:getText(("info_mode_%s"):format(text)), 7)
			end
		elseif o == "distance" then
			return specPS.tramLineDistance
		elseif o == "laneDrive" then
			return specPS.currentLane
		elseif o == "laneFull" then
			return specPS.tramLinePeriodicSequence 
		elseif o == "tram" then
			return specPS.createTramLines
		elseif o == "fert" then
			return specSE.allowFertilizer
		elseif o == "areawork" then
			return specSE.sessionHectares
		elseif o == "areafield" then
			return specSE.totalHectares
		elseif o == "timeuse" then
			return specSE.hectarePerHour
		elseif o == "seeduse" then
			return specSE.seedUsage
		elseif o == "segment" then
			local state = tonumber(s) or 0
			return specPS.shutoffMode == state
		elseif o == "tramtype" then
			return specPS.createPreMarkedTramLines
		elseif o == "audio" then
			return specSE.allowSound
		end	
	end
	return false
end

function DashboardLive.getDashboardLiveSelection(self, dashboard)
	dbgprint("getDashboardLiveSelection : dblSelection, dblSelectionGroup: "..tostring(dashboard.dblSelection)..", "..tostring(dashboard.dblSelectionGroup), 4)

	local spec = self.spec_DashboardLive
	local s, g = dashboard.dblSelection, dashboard.dblSelectionGroup
	
-- vanilla game selector
	if s ~= nil then
		local selectorActive = false
		if type(s) == "number" and s == -100 then
			return spec.selectorActive < 0
		elseif type(s) == "number" and s == 100 then
			return spec.selectorActive > 0
		elseif type(s) == "number" then
			return spec.selectorActive == s
		else
			for _,selector in ipairs(s) do
				if selector == spec.selectorActive then selectorActive = true end
			end
			return selectorActive
		end
-- vanilla game selector group
	elseif g ~= nil then
		local groupActive = false
		if type(g) == "number" then
			return spec.selectorGroup == g
		else
			for _,selGroup in ipairs(g) do
				if selGroup == spec.selectorGroup then groupActive = true end
			end
		end
		return groupActive
	end
	return false
end		

function DashboardLive.getDashboardLivePrint(self, dashboard)
	dbgprint("getDashboardLivePrint : dblOption: "..tostring(dashboard.dblOption), 4)
	
	return dashboard.dblOption or ""
end
	
function DashboardLive:onUpdate(dt)
	local spec = self.spec_DashboardLive
	local mspec = self.spec_motorized
	
	if self:getIsActiveForInput(true) then
		-- get active vehicle
		spec.selectorActive = getIndexOfActiveImplement(self:getRootVehicle())
		spec.selectorGroup = self.currentSelection.subIndex or 0
		--dbgprint("Selector value: "..tostring(spec.selectorActive), 2)
		--dbgprint("Selector group: "..tostring(spec.selectorGroup), 2)
		dbgrenderTable(spec, 1, 3)
	end
		
	-- zoom
	local spec = self.spec_DashboardLive
	if (spec.zoomPressed or spec.zoomPerm) and not spec.zoomed then
		dbgprint("Zooming in", 4)
		g_currentMission:consoleCommandSetFOV("20")
		spec.zoomed = true
	elseif (not spec.zoomPressed and not spec.zoomPerm) and spec.zoomed then
		dbgprint("Zoomig out", 4)
		g_currentMission:consoleCommandSetFOV("-1")
		spec.zoomed = false
	end
	spec.zoomPressed = false
	
	-- sync engine data with server
	spec.updateTimer = spec.updateTimer + dt
	if self.isServer and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
		spec.motorTemperature = mspec.motorTemperature.value
		spec.fanEnabled = mspec.motorFan.enabled
		spec.lastFuelUsage = mspec.lastFuelUsage
		spec.lastDefUsage = mspec.lastDefUsage
		spec.lastAirUsage = mspec.lastAirUsage
		
		if spec.updateTimer >= 1000 and spec.motorTemperature ~= self.spec_motorized.motorTemperature.valueSend then
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
		
		if spec.fanEnabled ~= spec.fanEnabledLast then
			spec.fanEnabledLast = spec.fanEnabled
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
		
	end
	if self.isClient and not self.isServer and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
		mspec.motorTemperature.value = spec.motorTemperature
		mspec.motorFan.enabled = spec.fanEnabled
		mspec.lastFuelUsage = spec.lastFuelUsage
		mspec.lastDefUsage = spec.lastDefUsage
		mspec.lastAirUsage = spec.lastAirUsage
	end
end
