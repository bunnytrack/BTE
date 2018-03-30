//=============================================================================
// BTEClient made by OwYeaW
//=============================================================================
class BTEClientData expands Info config(BT_Enhancements);

#exec texture IMPORT NAME=TS_0	FILE=TEXTURES\TS_0.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_1	FILE=TEXTURES\TS_1.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_2	FILE=TEXTURES\TS_2.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_3	FILE=TEXTURES\TS_3.PCX	MIPS=OFF
#exec texture IMPORT NAME=TS_4	FILE=TEXTURES\TS_4.PCX	MIPS=OFF

var config bool Enabled;
var config bool Ghost;
var config bool Ghosts;
var config bool TeamSkin;
var config bool ShowTrig;
var config bool WallHack;
var config bool SpeedMeter;

var config bool SpecGhost;
var config int SpecSPeed;
var config int SpecView;

var config bool CustomTimer;
var config int LocationX;
var config int LocationY;
var config float TimerScale;
var config byte Red;
var config byte Green;
var config byte Blue;

var config byte SkinColor;

var byte ServerSkinColor;
var bool ServerSpecGhost;
var int ServerSpecSPeed;
var int ServerSpecView;

replication
{
	reliable if (Role < ROLE_Authority)
		SetServerSkinColor, SetServerSpecVars;

	reliable if(Role == ROLE_Authority)
		GetClientVars;
}

event Spawned()
{
	GetClientVars();
}

simulated function GetClientVars()
{
	SetServerSpecVars(SpecGhost, SpecSPeed, SpecView);
	SetServerSkinColor(SkinColor);
}

function SetServerSpecVars(bool SpecGhost, int SpecSPeed, int SpecView)
{
	ServerSpecGhost = SpecGhost;
	ServerSpecSPeed = SpecSPeed;
	ServerSpecView = SpecView;
	PlayerPawn(Owner).Grab();
}

function SetServerSkinColor(byte C)
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
            case "SpecGhost": SpecGhost = !SpecGhost; break;
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

simulated function SpecSetting(string Setting, int Number)
{
	switch(Setting)
	{
		case "SpecSPeed": SpecSPeed = Number; break;
		case "SpecView": SpecView = Number;
	}
	if(!SpecGhost)
	{
		SpecGhost = true;
		SetServerSpecVars(SpecGhost, SpecSPeed, SpecView);
	}

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
	SetServerSkinColor(SkinColor);
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
	SpecGhost=True
	SpecSpeed=300
	SpecView=180
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