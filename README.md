# FS22_DashboardLive

Dashboard Live (short: DBL) has to be placed into your mod folder. It's functions have to be built into your vehicles dashboards (xml and i3d, if applicable) and then allows you to display all kinds of information in your board computers and/or dashboards. It's usable in all kinds of vehicle, no matter what brand or type. 

**Look out: This is a developer version which can and shurely will contain errors, blow up your logfile with debug entries and maybe break your savegame. So use this version at your own risk**

A zoom function is included for better viewing of displays: 
- Left shift key + space bar: Short zoom
- Both shift keys + space bar: Permanent zoom on/off 

If supported in the vehicle, the right Alt key and left/right arrow can be used to scroll through displays.

In MultiPlayer game, DBL synchronises engine temperature, fuel and air consumption from the server to the clients.

**Please report bugs and problems as issues. For ideas and wishes please open a discussion.**

Here you will find the most actual documentation of DBL: https://github.com/jason0611/FS22_DashboardLive/blob/master/doc/DashboardLive.pdf

```
-- Feature-Backlog: (+) realized | (-) planned | (?) found no way until now | (%) impossible

== Realized and available at ModHub
+ tippingState (text/number): percent number)
+ tipSide (boolean / text)
+ headingText1 (text): N/E/S/W
+ headingText2 (text): N/NE/E/SE/S/SW/W/NE
+ fieldNumber (text/number)
+ baleSize (number/text)
+ baleCount (number/text, needs )
+ lockSteeringAxle (boolean, needs lockSteeringAxles-Mod by Ifko)
+ realClock (text/number): Real-Life-Time
+ joints="S": Selects active (selected) vehicle
+ combineXP
+ fillLevel weight (thanks to HiPhi)
+ actual slip
+ pipe state
+ pipe overloading
+ hasSpec (boolean): test if specialization is present (thanks to HiPhi77)
+ hasTypeDesc (boolean): test if vehicle or implement is of wanted type
+ front loader state
+ mini-map integration

== Planned for next ModHub update ==
+ CVT-Addon
+ precisionFarming
+ RDA

== Planned for later ModHub updates ==
? camera integration
? cutter turn rate
- ISO-Bus: Use dashboards provided by implements
- Generic spec access (functions/values)
- displayType="AUDIO"

-- VanillaIntegration-Backlog:
+ Rigitrac SKE50
+ MAN TGS 18.500 4x4
+ JBC Fastrac 4220
+ Fendt 1000 Vario
+ Fendt 700 series (thanks to HiPhi)

-- Internal improvements
+ fix for lua error while using "cutHeight"
+ trim-function to adapt texts to given length
+ generalization of recursive functions
+ remove case-sensibility from commands
```
