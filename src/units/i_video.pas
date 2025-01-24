Unit i_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype
  , m_fixed
  ;

Const
  ORIGWIDTH = 320;
  ORIGHEIGHT = 200;

  MAXWIDTH = (ORIGWIDTH Shl 2); // für Crispy.hires 0..2
  MAXHEIGHT = (ORIGHEIGHT Shl 2); // für Crispy.hires 0..2

Var
  (*
   * Wird in I_GetScreenDimensions initialisiert und ist die mittels crispy.Hires scallierte "Fenstergröße"
   *)
  SCREENWIDTH: int = ORIGWIDTH;
  SCREENHEIGHT: int = ORIGHEIGHT;
  ScaleOffX, ScaleOffY: Integer;

Procedure I_RegisterWindowIcon(Const icon: P_unsigned_int; width, height: int);
Procedure I_SetWindowTitle(Const title: String);

Procedure I_InitGraphics();
Procedure I_StartTic();

Procedure I_DisplayFPSDots(dots_on: boolean);
Procedure I_StartFrame();

Procedure I_FinishUpdate();

Procedure I_ReadScreen(Var scr: pixel_tArray);
Procedure I_GetScreenDimensions();

Procedure I_UpdateNoBlit();

Procedure I_StartDisplay(); // [crispy]

Var
  // Flag indicating whether the screen is currently visible:
  // when the screen isnt visible, don't render the screen
  screenvisible: boolean = true;

  OpenGLTexture: Integer = 0;
  OpenGLControlWidth: Integer = 0;
  OpenGLControlHeight: Integer = 0;
  NONWIDEWIDTH: int; // [crispy] non-widescreen SCREENWIDTH --> TODO: Remove ?

  // [AM] Fractional part of the current tic, in the half-open
  //      range of [0.0, 1.0).  Used for interpolation.
  fractionaltic: fixed_t;

  // Joystick/gamepad hysteresis
  joywait: unsigned_int = 0;

Procedure DumpScreenToFile(Const source: pixel_tArray); // Debug, dumbs the given Screen to a file (with I_VideoBuffer as param this is more or less a screenshot ;) )

Implementation

Uses Graphics, config, dglOpenGL
  , usdl_wrapper
  , i_timer
  , v_video, v_diskicon
  ;

Var
  window_title: String = '';

  // If true, we display dots at the bottom of the screen to
  // indicate FPS.

  display_fps_dots: boolean;

  // Icon RGB data and dimensions
  icon_data: P_unsigned_int = Nil;
  icon_w: int = 0;
  icon_h: int = 0;
  initialized: Boolean = false;
Var
  OpenGLData: Array Of uint32; // Only 24-Bit needed, but OpenGL is faster in processing 32-Bit numbers.

Procedure I_InitWindowTitle();
Begin
  SDL_SetWindowTitle(Nil, window_title + ' - ' + PACKAGE_STRING)
End;

Procedure I_InitWindowIcon;
Var
  surface: SDL_Surface;
Begin
  surface := SDL_CreateRGBSurfaceFrom(icon_data, icon_w, icon_h,
    32, icon_w * 4,
    $FF Shl 24, $FF Shl 16,
    $FF Shl 8, $FF Shl 0);

  SDL_SetWindowIcon(Nil, surface);
  SDL_FreeSurface(surface);
End;

Procedure I_GetScreenDimensions();
Begin
  //  SDL_DisplayMode mode;
  //	int w = 16, h = 10;
  //	int ah;
  //
  SCREENWIDTH := ORIGWIDTH Shl crispy.hires;
  SCREENHEIGHT := ORIGHEIGHT Shl crispy.hires;

  ScaleOffX := (SCREENWIDTH - ORIGWIDTH) Div 2;
  ScaleOffY := (SCREENHEIGHT - ORIGHEIGHT) Div 2;

  NONWIDEWIDTH := SCREENWIDTH;

  //	ah = (aspect_ratio_correct == 1) ? (6 * SCREENHEIGHT / 5) : SCREENHEIGHT;
  //
  //	if (SDL_GetCurrentDisplayMode(video_display, &mode) == 0)
  //	{
  //		// [crispy] sanity check: really widescreen display?
  //		if (mode.w * ah >= mode.h * SCREENWIDTH)
  //		{
  //			w = mode.w;
  //			h = mode.h;
  //		}
  //	}
  //
  //	// [crispy] widescreen rendering makes no sense without aspect ratio correction
  //	if (crispy->widescreen && aspect_ratio_correct == 1)
  //	{
  //		switch(crispy->widescreen)
  //		{
  //			case RATIO_16_10:
  //				w = 16;
  //				h = 10;
  //				break;
  //			case RATIO_16_9:
  //				w = 16;
  //				h = 9;
  //				break;
  //			case RATIO_21_9:
  //				w = 21;
  //				h = 9;
  //				break;
  //			default:
  //				break;
  //		}
  //
  //		SCREENWIDTH = w * ah / h;
  //		// [crispy] make sure SCREENWIDTH is an integer multiple of 4 ...
  //		SCREENWIDTH = (SCREENWIDTH + (crispy->hires ? 0 : 3)) & (int)~3;
  //		// [crispy] ... but never exceeds MAXWIDTH (array size!)
  //		SCREENWIDTH = MIN(SCREENWIDTH, MAXWIDTH);
  //	}
  //
  //	WIDESCREENDELTA = ((SCREENWIDTH - NONWIDEWIDTH) >> crispy->hires) / 2;
End;

Procedure I_UpdateNoBlit();
Begin
  // what is this?
End;

Procedure I_StartDisplay();
Begin
  // [AM] Figure out how far into the current tic we're in as a fixed_t.
  fractionaltic := I_GetFracRealTime();

  //    SDL_PumpEvents();

  //    if (usemouse && !nomouse && window_focused)
  //    {
  //        I_ReadMouseUncapped();
  //    }
End;

Var
  dumpIndex: integer = 0;

Procedure DumpScreenToFile(Const source: pixel_tArray);
Var
  i, j: Integer;
  b: Tbitmap;
Begin
  b := TBitmap.Create;
  b.Width := SCREENWIDTH;
  b.Height := SCREENHEIGHT;
  For i := 0 To SCREENWIDTH - 1 Do Begin
    For j := 0 To SCREENHEIGHT - 1 Do Begin
      b.canvas.pixels[i, j] := Doom8BitTo24RGBBit[source[j * SCREENWIDTH + i]];
    End;
  End;
  b.SaveToFile(format('DumpScreen%0.3d.bmp', [dumpIndex]));
  inc(dumpIndex);
  b.free;
End;

Procedure SetVideoMode();
Begin
  //   int w, h;
  //    int x, y;
  //    int window_flags = 0, renderer_flags = 0;
  //    SDL_DisplayMode mode;
  //
  //    w = window_width;
  //    h = window_height;
  //
  //    // In windowed mode, the window can be resized while the game is
  //    // running.
  //    window_flags = SDL_WINDOW_RESIZABLE;
  //
  //    // Set the highdpi flag - this makes a big difference on Macs with
  //    // retina displays, especially when using small window sizes.
  //    window_flags |= SDL_WINDOW_ALLOW_HIGHDPI;
  //
  //    if (fullscreen)
  //    {
  //        if (fullscreen_width == 0 && fullscreen_height == 0)
  //        {
  //            // This window_flags means "Never change the screen resolution!
  //            // Instead, draw to the entire screen by scaling the texture
  //            // appropriately".
  //            window_flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
  //        }
  //        else
  //        {
  //            w = fullscreen_width;
  //            h = fullscreen_height;
  //            window_flags |= SDL_WINDOW_FULLSCREEN;
  //        }
  //    }
  //
  //    // Running without window decorations is potentially useful if you're
  //    // playing in three window mode and want to line up three game windows
  //    // next to each other on a single desktop.
  //    // Deliberately not documented because I'm not sure how useful this is yet.
  //    if (M_ParmExists("-borderless"))
  //    {
  //        window_flags |= SDL_WINDOW_BORDERLESS;
  //    }
  //
  //    I_GetWindowPosition(&x, &y, w, h);
  //
  //    // Create window and renderer contexts. We set the window title
  //    // later anyway and leave the window position "undefined". If
  //    // "window_flags" contains the fullscreen flag (see above), then
  //    // w and h are ignored.

  //    if (screen == NULL)
  //    {
  //        screen = SDL_CreateWindow(NULL, x, y, w, h, window_flags);
  //
  //        if (screen == NULL)
  //        {
  //            I_Error("Error creating window for video startup: %s",
  //            SDL_GetError());
  //        }
  //
  //        SDL_SetWindowMinimumSize(screen, SCREENWIDTH, actualheight);

  I_InitWindowTitle();
  I_InitWindowIcon();
  //    }

  //    // The SDL_RENDERER_TARGETTEXTURE flag is required to render the
  //    // intermediate texture into the upscaled texture.
  //    renderer_flags = SDL_RENDERER_TARGETTEXTURE;
  //
  //    if (SDL_GetCurrentDisplayMode(video_display, &mode) != 0)
  //    {
  //        I_Error("Could not get display mode for video display #%d: %s",
  //        video_display, SDL_GetError());
  //    }
  //
  //    // Turn on vsync if we aren't in a -timedemo
  //    if ((!singletics && mode.refresh_rate > 0) || crispy->demowarp)
  //    {
  //        if (crispy->vsync) // [crispy] uncapped vsync
  //        {
  //            renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
  //        }
  //    }
  //
  //    if (force_software_renderer)
  //    {
  //        renderer_flags |= SDL_RENDERER_SOFTWARE;
  //        renderer_flags &= ~SDL_RENDERER_PRESENTVSYNC;
  //        crispy->vsync = false;
  //    }
  //
  //    if (renderer != NULL)
  //    {
  //        SDL_DestroyRenderer(renderer);
  //        // all associated textures get destroyed
  //        texture = NULL;
  //        texture_upscaled = NULL;
  //    }
  //
  //    renderer = SDL_CreateRenderer(screen, -1, renderer_flags);
  //
  //    // If we could not find a matching render driver,
  //    // try again without hardware acceleration.
  //
  //    if (renderer == NULL && !force_software_renderer)
  //    {
  //        renderer_flags |= SDL_RENDERER_SOFTWARE;
  //        renderer_flags &= ~SDL_RENDERER_PRESENTVSYNC;
  //
  //        renderer = SDL_CreateRenderer(screen, -1, renderer_flags);
  //
  //        // If this helped, save the setting for later.
  //        if (renderer != NULL)
  //        {
  //            force_software_renderer = 1;
  //        }
  //    }
  //
  //    if (renderer == NULL)
  //    {
  //        I_Error("Error creating renderer for screen window: %s",
  //                SDL_GetError());
  //    }
  //
  //    // Important: Set the "logical size" of the rendering context. At the same
  //    // time this also defines the aspect ratio that is preserved while scaling
  //    // and stretching the texture into the window.
  //
  //    if (aspect_ratio_correct || integer_scaling)
  //    {
  //        SDL_RenderSetLogicalSize(renderer,
  //                                 SCREENWIDTH,
  //                                 actualheight);
  //    }
  //
  //    // Force integer scales for resolution-independent rendering.
  //
  //    SDL_RenderSetIntegerScale(renderer, integer_scaling);
  //
  //    // Blank out the full screen area in case there is any junk in
  //    // the borders that won't otherwise be overwritten.
  //
  //    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
  //    SDL_RenderClear(renderer);
  //    SDL_RenderPresent(renderer);
  //
  //#ifndef CRISPY_TRUECOLOR
  //    // Create the 8-bit paletted and the 32-bit RGBA screenbuffer surfaces.
  //
  //    if (screenbuffer != NULL)
  //    {
  //        SDL_FreeSurface(screenbuffer);
  //        screenbuffer = NULL;
  //    }
  //
  //    if (screenbuffer == NULL)
  //    {
  //        screenbuffer = SDL_CreateRGBSurface(0,
  //                                            SCREENWIDTH, SCREENHEIGHT, 8,
  //                                            0, 0, 0, 0);
  //        SDL_FillRect(screenbuffer, NULL, 0);
  //    }
  //#endif
  //
  //    // Format of argbbuffer must match the screen pixel format because we
  //    // import the surface data into the texture.
  //
  //    if (argbbuffer != NULL)
  //    {
  //        SDL_FreeSurface(argbbuffer);
  //        argbbuffer = NULL;
  //    }
  //
  //    if (argbbuffer == NULL)
  //    {
  //#ifdef CRISPY_TRUECOLOR
  //        argbbuffer = SDL_CreateRGBSurfaceWithFormat(
  //                     0, SCREENWIDTH, SCREENHEIGHT, 32, SDL_PIXELFORMAT_ARGB8888);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0xff, 0x0, 0x0));
  //        redpane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(redpane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0xd7, 0xba, 0x45));
  //        yelpane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(yelpane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0x0, 0xff, 0x0));
  //        grnpane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(grnpane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0x2c, 0x5c, 0x24)); // 44, 92, 36
  //        grnspane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(grnspane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0x0, 0x0, 0xe0)); // 0, 0, 224
  //        bluepane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(bluepane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0x82, 0x82, 0x82)); // 130, 130, 130
  //        graypane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(graypane, SDL_BLENDMODE_BLEND);
  //
  //        SDL_FillRect(argbbuffer, NULL, I_MapRGB(0x96, 0x6e, 0x0)); // 150, 110, 0
  //        orngpane = SDL_CreateTextureFromSurface(renderer, argbbuffer);
  //        SDL_SetTextureBlendMode(orngpane, SDL_BLENDMODE_BLEND);
  //#else
  //	    // pixels and pitch will be filled with the texture's values
  //	    // in I_FinishUpdate()
  //	    argbbuffer = SDL_CreateRGBSurfaceWithFormatFrom(
  //                     NULL, w, h, 0, 0, SDL_PIXELFORMAT_ARGB8888);
  //#endif
  //    }
  //
  //    if (texture != NULL)
  //    {
  //        SDL_DestroyTexture(texture);
  //    }
  //
  //    // Set the scaling quality for rendering the intermediate texture into
  //    // the upscaled texture to "nearest", which is gritty and pixelated and
  //    // resembles software scaling pretty well.
  //
  //    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest");
  //
  //    // Create the intermediate texture that the RGBA surface gets loaded into.
  //    // The SDL_TEXTUREACCESS_STREAMING flag means that this texture's content
  //    // is going to change frequently.
  //
  //    texture = SDL_CreateTexture(renderer,
  //                                SDL_PIXELFORMAT_ARGB8888,
  //                                SDL_TEXTUREACCESS_STREAMING,
  //                                SCREENWIDTH, SCREENHEIGHT);
  //
  //    // Workaround for SDL 2.0.14+ alt-tab bug (taken from Doom Retro via Prboom-plus and Woof)
  //#if defined(_WIN32)
  //    {
  //        SDL_version ver;
  //        SDL_GetVersion(&ver);
  //        if (ver.major == 2 && ver.minor == 0 && (ver.patch == 14 || ver.patch == 16))
  //        {
  //           SDL_SetHintWithPriority(SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS, "1", SDL_HINT_OVERRIDE);
  //        }
  //    }
  //#endif
  //
  //    // Initially create the upscaled texture for rendering to screen
  //
  //    CreateUpscaledTexture(true);
End;

Procedure I_RegisterWindowIcon(Const icon: P_unsigned_int; width, height: int);
Begin
  icon_data := icon;
  icon_w := width;
  icon_h := height;
End;

Procedure I_SetWindowTitle(Const title: String);
Begin
  window_title := title;
End;

Procedure I_InitGraphics;
Begin
  //   SDL_Event dummy;
  //#ifndef CRISPY_TRUECOLOR
  //    byte *doompal;
  //#endif
  //    char *env;
  //
  //    // Pass through the XSCREENSAVER_WINDOW environment variable to
  //    // SDL_WINDOWID, to embed the SDL window into the Xscreensaver
  //    // window.
  //
  //    env = getenv("XSCREENSAVER_WINDOW");
  //
  //    if (env != NULL)
  //    {
  //        char winenv[30];
  //        unsigned int winid;
  //
  //        sscanf(env, "0x%x", &winid);
  //        M_snprintf(winenv, sizeof(winenv), "SDL_WINDOWID=%u", winid);
  //
  //        putenv(winenv);
  //    }
  //
  //    SetSDLVideoDriver();
  //
  //    if (SDL_Init(SDL_INIT_VIDEO) < 0)
  //    {
  //        I_Error("Failed to initialize video: %s", SDL_GetError());
  //    }
  //
  //    // When in screensaver mode, run full screen and auto detect
  //    // screen dimensions (don't change video mode)
  //    if (screensaver_mode)
  //    {
  //        fullscreen = true;
  //    }

  // [crispy] run-time variable high-resolution rendering
  I_GetScreenDimensions();

  setlength(OpenGLData, SCREENWIDTH * SCREENHEIGHT);
  // Create the Texture where we can render to ;)
  glGenTextures(1, @OpenGLTexture);
  glBindTexture(GL_TEXTURE_2D, OpenGLTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage2D(GL_TEXTURE_2D, 0, gl_RGB, SCREENWIDTH, SCREENHEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, @OpenGLData[0]);

  //#ifndef CRISPY_TRUECOLOR
  //    blit_rect.w = SCREENWIDTH;
  //    blit_rect.h = SCREENHEIGHT;
  //#endif
  //
  //    // [crispy] (re-)initialize resolution-agnostic patch drawing
  //    V_Init();
  //
  //    if (aspect_ratio_correct == 1)
  //    {
  //        actualheight = 6 * SCREENHEIGHT / 5;
  //    }
  //    else
  //    {
  //        actualheight = SCREENHEIGHT;
  //    }
  //
  //    // Create the game window; this may switch graphic modes depending
  //    // on configuration.
  //    AdjustWindowSize();
  SetVideoMode();

  //#ifndef CRISPY_TRUECOLOR
  //    // Start with a clear black screen
  //    // (screen will be flipped after we set the palette)
  //
  //    SDL_FillRect(screenbuffer, NULL, 0);
  //
  //    // Set the palette
  //
  //    doompal = W_CacheLumpName(DEH_String("PLAYPAL"), PU_CACHE);
  //    I_SetPalette(doompal);
  //    SDL_SetPaletteColors(screenbuffer->format->palette, palette, 0, 256);
  //#endif
  //
  //    // SDL2-TODO UpdateFocus();
  //    UpdateGrab();
  //
  //    // On some systems, it takes a second or so for the screen to settle
  //    // after changing modes.  We include the option to add a delay when
  //    // setting the screen mode, so that the game doesn't start immediately
  //    // with the player unable to see anything.
  //
  //    if (fullscreen && !screensaver_mode)
  //    {
  //        SDL_Delay(startup_delay);
  //    }

  // The actual 320x200 canvas that we draw to. This is the pixel buffer of
  // the 8-bit paletted screen buffer that gets blit on an intermediate
  // 32-bit RGBA screen buffer that gets loaded into a texture that gets
  // finally rendered into our window or full screen in I_FinishUpdate().

  setlength(I_VideoBuffer, SCREENWIDTH * SCREENHEIGHT);
  V_RestoreBuffer();

  //    // Clear the screen to black.
  //
  //    memset(I_VideoBuffer, 0, SCREENWIDTH * SCREENHEIGHT * sizeof(*I_VideoBuffer));
  //
  //    // clear out any events waiting at the start and center the mouse
  //
  //    while (SDL_PollEvent(&dummy))
  //        ;
  //
  initialized := true;
  //
  //    // Call I_ShutdownGraphics on quit
  //
  //    I_AtExit(I_ShutdownGraphics, true);
End;

Procedure I_StartTic();
Begin
  If (Not initialized) Then exit;

  //  I_GetEvent(); --> Das ruft die SDL Eventloop auf, wir machen das hier aber via LCL also brauchen wir nichts zu machen ;)

  //  If (usemouse) And (Not nomouse) And (window_focused) Then Begin
  //    I_ReadMouse();
  //  End;

  //  If (joywait < I_GetTime()) Then Begin
  //    I_UpdateJoystick();
  //  End;
End;

// Set the variable controlling FPS dots.

Procedure I_DisplayFPSDots(dots_on: boolean);
Begin
  display_fps_dots := dots_on;
End;

Procedure I_StartFrame();
Begin
  // TODO: Dieser Code kann sicher wieder Raus, wenn mal alles funktioniert
  //       Aktuell sorgt er aber dafür, dass bei jedem Frame alles wieder gelöscht ist ;)
  //  FillChar(I_VideoBuffer[0], length(I_VideoBuffer), 0);
End;

Procedure I_FinishUpdate();
Var
  i: Integer;
  DestPtr: PUInt32;
Begin
  //   static int lasttic;
  //    int tics;
  //    int i;
  //
  //    if (!initialized)
  //        return;
  //
  //    if (noblit)
  //        return;
  //
  //    if (need_resize)
  //    {
  //        if (SDL_GetTicks() > last_resize_time + RESIZE_DELAY)
  //        {
  //            int flags;
  //            // When the window is resized (we're not in fullscreen mode),
  //            // save the new window size.
  //            flags = SDL_GetWindowFlags(screen);
  //            if ((flags & SDL_WINDOW_FULLSCREEN_DESKTOP) == 0)
  //            {
  //                SDL_GetWindowSize(screen, &window_width, &window_height);
  //
  //                // Adjust the window by resizing again so that the window
  //                // is the right aspect ratio.
  //                AdjustWindowSize();
  //                SDL_SetWindowSize(screen, window_width, window_height);
  //            }
  //            CreateUpscaledTexture(false);
  //            need_resize = false;
  //            palette_to_set = true;
  //        }
  //        else
  //        {
  //            return;
  //        }
  //    }
  //
  //    UpdateGrab();
  //
  //#if 0 // SDL2-TODO
  //    // Don't update the screen if the window isn't visible.
  //    // Not doing this breaks under Windows when we alt-tab away
  //    // while fullscreen.
  //
  //    if (!(SDL_GetAppState() & SDL_APPACTIVE))
  //        return;
  //#endif
  //
  //    // draws little dots on the bottom of the screen
  //
  If (display_fps_dots) Then Begin
    //	i = I_GetTime();
    //	tics = i - lasttic;
    //	lasttic = i;
    //	if (tics > 20) tics = 20;
    //
    //	for (i=0 ; i<tics*4 ; i+=4)
    //#ifndef CRISPY_TRUECOLOR
    //	    I_VideoBuffer[ (SCREENHEIGHT-1)*SCREENWIDTH + i] = 0xff;
    //#else
    //	    I_VideoBuffer[ (SCREENHEIGHT-1)*SCREENWIDTH + i] = pal_color[0xff];
    //#endif
    //	for ( ; i<20*4 ; i+=4)
    //#ifndef CRISPY_TRUECOLOR
    //	    I_VideoBuffer[ (SCREENHEIGHT-1)*SCREENWIDTH + i] = 0x0;
    //#else
    //	    I_VideoBuffer[ (SCREENHEIGHT-1)*SCREENWIDTH + i] = pal_color[0x0];
    //#endif
  End;

  //	// [crispy] [AM] Real FPS counter
  //	{
  //		static int lastmili;
  //		static int fpscount;
  //		int mili;
  //
  //		fpscount++;
  //
  //		i = SDL_GetTicks();
  //		mili = i - lastmili;
  //
  //		// Update FPS counter every second
  //		if (mili >= 1000)
  //		{
  //			crispy->fps = (fpscount * 1000) / mili;
  //			fpscount = 0;
  //			lastmili = i;
  //		}
  //	}

  // Draw disk icon before blit, if necessary.
  // V_DrawDiskIcon();

  //#ifndef CRISPY_TRUECOLOR
  //    if (palette_to_set)
  //    {
  //        SDL_SetPaletteColors(screenbuffer->format->palette, palette, 0, 256);
  //        palette_to_set = false;
  //
  //        if (vga_porch_flash)
  //        {
  //            // "flash" the pillars/letterboxes with palette changes, emulating
  //            // VGA "porch" behaviour (GitHub issue #832)
  //            SDL_SetRenderDrawColor(renderer, palette[0].r, palette[0].g,
  //                palette[0].b, SDL_ALPHA_OPAQUE);
  //        }
  //    }
  //
  //    // Blit from the paletted 8-bit screen buffer to the intermediate
  //    // 32-bit RGBA buffer and update the intermediate texture with the
  //    // contents of the RGBA buffer.
  //
  //    SDL_LockTexture(texture, &blit_rect, &argbbuffer->pixels,
  //                    &argbbuffer->pitch);
  //    SDL_LowerBlit(screenbuffer, &blit_rect, argbbuffer, &blit_rect);
  //    SDL_UnlockTexture(texture);
  //#else
  //    SDL_UpdateTexture(texture, NULL, argbbuffer->pixels, argbbuffer->pitch);
  //#endif

  // Make sure the pillarboxes are kept clear each frame.

  //    SDL_RenderClear(renderer);
  //
  //    if (crispy->smoothscaling && !force_software_renderer)
  //    {
  //    // Render this intermediate texture into the upscaled texture
  //    // using "nearest" integer scaling.
  //
  //    SDL_SetRenderTarget(renderer, texture_upscaled);
  //    SDL_RenderCopy(renderer, texture, NULL, NULL);
  //
  //    // Finally, render this upscaled texture to screen using linear scaling.
  //
  //    SDL_SetRenderTarget(renderer, NULL);
  //    SDL_RenderCopy(renderer, texture_upscaled, NULL, NULL);
  //    }
  //    else
  //    {
  //	SDL_SetRenderTarget(renderer, NULL);
  //	SDL_RenderCopy(renderer, texture, NULL, NULL);
  //    }
  //
  //#ifdef CRISPY_TRUECOLOR
  //    if (curpane)
  //    {
  //	SDL_SetTextureAlphaMod(curpane, pane_alpha);
  //	SDL_RenderCopy(renderer, curpane, NULL, NULL);
  //    }
  //#endif

  // Draw!
  glPushMatrix;
  // 1. Umkopieren der DOOM Puffer nach OpenGL
  glBindTexture(GL_TEXTURE_2D, OpenGLTexture);
  DestPtr := @OpenGLData[0];
  For i := 0 To high(I_VideoBuffer) Do Begin
    DestPtr^ := Doom8BitTo24RGBBit[I_VideoBuffer[i]];
    inc(DestPtr);
  End;

  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, SCREENWIDTH, SCREENHEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, @OpenGLData[0]);

  // 2. Anpassen des Screens
  // TODO: Da kann man später das Aspectratio zeug mit einbaun ...
  glScalef(OpenGLControlWidth / ORIGWIDTH, OpenGLControlHeight / ORIGHEIGHT, 1); // TODO: das könnte man Theoretisch aus aus OpenGL auslesen ..

  // 3. Rendern
  // Render the texture to the OpenGL Buffer
  // TODO: Das könnte man auch mit einer OpenGL-Liste machen, dann wirds schneller ;)
  glbegin(gl_quads);
  glTexCoord2f(0, 0);
  glvertex3f(0, 0, 0);
  glTexCoord2f(1, 0);
  glvertex3f(SCREENWIDTH / (1 Shl Crispy.hires), 0, 0);
  glTexCoord2f(1, 1);
  glvertex3f(SCREENWIDTH / (1 Shl Crispy.hires), SCREENHEIGHT / (1 Shl Crispy.hires), 0);
  glTexCoord2f(0, 1);
  glvertex3f(0, SCREENHEIGHT / (1 Shl Crispy.hires), 0);
  glend;
  glPopMatrix;

  //    if (crispy->uncapped && !singletics)
  //    {
  //        // Limit framerate
  //        if (crispy->fpslimit >= TICRATE)
  //        {
  //            uint64_t target_time = 1000000ull / crispy->fpslimit;
  //            static uint64_t start_time;
  //
  //            while (1)
  //            {
  //                uint64_t current_time = I_GetTimeUS();
  //                uint64_t elapsed_time = current_time - start_time;
  //                uint64_t remaining_time = 0;
  //
  //                if (elapsed_time >= target_time)
  //                {
  //                    start_time = current_time;
  //                    break;
  //                }
  //
  //                remaining_time = target_time - elapsed_time;
  //
  //                if (remaining_time > 1000)
  //                {
  //                    I_Sleep((remaining_time - 1000) / 1000);
  //                }
  //            }
  //        }
  //    }

  // Restore background and undo the disk indicator, if it was drawn.
  V_RestoreDiskBackground();
End;

Procedure I_ReadScreen(Var scr: pixel_tArray);
Begin
  move(I_VideoBuffer[0], scr[0], length(I_VideoBuffer) * sizeof(pixel_t));
End;

//Finalization
//  If assigned(iconBitmap) Then Begin
//    iconBitmap.free;
//    iconBitmap := Nil;
//  End;

End.

