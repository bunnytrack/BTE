//=============================================================================
// BTEClient made by OwYeaW
//=============================================================================
class BTEClientData expands Info config(BT_Enhancements);

#exec texture IMPORT NAME=TS_0	FILE=TEXTURES\TS_0.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_1	FILE=TEXTURES\TS_1.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_2	FILE=TEXTURES\TS_2.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_3	FILE=TEXTURES\TS_3.PCX	MIPS=OFF

var config bool Enabled, Ghost, Ghosts, TeamSkin, ShowTrig, WallHack, SpeedMeter, CustomTimer;
var config float TimerScale;
var config byte Red, Green, Blue;

replication
{
	reliable if(Role == ROLE_Authority)
		SwitchBool, TimerSetting;
}

function Tick(float DeltaTime)
{
	if(Owner == None)
		Destroy();
}

simulated function SwitchBool(string BoolName)
{
    switch(BoolName)
    {
        case ("Disable"): Enabled = false; break;
        default:
        Enabled = true;
        switch(BoolName)
        {
            case "Ghost": Ghost = !Ghost; break;
            case "Ghosts": Ghosts = !Ghosts; break;
            case "TeamSkin": TeamSkin = !TeamSkin; break;
            case "ShowTrig": ShowTrig = !ShowTrig; break;
            case "WallHack": WallHack = !WallHack; break;
            case "SpeedMeter": SpeedMeter = !SpeedMeter; break;
            case "CustomTimer": CustomTimer = !CustomTimer;
        }
    }
    SaveConfig();
}

simulated function TimerSetting(string Setting, float Number)
{
	switch(Setting)
	{
		case "Scale": TimerScale = Number; break;
		case "Red": Red = Number; break;
		case "Green": Green = Number; break;
		case "Blue": Blue = Number;
	}
	if(!CustomTimer)
		CustomTimer = true;

	SaveConfig();
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	Enabled=False
	Ghost=False
	Ghosts=False
	TeamSkin=False
	ShowTrig=False
	WallHack=False
	SpeedMeter=False
	CustomTimer=False
	TimerScale=1
	Red=255
	Green=88
	Blue=0
}