--
-- Multiplayer motor data fix for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 0.1.0.1
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

function DashboardLive.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DashboardLive)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DashboardLive)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DashboardLive)
end

function DashboardLive:onLoad(savegame)
	self.spec_DashboardLive = self["spec_"..DashboardLive.MOD_NAME..".DashboardLive"]
	local spec = self.spec_DashboardLive
	
	-- engine data
	spec.motorTemperature = 20
	spec.fanEnabled = false
	spec.fanEnabledLast = false
	spec.lastFuelUsage = 0
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
	
	-- management data
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.updateTimer = 0
	
	-- dashboard data
	spec.dashboard = {}
	spec.dashboard.temp = 0
	spec.dashboard.fuel = 0
	spec.dashboard.warnTemp = false
end

function DashboardLive:onRegisterActionEvents(isActiveForInput)
	dbgprint("onRegisterActionEvents", 4)
	if self.isClient then
		local spec = self.spec_DashboardLive
		DashboardLive.actionEvents = {} 
		if self:getIsActiveForInput(true) and spec ~= nil then 
			local prio = GS_PRIO_LOW
			local actionEventId
			
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZOOMIN', self, DashboardLive.ZOOM, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, prio)
			_, actionEventId = self:addActionEvent(DashboardLive.actionEvents, 'DBL_ZOOMOUT', self, DashboardLive.ZOOM, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, prio)
			
		end		
	end
end

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

-- Tools part
function DashboardLive:ZOOM(actionName, keyStatus, arg3, arg4, arg5)
-- dummy
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
	if self.isActive then
		dbgrender(self.isActive, 1, 3)
		dbgrender(string.format("%.2f", tostring(spec.dashboard.temp)), 2, 3)
		dbgrender(string.format("%.2f", tostring(spec.dashboard.fuel)), 3, 3)
		dbgrender("Temp Warning: "..tostring(spec.dashboard.warnTemp), 4, 3)
	end
end
