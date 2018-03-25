//=============================================================================
// BTEClient made by OwYeaW
//=============================================================================
class BTEClientData expands Info config(BT_Enhancements);

#exec texture IMPORT NAME=TS_0	FILE=TEXTURES\TS_0.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_1	FILE=TEXTURES\TS_1.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_2	FILE=TEXTURES\TS_2.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_3	FILE=TEXTURES\TS_3.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_4	FILE=TEXTURES\TS_4.PCX	MIPS=OFF

var config bool Enabled, Ghost, Ghosts, TeamSkin, ShowTrig, WallHack, SpeedMeter, CustomTimer;
var config float LocationX, LocationY, TimerScale;
var config byte Red, Green, Blue, SkinColor;
var byte ServerSkinColor;

replication
{
	reliable if (Role < ROLE_Authority)
		SSS;

	reliable if(Role == ROLE_Authority)
		SS;
}

event Spawned()
{
	SS();
}

simulated function SS()
{
	SSS(SkinColor);
}

function SSS(byte C)
{
	ServerSkinColor = C;
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
        case "Disable": Enabled = false; break;
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
		case "Blue": Blue = Number; break;
		case "X": LocationX = Number; break;
		case "Y": LocationY = Number;
	}
	if(!CustomTimer)
		CustomTimer = true;

	SaveConfig();
}

simulated function SetSkinColor(string Color)
{
	switch(Color)
	{
		case "Red": SkinColor = 0; break;
		case "Blue": SkinColor = 1; break;
		case "Green": SkinColor = 2; break;
		case "Yellow": SkinColor = 3; break;
		case "Black": SkinColor = 4; break;
		case "Team": SkinColor = 99;
	}
	SSS(SkinColor);
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
	SkinColor=99
	ServerSkinColor=99
	CustomTimer=False
	LocationX=0
	LocationY=0
	TimerScale=1
	Red=127
	Green=127
	Blue=0
}