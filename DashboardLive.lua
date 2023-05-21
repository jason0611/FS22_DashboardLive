--
-- Dashboard Extension for FS22
--
-- Jason06 / Glowins Modschmiede
--
DashboardLive = {}

if DashboardLive.MOD_NAME == nil then
	DashboardLive.MOD_NAME = g_currentModName
	DashboardLive.MOD_PATH = g_currentModDirectory
	DashboardLive.MODSETTINGSDIR = g_currentModSettingsDirectory
	createFolder(DashboardLive.MODSETTINGSDIR)
end

source(DashboardLive.MOD_PATH.."tools/gmsDebug.lua")
GMSDebug:init(DashboardLive.MOD_NAME, true, 2)
GMSDebug:enableConsoleCommands("dblDebug")

source(DashboardLive.MOD_PATH.."utils/DashboardUtils.lua")

-- DashboardLive Editor
DashboardLive.xTrans, DashboardLive.yTrans, DashboardLive.zTrans = 0, 0, 0
DashboardLive.xRot, DashboardLive.yRot, DashboardLive.zRot = 0, 0, 0
DashboardLive.xScl, DashboardLive.yScl, DashboardLive.zScl = 1, 1, 1
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
	schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dblOption", "DBL Option")
	schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dblTrailer", "DBL Trailer")
	dbgprint("initSpecialization : DashboardLive group options registered", 2)
	
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.dashboard.dashboardLive", "base fillLevel fillType vca hlm gps gps_lane gps_width proseed selector")
	DashboardLive.DBL_XML_KEY = "vehicle.dashboard.dashboardLive.dashboard(?)"
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#cmd", "DashboardLive command")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#joints")
	schema:register(XMLValueType.VECTOR_N, DashboardLive.DBL_XML_KEY .. "#selection")
	schema:register(XMLValueType.VECTOR_N, DashboardLive.DBL_XML_KEY .. "#selectionGroup")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#state", "state")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#stateText", "stateText")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#trailer", "trailer number")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#partition", "trailer partition")
	schema:register(XMLValueType.STRING, DashboardLive.DBL_XML_KEY .. "#option", "Option")
	schema:register(XMLValueType.FLOAT, DashboardLive.DBL_XML_KEY .. "#factor", "Factor")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#min", "Minimum")
	schema:register(XMLValueType.INT, DashboardLive.DBL_XML_KEY .. "#max", "Maximum")
	dbgprint("initSpecialization : DashboardLive element options registered", 2)
	
	DashboardLive.vanillaSchema = XMLSchema.new("vanillaIntegration")
	
	Dashboard.registerDashboardXMLPaths(DashboardLive.vanillaSchema, "vanillaDashboards.vanillaDashboard(?).dashboardLive", "base vca gps")
	DashboardLive.DBL_Vanilla_XML_KEY = "vanillaDashboards.vanillaDashboard(?).dashboardLive.dashboard(?)"
	
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#cmd", "DashboardLive command")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#joints")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#state", "state")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#option", "Option")
	DashboardLive.vanillaSchema:register(XMLValueType.FLOAT, DashboardLive.DBL_Vanilla_XML_KEY .. "#factor", "Factor")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#min", "Minimum")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#max", "Maximum")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#trailer", "trailer number")
	DashboardLive.vanillaSchema:register(XMLValueType.INT, DashboardLive.DBL_Vanilla_XML_KEY .. "#partition", "partition number")
	DashboardLive.vanillaSchema:register(XMLValueType.STRING, DashboardLive.DBL_Vanilla_XML_KEY .. "#stateText", "stateText")
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
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", DashboardLive)
end

function DashboardLive.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", DashboardLive.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", DashboardLive.getIsDashboardGroupActive)
end

function DashboardLive:onPreLoad(savegame)
	self.spec_DashboardLive = self["spec_"..DashboardLive.MOD_NAME..".DashboardLive"]
	local spec = self.spec_DashboardLive
	
	DashboardLive.vanillaIntegrationXML = DashboardLive.MOD_PATH.."xml/vanillaDashboards.xml"
	DashboardLive.vanillaIntegrationXMLFile = XMLFile.loadIfExists("VanillaDashboards", DashboardLive.vanillaIntegrationXML, DashboardLive.vanillaSchema)

	DashboardLive.modIntegrationXML = DashboardLive.MODSETTINGSDIR.."modDashboards.xml"
	DashboardLive.modIntegrationXMLFile = XMLFile.loadIfExists("ModDashboards", DashboardLive.modIntegrationXML, DashboardLive.vanillaSchema)
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
	if DashboardLive.vanillaIntegrationXMLFile ~= nil then
		DashboardUtils.createVanillaNodes(self, DashboardLive.vanillaIntegrationXMLFile, DashboardLive.modIntegrationXMLFile)
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
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <base>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        
        -- combine
        dashboardData = {	
        					valueTypeToLoad = "combine",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveCombine,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesCombine
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <combine>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <combine>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        
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
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <vca>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
		-- hlm
        dashboardData = {	
        					valueTypeToLoad = "hlm",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveHLM,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesHLM
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <hlm>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <hlm>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
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
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <gps>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
		-- gpsLane
        dashboardData = {	
        					valueTypeToLoad = "gpsLane",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveGPSLane,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesGPSNumbers
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
		if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <gpsLane>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <gpsLane>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
		-- gpsWidth
        dashboardData = {	
        					valueTypeToLoad = "gpsWidth",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveGPSWidth,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesGPSNumbers
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <gpsWidth>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <gpsWidth>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
		-- ps
        dashboardData = {	
        					valueTypeToLoad = "proSeed",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLivePS,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesPS
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <ps>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <ps>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
		-- selection
        dashboardData = {	
        					valueTypeToLoad = "selection",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveSelection,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesSelection
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <selection>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <selection>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        -- baler
        dashboardData = {
        					valueTypeToLoad = "baler",
        					valueObject = self,
        					valueFunc = DashboardLive.getDashboardLiveBaler,
        					additionalAttributesFunc = DashboardLive.getDBLAttributesBaler
        				}
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <baler>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <baler>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        -- lock steering axle by Ifko|nator (www.lsfarming-mods.com)
        dashboardData = {	
        					valueTypeToLoad = "lockSteeringAxle",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveLSA,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesLSA
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <lockSteeringAxle>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <lockSteeringAxle>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
         -- combineXP by yumi
        dashboardData = {	
        					valueTypeToLoad = "combineXP",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLiveCXP,
                        	additionalAttributesFunc = DashboardLive.getDBLAttributesCXP
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <combineXP>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <combineXP>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        -- frontLoader
        dashboardData = {
							valueTypeToLoad = "frontLoader",
							valueObject = self,
							valueFunc = DashboardLive.getDashboardLiveFrontloader,
							additionalAttributesFunc = DashboardLive.getDBLAttributesFrontloader
		}
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData) 
		if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <frontLoader>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <frontLoader>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
        -- print
        dashboardData = {	
        					valueTypeToLoad = "print",
                        	valueObject = self,
                        	valueFunc = DashboardLive.getDashboardLivePrint,
                            additionalAttributesFunc = DashboardLive.getDBLAttributesPrint
                        }
        self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.dashboardLive", dashboardData)  
        if spec.vanillaIntegration then
        	dbgprint("onLoad : VanillaIntegration <print>", 2)
        	self:loadDashboardsFromXML(DashboardLive.vanillaIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.vanillaIntegration), dashboardData)
        end
        if spec.modIntegration then
        	dbgprint("onLoad : ModIntegration <print>", 2)
        	self:loadDashboardsFromXML(DashboardLive.modIntegrationXMLFile, string.format("vanillaDashboards.vanillaDashboard(%d).dashboardLive", spec.modIntegration), dashboardData)
        end
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
		
		if g_server ~= nil then 
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
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_SI', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_SO', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XSI', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_XSO', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YSI', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_YSO', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZSI', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)	
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZSO', self, DashboardLive.MOVESYMBOL, false, true, true, true, nil)
				_, zoomActionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_PRINTOUT', self, DashboardLive.PRINTSYMBOL, false, true, false, true, nil)				
			end	
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
	if g_server ~= nil then
		if tostring(node) ~= nil and tonumber(index) ~= nil then
			DashboardUtils.createEditorNode(g_currentMission.controlledVehicle, tostring(node), tonumber(index))
			DashboardLive.editMode = true
			print("DBL Editor Mode enabled")
		else
			if DashboardLive.editSymbol ~= nil then
				setVisibility(DashboardLive.editSymbol, false)
			end
			DashboardLive.editSymbol = nil
			DashboardLive.editMode = false
			print("Usage: dblEditorMode <node> <index>")
		end
	else
		print("Editor Mode requires SinglePlayer or MultiPlayer Host")
	end
end
addConsoleCommand("dblEditorMode", "Glowins Mod Smithery: Enable Editor Mode: dblEditorMode [<node>]", "startEditorMode", DashboardLive)

function DashboardLive:MOVESYMBOL(actionName, keyStatus)
	dbgprint("MOVESYMBOL", 4)
	if not DashboardLive.editMode or DashboardLive.editSymbol == nil then return end

	if actionName == "DBL_XUP" then
		DashboardLive.xTrans = DashboardLive.xTrans - 0.0001
	elseif actionName == "DBL_XDN" then
		DashboardLive.xTrans = DashboardLive.xTrans + 0.0001
	elseif actionName == "DBL_YUP" then
		DashboardLive.yTrans = DashboardLive.yTrans + 0.0001
	elseif actionName == "DBL_YDN" then
		DashboardLive.yTrans = DashboardLive.yTrans - 0.0001
	elseif actionName == "DBL_ZUP" then
		DashboardLive.zTrans = DashboardLive.zTrans + 0.0001
	elseif actionName == "DBL_ZDN" then
		DashboardLive.zTrans = DashboardLive.zTrans - 0.0001
	elseif actionName == "DBL_XR" then
		DashboardLive.xRot = DashboardLive.xRot + 1
	elseif actionName == "DBL_XL" then
		DashboardLive.xRot = DashboardLive.xRot - 1
	elseif actionName == "DBL_YR" then
		DashboardLive.yRot = DashboardLive.yRot + 1
	elseif actionName == "DBL_YL" then
		DashboardLive.yRot = DashboardLive.yRot - 1
	elseif actionName == "DBL_ZR" then
		DashboardLive.zRot = DashboardLive.zRot + 1
	elseif actionName == "DBL_ZL" then
		DashboardLive.zRot = DashboardLive.zRot - 1
	elseif actionName == "DBL_SI" then
		DashboardLive.xScl = DashboardLive.xScl + 0.001
		DashboardLive.yScl = DashboardLive.yScl + 0.001
		DashboardLive.zScl = DashboardLive.zScl + 0.001
	elseif actionName == "DBL_SO" then
		DashboardLive.xScl = DashboardLive.xScl - 0.001
		DashboardLive.yScl = DashboardLive.yScl - 0.001
		DashboardLive.zScl = DashboardLive.zScl - 0.001
	elseif actionName == "DBL_XSI" then
		DashboardLive.xScl = DashboardLive.xScl + 0.001
	elseif actionName == "DBL_XSO" then
		DashboardLive.xScl = DashboardLive.xScl - 0.001
	elseif actionName == "DBL_YSI" then
		DashboardLive.yScl = DashboardLive.yScl + 0.001
	elseif actionName == "DBL_YSO" then
		DashboardLive.yScl = DashboardLive.yScl - 0.001
	elseif actionName == "DBL_ZSI" then
		DashboardLive.zScl = DashboardLive.zScl + 0.001
	elseif actionName == "DBL_ZSO" then
		DashboardLive.zScl = DashboardLive.zScl - 0.001
	end
	dbgprint("xTrans: "..tostring(DashboardLive.xTrans), 2)
	dbgprint("yTrans: "..tostring(DashboardLive.yTrans), 2)
	dbgprint("zTrans: "..tostring(DashboardLive.zTrans), 2)
	dbgprint("xRot: "..tostring(DashboardLive.xRot), 2)
	dbgprint("yRot: "..tostring(DashboardLive.yRot), 2)
	dbgprint("zRot: "..tostring(DashboardLive.zRot), 2)
	dbgprint("scale x: "..tostring(DashboardLive.xScl), 2)
	dbgprint("scale y: "..tostring(DashboardLive.yScl), 2)
	dbgprint("scale z: "..tostring(DashboardLive.zScl), 2)
	setTranslation(DashboardLive.editSymbol, DashboardLive.xTrans, DashboardLive.yTrans, DashboardLive.zTrans)
	setRotation(DashboardLive.editSymbol, math.rad(DashboardLive.xRot), math.rad(DashboardLive.yRot), math.rad(DashboardLive.zRot))
	setScale(DashboardLive.editSymbol, DashboardLive.xScl, DashboardLive.yScl, DashboardLive.zScl)
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
	print("x_scale = "..tostring(DashboardLive.xScl))
	print("y_scale = "..tostring(DashboardLive.yScl))
	print("z_scale = "..tostring(DashboardLive.zScl))
	if xmlPath == nil then return end
	print("==============================")
	print("<vanillaDashboard name=\""..tostring(self:getName()).."\" fileName=\""..tostring(xmlPath).."\" >")
	print("	<nodes>")
	print("		<node name=\"<set a name here>\" node=\""..DashboardLive.editNode.."\" symbol=\""..DashboardLive.editSymbolIndex.."\" moveTo=\""..tostring(DashboardLive.xTrans).." "..tostring(DashboardLive.yTrans).." "..tostring(DashboardLive.zTrans).."\" rotate=\""..tostring(DashboardLive.xRot).." "..tostring(DashboardLive.yRot).." "..tostring(DashboardLive.zRot).."\" scale=\""..tostring(DashboardLive.xScl).." "..tostring(DashboardLive.yScl).." "..tostring(DashboardLive.zScl).."\"/>")
	print("	</nodes>")
	print("</vanillaDashboard>")
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
	--dbgprint_r(implement, 4, 0)
end

-- Supporting functions

local function trim(text, textLength, alignment)
	local l = string.len(text)
	dbgprint("trim: alignment = "..tostring(alignment), 4)
	if l == textLength then
		return text
	elseif l < textLength then
		local diff = textLength - l
		local newText	 
		if alignment == RenderText.ALIGN_LEFT then
			newText = text..string.rep(" ", math.floor(diff))
		elseif alignment == RenderText.ALIGN_RIGHT then
			newText = string.rep(" ", math.floor(diff))..text
		else
			newText = string.rep(" ", math.floor(diff/2))..text..string.rep(" ", math.floor(diff/2))
		end
		if string.len(newText) < textLength then
			newText = newText .. " "
		end
		return newText
	elseif l > textLength then
		return string.sub(text, 1, textLength)
	end
end

local function lower(text)
	if text ~= nil then
		return string.lower(text)
	else
		return nil
	end
end

local function findSpecialization(device, specName, iteration, iterationStep)
	iterationStep = iterationStep or 0 -- initialization
	if (iteration == nil or iteration == iterationStep) and device ~= nil and device[specName] ~= nil then
		return device[specName]
	elseif (iteration == nil or iterationStep < iteration) and device.getAttachedImplements ~= nil then
		local implements = device:getAttachedImplements()
		for _,implement in pairs(implements) do
			local device = implement.object
			local spec = findSpecialization(device, specName, iteration, iterationStep + 1)
			if spec ~= nil then 
				return spec 
			end
		end
	else 
		return nil
	end
end

local function findSpecializationImplement(device, specName, iteration, iterationStep)
	iterationStep = iterationStep or 0 -- initialization
	if (iteration == nil or iteration == iterationStep) and device ~= nil and device[specName] ~= nil then
		return device
	elseif (iteration == nil or iterationStep < iteration) and device.getAttachedImplements ~= nil then
		local implements = device:getAttachedImplements()
		for _,implement in pairs(implements) do
			local device = findSpecializationImplement(implement.object, specName, iteration, iterationStep + 1)
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

local function getChoosenFillLevelState(device, ftPartition, ftType)
	local fillLevel = {abs = nil, pct = nil, max = nil, maxKg = nil, absKg = nil, pctKg = nil}
	local fillUnits = device:getFillUnits() or {}
	dbgprint("getChoosenFillLevelState: fillUnits = "..tostring(fillUnits), 4)
	
	for i = 1,#fillUnits do
		if ftPartition ~= 0 then i = ftPartition end
		local fillUnit = device:getFillUnitByIndex(i)
		dbgprint("getChoosenFillLevelState: fillUnit = "..tostring(fillUnit), 4)
		if fillUnit == nil then break end
		
		local ftIndex = device:getFillUnitFillType(i)
		local ftCategory = g_fillTypeManager.categoryNameToFillTypes[ftType]
		if ftType == "ALL" or ftIndex == g_fillTypeManager.nameToIndex[ftType] or ftCategory ~= nil and ftCategory[ftIndex] then
			if fillLevel.pct == nil then fillLevel.pct, fillLevel.abs, fillLevel.max, fillLevel.absKg = 0, 0, 0, 0 end
			-- we cannot just sum up percentages... 50% + 50% <> 100%
			--fillLevel.pct = fillLevel.pct + device:getFillUnitFillLevelPercentage(i)
			fillLevel.abs = fillLevel.abs + device:getFillUnitFillLevel(i)
			fillLevel.max = fillLevel.max + device:getFillUnitCapacity(i)
			-- so lets calculate it on our own. (lua should not have a divide by zero problem...)
			fillLevel.pct = fillLevel.abs / fillLevel.max
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(ftIndex)
			if fillTypeDesc ~= nil then
				fillLevel.absKg = fillLevel.absKg + device:getFillUnitFillLevel(i) * fillTypeDesc.massPerLiter * 1000
			else
				fillLevel.absKg = filllevel.absKg + device:getFillUnitFillLevel(i)
			end
		end
		if ftPartition ~= 0 then break end
	end
	return fillLevel
end

local function getChoosenAttacherState(device, ftType)
	local fillLevel = {abs = nil, pct = nil, max = nil, maxKg = nil, absKg = nil, pctKg = nil}
	local fillUnits = device.spec_dynamicMountAttacher.dynamicMountedObjects or {}
	dbgprint("getChoosenAttacherState: fillUnits = "..tostring(fillUnits), 4)
	
	for i,fillUnit in pairs(fillUnits) do
		dbgprint("getChoosenFillLevelState: fillUnit = "..tostring(fillUnit), 4)
		if fillUnit == nil then break end
		
		local ftIndex = fillUnit.fillType
		local ftCategory = g_fillTypeManager.categoryNameToFillTypes[ftType]
		if ftType == "ALL" or ftIndex == g_fillTypeManager.nameToIndex[ftType] or ftCategory ~= nil and ftCategory[ftIndex] then
			if fillLevel.pct == nil then fillLevel.pct, fillLevel.abs, fillLevel.max, fillLevel.absKg = 0, 0, 0, 0 end
			-- we cannot just sum up percentages... 50% + 50% <> 100%
			--fillLevel.pct = fillLevel.pct + device:getFillUnitFillLevelPercentage(i)
			fillLevel.abs = fillUnit.fillLevel ~= nil and fillLevel.abs + fillUnit.fillLevel or fillLevel.abs
			fillLevel.max = fillUnit.fillLevel ~= nil and fillLevel.max + fillUnit.fillLevel or fillLevel.max
			-- so lets calculate it on our own. (lua should not have a divide by zero problem...)
			fillLevel.pct = fillLevel.abs / fillLevel.max
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(ftIndex)
			if fillTypeDesc ~= nil then
				fillLevel.absKg = fillUnit.fillLevel ~= nil and fillLevel.absKg + fillUnit.fillLevel * fillTypeDesc.massPerLiter * 1000 or fillLevel.absKg
			else
				fillLevel.absKg = fillUnit.fillLevel ~= nil and fillLevel.absKg + fillUnit.fillLevel or fillLevel.absKg
			end
		end
	end
	return fillLevel
end

local function recursiveTrailerSearch(vehicle, trailer, step)
	dbgprint("recursiveTrailerSearch", 4)
	return findSpecializationImplement(vehicle, "spec_fillUnit", trailer)
end

-- returns fillLevel {pct, abs, max, absKg}
-- param vehicle - vehicle reference
-- param ftIndex - index of fillVolume: 1 - root/first trailer/implement, 2 - first/second trailer/implement, 3 - root/first and first/second trailer or implement
-- param ftType  - fillType
local function getFillLevelTable(vehicle, ftIndex, ftPartition, ftType)
	dbgprint("getFillLevelTable", 4)
	local fillLevelTable = {abs = nil, pct = nil, max = nil, maxKg = nil, absKg = nil, pctKg = nil}
	
	if ftType == nil then ftType = "ALL" end
	
	if ftType ~= "ALL" and g_fillTypeManager.nameToIndex[ftType] == nil and g_fillTypeManager.nameToCategoryIndex[ftType] == nil then
		Logging.xmlWarning(vehicle.xmlFile, "Given fillType "..tostring(ftType).." not known!")
		return fillLevelTable
	end
	
	local device = findSpecializationImplement(vehicle, "spec_fillUnit", ftIndex)
	if device ~= nil then
		fillLevelTable = getChoosenFillLevelState(device, ftPartition, ftType)
	else
		device = findSpecializationImplement(vehicle, "spec_dynamicMountAttacher", ftIndex)
		if device ~= nil then 
			fillLevelTable = getChoosenAttacherState(device, ftType)
		end
	end
	return fillLevelTable
end

local function recursiveCheck(implement, checkFunc, search, getCheckedImplement, iteration, iterationStep)
	if implement.object == nil then return false end
	
	if type(search)=="number" then 
		iteration = search
		search = false
	elseif iteration == nil then
		search = true
	end
	
	iterationStep = iterationStep or 0 -- only implements here, so we start at 0
	dbgprint("recursiveCheck : iteration: "..tostring(iteration), 4)
	
	local checkResult = false
	local checkFuncOrig = checkFunc
	if type(checkFunc)=="string" then
		checkFunc = implement.object[checkFunc]
	end
	if search or iterationStep == iteration then checkResult = checkFunc ~= nil and checkFunc(implement.object, false) end
	local returnImplement = checkResult and implement or nil
	
	if not checkResult and implement.object.spec_attacherJoints ~= nil and (search or iterationStep < iteration) and (iteration == nil or iterationStep < iteration) then
		local attachedImplements = implement.object.spec_attacherJoints.attachedImplements
		if attachedImplements ~= nil and attachedImplements[1]~=nil then 
			checkResult, returnImplement = recursiveCheck(attachedImplements[1], checkFuncOrig, search, getCheckedImplement, iteration, iterationStep + 1)
		end
	end
	if getCheckedImplement then
		return checkResult, returnImplement
	else
		return checkResult
	end
end

local function getIsFoldable(device)
	local spec = device.spec_foldable
	return spec ~= nil and spec.foldingParts ~= nil and #spec.foldingParts > 0
end

--[[
local function isFoldable(implement, search, getFoldableImplement, t)
	local foldable, returnImplement = recursiveCheck(implement, getIsFoldable, t == nil, getFoldableImplement, t)
	if getFoldableImplement then
		return foldable, returnImplement
	else
		return foldable
	end
end
--]]

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
	local jointExists = false
	
	local andMode = element.dblOption ~= nil and string.find(string.lower(element.dblOption), "all") ~= nil
	local orMode = element.dblOption ~= nil and string.find(string.lower(element.dblOption), "any") ~= nil
	local firstRun = true
	
	local t = element.dblTrailer
    if t ~= nil then 
    	t = t - 1
    	if t < 0 then t = 0 end
    end
	
    for _, jointIndex in ipairs(joints) do
    	dbgprint("jointIndex: "..tostring(tonumber(jointIndex)), 4)
    	local implement
    	if tonumber(jointIndex) == 0 then
    		implement = {}
    		implement.object = vehicle
    	elseif jointIndex == "S" then
    		implement = {}
    		implement.object = vehicle:getSelectedVehicle()
    	else
    		implement = vehicle:getImplementFromAttacherJointIndex(tonumber(jointIndex)) 
    	end
    	jointExists = vehicle:getAttacherJointByJointDescIndex(tonumber(jointIndex)) ~= nil
    	dbgprint("jointExists: "..tostring(jointExists).." / implement: "..tostring(implement), 4)
    	--dbgprint_r(implement, 4, 1)
    	
    	if implement ~= nil then
    		if mode == "hasspec" then
				resultValue = false
				local options = element.dblOption
				local option = string.split(options, " ")
				for _, c in ipairs(option) do
					local spec = findSpecialization(implement.object, c, t)
					resultValue = resultValue or spec ~= nil
				end
				dbgprint(implement.object:getFullName().." hasSpec "..tostring(options)..": "..tostring(resultValue), 4)
				
			elseif mode == "hastypedesc" then
				resultValue = false
				local vehicle = findSpecializationImplement(implement.object, "spec_attachable", t)
				if vehicle ~= nil then
					local options = element.dblOption
					local option = string.split(options, " ")
					for _, c in ipairs(option) do
						local typeDesc = vehicle.typeDesc or ""
						local typeDescI18n = g_i18n.texts["typeDesc_"..c]
						resultValue = resultValue or typeDesc == typeDescI18n
					end
				end
				dbgprint(implement.object:getFullName().." hasTypeDesc "..tostring(options)..": "..tostring(resultValue), 4)
				
            elseif mode == "raised" then
            	resultValue = not recursiveCheck(implement, "getIsLowered", true, false, t)
            	dbgprint(implement.object:getFullName().." raised: "..tostring(resultValue), 4)
            	
            elseif mode == "lowered" then
            	resultValue = recursiveCheck(implement, "getIsLowered", true, false, t)
            	dbgprint(implement.object:getFullName().." lowered: "..tostring(resultValue), 4)
            	
            elseif mode == "lowerable" then
				resultValue = recursiveCheck(implement, "getAllowsLowering", true, false, t)
				dbgprint(implement.object:getFullName().." lowerable: "..tostring(resultValue), 4)
				
			elseif mode == "lowering" or mode == "lifting" then
				if vehicle.spec_attacherJoints ~= nil and vehicle.spec_attacherJoints.attacherJoints ~= nil then
					local joint = vehicle.spec_attacherJoints.attacherJoints[tonumber(jointIndex)]
					
					local animationRunning = false
					local loweringRange = true
					local spec = findSpecialization(implement.object, "spec_foldable", t)
					if spec ~= nil and spec.foldMiddleAnimTime ~= nil and (spec.foldAnimTime <= (spec.turnOnFoldMinLimit or 0) or spec.foldAnimTime >= (spec.turnOnFoldMaxLimit or 1)) then 
            			loweringRange = false
            		end
					
					if mode == "lowering" then 
						resultValue = joint ~= nil and joint.isMoving and joint.moveDown and loweringRange
					else
						resultValue = joint ~= nil and joint.isMoving and not joint.moveDown and loweringRange
					end
				else
					resultValue = false
				end
			
			elseif mode == "pto" then
				resultValue = findPTOStatus(implement.object)
				
			elseif mode == "ptorpm" and vehicle.spec_motorized ~= nil and vehicle.spec_motorized.motor ~= nil then
				if findPTOStatus(implement.object) then
						resultValue = vehicle.spec_motorized.motor:getLastModulatedMotorRpm()
				else
					resultValue = 0
				end
				
            elseif mode == "foldable" then
            	local foldable = recursiveCheck(implement, getIsFoldable, t == nil, false, t) --isFoldable(implement, true)
				resultValue = foldable or false
				dbgprint(implement.object:getFullName().." foldable: "..tostring(resultValue), 4)
				
			elseif mode == "folded" then
				local foldable, foldableImplement = recursiveCheck(implement, getIsFoldable, t == nil, true, t) --isFoldable(implement, true, true, t)
				--local implement = subImplement or implement
				resultValue = foldable and foldableImplement.object.getIsUnfolded ~= nil and not foldableImplement.object:getIsUnfolded() and foldableImplement.object.spec_foldable.foldAnimTime == 1 or false
            	dbgprint(implement.object:getFullName().." folded: "..tostring(resultValue), 4)
            	
            elseif mode == "unfolded" then
            	local foldable, foldableImplement = recursiveCheck(implement, getIsFoldable, t == nil, true, t) --isFoldable(implement, true, true, t)
            	resultValue = foldable and foldableImplement.object.getIsUnfolded ~= nil and foldableImplement.object:getIsUnfolded() or false
            	dbgprint(implement.object:getFullName().." unfolded: "..tostring(resultValue), 4)
            	
            elseif mode == "unfolding" or mode == "folding" then
            	local foldable, foldableImplement = recursiveCheck(implement, getIsFoldable, t == nil, true, t) --isFoldable(implement, true, true, t)
            	if not foldable then 
            		resultValue = false
            	else
					local spec = foldableImplement ~= nil and foldableImplement.object ~= nil and foldableImplement.object.spec_foldable or nil
					local unfolded = foldableImplement ~= nil and foldableImplement.object ~= nil and foldableImplement.object.getIsUnfolded ~= nil and foldableImplement.object:getIsUnfolded()
					if mode == "folding" then
						resultValue = spec ~= nil and not unfolded and spec.foldMoveDirection == 1 and spec.foldAnimTime > 0 and spec.foldAnimTime < 1
					else
						resultValue = spec ~= nil and not unfolded and spec.foldMoveDirection == -1 and spec.foldAnimTime > 0 and spec.foldAnimTime < 1
					end
					dbgprint(implement.object:getFullName().." "..mode..": "..tostring(resultValue), 4)
				end
				
            elseif mode == "unfoldingstate" then
            	local spec = findSpecialization(implement.object, "spec_foldable", t)
            	local foldable = recursiveCheck(implement, getIsFoldable, t == nil, false, t) --isFoldable(implement, true, false, t)
            	if foldable and spec.foldAnimTime >= 0 and spec.foldAnimTime <= 1 then 
            		resultValue = 1 - spec.foldAnimTime
            	else
            		resultValue = 0
            	end
               	dbgprint(implement.object:getFullName().." unfoldingState: "..tostring(resultValue), 4)
             
            elseif mode == "foldingstate" then
            	local spec = findSpecialization(implement.object, "spec_foldable", t)
            	local foldable = recursiveCheck(implement, getIsFoldable, t == nil, false, t) --isFoldable(implement, true, false, t)
            	if foldable and spec.foldAnimTime >= 0 and spec.foldAnimTime <= 1 then 
            		resultValue = spec.foldAnimTime
            	else
            		resultValue = 0
            	end
               	dbgprint(implement.object:getFullName().." foldingState: "..tostring(resultValue), 4)
               	  	
            elseif mode == "tipping" then
            	local specTR = findSpecialization(implement.object, "spec_trailer", t)
            	resultValue = specTR ~= nil and specTR:getTipState() > 0
            	
            elseif mode == "tippingstate" then
            	local specImplement = findSpecializationImplement(implement.object, "spec_trailer", t)

            	if specImplement ~= nil and specImplement.spec_trailer:getTipState() > 0 then
            		local specTR = specImplement.spec_trailer
            		local tipSide = specTR.tipSides[specTR.currentTipSideIndex]
            		resultValue = tipSide ~= nil and specImplement:getAnimationTime(tipSide.animation.name) or 0
            	else
            		resultValue = 0
            	end
            	dbgprint(implement.object:getFullName().." tippingState (trailer "..tostring(t).."): "..tostring(resultValue), 4)
            	
			elseif mode == "tipside" or mode == "tipsidetext" then
				local s = element.dblStateText
				local specTR = findSpecialization(implement.object, "spec_trailer", t)            	
				if mode == "tipside" and s ~= nil and specTR ~= nil then 
					local fullState = "info_tipSide"..tostring(s)
					local fullStateName = g_i18n.texts[fullState]
					local trailerStateNum = specTR.preferedTipSideIndex
					local trailerStateName = specTR.tipSides[trailerStateNum] ~= nil and specTR.tipSides[trailerStateNum].name
					dbgprint("tipSide found for trailer: "..tostring(t).." / tipSide: "..tostring(trailerStateName), 4) 
					resultValue = fullStateName == trailerStateName
				elseif mode == "tipsidetext" and specTR ~= nil then
					local len = string.len(element.textMask or "00.0")
					local alignment = element.textAlignment or RenderText.ALIGN_RIGHT
					local tipSideName = specTR.tipSides ~= nil and specTR.preferedTipSideIndex ~= nil and specTR.tipSides[specTR.preferedTipSideIndex].name or " "
					resultValue = trim(tipSideName, len, alignment)
					dbgprint("tipSideText found for trailer: "..tostring(t).." / tipSide: "..tostring(returnValue), 4) 
				else 
					dbgprint(tostring(mode).." not found for trailer: "..tostring(t), 4)
					if mode == "tipsidetext" then
						resultValue=""
					else
						resultValue = false
					end
				end
            
            elseif mode == "ridgemarker" then
            	local specRM = findSpecialization(implement.object, "spec_ridgeMarker")
            	resultValue = specRM ~= nil and specRM.ridgeMarkerState or 0
            
            elseif mode == "filllevel" then
            	local o, p = lower(element.dblOption), element.dblPartition
				if t == nil then t = 0 end

				local maxValue, pctValue, absValue, maxKGValue,absKGValue, pctKGValue
				local fillLevel = getFillLevelTable(implement.object, t, p)
				dbgprint_r(fillLevel, 4, 2)
				
				if fillLevel.abs == nil then 
					maxValue, absValue, pctValue, absKGValue = 0, 0, 0, 0
				else
					maxValue, absValue, pctValue, absKGValue = fillLevel.max, fillLevel.abs, fillLevel.pct, fillLevel.absKg
				end
				if fillLevel.maxKg == math.huge then -- in case the trailer does not define a fill limit
					pctKGValue, maxKGValue = 0, 0
				else
					pctKGValue, maxKGValue = fillLevel.pctKg, fillLevel.maxKg
				end

				dbgrender("maxValue: "..tostring(maxValue), 1 + t * 7, 3)
				dbgrender("absValue: "..tostring(absValue), 2 + t * 7, 3)
				dbgrender("pctValue: "..tostring(pctValue), 3 + t * 7, 3)
				dbgrender("absKGValue: "..tostring(fillLevel.absKg), 4 + t * 7, 3)
				dbgrender("pctKGValue: "..tostring(fillLevel.pctKg), 5 + t * 7, 3)
				dbgrender("maxKGValue: "..tostring(fillLevel.maxKg), 6 + t * 7, 3)

				if o == "percent" then
					element.valueFactor = 100
					resultValue = pctValue
				elseif o == "max" then
					--element.valueFactor = 1
					resultValue = maxValue
				elseif o == "abskg" then
					resultValue = absKGValue
				elseif o == "percentkg" then
					element.valueFactor = 100
					resultValue = pctKGValue
				elseif o == "maxkg" then
					resultValue = maxKGValue
				else
					--element.valueFactor = 1
					resultValue = absValue
				end
				
			elseif mode == "balesize" or mode == "isroundbale" then
				local specBaler = findSpecialization(implement.object,"spec_baler")
				local options = lower(element.dblOption)
				if options == nil then options = "selected" end
				local baleTypeDef  
				if specBaler ~= nil and specBaler.currentBaleTypeIndex ~= nil and options == "current" then
					baleTypeDef = specBaler.baleTypes[specBaler.currentBaleTypeIndex]
				elseif specBaler ~= nil and specBaler.preSelectedBaleTypeIndex ~= nil and options == "selected" then
					baleTypeDef = specBaler.baleTypes[specBaler.preSelectedBaleTypeIndex]
				end
				if baleTypeDef ~= nil then
					if mode == "isroundbale" then 
						dbgprint("DBL isRoundBale: " .. tostring(baleTypeDef.isRoundBale),4)
						resultValue = baleTypeDef.isRoundBale
					elseif baleTypeDef.isRoundBale then
						dbgprint("DBL baleSize roundBale: " .. tostring(baleTypeDef.diameter) .. "("..options..")",4)
						resultValue = baleTypeDef.diameter * 100
					else
						dbgprint("DBL baleSize squareBale: " .. tostring(baleTypeDef.length) .. "("..options..")",4)
						resultValue = baleTypeDef.length * 100
					end
				end
			elseif mode == "balecountanz" or mode == "balecounttotal" then -- baleCounter by Ifko|nator, www.lsfarming-mods.com
				local specBaleCounter = findSpecialization(implement.object,"spec_baleCounter")	
				resultValue = 0
				if specBaleCounter ~= nil then 
					if mode == "balecountanz" then
						resultValue = specBaleCounter.countToday
						dbgprint(implement.object:getFullName().." baleCountAnz: "..tostring(resultValue), 4)	
					else
						resultValue = specBaleCounter.countTotal
						dbgprint(implement.object:getFullName().." baleCountTotal: "..tostring(resultValue), 4)
					end
				else
					-- Vermeer DLC bale counter (the vermeer pack is used before the göweil pack by the game)
					specBaleCounter = findSpecialization(implement.object,"spec_pdlc_vermeerPack.baleCounter")
					if specBaleCounter == nil then
						-- support for Goeweil DLC bale counter
						specBaleCounter = findSpecialization(implement.object,"spec_pdlc_goeweilPack.baleCounter")
					end
					if specBaleCounter ~= nil then
						if mode == "balecountanz" then
							resultValue = specBaleCounter.sessionCounter
							dbgprint(implement.object:getFullName().." baleCountAnz: "..tostring(resultValue), 4)	
						else
							resultValue = specBaleCounter.lifetimeCounter
							dbgprint(implement.object:getFullName().." baleCountTotal: "..tostring(resultValue), 4)
						end
					end
				end
			
			elseif mode == "wrappedbalecountanz" or mode == "wrappedbalecounttotal" then --baleCounter by Ifko|nator, www.lsfarming-mods.com
				local specBaleCounter = findSpecialization(implement.object,"spec_wrappedBaleCounter")	
				resultValue = 0
				if specBaleCounter ~= nil then 
					if mode == "wrappedbalecountanz" then
						resultValue = specBaleCounter.countToday
						dbgprint(implement.object:getFullName().." wrappedBaleCountAnz: "..tostring(resultValue), 4)	
					else
						resultValue = specBaleCounter.countTotal
						dbgprint(implement.object:getFullName().." wrappedBaleCountTotal: "..tostring(resultValue), 4)
					end
				end

			elseif mode == "locksteeringaxle" then --lockSteeringAxles by Ifko|nator, www.lsfarming-mods.com
				local c = element.dblCommand
				local specLSA = findSpecialization(implement.object, "spec_lockSteeringAxles", t)
				if specLSA ~= nil and c == "found" then
					resultValue = specLSA.foundSteeringAxle
				elseif specLSA ~= nil and c == "locked" then
					resultValue = specLSA.lockSteeringAxle
				else
					resultValue = false
				end
				dbgprint(implement.object:getFullName().." : lockSteeringAxles ("..tostring(c).."), trailer "..tostring(t)..": "..tostring(resultValue), 4)
			
			-- frontloader
			elseif mode == "toolrotation" or mode=="istoolrotation" then
				local factor = element.dblFactor or 1
				local specCyl = findSpecialization(implement.object,"spec_cylindered",t)
				local s = element.dblStateText
				dbgprint(implement.object:getFullName().." : frontLoader - " .. mode .. " - " .. s,3)
				resultValue = 0
				if specCyl ~= nil then
					for toolIndex, tool in ipairs(specCyl.movingTools) do
						if toolIndex == tonumber(element.dblOption) then
							local origin = tool.rotMax or 0
							local originDeg = math.deg(origin) * -1
							local rot = math.deg(tool.curRot[tool.rotationAxis]) * factor * -1 -- - originDeg
							if s=="origin" then rot = rot - originDeg end
							if element.dblCommand == "toolrotation" then
								resultValue = rot
							elseif element.dblCommand == "istoolrotation" then
								resultValue = rot >= element.dblMin and rot <=element.dblMax
							end
						end
					end
				end
			elseif mode=="swathstate" then
				local specWM =  findSpecialization(implement.object,"spec_workMode",t)
				local states
				if type(element.dblStateText) == "number" then
					states = {}
					states[1] = element.dblStateText
				elseif type(element.dblStateText) == "table" then
					states = element.dblStateText
				else
					states = string.split(element.dblStateText, " ")
				end
				resultValue = false
				for _, state in ipairs(states) do
					if tonumber(state) ~= nil and specWM ~= nil then
						resultValue = resultValue or specWM.state == tonumber(state)
					end
				end
			elseif mode=="mpconditioner" then
				resultValue = false
				local specMPConverter = findSpecialization(implement.object,"spec_mower",t)
				if specMPConverter ~= nil and specMPConverter.currentConverter ~= nil then
					resultValue = specMPConverter.currentConverter == "MOWERCONDITIONER"
				end
			elseif mode=="seedtype" then
				resultValue = ""
				local specS = findSpecialization(implement.object,"spec_sowingMachine")
				if specS ~= nil then
					local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(specS.seeds[specS.currentSeed])
					local len = string.len(element.textMask or "xxxx")
					local alignment = element.textAlignment
					resultValue = trim(fillType.title, len, alignment)
					resultValue = string.gsub(resultValue,"ü","u")
					resultValue = string.gsub(resultValue,"Ö","O")
				end
            elseif mode == "connected" then
            	resultValue = true
            	
            elseif mode == "disconnected" then
            	dbgprint("AttacherJoint #"..tostring(jointIndex).." not disconnected", 4)
            	noImplement = false
            end
            
            if andMode and not firstRun then
            	result = resultValue and result
            elseif orMode then
            	result = resultValue or result
            else 
            	result = resultValue
            	firstRun = false
            end
        end
        dbgprint("result / noImplement: "..tostring(result).." / "..tostring(noImplement), 4)
    end
    if mode == "disconnected" then
        dbgprint("Disconnected!", 4)
        return noImplement and jointExists
    end
    dbgprint("returnValue: "..tostring(result), 4)
    return result
end

-- Overwritten vanilla-functions to achieve a better tolerance to errors caused by wrong variable types
function DashboardLive:catchBooleanForDashboardStateFunc(superfunc, dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue)=="boolean" then
		newValue = newValue and 1 or 0
	end
	return superfunc(self, dashboard, newValue, minValue, maxValue, isActive)
end
Dashboard.defaultAnimationDashboardStateFunc = Utils.overwrittenFunction(Dashboard.defaultAnimationDashboardStateFunc, DashboardLive.catchBooleanForDashboardStateFunc)
Dashboard.defaultSliderDashboardStateFunc = Utils.overwrittenFunction(Dashboard.defaultSliderDashboardStateFunc, DashboardLive.catchBooleanForDashboardStateFunc)

-- GROUPS

function DashboardLive:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
        dbgprint("loadDashboardGroupFromXML : superfunc failed for group "..tostring(group.name), 2)
        return false
    end
    dbgprint("loadDashboardGroupFromXML : group: "..tostring(group.name), 2)
    
    group.dblCommand = lower(xmlFile:getValue(key .. "#dbl"))
    dbgprint("loadDashboardGroupFromXML : dblCommand: "..tostring(group.dblCommand), 2)
	
	if group.dblCommand == "page" then
		group.dblPage = xmlFile:getValue(key .. "#page")
		dbgprint("loadDashboardGroupFromXML : page: "..tostring(group.dblPage), 2)
	end
	
	group.dblOperator = lower(xmlFile:getValue(key .. "#op", "and"))
	dbgprint("loadDashboardGroupFromXML : dblOperator: "..tostring(group.dblOperator), 2)
	
	group.dblOption = xmlFile:getValue(key .. "#dblOption")
	dbgprint("loadDashboardGroupFromXML : dblOption: "..tostring(group.dblOption), 2)
	
	group.dblTrailer = xmlFile:getValue(key .. "#dblTrailer")
	dbgprint("loadDashboardGroupFromXML : dblTrailer: "..tostring(group.dblTrailer), 2)
	
	group.dblActiveWithoutImplement = xmlFile:getValue(key.. "#dblActiveWithoutImplement", false)
	dbgprint("loadDashboardGroupFromXML : dblActiveWithoutImplement: "..tostring(group.dblActiveWithoutImplement), 2)
	
	group.dblAttacherJointIndices = xmlFile:getValue(key .. "#dblAttacherJointIndices")
	dbgprint("loadDashboardGroupFromXML : dblAttacherJointIndices: "..tostring(group.dblAttacherJointIndices), 2)
	
	group.dblSelection = xmlFile:getValue(key .. "#dblSelection")
	dbgprint("loadDashboardGroupFromXML : dblSelection: "..tostring(group.dblSelection), 2)
	
	group.dblSelectionGroup = xmlFile:getValue(key .. "#dblSelectionGroup")
	dbgprint("loadDashboardGroupFromXML : dblSelectionGroup: "..tostring(group.dblSelectionGroup), 2)
	
	group.dblRidgeMarker = xmlFile:getValue(key .. "#dblRidgeMarker")
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
	elseif group.dblCommand == "base_selectorgroup" then
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
		
	--ph
	elseif group.dblCommand == "base_hasspec" then
		returnValue = getAttachedStatus(self, group, "hasspec",false)
		
	elseif group.dblCommand == "base_hastypedesc" then
		returnValue = getAttachedStatus(self, group, "hastypedesc",false)

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
	elseif specRM ~= nil and group.dblCommand == "base_ridgemarker" then
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
		
	elseif group.dblCommand == "vca_diff_awdf" then
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

-- base fillType vca hlm gps gps_lane gps_width proseed selector

-- readAttributes
-- base
function DashboardLive.getDBLAttributesBase(self, xmlFile, key, dashboard)

	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	local factor = xmlFile:getValue(key .. "#factor")
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    if factor ~= nil then dashboard.dblFactor = factor end
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
    dbgprint("getDBLAttributesBase : command: "..tostring(dashboard.dblCommand), 2)

	if dashboard.dblCommand == nil then 
		dashboard.dblCommand = ""
		dbgprint("getDBLAttributesBase : cmd is empty", 2)
    	return true
    end
	
    dashboard.dblAttacherJointIndices = xmlFile:getValue(key .. "#joints")
	dbgprint("getDBLAttributesBase : joints: "..tostring(dashboard.dblAttacherJointIndices), 2)

	dashboard.dblState = xmlFile:getValue(key .. "#state") -- swath state, ridgemarker state, ...
	dbgprint("getDBLAttributesBase : state: "..tostring(dashboard.dblState), 2)
	
	dashboard.dblStateText = xmlFile:getValue(key .. "#stateText") -- tipSide
	dbgprint("getDBLAttributesBase : stateText: "..tostring(dashboard.dblStateText), 2)
	
	dashboard.dblOption = xmlFile:getValue(key .. "#option") -- nil or 'default'
	dbgprint("getDBLAttributesBase : option: "..tostring(dashboard.dblOption), 2)
	
	dashboard.dblTrailer = xmlFile:getValue(key .. "#trailer") -- trailer
	dbgprint("getDBLAttributesBase : trailer: "..tostring(dashboard.dblTrailer), 2)
	
	dashboard.dblPartition = xmlFile:getValue(key .. "#partition", 0) -- trailer partition
	dbgprint("getDBLAttributesBase : partition: "..tostring(dashboard.dblPartition), 2)
	
	if dashboard.dblCommand == "filllevel" and dashboard.dblOption == "percent" then
    	dashboard.dblMin = dashboard.dblMin or 0
    	dashboard.dblMax = dashboard.dblMax or 100
	end
	
	return true
end

-- base
function DashboardLive.getDBLAttributesCombine(self, xmlFile, key, dashboard)

	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	local factor = xmlFile:getValue(key .. "#factor")
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    if factor ~= nil then dashboard.dblFactor = factor end
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
    dbgprint("getDBLAttributesBase : command: "..tostring(dashboard.dblCommand), 2)

	dashboard.dblState = xmlFile:getValue(key .. "#state") -- swath state, ridgemarker state, ...
	dbgprint("getDBLAttributesBase : state: "..tostring(dashboard.dblState), 2)
	
	dashboard.dblStateText = xmlFile:getValue(key .. "#stateText") -- tipSide
	dbgprint("getDBLAttributesBase : stateText: "..tostring(dashboard.dblStateText), 2)
	
	dashboard.dblFactor = xmlFile:getValue(key .. "#factor", 1)
	dbgprint("getDBLAttributesBase : factor: "..tostring(dashboard.dblFactor), 2)
	
	return true
end

--vca
function DashboardLive.getDBLAttributesVCA(self, xmlFile, key, dashboard)
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
    dbgprint("getDBLAttributesVCA : cmd: "..tostring(dashboard.dblCommand), 2)
    
    if dashboard.dblCommand == nil then 
    	Logging.xmlWarning(self.xmlFile, "No '#cmd' given for valueType 'vca'")
    	return false
    end

	return true
end

--HLM
function DashboardLive.getDBLAttributesHLM(self, xmlFile, key, dashboard)
	dashboard.dblOption = lower(xmlFile:getValue(key .. "#option"))
    dbgprint("getDBLAttributesHLM : option: "..tostring(dashboard.dblOption), 2)

    return true
end

--  gps
function DashboardLive.getDBLAttributesGPS(self, xmlFile, key, dashboard)

	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	local factor = xmlFile:getValue(key .. "#factor")
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    if factor ~= nil then dashboard.dblFactor = factor end
    
	dashboard.dblOption = lower(xmlFile:getValue(key .. "#option", "on")) -- 'on' or 'active'
    dbgprint("getDBLAttributesGPS : option: "..tostring(dashboard.dblOption), 2)

	return true
end

function DashboardLive.getDBLAttributesGPSNumbers(self, xmlFile, key, dashboard)
	
	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	local factor = xmlFile:getValue(key .. "#factor")
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    if factor ~= nil then dashboard.dblFactor = factor end
    
	dashboard.dblFactor = xmlFile:getValue(key .. "#factor", "1")
    dbgprint("getDBLAttributesNumbers : factor: "..tostring(dashboard.dblFactor), 2)
    
    dashboard.dblOption = xmlFile:getValue(key .. "#option")
	dbgprint("getDBLAttributesNumbers : option: "..tostring(dashboard.dblOption), 2)

	return true
end

-- ps
function DashboardLive.getDBLAttributesPS(self, xmlFile, key, dashboard)

	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	local factor = xmlFile:getValue(key .. "#factor")
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    if factor ~= nil then dashboard.dblFactor = factor end
    
	dashboard.dblOption = lower(xmlFile:getValue(key .. "#option", "mode"))
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

-- baler
function DashboardLive.getDBLAttributesBaler(self, xmlFile, key, dashboard)
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
    dbgprint("getDBLAttributesBase : command: "..tostring(dashboard.dblCommand), 2)
    
	dashboard.dblAttacherJointIndices = xmlFile:getValue(key .. "#joints")
	dbgprint("getDBLAttributesBaler : joints: "..tostring(dashboard.dblAttacherJointIndices), 2)
	
	dashboard.dblOption = lower(xmlFile:getValue(key .. "#option", "selected")) -- 'selected' or 'current'
	
	return true
end

-- lock steering axles
function DashboardLive.getDBLAttributesLSA(self, xmlFile, key, dashboard)
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
	dbgprint("getDBLAttributesLSA : command: "..tostring(dashboard.dblCommand), 2)
	
	dashboard.dblAttacherJointIndices = xmlFile:getValue(key .. "#joints")
	dbgprint("getDBLAttributesBase : joints: "..tostring(dashboard.dblAttacherJointIndices), 2)
	
	dashboard.dblTrailer = xmlFile:getValue(key .. "#trailer")
	dbgprint("getDBLAttributesBase : trailer: "..tostring(dashboard.dblTrailer), 2)
	
	return true
end

-- combineXP by yumi
function DashboardLive.getDBLAttributesCXP(self, xmlFile, key, dashboard)
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd"))
	dbgprint("getDBLAttributesCXP : command: "..tostring(dashboard.dblCommand), 2)
	
	dashboard.dblFactor = xmlFile:getValue(key .. "#factor", 100)
	dbgprint("getDBLAttributesCXP : factor: "..tostring(dashboard.dblFactor), 2)
	
	return true
end

-- print
function DashboardLive.getDBLAttributesPrint(self, xmlFile, key, dashboard)
	dashboard.dblOption = xmlFile:getValue(key .. "#option", "")
	dbgprint("getDBLAttributePrint : option: "..tostring(dashboard.dblOption), 2)
	
	return true
end

-- frontLoader
function DashboardLive.getDBLAttributesFrontloader(self, xmlFile, key, dashboard)
	
	dashboard.dblCommand = lower(xmlFile:getValue(key .. "#cmd", "toolrotation")) -- rotation,  minmax
    dbgprint("getDBLAttributesFrontloader : command: "..tostring(dashboard.dblCommand), 2)
    
	dashboard.dblAttacherJointIndices = xmlFile:getValue(key .. "#joints")
	dbgprint("getDBLAttributesFrontloader : joints: "..tostring(dashboard.dblAttacherJointIndices), 2)

	dashboard.dblOption = xmlFile:getValue(key .. "#option", "1") -- number of tool

	dashboard.dblFactor = xmlFile:getValue(key .. "#factor", "1") -- factor

	dashboard.dblStateText = xmlFile:getValue(key .. "#stateText","origin")

	local min = xmlFile:getValue(key .. "#min")
	local max = xmlFile:getValue(key .. "#max")
	
	if min ~= nil then dashboard.dblMin = min end
    if max ~= nil then dashboard.dblMax = max end
    
	
	return true
end

-- get states

function DashboardLive.getDashboardLiveBase(self, dashboard)
	dbgprint("getDashboardLiveBase : dblCommand: "..tostring(dashboard.dblCommand), 4)
	if dashboard.dblCommand ~= nil then
		local specWM = self.spec_workMode
		local specRM = self.spec_ridgeMarker
		local cmds, j, s, o = dashboard.dblCommand, dashboard.dblAttacherJointIndices, dashboard.dblState, dashboard.dblOption
		local cmd = string.split(cmds, " ")
		local returnValue = false
		
		for _, c in ipairs(cmd) do
			-- joint states
			if c == "disconnected" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "disconnected")
			
			elseif c == "connected" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "connected")
	
			elseif c == "lifted" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "raised", o == "default")
				
			elseif c == "lifting" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "lifting")
				
			elseif c == "lowering" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "lowering")
	
			elseif c == "lowered" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "lowered", o == "default")

			elseif c == "lowerable" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "lowerable", o == "default")

			elseif c == "pto" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "pto", o == "default")
				
			elseif c == "ptorpm" then
				if not dashboard.dblFactor then dashboard.dblFactor = 0.625 end
				returnValue = returnValue or getAttachedStatus(self, dashboard, "ptorpm", o == "default")

			elseif c == "foldable" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "foldable", o == "default")

			elseif c == "folded" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "folded", o == "default")

			elseif c == "unfolded" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "unfolded", o == "default")
			
			elseif c == "folding" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "folding")
			
			elseif c == "unfolding" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "unfolding")
			
			elseif c == "tipping" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "tipping", o == "default")
				
			elseif c == "swath" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "swathstate", o == "default")
				
			elseif c == "mpconditioner" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "mpconditioner", o == "default")
				
			elseif c == "seedtype" then
				returnValue = returnValue or getAttachedStatus(self, dashboard, "seedtype", o == "default")

			-- elseif specWM ~= nil and c == "swath" then
			-- 	if s == "" or tonumber(s) == nil then
			-- 		Logging.xmlWarning(vehicle.xmlFile, "No swath state number given for DashboardLive swath command")
			-- 		return false
			-- 	end
			-- 	returnValue = returnValue or specWM.state == tonumber(s)
			end
		end
		
		-- fillLevel	
		if cmds == "filllevel" then
			returnValue = getAttachedStatus(self, dashboard, "filllevel", 0)
			
		-- hasSpec	
		elseif cmds == "hasspec" then
			returnValue = getAttachedStatus(self,dashboard,"hasspec",false)
			
		-- hasTypeDesc
		elseif cmds == "hastypedesc" then
			returnValue = getAttachedStatus(self,dashboard,"hastypedesc",false)
			
		-- tippingState
		elseif cmds == "tippingstate" then
			returnValue = getAttachedStatus(self, dashboard, "tippingstate", 0)
			
		-- ridgeMarker
		elseif cmds == "ridgemarker" then
			if s == "" or tonumber(s) == nil then
				Logging.xmlWarning(self.xmlFile, "No ridgeMarker state given for DashboardLive ridgeMarker command")
				returnValue = false
			end
			returnValue = getAttachedStatus(self, dashboard, "ridgemarker") == tonumber(s)
		
		-- foldingState
		elseif cmds == "foldingstate" then
			returnValue = getAttachedStatus(self, dashboard, "foldingstate", 0)
			
		elseif cmds == "unfoldingstate" then
			returnValue = getAttachedStatus(self, dashboard, "unfoldingstate", 0)
		
		-- lowering state
		elseif cmds == "liftstate" and self.spec_attacherJoints ~= nil then 
			if tonumber(dashboard.dblAttacherJointIndices) ~= nil then
				local attacherJoint = self.spec_attacherJoints.attacherJoints[tonumber(dashboard.dblAttacherJointIndices)]
				if attacherJoint ~= nil and attacherJoint.moveAlpha ~= nil then
					returnValue = 1 - attacherJoint.moveAlpha
					dbgrenderTable(attacherJoint, 3, 3)
				else
					returnValue = 0
				end
			else
				Logging.xmlWarning(self.xmlFile, "command `liftstate` to show state of 3P-Joint must apply to only one attacherJoint")
				returnValue = 0
			end
			
		-- tipSide / tipSideText
		elseif cmds == "tipside" or cmds == "tipsidetext" then
			returnValue = getAttachedStatus(self, dashboard, cmds, 0)
		
		-- real clock
		elseif cmds == "realclock" then
			returnValue = getDate("%T")
			
		-- heading
		elseif cmds == "heading" or cmds == "headingtext1" or cmds == "headingtext2" then
			local x1, y1, z1 = localToWorld(self.rootNode, 0, 0, 0)
			local x2, y2, z2 = localToWorld(self.rootNode, 0, 0, 1)
			local dx, dz = x2 - x1, z2 - z1
			local heading = math.floor(180 - (180 / math.pi) * math.atan2(dx, dz))
			if cmds == "heading" then
				returnValue = heading
			elseif cmds == "headingtext2" then
				local headingTexts = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
				local index = math.floor(((heading + 22.5) % 360) * 8 / 360) + 1
				dbgprint("heading: "..tostring(heading).." / index: "..tostring(index), 4)
				returnValue = headingTexts[index]
			else
				local headingTexts = {"N", "E", "S", "W"}
				local index = math.floor(((heading + 45) % 360) * 4 / 360) + 1
				returnValue = headingTexts[index]
			end

		-- field number
		elseif cmds == "fieldnumber" then
			local fieldNum = 0
			local x, _, z = getWorldTranslation(self.rootNode)
			local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
			-- interpolate field number from number position on minimap
			local dist = math.huge
			if farmland ~= nil then
				local fields = g_fieldManager.farmlandIdFieldMapping[farmland.id]
				if fields ~= nil then
					for _, field in pairs(fields) do
						local rx, rz = field.posX, field.posZ
						dx, dz = rx - x, rz - z
						rdist = math.sqrt(dx^2 + dz^2)
						dist = math.min(dist, rdist)				
						if rdist == dist then fieldNum = field.fieldId end
					end
				end
			end
			returnValue = fieldNum
			
		-- empty command is allowed here to add symbols (EMITTER) in off-state, too
		elseif cmds == "" then
			returnValue = true
		end
		
		if dashboard.dblFactor ~= nil and type(returnValue) == "number" then
			returnValue = returnValue * dashboard.dblFactor
		end
		if dashboard.dblMin ~= nil and type(returnValue) == "number" then
			returnValue = math.max(returnValue, dashboard.dblMin)
		end
		if dashboard.dblMax ~= nil and type(returnValue) == "number" then
			returnValue = math.min(returnValue, dashboard.dblMax)
		end
		return returnValue
	end
	
	return false
end

function DashboardLive.getDashboardLiveCombine(self, dashboard)
	dbgprint("getDashboardLiveCombine : dblCommand: "..tostring(dashboard.dblCommand), 4)
	local spec = self.spec_combine
	if dashboard.dblCommand ~= nil and spec ~= nil then
		
		local c = dashboard.dblCommand
		local st = dashboard.dblStateText
		local sn = dashboard.dblState
		
		if c == "chopper" then
			if st == "enabled" then
				return not spec.isSwathActive
			elseif st == "active" then
				return spec.chopperPSenabled
			end
			
		elseif c == "swath" then
			if st == "enabled" then 
				return spec.isSwathActive
			elseif st == "active" then
				return spec.strawPSenabled
			end
			
		elseif c == "filling" then
			return spec.isFilling
		
		elseif c == "hectars" then
			return spec.workedHectars
			
		elseif c == "cutheight" then
			local specCutter = findspecialization(self, "spec_cutter")
			if specCutter ~= nil then
				return specCutter.currentCutHeight
			end
		
		elseif c == "pipestate" then
			local specPipe = self.spec_pipe
			if specPipe ~= nil and sn ~= nil then
				return specPipe.currentState == sn
			end
			
		elseif c == "pipefolding" then
			local specPipe = self.spec_pipe
			if specPipe ~= nil then
				return specPipe.currentState ~= specPipe.targetState
			end
		
		elseif c == "pipefoldingstate" then
			local specPipe = self.spec_pipe
			if specPipe ~= nil then
				local returnValue = specPipe:getAnimationTime(specPipe.animation.name) * dashboard.dblFactor
				dbgprint("pipeFoldingState: "..tostring(returnValue), 4)
				return returnValue
			end		
			
		elseif c == "overloading" then
			local spec_dis = self.spec_dischargeable
			if spec_dis ~= nil then
				if sn ~= nil then
					return spec_dis:getDischargeState() == sn
				else
					return spec_dis:getDischargeState() > 0
				end
			end
		end
	end
	
	--return false
end

function DashboardLive.getDashboardLiveVCA(self, dashboard)
	dbgprint("getDashboardLiveVCA : dblCommand: "..tostring(dashboard.dblCommand), 4)
	if dashboard.dblCommand ~= nil then
		local spec = self.spec_DashboardLive
		local c = dashboard.dblCommand

		if c == "park" then
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
		
		elseif c == "diff_awdf" then
			return spec.modVCAFound and self:vcaGetState("diffFrontAdv")
	
		elseif c == "ks" then
			return spec.modVCAFound and self:vcaGetState("ksIsOn")
			
		elseif c == "slip" then
			local slipVCA = spec.modVCAFound and self.spec_vca.wheelSlip ~= nil and (self.spec_vca.wheelSlip - 1) * 100 or 0
			local slipREA = self.spec_wheels ~= nil and self.spec_wheels.SlipSmoothed ~= nil and self.spec_wheels.SlipSmoothed or 0
			return math.max(slipVCA, slipREA)
			
		elseif c == "speed2" then
			return spec.modVCAFound and self:vcaGetState("ccSpeed2")
			
		elseif c == "speed3" then
			return spec.modVCAFound and self:vcaGetState("ccSpeed3")
			
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
	
	if spec.modGuidanceSteeringFound or spec.modVCAFound or spec.modEVFound then
		if o == "on" then
			local returnValue = specGS ~= nil and specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0) 
			returnValue = returnValue or (spec.modEVFound and self.vData.is[5])
			returnValue = returnValue or (specHLM ~= nil and specHLM.exists and specHLM.isOn and specHLM.contour ~= 0)
			return returnValue
		
		elseif o == "active" then
			local returnValue = specGS ~= nil and specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceSteeringIsActive
			returnValue = returnValue or (spec.modVCAFound and self:vcaGetState("snapIsOn")) 
			returnValue = returnValue or (spec.modEVFound and self.vData.is[5])
			returnValue = returnValue or (specHLM ~= nil and specHLM.exists and specHLM.isOn and not specHLM.isActive and specHLM.contour ~= 0 and not specHLM.contourSetActive)
			return returnValue
	
		elseif o == "lane+" then
			local returnValue = specGS ~= nil and specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil and specGS.guidanceData.currentLane >= 0	
			return returnValue

		elseif o == "lane-" then
			local returnValue = specGS ~= nil and specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive
			returnValue = returnValue and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil and specGS.guidanceData.currentLane < 0
			return returnValue
		end	
	end
	
	return false
end

function DashboardLive.getDashboardLiveGPSLane(self, dashboard)
	dbgprint("getDashboardLiveGPS : dblOption: "..tostring(dashboard.dblOption), 4)
	local o = string.lower(dashboard.dblOption or "")
	local spec = self.spec_DashboardLive
	local specGS = self.spec_globalPositioningSystem
	local returnValue = 0
	
	local factor = dashboard.dblFactor or 1
	if spec.modGuidanceSteeringFound and specGS ~= nil and specGS.guidanceData ~= nil and specGS.guidanceData.currentLane ~= nil then
		returnValue = math.abs(specGS.guidanceData.currentLane) * factor
	end
	
	if o == "delta" or o == "dir" or o == "dirleft" or o == "dirright" then
		local gsValue = specGS ~= nil and specGS.guidanceData.currentLane or 0
		gsValue = specGS ~= nil and math.floor(specGS.guidanceData.alphaRad * specGS.guidanceData.snapDirectionMultiplier * 100) / 100 or 0
		
		if o == "delta" then
			returnValue = gsValue * factor
		end
		
		if o == "dir" and gsValue < 0 then
			returnValue = -1
		elseif o == "dir" and gsValue > 0 then
			returnValue = 1
		elseif o == "dir" then
			returnValue = 0
		end
		
		if o == "dirleft" then
			returnValue = gsValue < -0.02
		elseif o == "dirright" then
			returnValue = gsValue > 0.02
		end		
	end
	
	if o == "headingdelta" then
		local x1, y1, z1 = localToWorld(self.rootNode, 0, 0, 0)
		local x2, y2, z2 = localToWorld(self.rootNode, 0, 0, 1)
		local dx, dz = x2 - x1, z2 - z1
		
		local heading = math.floor(180 - (180 / math.pi) * math.atan2(dx, dz))
		local snapAngle = 0
		
		-- we need to find the snap angle, specific to the Guidance Mod used
		-- Guidance Steering
		if specGS ~= nil and specGS.lastInputValues ~= nil and specGS.lastInputValues.guidanceIsActive then
			if specGS.guidanceData ~= nil and specGS.guidanceData.snapDirection ~= nil then
				local lineDirX, lineDirZ = unpack(specGS.guidanceData.snapDirection)
				snapAngle = -math.deg(math.atan(lineDirX/lineDirZ))
			end
		-- VCA
		elseif (spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0)  then
			local curSnapAngle, _, curSnapOffset = self:vcaGetCurrentSnapAngle( math.atan2(dx, dz) )
			snapAngle = 180 - math.deg(curSnapAngle)
		end

		local offset = heading - snapAngle
		if offset > 180 then 
			offset = offset - 360
		end
		if offset > 90 then
			offset = offset - 180
		end
		if offset < -90 then
			offset = offset + 180
		end
		returnValue = offset * factor
	end
	
	if dashboard.dblMin ~= nil and type(returnValue) == "number" then
		returnValue = math.max(returnValue, dashboard.dblMin)
	end
	if dashboard.dblMax ~= nil and type(returnValue) == "number" then
		returnValue = math.min(returnValue, dashboard.dblMax)
	end
	
	return returnValue
end

function DashboardLive.getDashboardLiveGPSWidth(self, dashboard)
	dbgprint("getDashboardLiveGPSWidth : dblOption: "..tostring(dashboard.dblOption), 4)
	local spec = self.spec_DashboardLive
	local specGS = self.spec_globalPositioningSystem
	local returnVaue = 0
	local factor = dashboard.dblFactor or 1
	if spec.modVCAFound and self:vcaGetState("snapDirection") ~= 0 then 
		returnValue = self.spec_vca.snapDistance * factor
	end
	if spec.modGuidanceSteeringFound and specGS ~= nil and specGS.guidanceData ~= nil and specGS.guidanceData.width ~= nil then
		returnValue = specGS.guidanceData.width * factor
	end
	
	if dashboard.dblMin ~= nil and type(returnValue) == "number" then
		returnValue = math.max(returnValue, dashboard.dblMin)
	end
	if dashboard.dblMax ~= nil and type(returnValue) == "number" then
		returnValue = math.min(returnValue, dashboard.dblMax)
	end
	
	return returnValue
end
		
function DashboardLive.getDashboardLivePS(self, dashboard)
	dbgprint("getDashboardLivePS : running", 4)
	local o, s = dashboard.dblOption, dashboard.dblState
	local specPS = findSpecialization(self, "spec_proSeedTramLines")
	local specSE = findSpecialization(self, "spec_proSeedSowingExtension")
	local returnValue = " "
	
	if specPS ~= nil and specSE ~= nil then
		if o == "mode" then
			if tonumber(s) ~= nil then
				returnValue = specPS.tramLineMode == tonumber(s)
			elseif FS22_proSeed ~= nil and FS22_proSeed.ProSeedTramLines ~= nil then
				local mode = specPS.tramLineMode
				local text = FS22_proSeed.ProSeedTramLines.TRAMLINE_MODE_TO_KEY[mode]
				local len = string.len(dashboard.textMask or "xxxx")
				returnValue = trim(g_i18n.modEnvironments["FS22_proSeed"]:getText(("info_mode_%s"):format(text)), len)
			end
		elseif o == "distance" then
			returnValue = specPS.tramLineDistance
		elseif o == "lanedrive" then
			returnValue = specPS.currentLane
		elseif o == "lanefull" then
			local maxLine = specPS.tramLinePeriodicSequence
			if maxLine == 2 and specPS.tramLineDistanceMultiplier == 1 then maxLine = 1 end
			returnValue = maxLine
		elseif o == "tram" then
			returnValue = specPS.createTramLines
		elseif o == "fert" then
			returnValue = specSE.allowFertilizer
		elseif o == "areawork" then
			returnValue = specSE.sessionHectares
		elseif o == "areafield" then
			returnValue = specSE.totalHectares
		elseif o == "timeuse" then
			returnValue = specSE.hectarePerHour
		elseif o == "seeduse" then
			returnValue = specSE.seedUsage
		elseif o == "segment" then
			local state = tonumber(s) or 0
			returnValue = specPS.shutoffMode == state
		elseif o == "tramtype" then
			returnValue = specPS.createPreMarkedTramLines
		elseif o == "audio" then
			returnValue = specSE.allowSound
		end	
		if dashboard.dblFactor ~= nil and type(returnValue) == "number" then
			returnValue = returnValue * dashboard.dblFactor
		end
		if dashboard.dblMin ~= nil and type(returnValue) == "number" then
			returnValue = math.max(returnValue, dashboard.dblMin)
		end
		if dashboard.dblMax ~= nil and type(returnValue) == "number" then
			returnValue = math.min(returnValue, dashboard.dblMax)
		end
	elseif o == "tram" or o == "fert" or o == "segment" or o == "tramtype" or o == "audio" then
		returnValue = false
	end
	return returnValue
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

function DashboardLive.getDashboardLiveBaler(self, dashboard)
	dbgprint("getDashboardLiveBaler : dblCommand: "..tostring(dashboard.dblCommand), 4)
	local spec = self.spec_DashboardLive
	local c = dashboard.dblCommand
	if c == "isroundbale" then
		return getAttachedStatus(self, dashboard, "baleisround", 0)
	elseif c == "balesize" then
		return getAttachedStatus(self, dashboard, "balesize", 0)
	elseif c == "balecountanz" then
		return getAttachedStatus(self, dashboard, "balecountanz", 0)
	elseif c == "balecounttotal" then
		return getAttachedStatus(self, dashboard, "balecounttotal", 0)
	elseif c == "wrappedbalecountanz" then
		return getAttachedStatus(self, dashboard, "wrappedbalecountanz", 0)
	elseif c == "wrappedbalecounttotal" then
		return getAttachedStatus(self, dashboard, "wrappedbalecounttotal", 0)
	end
end

function DashboardLive.getDashboardLiveLSA(self, dashboard)
	local returnValue = getAttachedStatus(self, dashboard, "locksteeringaxle", false)
	dbgprint("getDashboardLiveLSA : returnValue: "..tostring(returnValue), 4)
	return returnValue
end

function DashboardLive.getDashboardLiveCXP(self, dashboard)
	dbgprint("getDashboardLiveCXP : dblCommand: "..tostring(dashboard.dblCommand), 4)
	local specXP = findSpecialization(self, "spec_xpCombine")
	local c, f = dashboard.dblCommand, dashboard.dblFactor
	if specXP ~= nil and specXP.mrCombineLimiter ~= nil then
		local returnValue
		local mr = specXP.mrCombineLimiter
		if c == "tonperhour" then
			returnValue = mr.tonPerHour
		elseif c == "engineload" then
			returnValue = mr.engineLoad * mr.loadMultiplier * f
		elseif c == "yield" then
			returnValue = mr.yield
		elseif c == "highmoisture" then
			returnValue = mr.highMoisture
		end
		dbgprint("combineXP returnValue: "..tostring(mr[c]), 4)
		return returnValue
	elseif c == "highmoisture" then
		dbgprint("combineXP returnValue ("..tostring(self:getFullName()).."): false (spec not found)", 4)
		return false
	end
	dbgprint("combineXP returnValue ("..tostring(self:getFullName()).."): none (spec not found)", 4)
end

function DashboardLive.getDashboardLivePrint(self, dashboard)
	dbgprint("getDashboardLivePrint : dblOption: "..tostring(dashboard.dblOption), 4)
	
	return dashboard.dblOption or ""
end

function DashboardLive.getDashboardLiveFrontloader(self, dashboard)
	dbgprint("getDashboardLiveFrontloader : dblCommand: "..tostring(dashboard.dblCommand), 4)
	local c = dashboard.dblCommand
	local returnValue = 0
	if c == "toolrotation" then
		returnValue = getAttachedStatus(self, dashboard, "toolrotation")
		dbgprint("getDashboardLiveFrontloader : toolrotation: returnValue: "..tostring(returnValue), 4)
	elseif c == "istoolrotation" then
		returnValue = getAttachedStatus(self, dashboard,"istoolrotation")
		dbgprint("getDashboardLiveFrontloader : istoolrotation: returnValue: "..tostring(returnValue), 4)
	end
	return returnValue
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
		--dbgrenderTable(spec, 1, 3)
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

function DashboardLive:onDraw()
	if self.spec_combine ~= nil then
		dbgrender("chopper: "..tostring(self.spec_combine.chopperPSenabled), 23, 3)
		dbgrender("swath: "..tostring(self.spec_combine.strawPSenabled), 24, 3)
		dbgrender("filling: "..tostring(self.spec_combine.isFilling), 25, 3)
	end
	if self.spec_dischargeable ~= nil then
		dbgrenderTable(self.spec_dischargeable, 0, 3)
		dbgrender("dischargeState: "..tostring(self.spec_dischargeable:getDischargeState()), 26, 3)
	end
	if self.spec_globalPositioningSystem ~= nil then
		dbgrenderTable(self.spec_globalPositioningSystem.guidanceData, 1, 3)
	end
end
