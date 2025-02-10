# DOOM vs LCL (Lazarus Component Library)
In this section i want to handle all topics which are not directly C / C++ dependant, but more architectural.

## Polling vs. event based programming

Orig DOOM was written for DOS, in DOS the application more or less "owns" the machine when running. This means that the application need to implement a while loop which polls all the "devices" and then decides which code to be executed. 

The corresponding C code for DOOM is located in d_main.c and i_main.c. Below is the simplified version of how this is done in DOOM.

### i_main.c :
```C++ 
int main(int argc, char **argv)
{
  // init SDL 
  ..
  // start DOOM
  D_DoomMain();  // never returns
}
```

### d_main.c :
```C++
//
// D_DoomMain
//
void D_DoomMain (void)
{
  // Read in most of the console params
  ..
  // Run the main loop, there are multiple "entrances" to D_DoomLoop depending 
  // on the game mode. But at the end it does not matter which mode, all end up 
  // calling D_DoomLoop.
  D_DoomLoop();  // never returns
}

//
//  D_DoomLoop
//
void D_DoomLoop (void)
{
  // Init more stuff relevant for drawing a window
  .. 
  // Reset the game internal time measuring system
  // This is important when playing replay's as DOOM is "deterministic" 
  // when simulating.
  D_StartGameLoop();
  
  // Polling forever
  while (1)
  {
    D_RunFrame();
  }
}

//
//  D_RunFrame
//
void D_RunFrame()
{
  static boolean wipe = false; // Controlls the wipe function
  if (wipe)
  {
    // Draw the wipe animation, by complete blocking everything!
    // The wipe function starts with the last rendered framebufer and 
    // wipes this into the wipe endscreen buffer. When finished, the 
    // wipe variable is set to 0 and application execution continues like 
    // nothing has happened.
    wipe = !wipe_ScreenWipe(..);
    M_Drawer(); // menu is drawn even on top of wipes
    I_FinishUpdate(); // copy framebuffer to screen
    return;
  }

  // Start rendering a new frame, aktually the function call does nothing
  // as the framebuffer is completly writen by D_Display function.
  I_StartFrame ();
  
  // Simulate at least 1 tic (= 35ms)
  // Here the complete "Game logic" is executed and handled (but not rendered).
  TryRunTics (); 

  // Renders everything to the framebuffer and decides if a wipe animation needs
  // to be started.
  wipe = D_Display();
  if (wipe)
  {
    // init the wipe endscreen by reading the framebuffer. 
    // Store the actual gametic, so that wipe can be calculated correct.
    // ! Attention !
    // there is no rendering to the screen, so the application is still "showing" the last
    // framebuffer before wipe starts.
  } else {
    I_FinishUpdate (); // copy framebuffer to screen
  }
}
```
On modern frameworks (like used by LCL) this while loop is hidden deep inside the framework. Writing a while loop that runs forever is not allowed in this situation and can cause strange and unwanted behavior. The function calls shown above had to be converted for this reason into the schema shown below.
```pascal

Procedure TForm1.OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
Begin
  // init OpenGL
  ..
  // start DOOM
  D_DoomMain();
End;

//
// D_DoomMain
//
Procedure D_DoomMain(); 
Begin
  // Read in most of the console params
  ..
  // Run the main loop, there are multiple "entrances" to D_DoomLoop depending 
  // on the game mode. But at the end it does not matter which mode, all end up 
  // calling D_DoomLoop.
  // D_DoomLoop();
(* -- This is the part from D_DoomLoop without the while(1) *)
  // Init more stuff relevant for drawing a window
  .. 
  // Reset the game internal time measuring system
  // This is important when playing replay's as DOOM is "deterministic" 
  // when simulating.
  D_StartGameLoop();  
End;

//
// Render Event generating Timer (each 17ms)
//
Procedure TForm1.Timer1Timer(Sender: TObject);
Begin
  If Initialized Then Begin
    OpenGLControl1.Invalidate; // -> This triggers the OpenGLControl1Paint method
  End;
End;  

Procedure TForm1.OpenGLControl1Paint(Sender: TObject);
Begin
  If Not Initialized Then Exit;
  // Render Szene
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  go2d;
  (*
   * D_DoomLoop now tells whether the buffers are valid to swap (normal)
   * or in case of starting a wipe (or if is called to frequently) nothing should happen
   *)
  SkipSwapBuffers := D_DoomLoop();
  exit2d;
  If Not SkipSwapBuffers Then Begin
    OpenGLControl1.SwapBuffers;
  End;
End;

Function D_DoomLoop(): Boolean;
Begin
  result := D_RunFrame();
End; 

//
//  D_RunFrame
//

Function D_RunFrame(): Boolean;
Const
  wipe: boolean = false;
  oldgametic: int = 0;
Var
  nowtime: int;
  tics: int;
Begin
  result := false;
  tics := I_GetTime();
  // Logic that detects, that no game tic passed since last call -> return doing nothing
  If tics = oldgametic Then Begin
    result := true;
    exit;
  End;
  oldgametic := tics;
  If (wipe) Then Begin
    // Draw the wipe animation, by complete blocking everything!
    // The wipe function starts with the last rendered framebufer and 
    // wipes this into the wipe endscreen buffer. When finished, the 
    // wipe variable is set to 0 and application execution continues like 
    // nothing has happened.
    wipe := not wipe_ScreenWipe(..);
    M_Drawer(); // menu is drawn even on top of wipes
    I_FinishUpdate(); // copy framebuffer to screen
    Exit;
  End;

  // Start rendering a new frame, aktually the function call does nothing
  // as the framebuffer is completly writen by D_Display function.
  I_StartFrame ();
  
  // Simulate at least 1 tic (= 35ms)
  // Here the complete "Game logic" is executed and handled (but not rendered).
  TryRunTics (); 

  // Renders everything to the framebuffer and decides if a wipe animation needs
  // to be started.
  wipe := D_Display();
  If (wipe) Then Begin
    // init the wipe endscreen by reading the framebuffer. 
    // Store the actual gametic, so that wipe can be calculated correct.
    // ! Attention !
    // there is no rendering to the screen, so the application is still "showing" the last
    // framebuffer before wipe starts.
  End Else Begin
    I_FinishUpdate (); // copy framebuffer to screen
  End;
End;   

```

## The keyboard driver

Orig DOOM uses scancodes directly from the keyboard and converts them into "local" keys (e.g. "z" and "y" are swapped on german and english keyboards). When controlling game mechanics like "zoom in" the orig scancodes are used. When entering e.g. texts for chats or savegame names, the translated version is used.

FPC_DOOM uses the LCL keys, atm there is no localisation implemented.