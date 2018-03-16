//=============================================================================
// BTEPRI made by OwYeaW
//=============================================================================
class BTEPRI expands ReplicationInfo;

var PlayerPawn PP;
var int PlayerID;

var int	ArmorAmount, ChestAmount, ThighAmount, BootCharges;
var bool bShieldbelt, bChestArmor, bThighArmor, bJumpBoots;

var bool NetSpeedLimiter, KickPlayer, Broadcast;
var int ResetNetSpeed, MinimumNetSpeed, MaximumNetSpeed;

//=============================================================================
// replicating armor + boots from server to clients
//=============================================================================
replication
{
	reliable if (Role == ROLE_Authority)
		PP, PlayerID, ArmorAmount, ChestAmount, ThighAmount, bShieldbelt, bChestArmor, bThighArmor, bJumpBoots, BootCharges, ClientStuff;
}
//=============================================================================
// Tick - checks armor and boots in player's inventory + netspeed check
//=============================================================================
event Spawned()
{
	if(Role == ROLE_Authority)
		Enable('Tick');
}
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
	ClientStuff(ResetNetSpeed, KickPlayer);
	PlayerPawn(Owner).Suicide();
	PlayerPawn(Owner).ClientMessage("Netspeed values should be between " $ MinimumNetSpeed $ " and " $ MaximumNetSpeed);
	PlayerPawn(Owner).ClientMessage("Your netspeed was " $ NetSpeed $ " and has been reset to " $ ResetNetSpeed);

	Disable('Tick');
	SetTimer(0.3, false);

	if(Broadcast)
	{
		if(KickPlayer)
			BroadcastMessage(PlayerPawn(Owner).PlayerReplicationInfo.PlayerName $ " tried to use " $ NetSpeed $ " netspeed and got kicked from the server", true, 'CriticalEvent');
		else
			BroadcastMessage(PlayerPawn(Owner).PlayerReplicationInfo.PlayerName $ " tried to use " $ NetSpeed $ " netspeed", true, 'CriticalEvent');
	}
}
function Timer()
{
	Enable('Tick');
}
simulated function ClientStuff(int NetSpeed, bool bKick)
{
	if(Level.NetMode != NM_DedicatedServer)
	{
		PlayerPawn(Owner).ConsoleCommand("NETSPEED " $ NetSpeed);
		if(bKick)
			PlayerPawn(Owner).ConsoleCommand("DISCONNECT");
	}
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=9.000000
}