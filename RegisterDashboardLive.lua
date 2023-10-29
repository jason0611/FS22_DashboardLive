--
-- Register DashboardLive for LS 22
--
-- Jason06 / Glowins Modschmiede 
-- Version 0.1.0.1
--

source(g_currentModDirectory.."tools/gmsDebug.lua")
GMSDebug:init(g_currentModName, true, 4)
GMSDebug:enableConsoleCommands()

local specName = g_currentModName..".DashboardLive"

-- Definitionof displayType="AUDIO"
Dashboard.TYPES.AUDIO = 8

if g_specializationManager:getSpecializationByName("DashboardLive") == nil then
  	g_specializationManager:addSpecialization("DashboardLive", "DashboardLive", g_currentModDirectory.."DashboardLive.lua", nil)
  	dbgprint("Specialization 'DashboardLive' added", 2)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
    if
		SpecializationUtil.hasSpecialization(Dashboard, typeEntry.specializations)
		and
		SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    then
     	g_vehicleTypeManager:addSpecialization(typeName, specName)
		dbgprint(specName.." registered for "..typeName)
    end
end

