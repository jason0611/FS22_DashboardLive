--
-- Dashboard Extension for FS22
--
-- Jason06 / Glowins Modschmiede
-- Version 0.0.1.0
--
DashboardLive = {}

if DashboardLive.MOD_NAME == nil then
	DashboardLive.MOD_NAME = g_currentModName
end

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(DashboardLive.MOD_NAME, true, 4)
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
	dbgprint("initSpecialization : registered", 2)
end

function DashboardLive.registerDashboardXMLPaths(schema, basePath, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#dbl", "DashboardLive command")
	dbgprint("registerDashboardXMLPaths : registered for path "..basePath, 2)
end

function DashboardLive.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DashboardLive)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", DashboardLive)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", DashboardLive)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DashboardLive)
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

function DashboardLive:onLoad(savegame)
	self.spec_DashboardLive = self["spec_"..DashboardLive.MOD_NAME..".DashboardLive"]
	local spec = self.spec_DashboardLive
	
	-- management data
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.actPage = 1
	spec.maxPage = 1
	spec.groups = {}
	spec.groups[1] = true
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

function DashboardLive:onReadStream(streamId, connection)
	local spec = self.spec_DashboardLive
end

function DashboardLive:onWriteStream(streamId, connection)
	local spec = self.spec_DashboardLive
end
	
function DashboardLive:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamReadBool(streamId) then
	
		end
	end
end

function DashboardLive:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			
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

-- Main part
function DashboardLive:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
        return false
    end
    group.dblCommand = xmlFile:getValue(key .. "#dbl")
	if group.dblCommand == "page" then
		group.dblPage = xmlFile:getValue(key .. "#page")
	end
	group.dblOperator = xmlFile:getValue(key .. "#op", "or")
	dbgprint("loadDashboardGroupFromXML : group: "..tostring(group.name), 2)
    
    return true
end

local function getAttachedStatus(vehicle, group, mode)
	if group.attacherJointIndices == "" or group.attacherJointIndices == nil then
		Logging.xmlWarning(vehicle.xmlFile, "No attacherJointIndex given for DashboardLive attacher command")
		return false
	end
	
	local result = false
	
    for _, jointIndex in ipairs(group.attacherJointIndices) do
    	local implement = vehicle:getImplementFromAttacherJointIndex(jointIndex) 
    	if implement ~= nil then
            hasAttachment = true
            if mode == "raised" then
            	result = implement.object.getIsLowered ~= nil and not implement.object:getIsLowered()
            elseif mode == "pto" then
            	result = implement.object.getIsPowerTakeOffActive ~= nil and implement.object:getIsPowerTakeOffActive()
            elseif mode == "folded" then
            	result = implement.object.getIsUnfolded ~= nil and not implement.object:getIsUnfolded()
            end
        end
    end

    return result
end

function DashboardLive:getIsDashboardGroupActive(superFunc, group)
    local spec = self.spec_DashboardLive
    
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
	local returnValue
	
	-- command given?
	if group.dblCommand == nil then 
		return superFunc(self, group)

	-- page
	elseif group.dblCommand == "page" and group.dblPage ~= nil then 
		returnValue = spec.actPage == group.dblPage
	
	-- vanilla game
	elseif group.dblCommand == "base_lifted" then
		returnValue = getAttachedStatus(self, group, "raised")
	
	elseif group.dblCommand == "base_pto" then
		returnValue = getAttachedStatus(self, group, "pto")
	
	elseif group.dblCommand == "base_folded" then
		returnValue = getAttachedStatus(self, group, "folded")	
		
	-- VCA
	elseif group.dblCommand == "vca_park" then
		returnValue = spec.modVCAFound and self:vcaGetState("handbrake")
	
	elseif group.dblCommand == "vca_diff_front" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockFront")
	
	elseif group.dblCommand == "vca_diff_back" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockBack")
	
	elseif group.dblCommand == "vca_diff" then
		returnValue = spec.modVCAFound and (self:vcaGetState("diffLockFront") or self:vcaGetState("diffLockBack"))
	
	elseif group.dblCommand == "vca_diff_awd" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockAWD")
		
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
	end
	
    if group.dblOperator == "and" or group.dblCommand == "page" then 
    	return superFunc(self, group) and returnValue
    else
    	return superFunc(self, group) or returnValue
    end
end

function DashboardLive:loadDashboardFromXML(superFunc, xmlFile, key, dashboard)
	dashboard.dblCommand = xmlFile:getString(key.."#dbl")
	return superFunc(self, xmlFile, key, dashboard)
end

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
		local override = false
		if dashboard.dblCommand ~= nil then
			local spec = self.spec_DashboardLive
			local c = dashboard.dblCommand
			local newValue, minValue, maxValue = 0, 0, 1
			if c == "gps_lane" and spec.modGuidanceSteeringFound then
				local gsSpec = self.spec_globalPositioningSystem
				if gsSpec ~= nil and gsSpec.guidanceData ~= nil and gsSpec.guidanceData.currentLane ~= nil then
					maxValue = 999
					newValue = math.abs(gsSpec.guidanceData.currentLane) / 10
					dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
				end
			end
			if c == "vca_park" then
				if self:vcaGetState("handbrake") then 
					newValue = 1 
				else 
					newValue = 0 
				end
				dashboard.stateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
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
