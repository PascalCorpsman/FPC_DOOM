(******************************************************************************)
(* FPC_Doom                                                        02.01.2025 *)
(*                                                                            *)
(* Version     : see config.pas                                               *)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* Support     : www.Corpsman.de                                              *)
(*                                                                            *)
(* Description : FPC-Port of Crispy DOOM                                      *)
(*                                                                            *)
(* License     : See the file license.md, located under:                      *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(* Warranty    : There is no warranty, neither in correctness of the          *)
(*               implementation, nor anything other that could happen         *)
(*               or go wrong, use at your own risk.                           *)
(*                                                                            *)
(* Known Issues: none                                                         *)
(*                                                                            *)
(* History     : 0.01 - Initial version                                       *)
(*                                                                            *)
(******************************************************************************)
Unit Unit1;

{$MODE objfpc}{$H+}
{$DEFINE DebuggMode}

(*
 * Enable to see how much time is actually taken to "render" a frame
 *)
{.$DEFINE SHOW_RENDERTIME_IN_MS}

(*
 * Enable to see how many ticks per Second are calculated (should be 35)
 * -> Result will be shown in Form caption
 *)
{.$DEFINE CALC_TICKS_PER_SECOND}

Interface

Uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls,
  OpenGlcontext,
  (*
   * Kommt ein Linkerfehler wegen OpenGL dann: sudo apt-get install freeglut3-dev
   *)
  dglOpenGL // http://wiki.delphigl.com/index.php/dglOpenGL.pas
  , config // Wird eigentlich nicht benötigt, ist nur dazu da um schnell an die Deklaration der Version zu springen
  ;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    OpenGLControl1: TOpenGLControl;
    Timer1: TTimer;
    Procedure FormCreate(Sender: TObject);
    Procedure OpenGLControl1KeyDown(Sender: TObject; Var Key: Word;
      Shift: TShiftState);
    Procedure OpenGLControl1KeyUp(Sender: TObject; Var Key: Word;
      Shift: TShiftState);
    Procedure OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
    Procedure OpenGLControl1Paint(Sender: TObject);
    Procedure OpenGLControl1Resize(Sender: TObject);
    Procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Procedure Go2d();
    Procedure Exit2d();
  End;

Var
  Form1: TForm1;
  Initialized: Boolean = false; // Wenn True dann ist OpenGL initialisiert

Implementation

{$R *.lfm}

Uses
  m_argv
  , d_main, d_event
  , i_video
  , v_video
{$IFDEF CALC_TICKS_PER_SECOND}
  , d_loop
{$ENDIF}
{$IFDEF SHOW_RENDERTIME_IN_MS}
  // If you get a Error that the following unit is not found, please disable the define !
  , uOpenGL_ASCII_Font
{$ENDIF}
  ;

{ TForm1 }

Procedure Tform1.Go2d();
Begin
  glMatrixMode(GL_PROJECTION);
  glPushMatrix(); // Store The Projection Matrix
  glLoadIdentity(); // Reset The Projection Matrix
  //  glOrtho(0, 640, 0, 480, -1, 1); // Set Up An Ortho Screen
  glOrtho(0, OpenGLControl1.Width, OpenGLControl1.height, 0, -1, 1); // Set Up An Ortho Screen
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix(); // Store old Modelview Matrix
  glLoadIdentity(); // Reset The Modelview Matrix
  OpenGLControlWidth := OpenGLControl1.Width;
  OpenGLControlHeight := OpenGLControl1.Height;
End;

Procedure Tform1.Exit2d();
Begin
  glMatrixMode(GL_PROJECTION);
  glPopMatrix(); // Restore old Projection Matrix
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix(); // Restore old Projection Matrix
End;

Var
  allowcnt: Integer = 0;

Procedure TForm1.OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
Begin
  If allowcnt > 2 Then Begin
    exit;
  End;
  inc(allowcnt);
  // Sollen Dialoge beim Starten ausgeführt werden ist hier der Richtige Zeitpunkt
  If allowcnt = 1 Then Begin
    // Init dglOpenGL.pas , Teil 2
    ReadExtensions; // Anstatt der Extentions kann auch nur der Core geladen werden. ReadOpenGLCore;
    ReadImplementationProperties;
  End;
  If allowcnt = 2 Then Begin // Dieses If Sorgt mit dem obigen dafür, dass der Code nur 1 mal ausgeführt wird.
    (*
    Man bedenke, jedesmal wenn der Renderingcontext neu erstellt wird, müssen sämtliche Graphiken neu Geladen werden.
    Bei Nutzung der TOpenGLGraphikengine, bedeutet dies, das hier ein clear durchgeführt werden mus !!
    *)
    glenable(GL_TEXTURE_2D); // Texturen
    // Der Anwendung erlauben zu Rendern.
    Initialized := True;
    OpenGLControl1Resize(Nil);
    D_DoomMain(); // Initialisiert die Gesamte Spiel Engine
{$IFDEF SHOW_RENDERTIME_IN_MS}
    Create_ASCII_Font();
{$ENDIF}
  End;
  Form1.Invalidate;
End;

Procedure TForm1.OpenGLControl1Paint(Sender: TObject);
{$IFDEF CALC_TICKS_PER_SECOND}
Const
  Counter1s: QWord = 0;
Var
  aTime: QWord;
{$ENDIF}
{$IFDEF SHOW_RENDERTIME_IN_MS}
Const
  MaxRenderTime: integer = 0;
  Counter10s: QWord = 0;
Var
  TimePerFrame: QWord;
{$ENDIF}
Var
  SkipSwapBuffers: Boolean;
Begin
  If Not Initialized Then Exit;
  // Render Szene
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  go2d;
{$IFDEF SHOW_RENDERTIME_IN_MS}
  TimePerFrame := GetTickCount64;
  // Reset Max RenderTime Value every 10s
  If Counter10s = 0 Then Counter10s := TimePerFrame;
  If TimePerFrame - Counter10s > 10000 Then Begin
    Counter10s := TimePerFrame;
    MaxRenderTime := 0;
  End;
{$ENDIF}
  (*
   * Das Spiel läuft auf 35 Ticks pro Sekunde Normiert
   * -> Also Rendert es nicht immer, wenn es nicht rendert darf der
   *    Buffer nicht geswapped werden, sonst flackert alles, weil er oben schon
   *    gelöscht wurde..
   *)
  SkipSwapBuffers := D_DoomLoop();
{$IFDEF SHOW_RENDERTIME_IN_MS}
  TimePerFrame := GetTickCount64 - TimePerFrame;
  If TimePerFrame > MaxRenderTime Then MaxRenderTime := TimePerFrame;
  glBindTexture(GL_TEXTURE_2D, 0);
  (*
   * Das Spiel erwartet alle 35 ms gerendert zu werden
   * Der Aktuelle Rendertimer steht auf 17ms -> Also alles gut
   * Interessant wird es wenn MaxRenderTime > 35ms / 17ms wird !
   *)
  OpenGL_ASCII_Font.Textout(1, 1, format('%d' + LineEnding + '%d', [TimePerFrame, MaxRenderTime]));
{$ENDIF}
  exit2d;
  If Not SkipSwapBuffers Then Begin
    OpenGLControl1.SwapBuffers;
  End;
{$IFDEF CALC_TICKS_PER_SECOND}
  aTime := GetTickCount64;
  If Counter1s = 0 Then Counter1s := aTime;
  If aTime - Counter1s >= 1000 Then Begin
    caption := Format('%0.1f', [TicksPerSecond * 1000 / (aTime - Counter1s)]);
    TicksPerSecond := 0;
    Counter1s := aTime;
  End;
{$ENDIF}
End;

Procedure TForm1.OpenGLControl1Resize(Sender: TObject);
Begin
  If Initialized Then Begin
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glViewport(0, 0, OpenGLControl1.Width, OpenGLControl1.Height);
    gluPerspective(45.0, OpenGLControl1.Width / OpenGLControl1.Height, 0.1, 100.0);
    glMatrixMode(GL_MODELVIEW);
  End;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Var
  i: Integer;
Begin
  Constraints.MinWidth := ORIGWIDTH;
  Constraints.MinHeight := ORIGHEIGHT;
  //  width := 852; // TODO: Debug to be removed
  //  height := ;

    // Init dglOpenGL.pas , Teil 1
  If Not InitOpenGl Then Begin
    showmessage('Error, could not init dglOpenGL.pas');
    Halt;
  End;
  (*
  60 - FPS entsprechen
  0.01666666 ms
  Ist Interval auf 16 hängt das gesamte system, bei 17 nicht.
  Generell sollte die Interval Zahl also dynamisch zum Rechenaufwand, mindestens aber immer 17 sein.
  *)
  Timer1.Interval := 17;
  OpenGLControl1.Align := alClient;

  // -----  i_main.c
  myargc := ParamCount;
  setlength(myargv, myargc);
  For i := 0 To myargc - 1 Do Begin
    myargv[i] := ParamStr(i);
  End;

  // [crispy] Print date and time in the Load/Save Game menus in the current locale
  // setlocale(LC_TIME, "");

    //!
    // Print the program version and exit.
    //
//    if (M_ParmExists("-version") || M_ParmExists("--version")) {
//        puts(PACKAGE_STRING);
//        exit(0);
//    }


//        char buf[16];
//        SDL_version version;
//        SDL_GetVersion(&version);
//        M_snprintf(buf, sizeof(buf), "%d.%d.%d", version.major, version.minor, version.patch);
//        crispy->sdlversion = M_StringDuplicate(buf);
//        crispy->platform = SDL_GetPlatform();

{$IFDEF Windows}
  // compose a proper command line from loose file paths passed as arguments
  // to allow for loading WADs and DEHACKED patches by drag-and-drop
  M_AddLooseFiles();
{$ENDIF}

  M_FindResponseFile();
  M_SetExeDir();

  //  #ifdef SDL_HINT_NO_SIGNAL_HANDLERS
  //  SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
  //  #endif

  // start doom

  //  D_DoomMain (); --> Wird in MakeCurrent gemacht.
End;

Procedure TForm1.OpenGLControl1KeyDown(Sender: TObject; Var Key: Word;
  Shift: TShiftState);
Var
  ev: event_t;
Begin
  // See d_event.pas for descriptions
  ev := GetTypedEmptyEvent(ev_keydown);
  // Siehe i_input.c I_HandleKeyboardEvent
  ev.data1 := Key; // doomkeys.h is made to be equal to lcl
  ev.data2 := Key; // TODO: muss noch richtig gemacht werden ?
  ev.data3 := Key; // TODO: muss noch richtig gemacht werden ?
  D_PostEvent(ev);
End;

Procedure TForm1.OpenGLControl1KeyUp(Sender: TObject; Var Key: Word;
  Shift: TShiftState);
Var
  ev: event_t;
Begin
  // See d_event.pas for descriptions
  ev := GetTypedEmptyEvent(ev_keyup);
  // Siehe i_input.c I_HandleKeyboardEvent
  ev.data1 := Key; // doomkeys.h is made to be equal to lcl
  D_PostEvent(ev);
End;

Procedure TForm1.Timer1Timer(Sender: TObject);
{$IFDEF DebuggMode}
Var
  i: Cardinal;
  p: Pchar;
{$ENDIF}
Begin
  If Initialized Then Begin
    OpenGLControl1.Invalidate;
{$IFDEF DebuggMode}
    i := glGetError();
    If i <> 0 Then Begin
      Timer1.Enabled := false;
      p := gluErrorString(i);
      showmessage('OpenGL Error (' + inttostr(i) + ') occured.' + LineEnding + LineEnding +
        'OpenGL Message : "' + p + '"' + LineEnding + LineEnding +
        'Applikation will be terminated.');
      close;
    End;
{$ENDIF}
  End;
End;

End.

