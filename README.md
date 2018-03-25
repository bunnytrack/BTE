# BunnyTrack Enhancements

## Author
* OwYeaW

## Description
This Mutator for BunnyTrack gives players and spectators many new and improved features.  
BTPlusPlus' HUD will be destroyed and replaced by a new customizable HUD.   
The settings from each say command will be saved and stored on the client inside BT_Enhancements.ini.   
Configurable settings for the server such as a netspeed limiter and a fix for lagging movers are found inside BTE.ini.

## Features

### Spectator
- Move through walls.
- Use Teleporters.
- Voice Taunts.
- Say messages can use commands just like players do and have no length limitation anymore.
- Checkpoint/ThrowWeapon/Suicide key will teleport you to the location that you're aiming at.
- AltFire key (while not viewing a player) will view the closest player at the place that you're aiming at.
- Jump key (while viewing a player) will release you from the player at the player's location.
- Console command "chase" will let you view a specific player. (Example: "chase lane" > specs Tamerlane)
- Removed clientmessages when switching between players or viewing from own camera.

### HUD
- Timer scaling and customizable color.
- Boots charges shown on HUD.
- A Speed meter showing horizontal and vertical momentum of the player.
- Other player's Timer, Speed, Boots and Armor shown on your HUD when F5'ing/specating.
- Team colorized playername shown when F5'ing/spectating.
- Simplified playername and health when aiming on a player.

### Say commands
Show all Commands / Help

- !BTE or !Help

Make yourself Transparent

- !Ghost

Make everyone Transparent

- !Ghosts

Show all Triggers

- !ShowTrig

Team colorized playerskins

- !TeamSkin

WallHack only for Spectators

- !WallHack

Speed meter on HUD

- !SpeedMeter or !Speed

Disable all of the above features

- !Disable

Enable/Disable custom Timer

- !Timer

Timer scaling

- !TimerScale 1 or !tscale 1.5

Timer Red/Green/Blue colors

- !TRed 255 or !tr 255
- !TGreen 0 or !tg 0
- !TBlue 255 or !tb 255

### Netspeed limiter
The Netspeed limiter prevents players from using unallowed netspeed values.    
Players that attempt to change their netspeed to an unallowed value will automatically suicide and are unable to play.       
Extra options are to automatically kick the player, correct the player's netspeed or/and to broadcast a message to all players.

Inside `BTE.ini` you can add maps as an exceptions to where the netspeed limiter should be disabled.    
As an admin you can use the command `mutate nsmap` to add the current map to the exceptions list.

```
[BTE_BTNet.BTE]
NetSpeedLimiter=True
KickPlayer=False
Broadcast=True
AutoCorrectNetSpeed=True
CorrectNetSpeed=20000
MinimumNetSpeed=10000
MaximumNetSpeed=20000
MapExceptions=CTF-BT-BasicGayMap-v2,CTF-BT-Slide1337
```

### Moverlag Fix
Inside `BTE.ini` you can fill in maps with the lagmover names, so that at the start of each game these movers will be fixed.   
As an admin you can use the command `mutate lagmover` to lag/unlag the mover that you're aiming at.

```
FixLagMovers=True
LagMovers[0]=Mover17,Mover18,Mover99,Mover100:CTF-BT-Donnie-v1
LagMovers[1]=Mover12,Mover14,Mover24,Mover25:CTF-BT-Canyon[2011]
LagMovers[1]=ExampleMover1,AssertMover3,furymover4_3,leetmover7:CTF-BT-epicmap
```

## Installation
1. Copy the file(s) inside the `compiled` folder to your server's `UT/System/` directory
2. Open your server's `UnrealTournament.ini`
3. Under `[Engine.GameEngine]` add:  
`ServerPackages=BTEUser`  
`ServerPackages=BTE_BTNet`  
`ServerActors=BTE_BTNet.BTE`
4. Configure `BTE.ini` to your needs
5. Restart your server

## Version
2018-03-24
