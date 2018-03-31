//=============================================================================
// BTSpectator made by OwYeaW
//=============================================================================
class BTSpectator expands CHSpectator;

var bool bTouchingTele, SpecGhost;
var int SpecSpeed, SpecView;
var BTEClientData BTEC;

replication
{
	reliable if(Role == ROLE_Authority)
		GetVoice, SpecGhost, SpecSpeed, SpecView;
	reliable if(Role < ROLE_Authority)
		Chase, JumpFrom, TeleSpec, SetVoice;
}

simulated event PostBeginPlay()
{
	if(Level.NetMode != NM_DedicatedServer)
		SetTimer(0.05, true);

	GetVoice();
	Super.PostBeginPlay();
}
//=============================================================================
// STATE CHEATFLYING
//=============================================================================
state CheatFlying
{
ignores SeePlayer, HearNoise, Bump, TakeDamage;

	function AnimEnd()
	{
		PlaySwimming();
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		Acceleration = Normal(NewAccel);
		Velocity = Normal(NewAccel) * SpecSpeed;
		AutonomousPhysics(DeltaTime);
	}

	event PlayerTick( float DeltaTime )
	{
		if ( bUpdatePosition )
			ClientUpdatePosition();

		PlayerMove(DeltaTime);
	}

	function PlayerMove(float DeltaTime)
	{
		local rotator newRotation;
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);  

		UpdateRotation(DeltaTime, 1);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
	}

	function BeginState()
	{
		EyeHeight = BaseEyeHeight;
		SetPhysics(PHYS_Flying);
		if  ( !IsAnimating() ) PlaySwimming();
		// log("cheat flying");
	}
}
//=============================================================================
// 3RD PERSON VIEW STUFF
//=============================================================================
function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
	local vector View,HitLocation,HitNormal;
	local float ViewDist;

	CameraRotation = ViewRotation;
	View = vect(1,0,0) >> CameraRotation;
	if( Trace( HitLocation, HitNormal, CameraLocation - (Dist + 30) * vector(CameraRotation), CameraLocation ) != None )
		ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
	else
		ViewDist = Dist;
	CameraLocation -= (ViewDist - 30) * View; 
}
function GhostCalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
	local vector View;

	CameraRotation = ViewRotation;
	View = vect(1,0,0) >> CameraRotation;
	CameraLocation -= (Dist - 30) * View;
}
event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local Pawn PTarget;

	if(ViewTarget != None)
	{
		ViewActor = ViewTarget;
		CameraLocation = ViewTarget.Location;
		CameraRotation = ViewTarget.Rotation;
		PTarget = Pawn(ViewTarget);
		if(PTarget != None)
		{
			if(Level.NetMode == NM_Client)
			{
				if(PTarget.bIsPlayer)
					PTarget.ViewRotation = TargetViewRotation;
				PTarget.EyeHeight = TargetEyeHeight;
				if(PTarget.Weapon != None)
					PTarget.Weapon.PlayerViewOffset = TargetWeaponViewOffset;
			}
			if(PTarget.bIsPlayer)
				CameraRotation = PTarget.ViewRotation;
			if(!bBehindView)
				CameraLocation.Z += PTarget.EyeHeight;
		}
		if(bBehindView)
		{
			if(SpecGhost)
				GhostCalcBehindView(CameraLocation, CameraRotation, SpecView);
			else
				CalcBehindView(CameraLocation, CameraRotation, SpecView);
		}
		return;
	}

	ViewActor = Self;
	CameraLocation = Location;

	// First-person view.
	CameraRotation = ViewRotation;
	CameraLocation.Z += EyeHeight;
	CameraLocation += WalkBob;
}
//=============================================================================
// TELEPORTER STUFF
//=============================================================================
simulated function Timer()
{
	local Teleporter Tele;
	local bool bTeleFound;

	foreach VisibleCollidingActors(class'Teleporter', Tele, 39, Location, false)
	{
		if(!bTouchingTele)
		{
			TeleSpec(Tele);
			bTouchingTele = true;
		}
		bTelefound = true;
	}
	if(!bTelefound && bTouchingTele)
		bTouchingTele = false;
}
function TeleSpec(Teleporter Tele)
{
	local rotator newRot;
	local Teleporter Dest;
	local int i;

	if(Tele.bEnabled && Tele.URL != "")
	{
		if( (InStr( Tele.URL, "/" ) >= 0) || (InStr( Tele.URL, "#" ) >= 0) )
		{
			// Teleport to a level on the net.
			if(Role == ROLE_Authority)
				Level.Game.SendPlayer(Self, Tele.URL);
		}
		else
		{
			foreach AllActors(class'Teleporter', Dest)
				if(string(Dest.tag) ~= Tele.URL && Dest != Tele)
					i++;

			i = rand(i);
			foreach AllActors(class'Teleporter', Dest)
				if(string(Dest.tag) ~= Tele.URL && Dest != Tele && i-- == 0 )
					break;

			if(Dest != None)
			{
				newRot = Rotation;
				if(Dest.bChangesYaw)
				{
					newRot.Yaw = Dest.Rotation.Yaw;
					newRot.Yaw += (32768 + Rotation.Yaw - Tele.Rotation.Yaw);
				}
				SetLocation(Dest.Location);
				if(Role == ROLE_Authority)
				{
					SetRotation(newRot);
					ViewRotation = newRot;
				}
			}
			else if(Role == ROLE_Authority)
				ClientMessage( "Teleport destination for "$Tele$" not found!" );
		}
	}
}
//=============================================================================
// EXEC FUNCTIONS
//=============================================================================
// Say MSG stuff
//=============================================================================
exec function Say(string Msg)
{
	local Pawn P;

	if(bAdmin && left(Msg,1) == "#")
	{
		Msg = right(Msg, len(Msg) - 1);
		for(P = Level.PawnList; P != None; P = P.nextPawn)
		{
			if( P.IsA('PlayerPawn') )
			{
				PlayerPawn(P).ClearProgressMessages();
				PlayerPawn(P).SetProgressTime(6);
				PlayerPawn(P).SetProgressMessage(Msg,0);
			}
		}
		return;
	}
	if( Level.Game.AllowsBroadcast(self, Len(Msg)) )
	{
		for(P = Level.PawnList; P != None; P = P.nextPawn)
		{
			if( P.bIsPlayer || P.IsA('MessagingSpectator') )
			{
				if(Level.Game != None && Level.Game.MessageMutator != None)
				{
					if( Level.Game.MessageMutator.MutatorTeamMessage(Self, P, PlayerReplicationInfo, Msg, 'Say', true) )
						P.TeamMessage(PlayerReplicationInfo, Msg, 'Say', true);
				}
				else
					P.TeamMessage(PlayerReplicationInfo, Msg, 'Say', true);
			}
		}
	}
}
// Speech stuff
//=============================================================================
exec function Speech(int Type, int Index, int Callsign)
{
	local VoicePack V;

	GetVoice();

	V = Spawn(PlayerReplicationInfo.VoiceType, Self);
	if(V != None)
		V.PlayerSpeech(Type, Index, Callsign);
}
simulated function GetVoice()
{
	local class<VoicePack> VP;

	VP = class<VoicePack>(DynamicLoadObject(GetDefaultURL("Voice"), class'Class'));
	if(VP != None)
		SetVoice(VP);
}
function SetVoice(class<VoicePack> VP)
{
	PlayerReplicationInfo.VoiceType = VP;
}
// Alt Fire function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function AltFire(optional float F)
{
	local vector HitLocation, HitNormal;
	local Pawn aP;
	local float aF;

	if(ViewTarget != None)
	{
		bBehindView = false;
		Viewtarget = None;
	}
	else if(Level.NetMode != NM_Client)	//Server sets this one, prevents ACE kick
	{
		Trace(HitLocation, HitNormal, Location + vector(ViewRotation) * 15000);
		if( HitLocation != vect(0,0,0) )
		{
			aF = 1001;
			ForEach VisibleCollidingActors (class'Pawn', aP, 1000)
			{
				if( (aP.PlayerReplicationInfo != none) && (aP.PlayerReplicationInfo.PlayerName != "Player" ) )
				{
					if(VSize(aP.Location - HitLocation) < aF)
					{
						ViewTarget = aP;
						aF = VSize(aP.Location - HitLocation);
					}
				}
			}
			if(ViewTarget != None)
			{
				bBehindView = true;
				ViewTarget.BecomeViewTarget();
			}
		}
	}
}
// Jump function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function Jump(optional float F)
{
	if(Pawn(ViewTarget) != None)
		JumpFrom();
	else if(F != 0)
		Super.Jump(F);
}
function JumpFrom()
{
	SetLocation(ViewTarget.Location);
	ViewTarget = None;
	bBehindView = false;
}
// Chase function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function Chase(string aPlayer)
{
	local PlayerReplicationInfo PRI;

	if(Level.NetMode != NM_CLient && aPlayer != "")
	{
		ForEach AllActors(class'PlayerReplicationInfo', PRI)
		{
			if(PRI.PlayerName != "Player" && InStr(Caps(PRI.PlayerName), Caps(aPlayer)) >= 0)
			{
				ViewTarget = PRI.Owner;
				bBehindView = true;
				return;
			}
		}
	}
}
// ThrowWeapon/Suicide function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function ThrowWeapon()
{
	local vector HitLocation, HitNormal;

	if(Level.NetMode != NM_Client) //Server sets this one, prevents ACE kick
	{
		if(Pawn(ViewTarget) == None)
		{
			Trace(HitLocation, HitNormal, Location + vector(ViewRotation) * 15000);
			if( HitLocation != vect(0,0,0) )
				SetLocation(HitLocation + HitNormal * 5);
		}
	}
}
// Suicide - Teleport 1500 units forward
//=============================================================================
exec function Suicide()
{
	if(Level.NetMode != NM_Client) //Server sets this one, prevents ACE kick
	{
		if(Pawn(ViewTarget) == None)
		{
			SetLocation(Location + vector(ViewRotation) * 1500);
		}
	}
}
// Fly function taken from Spectator.uc and modified
//=============================================================================
exec function Fly()
{
	UnderWaterTime = -1;
	GotoState('CheatFlying');
	ClientRestart();
}
// Possess function taken from Spectator.uc and modified
//=============================================================================
function Possess()
{
	bIsPlayer = true;
	DodgeClickTime = FMin(0.3, DodgeClickTime);
	EyeHeight = BaseEyeHeight;
	NetPriority = 2;
	Weapon = None;
	Inventory = None;
	Fly();
	GetVoice();
}
// Grab - Initialize function
//=============================================================================
exec function Grab()
{
	if(BTEC.ServerSpecGhost)
	{
		SpecGhost = true;
		bCollideWorld = false;
	}
	if(BTEC.ServerSpecSpeed < 0)
		SpecSpeed = 0;
	else
		SpecSpeed = BTEC.ServerSpecSpeed;

	if(BTEC.ServerSpecView < 0)
		SpecView = 0;
	else
		SpecView = BTEC.ServerSpecView;
}
//=============================================================================
// REMOVE SPAMMY CLIENTMESSAGES
//=============================================================================
exec function ViewPlayerNum(optional int num)
{
	local Pawn P;

	if(!PlayerReplicationInfo.bIsSpectator && !Level.Game.bTeamGame)
		return;

	if(num >= 0)
	{
		P = Pawn(ViewTarget);
		if(P != None && P.bIsPlayer && P.PlayerReplicationInfo.TeamID == num)
		{
			ViewTarget = None;
			bBehindView = false;
			return;
		}
		for(P = Level.PawnList; P != None; P = P.NextPawn)
		{
			if(P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.Team == PlayerReplicationInfo.Team && !P.PlayerReplicationInfo.bIsSpectator && P.PlayerReplicationInfo.TeamID == num )
			{
				if(P != Self)
				{
					ViewTarget = P;
					bBehindView = true;
				}
				return;
			}
		}
		return;
	}
	if(Role == ROLE_Authority)
	{
		ViewClass(class'Pawn', true);
		While( ViewTarget != None && (!Pawn(ViewTarget).bIsPlayer || Pawn(ViewTarget).PlayerReplicationInfo.bIsSpectator) )
			ViewClass(class'Pawn', true);
	}
}
exec function ViewPlayer(string S)
{
	local pawn P;

	for(P = Level.pawnList; P != None; P = P.NextPawn)
		if(P.bIsPlayer && P.PlayerReplicationInfo.PlayerName ~= S)
			break;
	if( P != None && Level.Game.CanSpectate(Self, P) )
	{
		if(P == Self)
			ViewTarget = None;
		else
			ViewTarget = P;
	}
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
exec function CheatView(class<actor> aClass)
{
	local actor Other, First;
	local bool bFound;

	if(!bCheatsEnabled)
		return;
	if(!bAdmin && Level.NetMode != NM_Standalone)
		return;
	First = None;
	ForEach AllActors(aClass, Other)
	{
		if(First == None && Other != Self)
		{
			First = Other;
			bFound = true;
		}
		if(Other == ViewTarget)
			First = None;
	}
	if(First != None)
		ViewTarget = First;
	else
		ViewTarget = None;
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
exec function ViewSelf()
{
	bBehindView = false;
	Viewtarget = None;
}
exec function ViewClass(class<actor> aClass, optional bool bQuiet)
{
	local actor Other, First;
	local bool bFound;

	if(Level.Game != None && !Level.Game.bCanViewOthers)
		return;
	First = None;
	ForEach AllActors(aClass, Other)
	{
		if( First == None && Other != Self && ( (bAdmin && Level.Game == None) || Level.Game.CanSpectate(Self, Other) ) )
		{
			First = Other;
			bFound = true;
		}
		if(Other == ViewTarget)
			First = None;
	}
	if(First != None)
		ViewTarget = First;
	else
		ViewTarget = None;
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	Texture=None
	bCollideActors=False
	bCollideWorld=True
	bBlockActors=False
	bBlockPlayers=False
	bProjTarget=False
	AirSpeed=12000
	SpecGhost=False
	SpecSpeed=300
	SpecView=180
}