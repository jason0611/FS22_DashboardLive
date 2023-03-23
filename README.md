# FS22_DashboardLive

Dashboard Live (short: DBL) has to be built into your vehicles and then allows you to display all kinds of information in your board computers and/or dashboards in all kinds of tractors, no matter what brand. 

**Look out: This is a developer version which can and shurely will contain errors, blow up your logfile with debug entries and maybe break your savegame. So use this version at your own risk**

A zoom function is included for better viewing of displays: 
- Left shift key + space bar: Short zoom
- Both shift keys + space bar: Permanent zoom on/off 

If supported in the vehicle, the right Alt key and left/right arrow can be used to scroll through displays.

In MultiPlayer game, DBL synchronises engine temperature, fuel and air consumption from the server to the clients.

**Please report bugs and problems as issues. For ideas and wishes please open a discussion.**

Here you will find the most actual documentation of DBL: https://github.com/jason0611/FS22_DashboardLive/blob/master/doc/DashboardLive.pdf

```
-- Feature-Backlog: (+) realized | (-) planned | (?) found no way until now | (%) not possible

+ tippingState (text/number): percent number)
+ tipSide (boolean / text)
+ headingText1 (text): N/E/S/W
+ headingText2 (text): N/NE/E/SE/S/SW/W/NE
+ fieldNumber (text/number)
+ hasSpec (boolean): test if specialization is present
+ baleSize (number/text)
+ baleCount (number/text, needs )
+ lockSteeringAxle (boolean, needs lockSteeringAxles-Mod by Ifko)
+ realClock (text/number): Real-Life-Time
+ joints="S": Selects active (selected) vehicle
- combineXP
- precisionFarming
- fillLevel weight
- ISO-Bus: activate terminal depending on connected implement
- actual slip
- pipe state
- pipe overloading
- cutter turn rate
- front loader state
% mini-map integration
% camera integration

-- VanillaIntegration-Backlog:
+ Fendt 700 series (thanks to HiPhi)

-- Internal improvements
+ trim-function to adapt texts to given length
- generalization of recursive functions
- remove case-sensibility from commands

```

