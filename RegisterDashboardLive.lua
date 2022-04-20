--
-- Register DashboardLive for LS 22
--
-- Jason06 / Glowins Modschmiede 
-- Version 0.1.0.1
--

if g_specializationManager:getSpecializationByName("DashboardLive") == nil then
  	g_specializationManager:addSpecialization("DashboardLive", "DashboardLive", g_currentModDirectory.."DashboardLive.lua", nil)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager:types) do
    if
		SpecializationUtil.hasSpecialization(Dashboard, typeEntry.specializations)
		and
		SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    then
     	g_vehicleTypeManager:addSpecialization(typeName, "DashboardLive")
     	--g_vehicleTypeManager:addSpecialization(typeEntry.name, "FS22_DashboardLive.DashboardLive")
     	print("Added to "..tostring(typeName))
    end
end

