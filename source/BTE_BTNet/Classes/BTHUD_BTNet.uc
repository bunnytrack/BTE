//=============================================================================
// BTHUD made by OwYeaW
//=============================================================================
class BTHUD_BTNet extends ChallengeTeamHUD;

#exec texture IMPORT NAME=Bootz		FILE=TEXTURES\Bootz.PCX		MIPS=OFF
#exec texture IMPORT NAME=Bunny		FILE=TEXTURES\Bunny.PCX		FLAGS=2 MIPS=OFF
#exec texture IMPORT NAME=BTTimer	FILE=TEXTURES\BTTIMER.PCX	FLAGS=3 MIPS=OFF

struct PlayerInfo
{
	var PlayerReplicationInfo	PRI;
	var BTPPReplicationInfo		RI;
	var BTEPRI					EPRI;
};
var PlayerInfo PI[32];

var color					OrangeColor;
var color					YellowColor;
var color					BlackColor;
var color					GreyColor;
var ClientData				Config;
var BTEClientData			BTEC;
var BTEPRI					EPRI;
var BTPPGameReplicationInfo	GRI;
var BTPPReplicationInfo		RI;

var Texture TStexP;
var Texture TStexW;
var Console	PlayerConsole;
var string	cmdBuffer;

var int		Index;
var int		LastTime;
var bool	lastUpdate;
var float	cStamp;
var int		oldUpdate;

var() color TeamColor[4];
var() color AltTeamColor[4];

var() name OrderNames[16];
var() int NumOrders;

var CTFFlag MyFlag;

function Timer()
{
	Super.Timer();

	if(PlayerOwner == None || PawnOwner == None)
		return;
	if(PawnOwner.PlayerReplicationInfo.HasFlag != None)
		PlayerOwner.ReceiveLocalizedMessage(class'CTFMessage2', 0);
}

function HelpMSG()
{
	Pawn(Owner).ClientMessage("***********************************************");
	Pawn(Owner).ClientMessage("* BT Enhancements Commands");
	Pawn(Owner).ClientMessage("***********************************************");
	Pawn(Owner).ClientMessage("Make yourself Transparent");
	Pawn(Owner).ClientMessage(" - !Ghost");
	Pawn(Owner).ClientMessage("Make everyone Transparent");
	Pawn(Owner).ClientMessage(" - !Ghosts");
	Pawn(Owner).ClientMessage("Team colorized playerskins");
	Pawn(Owner).ClientMessage(" - !TeamSkin");
	Pawn(Owner).ClientMessage("Show all Triggers");
	Pawn(Owner).ClientMessage(" - !ShowTrig");
	Pawn(Owner).ClientMessage("WallHack only for Spectators");
	Pawn(Owner).ClientMessage(" - !Wallhack");
	Pawn(Owner).ClientMessage("Speed Meter");
	Pawn(Owner).ClientMessage(" - !SpeedMeter or !Speed");
	Pawn(Owner).ClientMessage("Disable all of the above features");
	Pawn(Owner).ClientMessage(" - !Disable");
	Pawn(Owner).ClientMessage("Enable/Disable Custom Timer");
	Pawn(Owner).ClientMessage(" - !Timer");
	Pawn(Owner).ClientMessage("Timer scaling");
	Pawn(Owner).ClientMessage(" - !TimerScale 1 or !tscale 2");
	Pawn(Owner).ClientMessage("Timer Red/Green/Blue colors");
	Pawn(Owner).ClientMessage(" - !TRed 255 or !tr <number>");
	Pawn(Owner).ClientMessage(" - !TGreen 0 or !tg <number>");
	Pawn(Owner).ClientMessage(" - !TBlue 90 or !tb <number>");
	Pawn(Owner).ClientMessage("***********************************************");
	Pawn(Owner).ClientMessage("* Original timer color: R=127 G=127 B=0");
	Pawn(Owner).ClientMessage("***********************************************");
}

simulated function BindReplications()
{
	local Info temp;

	if(Config == None || GRI == None || BTEC == None)
	{
		foreach AllActors(class'Info', temp)
		{
			if(PlayerPawn(temp.Owner) == PlayerOwner)
			{
				if(temp.IsA('ClientData'))
					Config = ClientData(temp);
				else if(temp.IsA('BTEClientData'))
					BTEC = BTEClientData(temp);
			}
			else if(temp.IsA('BTPPGameReplicationInfo'))
				GRI = BTPPGameReplicationInfo(temp);
		}
	}
}

simulated function PostRender( canvas Canvas )
{
	local float XL, YL, XPos, YPos, FadeValue, XX, YY;
	local string Message, SS;
	local int M, i, j, k, XOverflow, X, Y, z;
	local float OldOriginX;
	local CTFFlag Flag;
	local bool bAlt;
	local int Time;

	local Pawn				PAWNS;
	local Trigger			TRIG;
	local TournamentPlayer	TP;

	HUDSetup(canvas);
	if ( (PawnOwner == None) || (PlayerOwner.PlayerReplicationInfo == None) )
		return;

	if(bShowInfo)
	{
		ServerInfo.RenderInfo( Canvas );
		return;
	}
/*
==========================================================
*/
	BindReplications();
	if(BTEC != None)
	{
		if(PlayerConsole == None)
			PlayerConsole = PlayerPawn(Owner).Player.Console;

		if(PlayerConsole.IsInState('Typing'))
		{
			if(PlayerConsole.TypedStr != cmdBuffer)
				cmdBuffer = PlayerConsole.TypedStr;
		}
		else
		{
			if(cmdBuffer != "")
			{
				switch(cmdBuffer)
				{
					case "say !ghost":
						if(!Pawn(Owner).PlayerReplicationInfo.bIsSpectator)
						{
							BTEC.SwitchBool("Ghost");
							if (BTEC.Ghost)
							{
								Pawn(Owner).Style = STY_Translucent;
								if (Pawn(Owner).Weapon != None)
									Pawn(Owner).Weapon.Style = STY_Translucent;
								Pawn(Owner).bBehindview = true;
								Pawn(Owner).ClientMessage("You are now see-through");
							}
							else
							{
								Pawn(Owner).Style = STY_Normal;
								if (Pawn(Owner).Weapon != None)
									Pawn(Owner).Weapon.Style = STY_Normal;
								Pawn(Owner).bBehindview = false;
								Pawn(Owner).ClientMessage("You are no longer see-through");
							}
						}
						else
							Pawn(Owner).ClientMessage("Ghost is for Players only - Try '!Ghosts'");
					break;

					case "say !ghosts":
						BTEC.SwitchBool("Ghosts");
						if (!BTEC.Ghosts)
						{
							foreach AllActors(class'TournamentPlayer', TP)
							{
								if(TP == TournamentPlayer(Owner) && BTEC.Ghost)
									continue;
	
								TP.Style = STY_Normal;
								if (TP.Weapon != None)
									TP.Weapon.Style = STY_Normal;
							}
							Pawn(Owner).ClientMessage("Players are no longer see-through");
						}
						else
							Pawn(Owner).ClientMessage("Players are now see-through");
					break;
	
					case "say !showtrig":
						BTEC.SwitchBool("ShowTrig");
						if (!BTEC.ShowTrig)
						{
							foreach AllActors(class'Trigger', TRIG)
								TRIG.bHidden = true;
							Pawn(Owner).ClientMessage("Triggers are no longer visible");
						}
						else
							Pawn(Owner).ClientMessage("Triggers are now visible");
					break;
				
					case "say !teamskin":
						BTEC.SwitchBool("TeamSkin");
						if(BTEC.TeamSkin)
							Pawn(Owner).ClientMessage("TeamSkin Enabled");
						else
							Pawn(Owner).ClientMessage("TeamSkin Disabled - Reconnect to let it take effect");
					break;

					case "say !wallhack":
						if(Pawn(Owner).PlayerReplicationInfo.bIsSpectator)
						{
							BTEC.SwitchBool("WallHack");
							if(BTEC.WallHack)
								Pawn(Owner).ClientMessage("Wallhack Enabled");
							else
								Pawn(Owner).ClientMessage("Wallhack Disabled");
						}
						else
							Pawn(Owner).ClientMessage("Wallhack is for Spectators only");
					break;

					case "say !speedmeter":
					case "say !speed":
						BTEC.SwitchBool("SpeedMeter");
						if(BTEC.SpeedMeter)
							Pawn(Owner).ClientMessage("Speed meter Enabled");
						else
							Pawn(Owner).ClientMessage("Speed meter Disabled");
					break;

					case "say !timer":
						BTEC.SwitchBool("CustomTimer");
						if(BTEC.CustomTimer)
							Pawn(Owner).ClientMessage("Custom timer Enabled");
						else
							Pawn(Owner).ClientMessage("Custom timer Disabled");
					break;

					default:
					if (ParseDelimited(cmdBuffer, " ", 2) ~= "!timerscale" || ParseDelimited(cmdBuffer, " ", 2) ~= "!tscale")
					{
						SS = ParseDelimited(cmdBuffer, " ", 3);
						BTEC.TimerSetting("Scale", float(SS));
						Pawn(Owner).ClientMessage("Timer scale set to " $ float(SS));
					}
					else if (ParseDelimited(cmdBuffer, " ", 2) ~= "!tred" || ParseDelimited(cmdBuffer, " ", 2) ~= "!tr")
					{
						SS = ParseDelimited(cmdBuffer, " ", 3);
						BTEC.TimerSetting("Red", byte(SS));
						Pawn(Owner).ClientMessage("Timer Red color set to " $ byte(SS));
					}
					else if (ParseDelimited(cmdBuffer, " ", 2) ~= "!tgreen" || ParseDelimited(cmdBuffer, " ", 2) ~= "!tg")
					{
						SS = ParseDelimited(cmdBuffer, " ", 3);
						BTEC.TimerSetting("Green", byte(SS));
						Pawn(Owner).ClientMessage("Timer Green color set to " $ byte(SS));
					}
					else if (ParseDelimited(cmdBuffer, " ", 2) ~= "!tblue" || ParseDelimited(cmdBuffer, " ", 2) ~= "!tb")
					{
						SS = ParseDelimited(cmdBuffer, " ", 3);
						BTEC.TimerSetting("Blue", byte(SS));
						Pawn(Owner).ClientMessage("Timer Blue color set to " $ byte(SS));
					}
					else if (cmdBuffer ~= "say !disable")
					{
						Pawn(Owner).ClientMessage("BT Enhancements Disabled - Reconnecting");
						BTEC.SwitchBool("Disable");
						ConsoleCommand("Reconnect");
					}
					else if (cmdBuffer ~= "say !help" || cmdBuffer ~= "say !BTE")
						HelpMsg();
				}
				cmdBuffer = "";
			}
		}

		if(BTEC.Enabled)
		{
			if(BTEC.TeamSkin || BTEC.Ghosts)
			{
				foreach AllActors(class'TournamentPlayer', TP)
				{
					if(BTEC.TeamSkin)
					{
						TStexP = Texture(DynamicLoadObject("BTEUser.TS_"$TP.PlayerReplicationInfo.Team, class'Texture'));
						if(TP.MultiSkins[0] != TStexP)
						{
							TP.bUnlit = true;
							TP.MultiSkins[0] = TStexP;
							TP.MultiSkins[1] = TStexP;
							TP.MultiSkins[2] = TStexP;
							TP.MultiSkins[3] = TStexP;
						}
						if(TP.Weapon != None)
						{
							TStexW = Texture(DynamicLoadObject("BTEUser.TS_"$TP.PlayerReplicationInfo.Team, class'Texture'));
							if(TP.Weapon.MultiSkins[0] != TStexW)
							{
								TP.Weapon.bUnlit = true;
								TP.Weapon.MultiSkins[0] = TStexW;
								TP.Weapon.MultiSkins[1] = TStexW;
								TP.Weapon.MultiSkins[2] = TStexW;
								TP.Weapon.MultiSkins[3] = TStexW;
							}
						}
					}
					if(BTEC.Ghosts)
					{
						if(TP.Style != STY_Translucent)
							TP.Style = STY_Translucent;
						if(TP.Weapon != None && TP.Weapon.Style != STY_Translucent)
							TP.Weapon.Style = STY_Translucent;
					}
				}
			}

			if(BTEC.ShowTrig)
			{
				foreach AllActors(class'Trigger', TRIG)
				{
					TRIG.bHidden = false;
					TRIG.DrawType = DT_Sprite;
				}
			}

			if(Pawn(Owner).PlayerReplicationInfo.bIsSpectator && !Pawn(Owner).PlayerReplicationInfo.bWaitingPlayer)
			{
				foreach AllActors(class'Pawn', PAWNS)
				{
					if( PAWNS.Health > 0 && PAWNS != PawnOwner || (PAWNS == PawnOwner && Pawn(Owner).bBehindView) )
					{
						if(BTEC.WallHack)
							Canvas.DrawActor(PAWNS, false, true);
						else
							Canvas.DrawActor(PAWNS, false, false);
					}
				}
			}
		}
	}
/*
==========================================================
*/
	Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
	OldOriginX = Canvas.OrgX;
	// Master message short queue control loop.
	Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
	Canvas.StrLen("TEST", XL, YL);
	Canvas.SetClip(768*Scale - 10, Canvas.ClipY);
	bDrawFaceArea = false;
	if ( !bHideFaces && !PlayerOwner.bShowScores && !bForceScores && !bHideHUD && !PawnOwner.PlayerReplicationInfo.bIsSpectator && (Scale >= 0.4) )
	{
		DrawSpeechArea(Canvas, XL, YL);
		bDrawFaceArea = (FaceTexture != None) && (FaceTime > Level.TimeSeconds);
		if (bDrawFaceArea)
		{
			if ( !bHideHUD && ((PawnOwner.PlayerReplicationInfo == None) || !PawnOwner.PlayerReplicationInfo.bIsSpectator) )
				Canvas.SetOrigin( FMax(YL*4 + 8, 70*Scale) + 7*Scale + 6 + FaceAreaOffset, Canvas.OrgY );
		}
	}

	for (i=0; i<4; i++)
	{
		if ( ShortMessageQueue[i].Message != None )
		{
			j++;

			if ( bResChanged || (ShortMessageQueue[i].XL == 0) )
			{
				if ( ShortMessageQueue[i].Message.Default.bComplexString )
				Canvas.StrLen(ShortMessageQueue[i].Message.Static.AssembleString(self,ShortMessageQueue[i].Switch,
					ShortMessageQueue[i].RelatedPRI,ShortMessageQueue[i].StringMessage),ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
				else
				Canvas.StrLen(ShortMessageQueue[i].StringMessage, ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
				Canvas.StrLen("TEST", XL, YL);
				ShortMessageQueue[i].numLines = 1;
				if ( ShortMessageQueue[i].YL > YL )
				{
					ShortMessageQueue[i].numLines++;
					for (k=2; k<4-i; k++)
					{
						if (ShortMessageQueue[i].YL > YL*k)
							ShortMessageQueue[i].numLines++;
					}
				}
			}

			// Keep track of the amount of lines a message overflows, to offset the next message with.
			Canvas.SetPos(6, 2 + YL * YPos);
			YPos += ShortMessageQueue[i].numLines;
			if ( YPos > 4 )
				break;

			if ( ShortMessageQueue[i].Message.Default.bComplexString )
			{
				// Use this for string messages with multiple colors.
				ShortMessageQueue[i].Message.Static.RenderComplexMessage(Canvas,ShortMessageQueue[i].XL,  YL,
				ShortMessageQueue[i].StringMessage,ShortMessageQueue[i].Switch,ShortMessageQueue[i].RelatedPRI,
				None,ShortMessageQueue[i].OptionalObject);
			}
			else
			{
				Canvas.DrawColor = ShortMessageQueue[i].Message.Default.DrawColor;
				Canvas.DrawText(ShortMessageQueue[i].StringMessage, False);
			}
		}
	}

	Canvas.DrawColor = WhiteColor;
	Canvas.SetClip(OldClipX, Canvas.ClipY);
	Canvas.SetOrigin(OldOriginX, Canvas.OrgY);

	if ( PlayerOwner.bShowScores || bForceScores )
	{
		if ( (PlayerOwner.Scoring == None) && (PlayerOwner.ScoringType != None) )
			PlayerOwner.Scoring = Spawn(PlayerOwner.ScoringType, PlayerOwner);
		if ( PlayerOwner.Scoring != None )
		{
			PlayerOwner.Scoring.OwnerHUD = self;
			PlayerOwner.Scoring.ShowScores(Canvas);
			if ( PlayerOwner.Player.Console.bTyping )
				DrawTypingPrompt(Canvas, PlayerOwner.Player.Console);
			return;
		}
	}

	YPos = FMax(YL*4 + 8, 70*Scale);
	if ( bDrawFaceArea )
		DrawTalkFace( Canvas,0, YPos );	// DrawTalkFace( Canvas, YPos ); WAS ERROR CODE?
		//DrawTalkFace( Canvas, YPos ); // DrawTalkFace( Canvas,0, YPos ); WAS ERROR CODE?
	if (j > 0)
	{
		bDrawMessageArea = True;
		MessageFadeCount = 2;
	}
	else
		bDrawMessageArea = False;

	if (!bHideCenterMessages)
	{
		// Master localized message control loop.
		for (i=0; i<10; i++)
		{
			if (LocalMessages[i].Message != None)
			{
				if (LocalMessages[i].Message.Default.bFadeMessage && Level.bHighDetailMode)
				{
					Canvas.Style = ERenderStyle.STY_Translucent;
					FadeValue = (LocalMessages[i].EndOfLife - Level.TimeSeconds);
					if (FadeValue > 0.0)
					{
						if ( bResChanged || (LocalMessages[i].XL == 0) )
						{
							if ( LocalMessages[i].Message.Static.GetFontSize(LocalMessages[i].Switch) == 1 )
								LocalMessages[i].StringFont = MyFonts.GetBigFont( Canvas.ClipX );
							else // ==2
								LocalMessages[i].StringFont = MyFonts.GetHugeFont( Canvas.ClipX );
							Canvas.Font = LocalMessages[i].StringFont;
							Canvas.StrLen(LocalMessages[i].StringMessage, LocalMessages[i].XL, LocalMessages[i].YL);
							LocalMessages[i].YPos = LocalMessages[i].Message.Static.GetOffset(LocalMessages[i].Switch, LocalMessages[i].YL, Canvas.ClipY);
						}
						Canvas.Font = LocalMessages[i].StringFont;
						Canvas.DrawColor = LocalMessages[i].DrawColor * (FadeValue/LocalMessages[i].LifeTime);
						Canvas.SetPos( 0.5 * (Canvas.ClipX - LocalMessages[i].XL), LocalMessages[i].YPos );
						Canvas.DrawText( LocalMessages[i].StringMessage, False );
					}
				}
				else
				{
					if ( bResChanged || (LocalMessages[i].XL == 0) )
					{
						if ( LocalMessages[i].Message.Static.GetFontSize(LocalMessages[i].Switch) == 1 )
							LocalMessages[i].StringFont = MyFonts.GetBigFont( Canvas.ClipX );
						else // == 2
							LocalMessages[i].StringFont = MyFonts.GetHugeFont( Canvas.ClipX );
						Canvas.Font = LocalMessages[i].StringFont;
						Canvas.StrLen(LocalMessages[i].StringMessage, LocalMessages[i].XL, LocalMessages[i].YL);
						LocalMessages[i].YPos = LocalMessages[i].Message.Static.GetOffset(LocalMessages[i].Switch, LocalMessages[i].YL, Canvas.ClipY);
					}
					Canvas.Font = LocalMessages[i].StringFont;
					Canvas.Style = ERenderStyle.STY_Normal;
					Canvas.DrawColor = LocalMessages[i].DrawColor;
					Canvas.SetPos( 0.5 * (Canvas.ClipX - LocalMessages[i].XL), LocalMessages[i].YPos );
					Canvas.DrawText( LocalMessages[i].StringMessage, False );
				}
			}
		}
	}
	Canvas.Style = ERenderStyle.STY_Normal;

	if ( !PlayerOwner.bBehindView && (PawnOwner.Weapon != None) && (Level.LevelAction == LEVACT_None) )
	{
		Canvas.DrawColor = WhiteColor;
		PawnOwner.Weapon.PostRender(Canvas);
		if ( !PawnOwner.Weapon.bOwnsCrossHair )
			DrawCrossHair(Canvas, 0,0 );
	}

	if(PawnOwner != None)
	{
		if(PawnOwner.bIsPlayer && !bHideHUD)
		{
			SetInfo(PawnOwner.PlayerReplicationInfo);
			//	DRAW NEW LIVE FEED
			if(PawnOwner != Owner)
			{
				Canvas.bCenter = true;
				Canvas.Style = ERenderStyle.STY_Normal;	
				Canvas.Font = MyFonts.GetHugeFont(Canvas.ClipX);
				Canvas.StrLen("test", XX, YY);
				Canvas.SetPos(0, Canvas.ClipY - YY * 0.666 - 0.0833 * Canvas.ClipY);

				Canvas.DrawColor = ChallengeTeamHUD(PlayerOwner.myHUD).TeamColor[PawnOwner.PlayerReplicationInfo.Team];
				DrawShadowText(Canvas, PawnOwner.PlayerReplicationInfo.PlayerName, True);

				//	RESET EVERYTHING
				Canvas.bCenter = false;
				Canvas.DrawColor = WhiteColor;
				Canvas.Style = Style;
				Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
			}
			//	DRAW INFO FOR PLAYERS
			if(!Pawn(Owner).PlayerReplicationInfo.bIsSpectator)
			{
				if(GRI != None)
				{
					if(GRI.bShowAntiBoostStatus)
						DrawAntiBoostStatus(Canvas);
					DrawCP_TimesStatus(Canvas, GRI.bShowAntiBoostStatus);
				}
			}
			//	DRAW SPEC TIMER
			if(RI != None && !PawnOwner.IsInState('GameEnded') && !PawnOwner.PlayerReplicationInfo.bWaitingPlayer && !PawnOwner.PlayerReplicationInfo.bIsSpectator)
			{
				//see if server sent a new runtime
				if(oldUpdate != RI.runTime)
				{
					oldUpdate = RI.runTime;
					cStamp = Level.TimeSeconds;
				}
				//update HUD-Timer if the Game is not ended and the player is on a run
				if(!PlayerOwner.IsInState('GameEnded') && !RI.bNeedsRespawn)
				{
					//round down
					//Time = RI.runTime/10;
					//this is about the current time: runs on until server saw a cap; this may cause the timer to jump back a bit
					Time = (oldUpdate + int((Level.TimeSeconds - cStamp) * 90.9090909))/10;//move on from last update until server sends a new one
					LastTime = Time;
					lastUpdate = False;
				}
				else
				{
					oldUpdate = 0;//either dead or game over -> reset
					if(!lastUpdate && !RI.bBoosted)//get the captime replicated, but only show deciseconds
					{
						Time = RI.LastCap / 10;
						LastTime = Time;
						lastUpdate = True;
					}
					Time = LastTime;
				}
				DrawHUDTimes(Canvas, Time/600, Time % 600);
			}
		}
	}

	if ( bStartUpMessage && (Level.TimeSeconds < 5) )
	{
		bStartUpMessage = false;
		PlayerOwner.SetProgressTime(7);
	}
	if ( (PlayerOwner.ProgressTimeOut > Level.TimeSeconds) && !bHideCenterMessages )
		DisplayProgressMessage(Canvas);

	// Display MOTD
	if (MOTDFadeOutTime > 0.0)
		DrawMOTD(Canvas);

	if(!bHideHUD)
	{
		if(!PawnOwner.PlayerReplicationInfo.bIsSpectator)
		{
			Canvas.Style = Style;

			// Draw Ammo
			if ( !bHideAmmo )
				DrawAmmo(Canvas);

			// Draw Health/Armor status + Boots
			if(EPRI != None)
				DrawStatuz(Canvas);	// NEW AND IMPROVED
			else
				DrawStatus(Canvas);	// IF EPRI ISNT WORKING

			if(BTEC != None && BTEC.Enabled && BTEC.SpeedMeter)
				DrawSpeed(Canvas, PawnOwner);

			// Display Weapons
			if ( !bHideAllWeapons )
				DrawWeapons(Canvas);
			else if ( Level.bHighDetailMode && (PawnOwner == PlayerOwner) && (PlayerOwner.Handedness == 2) )
			{
				// if weapon bar hidden and weapon hidden, draw weapon name when it changes
				if ( PawnOwner.PendingWeapon != None )
				{
					WeaponNameFade = 1.0;
					Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
					Canvas.DrawColor = PawnOwner.PendingWeapon.NameColor;
					Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
					Canvas.DrawText(PawnOwner.PendingWeapon.ItemName, False);
				}
				else if ( (Level.NetMode == NM_Client) && PawnOwner.IsA('TournamentPlayer') && (TournamentPlayer(PawnOwner).ClientPending != None) )
				{
					WeaponNameFade = 1.0;
					Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
					Canvas.DrawColor = TournamentPlayer(PawnOwner).ClientPending.NameColor;
					Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
					Canvas.DrawText(TournamentPlayer(PawnOwner).ClientPending.ItemName, False);
				}
				else if ( (WeaponNameFade > 0) && (PawnOwner.Weapon != None) )
				{
					Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
					Canvas.DrawColor = PawnOwner.Weapon.NameColor;
					if ( WeaponNameFade < 1 )
						Canvas.DrawColor = Canvas.DrawColor * WeaponNameFade;
					Canvas.SetPos(Canvas.ClipX - 360 * Scale, Canvas.ClipY - 64 * Scale);
					Canvas.DrawText(PawnOwner.Weapon.ItemName, False);
				}
			}
			// Display Frag count
			if ( !bAlwaysHideFrags && !bHideFrags )
				DrawFragCount(Canvas);
		}
		// Team Game Synopsis
		if ( !bHideTeamInfo )
			DrawGameSynopsis(Canvas);

		// Display Identification Info
		if ( PawnOwner == PlayerOwner )
			DrawIdentifyInfo(Canvas);

		if ( HUDMutator != None )
			HUDMutator.PostRender(Canvas);

		if ( (PlayerOwner.GameReplicationInfo != None) && (PlayerPawn(Owner).GameReplicationInfo.RemainingTime > 0) )
		{
			if ( TimeMessageClass == None )
				TimeMessageClass = class<CriticalEventPlus>(DynamicLoadObject("Botpack.TimeMessage", class'Class'));

			if ( (PlayerOwner.GameReplicationInfo.RemainingTime <= 300) && (PlayerOwner.GameReplicationInfo.RemainingTime != LastReportedTime) )
			{
				LastReportedTime = PlayerOwner.GameReplicationInfo.RemainingTime;
				if ( PlayerOwner.GameReplicationInfo.RemainingTime <= 30 )
				{
					bTimeValid = ( bTimeValid || (PlayerOwner.GameReplicationInfo.RemainingTime > 0) );
					if ( PlayerOwner.GameReplicationInfo.RemainingTime == 30 )
						TellTime(5);
					else if ( bTimeValid && PlayerOwner.GameReplicationInfo.RemainingTime <= 10 )
						TellTime(16 - PlayerOwner.GameReplicationInfo.RemainingTime);
				}
				else if ( PlayerOwner.GameReplicationInfo.RemainingTime % 60 == 0 )
				{
					M = PlayerOwner.GameReplicationInfo.RemainingTime/60;
					TellTime(5 - M);
				}
			}
		}
	}
	if ( PlayerOwner.Player.Console.bTyping )
		DrawTypingPrompt(Canvas, PlayerOwner.Player.Console);

	if ( PlayerOwner.bBadConnectionAlert && (PlayerOwner.Level.TimeSeconds > 5) )
	{
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawColor = WhiteColor;
		Canvas.SetPos(Canvas.ClipX - (64*Scale), Canvas.ClipY / 2);
		Canvas.DrawIcon(texture'DisconnectWarn', Scale);
	}

   	//Super.PostRender( Canvas );

	if ( (PlayerOwner == None) || (PawnOwner == None) || (PlayerOwner.GameReplicationInfo == None)
		|| (PawnOwner.PlayerReplicationInfo == None)
		|| ((PlayerOwner.bShowMenu || PlayerOwner.bShowScores) && (Canvas.ClipX < 640)) )
		return;

	//Canvas.Style = Style;
	if( !bHideHUD && !bHideTeamInfo )
	{
		X = Canvas.ClipX - 70 * Scale;
		Y = Canvas.ClipY - 350 * Scale;

		Canvas.SetPos(X, Y);
		Canvas.Style = ERenderStyle.STY_Translucent;
		Canvas.DrawColor = ChallengeTeamHUD(PlayerOwner.myHUD).TeamColor[0];
		Canvas.DrawIcon(texture'Bunny', Scale * 2);
		DrawBigNum(Canvas, int(TournamentGameReplicationInfo(PlayerOwner.GameReplicationInfo).Teams[0].Score), Canvas.ClipX - 144 * Scale, Canvas.ClipY - 336 * Scale - (150 * Scale * 0), 1);
		Canvas.SetPos(X, Y - 150 * Scale);
		Canvas.DrawColor = ChallengeTeamHUD(PlayerOwner.myHUD).TeamColor[1];
		Canvas.DrawIcon(texture'Bunny', Scale * 2);
		DrawBigNum(Canvas, int(TournamentGameReplicationInfo(PlayerOwner.GameReplicationInfo).Teams[1].Score), Canvas.ClipX - 144 * Scale, Canvas.ClipY - 336 * Scale - (150 * Scale * 1), 1);
		Canvas.Style = ERenderStyle.STY_Normal;
	}
}

simulated function DrawStatuz(Canvas Canvas)
{
	local float StatScale, H1, H2, X, Y, DamageTime;
	Local int i;
	local bool bHasDoll;
	local Bot BotOwner;
	local TournamentPlayer TPOwner;
	local texture Doll, DollBelt;

	if(!bHideStatus)
	{
		TPOwner = TournamentPlayer(PawnOwner);
		if (Canvas.ClipX < 400)
			bHasDoll = false;
		else if(TPOwner != None)
		{
			Doll = TPOwner.StatusDoll;
			DollBelt = TPOwner.StatusBelt;
			bHasDoll = true;
		}
		else
		{
			BotOwner = Bot(PawnOwner);
			if(BotOwner != None)
			{
				Doll = BotOwner.StatusDoll;
				DollBelt = BotOwner.StatusBelt;
				bHasDoll = true;
			}
		}
		if(bHasDoll)
		{
			Canvas.Style = ERenderStyle.STY_Translucent;
			StatScale = Scale * StatusScale;
			X = Canvas.ClipX - 128 * StatScale;
			Canvas.SetPos(X, 0);
			if(PawnOwner.DamageScaling > 2.0)
				Canvas.DrawColor = PurpleColor;
			else
				Canvas.DrawColor = HUDColor;
			Canvas.DrawTile(Doll, 128*StatScale, 256*StatScale, 0, 0, 128.0, 256.0);
			Canvas.DrawColor = HUDColor;
			if(EPRI.bShieldBelt)
			{
				Canvas.DrawColor = BaseColor;
				Canvas.DrawColor.B = 0;
				Canvas.SetPos(X, 0);
				Canvas.DrawIcon(DollBelt, StatScale);
			}
			if(EPRI.bChestArmor)
			{
				Canvas.DrawColor = HUDColor * FMin(0.01 * EPRI.ChestAmount, 1);
				Canvas.SetPos(X, 0);
				Canvas.DrawTile(Doll, 128 * StatScale, 64 * StatScale, 128, 0, 128, 64);
			}
			if(EPRI.bThighArmor)
			{
				Canvas.DrawColor = HUDColor * FMin(0.02 * EPRI.ThighAmount, 1);
				Canvas.SetPos(X, 64 * StatScale);
				Canvas.DrawTile(Doll, 128 * StatScale, 64 * StatScale, 128, 64, 128, 64);
			}
			if(EPRI.bJumpBoots)
			{
				Canvas.DrawColor = HUDColor;
				Canvas.SetPos(X, 128 * StatScale);
				Canvas.DrawTile(Doll, 128 * StatScale, 64 * StatScale, 128, 128, 128, 64);
			}
			Canvas.Style = Style;
			if( (PawnOwner == PlayerOwner) && Level.bHighDetailMode && !Level.bDropDetail )
			{
				for(i = 0; i < 4; i++)
				{
					DamageTime = Level.TimeSeconds - HitTime[i];
					if(DamageTime < 1)
					{
						Canvas.SetPos(X + HitPos[i].X * StatScale, HitPos[i].Y * StatScale);
						if(HUDColor.G > 100 || HUDColor.B > 100)
							Canvas.DrawColor = RedColor;
						else
							Canvas.DrawColor = (WhiteColor - HudColor) * FMin(1, 2 * DamageTime);
						Canvas.DrawColor.R = 255 * FMin(1, 2 * DamageTime);
						Canvas.DrawTile(Texture'BotPack.HudElements1', StatScale * HitDamage[i] * 25, StatScale * HitDamage[i] * 64, 0, 64, 25.0, 64.0);
					}
				}
			}
		}
	}
	Canvas.DrawColor = HUDColor;
	if(bHideStatus && bHideAllWeapons)
	{
		X = 0.5 * Canvas.ClipX;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 64 * Scale;
	}
	Canvas.SetPos(X,Y);
	if(PawnOwner.Health < 50)
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = WhiteColor * H2 + (HUDColor - WhiteColor) * H1;
	}
	else
		Canvas.DrawColor = HUDColor;
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 128, 128, 128.0, 64.0);

	if(PawnOwner.Health < 50)
	{
		H1 = 1.5 * TutIconBlink;
		H2 = 1 - H1;
		Canvas.DrawColor = Canvas.DrawColor * H2 + (WhiteColor - Canvas.DrawColor) * H1;
	}
	else
		Canvas.DrawColor = WhiteColor;
	DrawBigNum(Canvas, Max(0, PawnOwner.Health), X + 4 * Scale, Y + 16 * Scale, 1);

	Canvas.DrawColor = HUDColor;
	if(bHideStatus && bHideAllWeapons)
	{
		X = 0.5 * Canvas.ClipX - 128 * Scale;
		Y = Canvas.ClipY - 64 * Scale;
	}
	else
	{
		X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
		Y = 0;
	}
	Canvas.SetPos(X, Y);
	Canvas.DrawTile(Texture'BotPack.HudElements1', 128*Scale, 64*Scale, 0, 192, 128.0, 64.0);

	if(EPRI.bShieldBelt)
		Canvas.DrawColor = GoldColor;
	else
		Canvas.DrawColor = WhiteColor;
	DrawBigNum(Canvas, EPRI.ArmorAmount, X + 4 * Scale, Y + 16 * Scale, 1);

	if(EPRI.bJumpBoots)
	{
		Canvas.DrawColor = HUDColor;
		if(bHideStatus && bHideAllWeapons)
		{
			if(bHideAmmo)
			{
				X = 0.5 * Canvas.ClipX + 128 * Scale;
				Y = Canvas.ClipY - 64 * Scale;
			}
			else	// Draw after ammo.
			{
				X = 0.5 * Canvas.ClipX + 256 * Scale;
				Y = Canvas.ClipY - 64 * Scale;
			}
		}
		else
		{
			X = Canvas.ClipX - 128 * StatScale - 140 * Scale;
			Y = 128 * Scale;
		}
		Canvas.SetPos(X,Y);
		Canvas.DrawTile(Texture'Bootz', 128 * Scale, 64 * Scale, 0, 0, 128.0, 64.0);
		Canvas.DrawColor = WhiteColor;
		DrawBigNum(Canvas, EPRI.BootCharges, X + 4 * Scale, Y + 16 * Scale, 1);
	}
}

simulated function DrawTeam(Canvas Canvas, TeamInfo TI){}

function SetInfo(PlayerReplicationInfo PRI)
{
	local int i;
	local bool bInit, bFoundRI, bFoundEPRI;
	local ReplicationInfo Rinfo;

	// See if it's already initialized
	for(i = 0; i < Index; i++)
	{
		if(PI[i].PRI == PRI)
		{
			EPRI	= PI[i].EPRI;
			RI		= PI[i].RI;
			bInit = true;
			break;
		}
	}
	if(!bInit)	// Not initialized, find the RI + EPRI
	{
		foreach Level.AllActors(class'ReplicationInfo', Rinfo)
		{
			if( Rinfo.IsA('BTPPReplicationInfo') )
			{
				if(BTPPReplicationInfo(Rinfo).PlayerID == PRI.PlayerID)
				{
					RI = BTPPReplicationInfo(Rinfo);
					bFoundRI = true;
				}
			}
			else if( Rinfo.IsA('BTEPRI') )
			{
				if(BTEPRI(Rinfo).PlayerID == PRI.PlayerID)
				{
					EPRI = BTEPRI(Rinfo);
					bFoundEPRI = true;
				}
			}
		}

		if(bFoundRI && bFoundEPRI)	// Init the slot - on newly found EPRI-RI
		{
			if(Index < 32)	// use empty elements in array
			{
				PI[Index].PRI = PRI;
				PI[Index].RI = RI;
				PI[Index].EPRI = EPRI;
				Index++;
			}
			else	// not enough empty elements, use an old element
			{
				for(i = 0; i < 32; i++)
				{
					if (PI[i].EPRI == None)
						break;	// assign here
				}
				PI[i].PRI = PRI;
				PI[i].RI = RI;
				PI[i].EPRI = EPRI;
			}
		}
	}
}

/*##################################################################################################
##
## Draw Functions
##
##################################################################################################*/
simulated function DrawSpeed(Canvas Canvas, Pawn P)
{
	local Vector HorizontalVelocity;
	local int HoriSpeed;
	local int VertSpeed;
	local string TextH;
	local string TextV;
	local float YY, XX;

	HorizontalVelocity = P.Velocity;
	HorizontalVelocity.Z = 0;

	HoriSpeed = VSize(HorizontalVelocity);
	VertSpeed = Abs(P.Velocity.Z);

	TextH = string(HoriSpeed);
	TextV = string(VertSpeed);

	Canvas.bCenter = true;
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = OrangeColor;
	Canvas.Font = MyFonts.GetHugeFont(Canvas.ClipX);
	Canvas.StrLen("test", XX, YY);

	Canvas.SetPos(0, (Canvas.ClipY - YY * 0.666 - 0.0833 * Canvas.ClipY) - YY);
	DrawShadowText(Canvas, TextH);

	Canvas.SetPos(0, (Canvas.ClipY - YY * 0.666 - 0.0833 * Canvas.ClipY) - YY * 2);
	DrawShadowText(Canvas, TextV);

	Canvas.bCenter = false;
}

simulated function DrawHUDTimes(Canvas Canvas, int Minutes, int Seconds)
{
	local int d;
	local float TimerScale, W, H, SW;

	Canvas.CurY = 4;
	Canvas.Style = ERenderStyle.STY_Normal;

	if(BTEC != None && BTEC.CustomTimer)
		TimerScale = Scale * BTEC.TimerScale;
	else
		TimerScale = Scale;

	if(Minutes > 99)//too long run time: show -:-- in red
	{
		Canvas.DrawColor = RedColor;
		Canvas.CurX = Canvas.ClipX / 2 - 57 * TimerScale;

		//	-:
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*50, 35*TimerScale, 0, 64, 50.0, 35.0);
		Canvas.CurX += 7*TimerScale;

		//	-
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, 0, 64, 25.0, 35.0);
		Canvas.CurX += 7*TimerScale;

		//	-
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, 0, 64, 25.0, 35.0);
	}
	else //	show actual timer
	{
		//a bit to the left
		Canvas.CurX = Canvas.ClipX / 2 - 86 * TimerScale;

		if(RI != None && RI.bNeedsRespawn)	//Captime/reset on death in grey
			Canvas.DrawColor = GreyColor;
		else if(Minutes < 100)	//yellow for default timer
		{
			if(BTEC != None && BTEC.CustomTimer)
			{
				Canvas.DrawColor.R = BTEC.Red;
				Canvas.DrawColor.G = BTEC.Green;
				Canvas.DrawColor.B = BTEC.Blue;
			}
			else
				Canvas.DrawColor = YellowColor;
		}

		if ( Minutes >= 10 )
		{
			d = Minutes/10;
			DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, d*25, 0, 25.0, 35.0);
			Canvas.CurX += 7*TimerScale;
			Minutes= Minutes - 10 * d;
		}
		else
		{
			//leading 0
			DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, 0, 0, 25.0, 35.0);
			Canvas.CurX += 7*TimerScale;
		}

		//single digit minutes
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, Minutes*25, 0, 25.0, 35.0);
		Canvas.CurX += 3*TimerScale;

		// ":" 
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*12, 35*TimerScale, 30, 64, 12.0, 35.0);
		Canvas.CurX += 5 * TimerScale;

		//Seconds 1
		d = Seconds/100;
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, 25*d, 0, 25.0, 35.0);
		Canvas.CurX += 7*TimerScale;

		//Seconds 2
		Seconds -=  100*d;
		d = Seconds / 10;
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*25, 35*TimerScale, 25*d, 0, 25.0, 35.0);
		Canvas.CurX += 7*TimerScale;

		// "."
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*12, 32*TimerScale, 32, 46, 12.0, 32.0);
		Canvas.CurX += 3 * TimerScale;

		//Deciseconds
		Seconds -= 10*d;
		DrawShadowTile(Canvas, Texture'BTTimer', TimerScale*16, 42*TimerScale, 25*Seconds, 0, 25.0, 64.0);
	}
	Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GoldColor;
	Canvas.Style = ERenderStyle.STY_Normal;
//	Canvas.CurX += 7*TimerScale;
	Canvas.Font = Canvas.SmallFont;

	if(RI.bBoosted)
	{
		Canvas.TextSize("YOU WERE BOOSTED, RECORD WILL NOT COUNT", W, H);
		Canvas.SetPos(Canvas.ClipX/2 - W/2, 50*TimerScale+2);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).RedColor;
		DrawShadowText(Canvas, "YOU WERE BOOSTED, RECORD WILL NOT COUNT");
	}

	if(!Pawn(Owner).PlayerReplicationInfo.bIsSpectator)
	{
		Canvas.Reset();
		Canvas.SetPos(5, Canvas.ClipY/2);
		Canvas.Font = Canvas.SmallFont;
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).WhiteColor;
		DrawShadowText(Canvas, "SERVER RECORD:");
		Canvas.TextSize("SERVER RECORD:", W, H);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GoldColor;
		Canvas.SetPos(5, Canvas.ClipY/2 + H+1);
		DrawShadowText(Canvas, GRI.MapBestPlayer);
		Canvas.TextSize(GRI.MapBestPlayer, W, H);
		Canvas.SetPos(5+W, Canvas.ClipY/2 + H+1);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).WhiteColor;
		DrawShadowText(Canvas, " - ");
		Canvas.TextSize(" - ", SW, H);
		Canvas.SetPos(5+W+SW, Canvas.ClipY/2 + H+1);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GreenColor;
		DrawShadowText(Canvas, GRI.MapBestTime);
		Canvas.SetPos(5, Canvas.ClipY/2 + 2*H+2);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).WhiteColor;
		DrawShadowText(Canvas, "YOUR RECORD:");
		Canvas.SetPos(5, Canvas.ClipY/2 + 3*H+3);
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GreenColor;
		DrawShadowText(Canvas, Config.BestTimeStr);
	}
}

simulated function DrawAntiBoostStatus(Canvas Canvas)
{
	local float W, H;

	Canvas.Reset();
	Canvas.Font = Canvas.SmallFont;
	Canvas.TextSize("ANTIBOOST: ", W, H);
	Canvas.SetPos(5, Canvas.ClipY/2-1.5*H-1);
	Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).WhiteColor;
	DrawShadowText(Canvas, "ANTIBOOST: ");
	Canvas.SetPos(5+W, Canvas.ClipY/2-1.5*H-1);
	if(Config.bAntiBoost)
	{
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GreenColor;
		DrawShadowText(Canvas, "ON");
	}
	else
	{
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).RedColor;
		DrawShadowText(Canvas, "OFF");
	}
}

simulated function DrawCP_TimesStatus(Canvas Canvas, bool antiBoostThere)
{
	local float W, H;

	Canvas.Reset();
	Canvas.Font = Canvas.SmallFont;
	Canvas.TextSize("CP-TIMES: ", W, H);
	if(antiBoostThere)
		Canvas.SetPos(5, Canvas.ClipY/2-3.0*H-1);
	else
		Canvas.SetPos(5, Canvas.ClipY/2-1.5*H-1);
	Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).WhiteColor;
	DrawShadowText(Canvas, "CP-TIMES: ");
	if(antiBoostThere)
		Canvas.SetPos(5+W, Canvas.ClipY/2-3.0*H-1);
	else
		Canvas.SetPos(5+W, Canvas.ClipY/2-1.5*H-1);
	if(Config.bCheckpoints)
	{
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).GreenColor;
		DrawShadowText(Canvas, "ON");
	}
	else
	{
		Canvas.DrawColor = ChallengeHUD(PlayerOwner.myHUD).RedColor;
		DrawShadowText(Canvas, "OFF");
	}
}

function DrawShadowTile( Canvas Canvas, Texture Tex, float XL, float YL, float U, float V, float UL, float VL)
{
	local float X, Y;
	local color OldColor;

	X = Canvas.CurX;
	Y = Canvas.CurY;
	Canvas.CurX += 1;
	Canvas.CurY += 1;
	OldColor = Canvas.DrawColor;
	Canvas.DrawColor = BlackColor;
	Canvas.DrawTile(Tex, XL, YL, U, V, UL, VL);
	Canvas.SetPos(X, Y);
	Canvas.DrawColor = OldColor;
	Canvas.DrawTile(Tex, XL, YL, U, V, UL, VL);
}

function DrawShadowText (Canvas Canvas, coerce string Text, optional bool Param)
{
    local Color OldColor;
    local int XL,YL;
    local float X, Y;

	if(Text == "")
		Text = " ";

    OldColor = Canvas.DrawColor;

    Canvas.DrawColor = BlackColor;
    XL = 1;
	YL = 1;
	X = Canvas.CurX;
	Y = Canvas.CurY;
	Canvas.SetPos(X+XL,Y+YL);
	Canvas.DrawText(Text, Param);
	Canvas.DrawColor = OldColor;
	Canvas.SetPos(X,Y);
	Canvas.DrawText(Text, Param);
}

function string ParseDelimited(string Text, string Delimiter, int Count, optional bool bToEndOfLine)
{
	local string Result, S;
	local int Found, i;

	Result = "";
	Found = 1;

	for(i = 0; i < Len(Text); i++)
	{
		S = Mid(Text, i, 1);
		if(InStr(Delimiter, S) != -1)
		{
			if(Found == Count)
			{
				if(bToEndOfLine)
					return Result$Mid(Text, i);
				else
					return Result;
			}
			Found++;
		}
		else
		{
			if(Found >= Count)
				Result = Result $ S;
		}
	}
	return Result;
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	IdentifyName=""
	IdentifyHealth=""
	GreyColor=(R=170,G=170,B=170)
	YellowColor=(R=127,G=127,B=0)
	OrangeColor=(R=255,G=88)
}