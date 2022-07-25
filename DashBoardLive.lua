--
-- Multiplayer motor data fix for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 0.0.0.5
--
DashboardLive = {}

if DashboardLive.MOD_NAME == nil then
	DashboardLive.MOD_NAME = g_currentModName
end

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(DashboardLive.MOD_NAME, true, 3)
GMSDebug:enableConsoleCommands("dblDebug")

-- Standards / Basics

function DashboardLive.prerequisitesPresent(specializations)
  return true
end

function DashboardLive.initSpecialization()
    local schema = Vehicle.xmlSchema
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.dashboard.default")
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dbl", "DashboardLive command")
    schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#op", "DashboardLive operator")
	schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#dbl_opt", "DashboardLive operator")
end


function DashboardLive.registerEventListeners(vehicleType)
	--SpecializationUtil.registerEventListener(vehicleType, "onUpdate", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "initSpecialization", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DashboardLive)
        SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "registerOverwrittenFunctions", DashboardLive)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DashboardLive)
end

function DashboardLive.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", DashboardLive.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", DashboardLive.getIsDashboardGroupActive)
end

function DashboardLive:onLoad(savegame)
	self.spec_DashboardLive = self["spec_"..DashboardLive.MOD_NAME..".DashboardLive"]
	local spec = self.spec_DashboardLive
	
	-- management data
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.updateTimer = 0
end

function DashboardLive:onPostLoad(savegame)
        local spec = self.spec_DashboardLive

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
end

function DashboardLive:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
        return false
    end
    
    group.dblCommand = xmlFile:getValue(key .. "#dbl")
    group.dblOperator = xmlFile:getValue(key .. "#op", "or")
	group.dplOption = xmlFile:getValue(key .. "#dbl_opt")
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
	
	if group.dblCommand == nil then 
		return superFunc(self, group)
	
	elseif group.dblCommand == "base_lifted" then
		returnValue = getAttachedStatus(self, group, "raised")
	
	elseif group.dblCommand == "base_pto" then
		returnValue = getAttachedStatus(self, group, "pto")
	
	elseif group.dblCommand == "base_folded" then
		returnValue = getAttachedStatus(self, group, "folded")	
		
	elseif group.dblCommand == "vca_park" then
		returnValue = spec.modVCAFound and self:vcaGetState("handbrake")
	
	elseif group.dblCommand == "vca_diff_front" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockFront")
	
	elseif group.dblCommand == "vca_diff_back" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockBack")
	
	elseif group.dblCommand == "vca_diff_awd" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffLockAWD")
		
	elseif group.dblCommand == "vca_diff_awdF" then
		returnValue = spec.modVCAFound and self:vcaGetState("diffFrontAdv")
	
	elseif group.dblCommand == "hlm_active_field" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn and not self.spec_HeadlandManagement.isActive
	
	elseif group.dblCommand == "hlm_active_headland" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn and self.spec_HeadlandManagement.isActive
	
	elseif group.dblCommand == "hlm_on" then
		returnValue = spec.modHLMFound and self.spec_HeadlandManagement.isOn
		
	elseif group.dblCommand == "gps_on" then
		local gsSpec = self.spec_globalPositioningSystem
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceIsActive
		
	elseif group.dblCommand == "gps_active" then
		local gsSpec = self.spec_globalPositioningSystem
		returnValue = spec.modGuidanceSteeringFound and gsSpec ~= nil and gsSpec.lastInputValues ~= nil and gsSpec.lastInputValues.guidanceSteeringIsActive
	end
    
    if group.dblOperator == "and" then 
    	return superFunc(self, group) and returnValue
    else
    	return superFunc(self, group) or returnValue
    end
end

function DashboardLive:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 4)
	if self.isClient then
		local spec = self.spec_DashboardLive
		DashboardLive.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil then 
			local prio = GS_PRIO_LOW
			local actionEventId
			
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_TEST1', self, DashboardLive.TEST, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, prio)
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_TEST2', self, DashboardLive.TEST, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, prio)
			
			dbgprint("actionEvents set", 2)
		end		
	end
end

function DashboardLive:onReadStream(streamId, connection)
	local spec = self.spec_DashboardLive
	--[[
	spec.motorTemperature = streamReadFloat32(streamId)
	spec.fanEnabled = streamReadBool(streamId)
	spec.lastFuelUsage = streamReadFloat32(streamId)
	spec.lastDefUsage = streamReadFloat32(streamId)
	spec.lastAirUsage = streamReadFloat32(streamId)
	--]]
end

function DashboardLive:onWriteStream(streamId, connection)
	local spec = self.spec_DashboardLive
	--[[
	streamWriteFloat32(streamId, spec.motorTemperature)
	streamWriteBool(streamId, spec.fanEnabled)
	streamWriteFloat32(streamId, spec.lastFuelUsage)
	streamWriteFloat32(streamId, spec.lastDefUsage)
	streamWriteFloat32(streamId, spec.lastAirUsage)
	--]]
end
	
function DashboardLive:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamReadBool(streamId) then
			--[[
			spec.motorTemperature = streamReadFloat32(streamId)
			spec.fanEnabled = streamReadBool(streamId)
			spec.lastFuelUsage = streamReadFloat32(streamId)
			spec.lastDefUsage = streamReadFloat32(streamId)
			spec.lastAirUsage = streamReadFloat32(streamId)
			--]]
		end
	end
end

function DashboardLive:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_DashboardLive
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			--[[
			streamWriteFloat32(streamId, spec.motorTemperature)
			streamWriteBool(streamId, spec.fanEnabled)
			streamWriteFloat32(streamId, spec.lastFuelUsage)
			streamWriteFloat32(streamId, spec.lastDefUsage)
			streamWriteFloat32(streamId, spec.lastAirUsage)
			self.spec_motorized.motorTemperature.valueSend = spec.motorTemperature
			--]]
		end
	end
end

-- Tools part
function DashboardLive:TEST(actionName, keyStatus, arg3, arg4, arg5)
	local spec = self.spec_DashboardLive
	local motor = self.spec_motorized.motor
	dbgprint("actionName: "..actionName)
	if actionName == "DBL_TEST1" then 
		local gsm = motor.gearShiftMode
		gsm = gsm + 1
		if gsm > 3 then gsm = 1 end
		motor:setGearShiftMode(gsm)
		dbgprint("TEST: gearShiftMode set to "..tostring(gsm), 1)
	end
	--if actionName == "DBL_TEST1" then spec.dashboard.warnTest1 = not spec.dashboard.warnTest1 end
	if actionName == "DBL_TEST2" then spec.dashboard.warnTest2 = not spec.dashboard.warnTest2 end
end

-- Main part

local function updateDashboardSlow(v, dt)
	local mspec = v.spec_motorized
	local spec = v.spec_DashboardLive
	
	spec.dashboard.temp = mspec.motorTemperature.value
	spec.dashboard.warnTemp = (spec.dashboard.temp > 80)
end

local function updateDashboardFast(v, dt)
	local mspec = v.spec_motorized
	local spec = v.spec_DashboardLive
	
	spec.dashboard.fuel = mspec.lastFuelUsage
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
			self:raiseDirtyFlags(spec.dirtyFlag)
			spec.fanEnabledLast = spec.fanEnabled
		end
		
	end
	if self.isClient and not self.isServer and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
		mspec.motorTemperature.value = spec.motorTemperature
		mspec.motorFan.enabled = spec.fanEnabled
		mspec.lastFuelUsage = spec.lastFuelUsage
		mspec.lastDefUsage = spec.lastDefUsage
		mspec.lastAirUsage = spec.lastAirUsage
	end
	
	updateDashboardFast(self, dt)
	
	if spec.updateTimer >= 1000 then
		updateDashboardSlow(self, dt)
		spec.lastUpdateTimer = dt
		dbgprint("updateDashboardSlow", 4)
	end
	if spec.updateTimer > 1000 then spec.updateTimer = 0 end
end

function DashboardLive:onDraw(dt)
	local spec = self.spec_DashboardLive
	local mspec = self.spec_motorized
	if self.isActive then
		--dbgrenderTable(self.spec_DashboardLive, 1, 3)
	end
end
