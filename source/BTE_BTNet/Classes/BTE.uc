//=============================================================================
// BT Enhancements made by OwYeaW
//=============================================================================
class BTE expands Mutator config(BTE);

var config bool NetSpeedLimiter, KickPlayer, Broadcast;
var config int ResetNetSpeed, MinimumNetSpeed, MaximumNetSpeed;
var config string MapExceptions;

var config bool FixLagMovers;
var config string LagMovers[64];

var int Counter;
var int	CurrentID;
var string LevelName;
var bool bNetSpeedLimiter;

struct PlayerInfo
{
	var PlayerPawn PP;
	var BTEPRI EPRI;
	var BTEClientData BTEC;
};
var PlayerInfo PI[32];

struct SpecInfo
{
	var	PlayerPawn PP;
	var BTEClientData BTEC;
};
var PlayerInfo SI[32];

function PreBeginPlay()
{
	Level.Game.BaseMutator.AddMutator(self);

	if(Role == ROLE_Authority)
		Enable('Tick');

	Super.PreBeginPlay();
}

function PostBeginPlay()
{
	LevelName = GetLevelName();

	if(NetSpeedLimiter && InStr(MapExceptions, LevelName) == -1)
		bNetSpeedLimiter = true;
	else
		bNetSpeedLimiter = false;

	if(FixLagMovers)
		UnLagMovers();

	Super.PostBeginPlay();
}

function ModifyLogin(out class<playerpawn> SpawnClass, out string Portal, out string Options)
{
	if (SpawnClass == class'CHSpectator')
		SpawnClass = class'BTSpectator';

	if ( NextMutator != None )
		NextMutator.ModifyLogin(SpawnClass, Portal, Options);
}
//=============================================================================
// MUTATOR INITIALIZATION
//=============================================================================
function tick(float DeltaTime)
{
	local BTPPHUDNotify N;

	Counter++;
	if(Counter < 1000)
	{
		foreach AllActors(class'BTPPHUDNotify', N)
		{
			if(N != None)
			{
				//	setting a complete BT HUD as default HUD
				Level.Game.HUDType = class'BTHUD_BTNet';
				//	destroy BTPPHUDNotify to prevent BT++' HUDMutator from spawning
				N.Destroy();
				//	keeps actors visible when seeing through BSP
				if(int(ConsoleCommand("GET IPDRV.TCPNETDRIVER RELEVANTTIMEOUT")) < 1200)
					ConsoleCommand("SET IPDRV.TCPNETDRIVER RELEVANTTIMEOUT 1200");

				log("+-----------------");
				log("| * BT Enhancements Enabled");
				Log("| BTPPHUDNotify Destroyed");
				Log("| TickCounter: " $ Counter);
				log("+-----------------");
				GotoState('Enabled');
			}
		}
	}
	else
	{
		log("+-----------------");
		log("| * BT Enhancements Disabled");
		Log("| BTPPHUDNotify was not found");
		Log("| TickCounter: " $ Counter);
		log("+-----------------");
		Destroy();
	}
}
//=============================================================================
// PLAYER/SPEC INITIALIZATION FOR CLIENT SETTINGS AND BOOTS + ARMOR
//=============================================================================
state Enabled
{
	function tick(float DeltaTime)
	{
		CheckForNewPlayer();
		Super.tick(DeltaTime);
	}
}
function CheckForNewPlayer()
{
	local Pawn P;

	if(Level.Game.CurrentID > CurrentID)
	{
		for(P = Level.PawnList; P != None; P = P.NextPawn)
			if(P.PlayerReplicationInfo.PlayerID == CurrentID)
				break;
		CurrentID++;

		if(PlayerPawn(P) != None && P.bIsPlayer)
		{
			if(P.PlayerReplicationInfo.bIsSpectator && !P.PlayerReplicationInfo.bWaitingPlayer)
				InitNewSpec(PlayerPawn(P));
			else
				InitNewPlayer(PlayerPawn(P));
		}
	}
}
//=============================================================================
// INIT SPEC
//=============================================================================
function InitNewSpec(PlayerPawn PP)
{
	local int i, k;

	i = FindFreeSISlot();

	SI[i].PP = PP;
	SI[i].BTEC = Spawn(class'BTEUser.BTEClientData', PP);
}
function int FindFreeSISlot()
{
	local int i;

	for(i = 0; i < 32; i++)
	{
		if(SI[i].PP == None)
			return i;
		else if(SI[i].PP.Player == None)
			return i;
	}
}
//=============================================================================
// INIT PLAYER
//=============================================================================
function InitNewPlayer(PlayerPawn PP)
{
	local int i;

	i = FindFreePISlot();

	PI[i].PP = PP;
	PI[i].BTEC = Spawn(class'BTEUser.BTEClientData', PP);
	PI[i].EPRI = Spawn(class'BTEPRI', PP);
	PI[i].EPRI.PlayerID = PP.PlayerReplicationInfo.PlayerID;
	PI[i].EPRI.PP = PP;
	PI[i].EPRI.NetSpeedLimiter = bNetSpeedLimiter;
	PI[i].EPRI.KickPlayer = KickPlayer;
	PI[i].EPRI.Broadcast = Broadcast;
	PI[i].EPRI.ResetNetSpeed = ResetNetSpeed;
	PI[i].EPRI.MinimumNetSpeed = MinimumNetSpeed;
	PI[i].EPRI.MaximumNetSpeed = MaximumNetSpeed;
}
function int FindFreePISlot()
{
	local int i;

	for(i = 0; i < 32; i++)
	{
		if(PI[i].PP == None)
			return i;
		else if(PI[i].PP.Player == None)
			return i;
	}
}
//====================================
// Find PI or SI for PP
//====================================
function int FindPP(PlayerPawn PP)
{
	local int i;

	if(PP.PlayerReplicationInfo.bIsSpectator && !PP.PlayerReplicationInfo.bWaitingPlayer)
	{
		for(i = 0; i < 32; i++)
		{
			if(SI[i].PP == PP)
				return i;
		}
		return -1;
	}
	else
	{
		for(i = 0; i < 32; i++)
		{
			if(PI[i].PP == PP)
				return i;
		}
		return -1;
	}
}
//=============================================================================
// MUTATE CHECKPOINT	-> TELEPORT BIND
// MUTATE LAGMOVER		-> SWITCH LAG MOVER
// MUTATE NSMAP			-> Add current map to MapExceptions
//=============================================================================
function Mutate(string MutateString, PlayerPawn Sender)
{
	Super.Mutate(MutateString, Sender);

	switch MutateString
	{
		case "checkpoint":
			if( Sender.IsA('BTSpectator') && !Sender.IsInState('GameEnded') )
				BTSpectator(Sender).Suicide();
			break;

		case "lagmover":
			if(Sender.bAdmin)
				SwitchLagMover(Sender);
			break;

		case "nsmap":
			if(Sender.bAdmin)
				AddMapToExceptions(Sender);
	}
}
function AddMapToExceptions(PlayerPawn Sender)
{
	local BTEPRI EPRI;

	if(InStr(MapExceptions, LevelName) == -1)
	{
		Sender.ClientMessage("Added map as an exception - Players can now use any netspeed value");
		MapExceptions = MapExceptions $ "," $ LevelName;
		SaveConfig();

		bNetSpeedLimiter = false;
		foreach AllActors(class'BTEPRI', EPRI)
			if(EPRI.NetSpeedLimiter)
				EPRI.NetSpeedLimiter = false;
	}
	else
		Sender.ClientMessage("This map is already an exception");
}
function SwitchLagMover(PlayerPawn Sender)
{
	local Actor HitActor;
	local vector X,Y,Z, HitLocation, HitNormal, EndTrace, StartTrace;
	local Mover HitMover;

	GetAxes(Sender.ViewRotation,X,Y,Z);

	StartTrace = Sender.Location + Sender.EyeHeight * vect(0,0,1);
	EndTrace = StartTrace + X * 10000;

	HitActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace, false);
	HitMover = Mover(HitActor);

	if(HitMover != None)
	{
		if(HitMover.RemoteRole == ROLE_DumbProxy)
		{
			HitMover.RemoteRole = ROLE_SimulatedProxy;
			Sender.ClientMessage(string(HitMover.Name) $ " is now SimulatedProxy");
		}
		else
		{
			HitMover.RemoteRole = ROLE_DumbProxy;
			Sender.ClientMessage(string(HitMover.Name) $ " is now DumbProxy");
		}
	}
}
function UnLagMovers()
{
	local int i, j, en;
	local bool bMapMatch;
	local Mover M;

	for(i = 0; i < 64; i++)
	{
		if(LagMovers[i] == "")
			continue;
		en = ElementsNum(SepRight(LagMovers[i]));
		for(j = 1; j <= en; j++)
		{
			if(InStr(Caps(LevelName), Caps(SelElem(SepRight(LagMovers[i]),j, ","))) != -1)
			{
				bMapMatch = True;
				break;
			}
		}
		if(bMapMatch)
		{
			en = ElementsNum(SepLeft(LagMovers[i]));
			for(j = 1;j <= en;j++)
			{
				Foreach AllActors(Class'Mover',M)
				{
					if(string(M.Name) == SelElem(SepLeft(LagMovers[i]), j, ","))
						M.RemoteRole = ROLE_DumbProxy;
				}
			}
		}
	}
}
//====================================
// SelElem - Selects an element from a string where elements are separated by a "Char"
//====================================
static final function string SelElem(string Str, int Elem, optional string Char)
{
	local int pos, count;
	if(Char == "")
		Char = ":"; // this is a default separator

	while( (Elem--) >1)
	{
		pos = InStr(Str, Char);
		if(pos != -1)
			Str = Mid(Str, pos+1);
		else
			return "";
	}
	pos = InStr(Str, Char);
	if(pos != -1)
		return Left(Str, pos);
	else
		return Str;
}
//====================================
// SepRight - Separates a right part of a string with a certain character as a separator
//====================================
static final function string SepRight(string Input, optional string Char)
{
	local int pos;
	if(Char == "")
		Char = ":"; // this is a default separator

	pos = InStr(Input, Char);
	if(pos != -1)
		return Mid(Input, pos+1);
	else
		return "";
}
//====================================
// SepLeft - Separates a left part of a string with a certain character as a separator
//====================================
static final function string SepLeft(string Input, optional string Char)
{
	local int pos;
	if(Char == "")
		Char = ":"; // this is a default separator

	pos = InStr(Input, Char);
	if(pos != -1)
		return Left(Input, pos);
	else
		return "";
}
//====================================
// ElementsNum - Counts a specified character in a string(and thus elements) and returns the countresult-1;
//====================================
static final function int ElementsNum(string Str, optional string Char)
{
	local int count, pos;

	if(Char == "")
		Char = ","; // this is a default separator for config lists
	while(true)
	{
		pos = InStr(Str, Char);
		if(pos == -1)
			break;
		Str = Mid(Str, pos+1);
		count++;
	}
	return count+1;
}
//====================================
// GetLevelName - Returns a level name(file name) in a readable format
// Triggered in: PostBeginPlay
//====================================
function string GetLevelName()
{
	local string Str;
	local int Pos;

	Str = string(Level);
	Pos = InStr(Str, ".");
	if(Pos != -1)
		return Left(Str, Pos);
	else
		return Str;
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	NetSpeedLimiter=True
	KickPlayer=True
	Broadcast=True
	ResetNetSpeed=20000
	MinimumNetSpeed=8000
	MaximumNetSpeed=20000
	MapExceptions="CTF-BT-BasicGayMap-v2"
	FixLagMovers=True
	LagMovers(0)="Mover17,Mover18,Mover99,Mover100:CTF-BT-Donnie-v1"
	LagMovers(1)="Mover12,Mover14,Mover24,Mover25:CTF-BT-Canyon[2011]"
}