Unit ufpc_doom_types;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  INT_MIN = -2147483648; // = low(int); ?
  INT_MAX = 2147483647; // = high(int); ?

  BRIGHTMAPS_OFF = 0;
  BRIGHTMAPS_TEXTURES = 1;
  BRIGHTMAPS_SPRITES = 2;
  BRIGHTMAPS_BOTH = 3;
  NUM_BRIGHTMAPS = 4;

  TRANSLUCENCY_OFF = 0;
  TRANSLUCENCY_MISSILE = 1;
  TRANSLUCENCY_ITEM = 2;
  TRANSLUCENCY_BOTH = 3;
  NUM_TRANSLUCENCY = 4;

  CROSSHAIR_OFF = 0;
  CROSSHAIR_STATIC = 1;
  CROSSHAIR_PROJECTED = 2;
  NUM_CROSSHAIRS = 3;
  CROSSHAIR_INTERCEPT = $10;

  NUM_CROSSHAIRTYPES = 3;

  FREEAIM_AUTO = 0;
  FREEAIM_DIRECT = 1;
  FREEAIM_BOTH = 2;
  NUM_FREEAIMS = 3;

Type
  TProcedure = Procedure();

  signed_char = Int8;

  uint8_t = UInt8;
  uint16_t = UInt16;
  uint64_t = UInt64;
  size_t = UInt64;
  short = Int16;
  unsigned_short = uInt16;

  int = int32;
  int32_t = Int32;
  uint32_t = UInt32;
  unsigned = UInt32; // Geraten, den dass steht nirgends, könnte auch PTR_int sein ??
  P_int = ^int;
  unsigned_int = uint32;
  P_unsigned_int = ^unsigned_int;
  int64_t = Int64;
  float = single;

  fixed_t = int;
  Pfixed_t = ^fixed_t;

  TCrispy = Record
    // [crispy] "crispness" config variables
    automapoverlay: int; // 0, ?
    //    	int automaprotate;
    //    	int automapstats;
    bobfactor: int; // 0,1,2
    brightmaps: int;
    //    	int btusetimer;
    centerweapon: int;
    coloredblood: int;
    //    	int coloredhud;
    crosshair: int;
    crosshairhealth: int;
    crosshairtarget: int;
    crosshairtype: int;
    //    	int defaultskill;
    //    	int demotimer;
    //    	int demotimerdir;
    //    	int demobar;
    //    	int extautomap;
    flipcorpses: int;
    //    	int fpslimit;
    freeaim: int;
    freelook: int; // 0,1 ?
    //    	int freelook_hh;
    //    	int gamma;
    hires: Int; // 0, 1, 2 Alles über 2 macht eigentlich keinen Sinn mehr, Bei werten > 2 muss MAXWIDTH und MAXHEIGHT aus i_video.pas angepasst werden, sonst knallts beim start !
    //    	int jump;
    //    	int leveltime;
    mouselook: int; // ?
    //    	int neghealth;
    //    	int overunder;
    pitch: int; // ?
    //    	int playercoords;
    //    	int secretmessage;
    //    	int smoothlight;
    //    	int smoothmap;
    //    	int smoothscaling;
    //    	int soundfix;
    //    	int soundfull;
    //    	int soundmono;
    //    	int statsformat;
    translucency: int;
    //    #ifdef CRISPY_TRUECOLOR
    //    	int truecolor;
    //    #endif
    uncapped: int; // 0, ?
    //    	int vsync;
    //    	int widescreen;

    //    	// [crispy] in-game switches and variables
    //    	int screenshotmsg;
    //    	int snowflakes;
    cleanscreenshot: int;
    //    	int demowarp;
    //    	int fps;

    flashinghom: Boolean;
    //    	boolean fliplevels;
    flipweapons: Boolean;
    //    	boolean haved1e5;
    //    	boolean haved1e6;
    //    	boolean havee1m10;
    //    	boolean havemap33;
    //    	boolean havessg;
    singleplayer: boolean;
    stretchsky: Boolean; // wird in R_InitSkyMap initialisiert

    //    	// [crispy] custom difficulty parameters
    //    	boolean autohealth;
    //    	boolean fast;
    //    	boolean keysloc;
    //    	boolean moreammo;
    //    	boolean pistolstart;

    //    	char *havenerve;
    //    	char *havemaster;
    //    	char *havesigil;
    //    	char *havesigil2;

    //    	const char *sdlversion;
    //    	const char *platform;

    //    	void (*post_rendering_hook) (void);
  End;

Var
  Crispy: TCrispy;
  Critical: ^TCrispy;

Procedure Nop(); // Just for debugging to have a breakpoint position ;)

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String): String;
Procedure CheckCrispySingleplayer(singleplayer: Boolean);

Function Clamp(Value, Lower, Upper: fixed_t): fixed_t; // overload;

Implementation

Var
  critical_s: TCrispy; // wird im Initialization gesetzt

Function Clamp(Value, Lower, Upper: fixed_t): fixed_t; // overload;
Begin
  If value < lower Then Begin
    result := lower;
  End
  Else Begin
    If Value > Upper Then Begin
      result := upper;
    End
    Else Begin
      result := value;
    End;
  End;
End;

Procedure Nop();
Begin

End;

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String
  ): String;
Begin
  If aValue Then Begin
    result := aTrueString;
  End
  Else Begin
    Result := aFalseString;
  End;
End;

Procedure CheckCrispySingleplayer(singleplayer: Boolean);
Begin
  crispy.singleplayer := singleplayer;
  If (crispy.singleplayer) Then Begin
    critical := @Crispy;
  End
  Else Begin
    critical := @critical_s;
  End;
End;

Initialization

  Crispy.automapoverlay := 0;
  Crispy.bobfactor := 0;
  Crispy.brightmaps := 0;
  Crispy.centerweapon := 0;
  Crispy.coloredblood := 0;
  Crispy.crosshair := CROSSHAIR_OFF; // TODO: der CROSSHAIR_PROJECTED erzeugt noch an ettlichen stellen einen Bug, obwohl er eigentlich gehen sollte :/
  Crispy.crosshairhealth := 0;
  Crispy.crosshairtarget := 0;
  Crispy.crosshairtype := 0;
  Crispy.flipcorpses := 0;
  Crispy.freeaim := 0;
  Crispy.freelook := 0;

  Crispy.hires := 1;
  //  Crispy.extautomap := 1;
  //  Crispy.gamma := 9; // default level is "OFF" for intermediate gamma levels
  Crispy.mouselook := 0;
  Crispy.pitch := 0;
  Crispy.translucency := 0;
  Crispy.uncapped := 0;
  Crispy.cleanscreenshot := 0;
  Crispy.flashinghom := false;
  Crispy.flipweapons := false;
  Crispy.singleplayer := false;
  Crispy.stretchsky := false;

  //  Crispy.smoothscaling := 1;
  //  Crispy.soundfix := 1;
    //    #ifdef CRISPY_TRUECOLOR
    //    Crispy.smoothlight := 1;
    //    Crispy.truecolor := 1;
    //    #Endif
  //  Crispy.vsync := 1;
  //  Crispy.widescreen := 1; // match screen by default

  FillChar(critical_s, sizeof(critical_s), 0);

End.

