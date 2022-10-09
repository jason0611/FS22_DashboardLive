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
source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(DashboardLive.MOD_NAME, true, 2)
GMSDebug:enableConsoleCommands("dblDebug")



-- Standards / Basics

function DashboardLive.prerequisitesPresent(specializations)
  return true
end

function DashboardLive.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dbl", "DashboardLive command")
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#op", "DashboardLive operator")
	schema:register(XMLValueType.INT, Dashboard.GROUP_XML_KEY .. "#page", "DashboardLive page")
	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#dblActiveWithoutImplement", "return 'true' without implement")
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#dblAttacherJointIndices")
	dbgprint("initSpecialization : DashboardLive registered", 2)
end

function DashboardLive.registerDashboardXMLPaths(schema, basePath, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#dbl", "DashboardLive command")
	dbgprint("registerDashboardXMLPaths : registered for path "..basePath, 2)
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
end

function DashboardLive.registerFunctions(vehicleType)
end

function DashboardLive.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", DashboardLive.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", DashboardLive.getIsDashboardGroupActive)
    
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadEmitterDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadNumberDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTextDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimationDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRotationDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadVisibilityDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSliderDashboardFromXML", DashboardLive.loadDashboardFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMultiStateDashboardFromXML", DashboardLive.loadDashboardFromXML)
    
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateDashboards", DashboardLive.updateDashboards)
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
	
	-- engine data
	spec.motorTemperature = 20
	spec.fanEnabled = false
	spec.fanEnabledLast = false
	spec.lastFuelUsage = 0
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
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

-- Main script

-- Dashboard groups

function DashboardLive:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
        return false
    end
    dbgprint("loadDashboardGroupFromXML : group: "..tostring(group.name), 2)
    
    group.dblCommand = xmlFile:getValue(key .. "#dbl")
    dbgprint("loadDashboardGroupFromXML : dblCommand: "..tostring(group.dblCommand), 2)
	
	if group.dblCommand == "page" then
		group.dblPage = xmlFile:getValue(key .. "#page")
		dbgprint("loadDashboardGroupFromXML : page: "..tostring(group.dblPage), 2)
	end
	
	group.dblOperator = xmlFile:getValue(key .. "#op", "or")
	dbgprint("loadDashboardGroupFromXML : dblOperator: "..tostring(group.dblOperator), 2)
	
	group.dblActiveWithoutImplement = xmlFile:getValue(key.. "#dblActiveWithoutImplement", false)
	dbgprint("loadDashboardGroupFromXML : dblActiveWithoutImplement: "..tostring(group.dblDefault), 2)
	
	group.dblAttacherJointIndices = xmlFile:getValue(key .. "#dblAttacherJointIndices", "", true)
	--group.dblAttacherJointIndices = xmlFile:getValue(key .. "#dblAttacherJointIndices")
	dbgprint("loadDashboardGroupFromXML : dblAttacherJointIndices: "..tostring(group.dblAttacherJointIndices), 2)
    
    return true
end

-- Supporting functions

local function getAttachedStatus(vehicle, group, mode, default)
	if group.dblAttacherJointIndices == nil or #group.dblAttacherJointIndices == 0 then
		if group.attacherJointIndices ~= nil and #group.attacherJointIndices ~= 0 then
			group.dblAttacherJointIndices = group.attacherJointIndices
		else
			Logging.xmlWarning(vehicle.xmlFile, "No attacherJointIndex given for DashboardLive attacher command")
			return false
		end
	end
	
	local result = default or false
	
    for _, jointIndex in ipairs(group.dblAttacherJointIndices) do
    	local implement = vehicle:getImplementFromAttacherJointIndex(jointIndex) 
    	if implement ~= nil then
    		local foldable = implement.object.spec_foldable ~= nil and implement.object.spec_foldable.foldingParts ~= nil and #implement.object.spec_foldable.foldingParts > 0
            if mode == "raised" then
            	result = implement.object.getIsLowered ~= nil and not implement.object:getIsLowered()
            elseif mode == "lowered" then
            	result = implement.object.getIsLowered ~= nil and implement.object:getIsLowered()
            elseif mode == "pto" then
            	result = implement.object.getIsPowerTakeOffActive ~= nil and implement.object:getIsPowerTakeOffActive()
            elseif mode == "folded" then
            	result = foldable and implement.object.getIsUnfolded ~= nil and not implement.object:getIsUnfolded()
            elseif mode == "unfolded" then
            	result = foldable and implement.object.getIsUnfolded ~= nil and implement.object:getIsUnfolded()
            end
        end
    end
    
    return result
end

-- Main part

function DashboardLive:getIsDashboardGroupActive(superFunc, group)
    local spec = self.spec_DashboardLive
    local specCS = self.spec_crabSteering
    local specWM = self.spec_workMode
    
--[[
    group.baseFrontLifted	= dblEntry == "base_front_lifted"
    group.baseBackLifted 	= dblEntry == "base_back_lifted"
    group.baseFrontPto 		= dblEntry == "base_front_pto"
    group.baseBackPto 		= dblEntry == "base_back_pto"
    
    group.vcaPark 			= dblEntry == "vca_park"
    group.vcaDiffFront 		= dblEntry == "vca_diff_front"
	group.vcaDiffBack 		= dblEntry == "vca_diff_back"
    group.vcaDiffAwd 		= dblEntry == "vca_diff_awd"
--]]
	local returnValue = false
	
	-- command given?
	if group.dblCommand == nil then 
		return superFunc(self, group)

	-- page
	elseif group.dblCommand == "page" and group.dblPage ~= nil then 
		returnValue = spec.actPage == group.dblPage
	
	-- vanilla game
	elseif group.dblCommand == "base_lifted" then
		returnValue = getAttachedStatus(self, group, "raised", group.dblActiveWithoutImplement)
		
	elseif group.dblCommand == "base_lowered" then
		returnValue = getAttachedStatus(self, group, "lowered", group.dblActiveWithoutImplement)
	
	elseif group.dblCommand == "base_pto" then
		returnValue = getAttachedStatus(self, group, "pto", group.dblActiveWithoutImplement)
	
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
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceIsActive
		
	elseif group.dblCommand == "gps_active" then
		local gsSpec = self.spec_globalPositioningSystem
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive
	
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
		
	elseif group.dblCommand == "ps_mode" then
	
	elseif group.dblCommand == "ps_trackNum" then
	
	elseif group.dblCommand == "ps_trackAnz" then
	
	elseif group.dblCommand == "ps_half" then
	
	elseif group.dblCommand == "ps_marker" then
	end
	
    if group.dblOperator == "and" or group.dblCommand == "page" then 
    	return superFunc(self, group) and returnValue
    else
    	return superFunc(self, group) or returnValue
    end
end

-- Single dashboard entries

function DashboardLive:loadDashboardFromXML(superFunc, xmlFile, key, dashboard)
	dashboard.dblCommand = xmlFile:getString(key.."#dbl")
	dashboard.dblOption = xmlFile:getString(key.."#dblOpt")
	dashboard.dblTrailer = xmlFile:getInt(key.."#dblTrailer")
	return superFunc(self, xmlFile, key, dashboard)
end

-- Supporting functions

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
	dbgrenderTable(fillLevel, 1 + 5 * ftIndex, 3)
	return fillLevel
end

-- main part

function DashboardLive.updateDashboards(self, superFunc, dashboards, dt, force)
-- Giants's stuff ----------------------------------------
    for i=1, #dashboards do
        local dashboard = dashboards[i]
        local isActive = true
        for j=1, #dashboard.groups do
            if not dashboard.groups[j].isActive then
                isActive = false
                break
            end
        end
        
-- Own stuff ---------------------------------------------
		local override = false -- override forced dashboard update if update is done here already
		if dashboard.dblCommand ~= nil then
			local spec = self.spec_DashboardLive
			local c, o, t = dashboard.dblCommand, dashboard.dblOption, dashboard.dblTrailer
			local newValue, minValue, maxValue = 0, 0, 1
			if c == "gps_lane" and spec.modGuidanceSteeringFound then
				local gsSpec = self.spec_globalPositioningSystem
				if gsSpec ~= nil and gsSpec.guidanceData ~= nil and gsSpec.guidanceData.currentLane ~= nil then
					maxValue = 999
					newValue = math.abs(gsSpec.guidanceData.currentLane) / 10
					dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
				end
			end
			if c == "gps_width" and spec.modGuidanceSteeringFound then
				local gsSpec = self.spec_globalPositioningSystem
				if gsSpec ~= nil and gsSpec.guidanceData ~= nil and gsSpec.guidanceData.width ~= nil then
					maxValue = 999
					newValue = gsSpec.guidanceData.width * 10
					dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
				end
			end
			if c == "vca_park" or c == "ev_park" then
				if (spec.modVCAFound and self:vcaGetState("handbrake")) or (spec.modEVFound and self.vData.is[13]) then 
					newValue = 1 
				else 
					newValue = 0 
				end
				dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
				override = true
			end
			if c == "base_fillLevel" or c == "base_fillLevel_percent" and t ~= nil then
				local pctValue, absValue
				local ftType = o
				local fillLevel = getFillLevelStatus(self, t, ftType)
				dbgprint_r(fillLevel, 4, 2)
				if fillLevel.abs == nil then 
					maxValue, absValue, pctValue = 0, 0, 0
				else
					maxValue, absValue, pctValue = fillLevel.max, fillLevel.abs, fillLevel.pct
				end
				if c == "base_fillLevel" then
					newValue = absValue
				else
					newValue = pctValue * 100
				end
				
				dbgrender("maxValue: "..tostring(maxValue), 1 + t * 4, 3)
				dbgrender("absValue: "..tostring(absValue), 2 + t * 4, 3)
				dbgrender("pctValue: "..tostring(pctValue), 3 + t * 4, 3)
				
				minValue = 0
				dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
				override = true	
			end
			if c == "print" and o ~= nil then
				dashboard.stateFunc(self, dashboard, o, nil, nil, isActive)
				override = true
			end
		end
		
-- Own stuff end -----------------------------------------
	
-- Giant's stuff -----------------------------------------
        if dashboard.valueObject ~= nil and dashboard.valueFunc ~= nil then
            local value = self:getDashboardValue(dashboard.valueObject, dashboard.valueFunc, dashboard)

            if dashboard.valueFactor ~= nil and type(value) == "number" then
                value = value * dashboard.valueFactor
            end

            if not isActive then
                value = dashboard.idleValue
            end

            if dashboard.doInterpolation and type(value) == "number" and value ~= dashboard.lastInterpolationValue then
                local dir = MathUtil.sign(value - dashboard.lastInterpolationValue)
                local limitFunc = math.min
                if dir < 0 then
                    limitFunc = math.max
                end

                value = limitFunc(dashboard.lastInterpolationValue + dashboard.interpolationSpeed * dir * dt, value)
                dashboard.lastInterpolationValue = value
            end

            if value ~= dashboard.lastValue or force then
                dashboard.lastValue = value

                local min, max
                if type(value) == "number" then
                    -- for idle values while not active we ignore the limits
                    min = self:getDashboardValue(dashboard.valueObject, dashboard.minFunc, dashboard)
                    if min ~= nil and isActive then
                        value = math.max(min, value)
                    end

                    max = self:getDashboardValue(dashboard.valueObject, dashboard.maxFunc, dashboard)
                    if max ~= nil and isActive then
                        value = math.min(max, value)
                    end

                    local center = self:getDashboardValue(dashboard.valueObject, dashboard.centerFunc, dashboard)
                    if center ~= nil then
                        local maxValue = math.max(math.abs(min), math.abs(max))
                        if value < center then
                            value = -value / min * maxValue
                        elseif value > center then
                            value = value / max * maxValue
                        end

                        max = maxValue
                        min = -maxValue
                    end
                end

                if dashboard.valueCompare ~= nil then
                    if type(dashboard.valueCompare) == "table" then
                        local oldValue = value
                        value = false
                        for _, compareValue in ipairs(dashboard.valueCompare) do
                            if oldValue == compareValue then
                                value = true
                            end
                        end
                    else
                        value = value == dashboard.valueCompare
                    end
                end

                dashboard.stateFunc(self, dashboard, value, min, max, isActive)
            end
-- Own addition: Skip forced update if stateFunc was already called
        elseif force and not override then
            dashboard.stateFunc(self, dashboard, true, nil, nil, isActive)
        end
    end
-- Giant's stuff end -------------------------------------
end

function DashboardLive:onUpdate(dt)
	local spec = self.spec_DashboardLive
	local mspec = self.spec_motorized
	
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
