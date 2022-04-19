--
-- Multiplayer motor data fix for LS 22
--
-- Jason06 / Glowins Modschmiede
-- Version 0.1.0.1
--
EngineDataFixMP = {}

--[[
if EngineDataFixMP.MOD_NAME == nil then
	EngineDataFixMP.MOD_NAME = g_currentModName
end

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(EngineDataFixMP.MOD_NAME)
GMSDebug:enableConsoleCommands("emdDebug")
--]]

-- Standards / Basics

function EngineDataFixMP.prerequisitesPresent(specializations)
  return true
end

function EngineDataFixMP.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", EngineDataFixMP)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", EngineDataFixMP)
 	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EngineDataFixMP)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EngineDataFixMP)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", EngineDataFixMP)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", EngineDataFixMP)
end

function EngineDataFixMP:onLoad(savegame)
	local spec = self.spec_EngineDataFixMP
	spec.motorTemperature = 20
	spec.fanEnabled = false
	spec.fanEnabledLast = false
	spec.lastFuelUsage = 0
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.timer = 0
end

function EngineDataFixMP:onReadStream(streamId, connection)
	local spec = self.spec_EngineDataFixMP
	spec.motorTemperature = streamReadFloat32(streamId)
	spec.fanEnabled = streamReadBool(streamId)
	spec.lastFuelUsage = streamReadFloat32(streamId)
	spec.lastDefUsage = streamReadFloat32(streamId)
	spec.lastAirUsage = streamReadFloat32(streamId)
end

function EngineDataFixMP:onWriteStream(streamId, connection)
	local spec = self.spec_EngineDataFixMP
	streamWriteFloat32(streamId, spec.motorTemperature)
	streamWriteBool(streamId, spec.fanEnabled)
	streamWriteFloat32(streamId, spec.lastFuelUsage)
	streamWriteFloat32(streamId, spec.lastDefUsage)
	streamWriteFloat32(streamId, spec.lastAirUsage)
end
	
function EngineDataFixMP:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_EngineDataFixMP
		if streamReadBool(streamId) then
			spec.motorTemperature = streamReadFloat32(streamId)
			spec.fanEnabled = streamReadBool(streamId)
			spec.lastFuelUsage = streamReadFloat32(streamId)
			spec.lastDefUsage = streamReadFloat32(streamId)
			spec.lastAirUsage = streamReadFloat32(streamId)
		end
	end
end

function EngineDataFixMP:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_EngineDataFixMP
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

-- Main part

function EngineDataFixMP:onUpdate(dt)
	local spec = self.spec_EngineDataFixMP
	local mspec = self.spec_motorized
	
	if self.isServer and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
		spec.motorTemperature = mspec.motorTemperature.value
		spec.fanEnabled = mspec.motorFan.enabled
		spec.lastFuelUsage = mspec.lastFuelUsage
		spec.lastDefUsage = mspec.lastDefUsage
		spec.lastAirUsage = mspec.lastAirUsage
		
		spec.timer = spec.timer + dt
		
		if spec.timer >= 1000 and spec.motorTemperature ~= self.spec_motorized.motorTemperature.valueSend then
			self:raiseDirtyFlags(spec.dirtyFlag)
			spec.timer = 0
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
end
