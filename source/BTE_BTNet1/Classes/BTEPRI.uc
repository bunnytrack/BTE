//=============================================================================
// BTEPRI made by OwYeaW
//=============================================================================
class BTEPRI expands ReplicationInfo;

var PlayerPawn PP;
var int PlayerID;
var string DefaultSkin, DefaultFace;
var byte SkinColor, TeamColor;
var BTEClientData BTEC;

var int	ArmorAmount, ChestAmount, ThighAmount, BootCharges;
var bool bShieldbelt, bChestArmor, bThighArmor, bJumpBoots;

var bool NetSpeedLimiter, KickPlayer, Broadcast, AutoCorrectNetspeed;
var int CorrectNetspeed, MinimumNetSpeed, MaximumNetSpeed;
//=============================================================================
// replicating armor + boots from server to clients
//=============================================================================
replication
{
	reliable if (Role < ROLE_Authority)
		ServerSkinStuff;

	reliable if (Role == ROLE_Authority)
		PP, PlayerID, ArmorAmount, ChestAmount, ThighAmount, bShieldbelt, bChestArmor, bThighArmor, bJumpBoots, BootCharges, ClientSkinStuff, DefaultSkin, DefaultFace, SkinColor;
}
event Spawned()
{
	if(Role == ROLE_Authority)
		Enable('Tick');

	ClientSkinStuff();
}
simulated function ClientSkinStuff()
{
	local string Skin;
	local string Face;

	Skin = PlayerPawn(Owner).GetDefaultURL("Skin");
	Face = PlayerPawn(Owner).GetDefaultURL("Face");

	ServerSkinStuff(Face, Skin);
}
function ServerSkinStuff(string gotFace, string gotSkin)
{
	DefaultSkin = gotSkin;
	DefaultFace = gotFace;

	GetSkinColor();
	SetSkinColor();
}
function SetSkinColor()
{
	if(SkinColor >= 0 && SkinColor < 5)
		PlayerPawn(Owner).static.SetMultiSkin(PlayerPawn(Owner), DefaultSkin, DefaultFace, SkinColor);
}
function GetSkinColor()
{
	if(BTEC != None)
		SkinColor = BTEC.ServerSkinColor;
}
//=============================================================================
// Tick - checks armor and boots in player's inventory + netspeed check
//=============================================================================
function Tick(float d)
{
	Local inventory Inv;
	local int NetSpeed;
	local int i;

	if(Owner == None)
		Destroy();
	else
	{
		BootCharges = 0;
		ArmorAmount = 0;
		ThighAmount = 0;
		ChestAmount = 0;
		bJumpBoots = false;
		bShieldbelt = false;
		bThighArmor = false;
		bChestArmor = false;
		for(Inv = PP.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if(Inv.bIsAnArmor)
			{
				if( Inv.IsA('UT_Shieldbelt') )
					bShieldbelt = true;
				else if( Inv.IsA('Thighpads') )
				{
					ThighAmount += Inv.Charge;
					bThighArmor = true;
				}
				else
				{
					bChestArmor = true;
					ChestAmount += Inv.Charge;
				}
				ArmorAmount += Inv.Charge;
			}
			else if( Inv.IsA('UT_JumpBoots') )
			{
				bJumpBoots = true;
				BootCharges = Inv.Charge;
			}
			else
			{
				i++;
				if(i > 100)
					break; // can occasionally get temporary loops in netplay
			}
		}

		if(PlayerPawn(Owner).PlayerReplicationInfo.Team != TeamColor)
		{
			TeamColor = PlayerPawn(Owner).PlayerReplicationInfo.Team;
			GetSkinColor();
			SetSkinColor();
		}

		if(NetSpeedLimiter)
		{
			NetSpeed = PlayerPawn(Owner).Player.CurrentNetSpeed;
			if(NetSpeed > MaximumNetSpeed || NetSpeed < MinimumNetSpeed)
				TakeAction(NetSpeed);
		}
	}
}
//=============================================================================
// Anti Netspeed cheat Functions
//=============================================================================
function TakeAction(int NetSpeed)
{
	PlayerPawn(Owner).ClientMessage("Netspeed values should be between " $ MinimumNetSpeed $ " and " $ MaximumNetSpeed);
	if(AutoCorrectNetSpeed)
	{
		PlayerPawn(Owner).ConsoleCommand("NETSPEED " $ CorrectNetspeed);
		PlayerPawn(Owner).ClientMessage("Your netspeed was " $ NetSpeed $ " and has been reset to " $ CorrectNetspeed);
	}
	else
		PlayerPawn(Owner).ClientMessage("Your netspeed is " $ NetSpeed);

	if(KickPlayer)
		PlayerPawn(Owner).Destroy();
	else
		PlayerPawn(Owner).Suicide();

	if(Broadcast)
	{
		if(KickPlayer)
			BroadcastMessage(PlayerPawn(Owner).PlayerReplicationInfo.PlayerName $ " tried to use " $ NetSpeed $ " netspeed and got kicked from the server", true, 'CriticalEvent');
		else if(AutoCorrectNetSpeed)
			BroadcastMessage(PlayerPawn(Owner).PlayerReplicationInfo.PlayerName $ " tried to use " $ NetSpeed $ " netspeed", true, 'CriticalEvent');
	}

	Disable('Tick');
	SetTimer(0.3, false);
}
function Timer()
{
	Enable('Tick');
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=9.000000
}