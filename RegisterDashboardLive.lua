--
-- Register Multiplayer motor data fix for LS 22
--
-- Jason06 / Glowins Modschmiede 
-- Version 0.1.0.1
--

if g_specializationManager:getSpecializationByName("EngineDataFixMP") == nil then
  	g_specializationManager:addSpecialization("EngineDataFixMP", "EngineDataFixMP", g_currentModDirectory.."EngineDataFixMP.lua", true, nil)
end

for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
    if
		SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
    
    then
     	g_vehicleTypeManager:addSpecialization(typeName, "EngineDataFixMP")
    end
end

