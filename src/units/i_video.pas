Unit i_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  ORIGWIDTH = 320;
  ORIGHEIGHT = 200;

Procedure I_RegisterWindowIcon(Const icon: P_unsigned_int; width, height: int);
Procedure I_SetWindowTitle(Const title: String);

Procedure I_InitGraphics();

Procedure I_DisplayFPSDots(dots_on: boolean);

Var
  SCREENWIDTH: int; // Eigentlich unnötig Redundant
  SCREENHEIGHT: int; // Eigentlich unnötig Redundant

Implementation

Uses Graphics, config
  , v_video
  , usdl_wrapper
  , doomtype
  ;

Var
  screen: SDL_Window = Nil;
  window_title: String = '';

  //  argbbuffer: Array[0..ORIGWIDTH - 1, 0..ORIGHEIGHT - 1] Of pixel_t; --> Brauchen wir nicht wir schreiben direkt in I_VideoBuffer da OpenGL das alles für uns Scalliert ;)

  // If true, we display dots at the bottom of the screen to
  // indicate FPS.

  display_fps_dots: boolean;

  // Icon RGB data and dimensions
  icon_data: P_unsigned_int = Nil;
  icon_w: int = 0;
  icon_h: int = 0;

Procedure I_InitWindowTitle();
Begin
  SDL_SetWindowTitle(screen, window_title + ' - ' + PACKAGE_STRING)
End;

Procedure I_InitWindowIcon;
Var
  surface: SDL_Surface;
Begin
  surface := SDL_CreateRGBSurfaceFrom(icon_data, icon_w, icon_h,
    32, icon_w * 4,
    $FF Shl 24, $FF Shl 16,
    $FF Shl 8, $FF Shl 0);

  SDL_SetWindowIcon(screen, surface);
  SDL_FreeSurface(surface);
End;

Procedure I_GetScreenDimensions();
Begin
  //  SDL_DisplayMode mode;
  //	int w = 16, h = 10;
  //	int ah;
  //
  SCREENWIDTH := ORIGWIDTH Shl 0; // crispy->hires; ist eigentlich 1 -> Brauchen wir aber nicht, da das OpenGL macht ;)
  SCREENHEIGHT := ORIGHEIGHT Shl 0; // crispy->hires; ist eigentlich 1 -> Brauchen wir aber nicht, da das OpenGL macht ;)
  //
  //	NONWIDEWIDTH = SCREENWIDTH;
  //
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

  setlength(I_VideoBuffer, ORIGWIDTH * ORIGHEIGHT);
  //    V_RestoreBuffer();
  //
  //    // Clear the screen to black.
  //
  //    memset(I_VideoBuffer, 0, SCREENWIDTH * SCREENHEIGHT * sizeof(*I_VideoBuffer));
  //
  //    // clear out any events waiting at the start and center the mouse
  //
  //    while (SDL_PollEvent(&dummy))
  //        ;
  //
  //    initialized = true;
  //
  //    // Call I_ShutdownGraphics on quit
  //
  //    I_AtExit(I_ShutdownGraphics, true);
End;

// Set the variable controlling FPS dots.

Procedure I_DisplayFPSDots(dots_on: boolean);
Begin
  display_fps_dots := dots_on;
End;

//Finalization
//  If assigned(iconBitmap) Then Begin
//    iconBitmap.free;
//    iconBitmap := Nil;
//  End;

End.

