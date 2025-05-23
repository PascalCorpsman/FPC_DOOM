# FPC DOOM

In this repository i try to port DOOM to Free-Pascal using OpenGL and therefore beeing platform indipendant.

> !! Attention !!
> 
> This is a work in progress, the game is already playable, but not everything is ported.
> Its highly recommended to play with debugger and Lazarus-IDE. 
> If you get a "Port me." exception, you reached the end of the actual porting progress.

The original code was released by [id-Software](https://github.com/id-Software/DOOM) unfortunatunelly 
i was not able to get the code compiled, so i decided to use the 
[crispy-doom](https://github.com/fabiangreffrath/crispy-doom) version as base (as this one directly compiled 
and was able to start and play the .wad files i have had laying around).

Also i found some usefull documentations that try to explain the code:
- https://fabiensanglard.net/doomIphone/doomClassicRenderer.php
- https://doomwiki.org/wiki/Doom_source_code
- https://doom.fandom.com/wiki/Doom_source_code
- https://doom.fandom.com/wiki/Doom_source_code_files
- https://www.youtube.com/watch?v=cqL3jvlU61c&themeRefresh=1
  
There is already a [FPC Doom](https://github.com/jval1972/FPCDoom) on the [List](https://doomwiki.org/wiki/Source_port) of 
ports, but that version only supports DirectX and therefore only supports Windows platform.

## What needs to be done to compile the code

- install [Lazarus-IDE](https://www.lazarus-ide.org/)
- install package LazOpenGLContext (is shipped with lazarus)
- download [dglOpenGL.pas](https://github.com/saschawillems/dglopengl) and store it in the units folder
- download [bass](https://www.un4seen.com) and store bass.pas in the units folder

  o Windows users:
    - copy bass.dll into root folder  
  
  o Linux users:
    - copy libbass.so to /usr/lib 
    - chmod o+r it 
  
## What needs to be done to play the game

- get a valid .wad file and copy it where the binary is beeing created (or use this [shareware](https://www.doomworld.com/3ddownloads/ports/shareware_doom_iwad.zip) version)
- read carefull the above hint and see section [progress](#progress)
- Download and install bass (see [What needs to be done to compile the code](#what-needs-to-be-done-to-compile-the-code))
- start the application (at best using the Lazarus IDE)

## Lessons learned ?

As this section is not interesting for everyone i extracted this into a separate section [lessons learned](lessons_learned.md).
Furthermore there are some special points when porting a "old" DOS application to a modern "Linux/Windows" application, which i handle in the section [DOOM vs. LCL](doom_vs_lcl.md).

## Difference to other source ports and key mappings

As i am not doing a 100% source port but more a port for me and my education (or personal needs), FPC DOOM will not be like Vanilla DOOM and even not like Crispy DOOM. To See the differences look [here](differences.md).

## Known Bugs
- Replaying of demo's does not work because the time is "glichting" away during simulation
- not really a bug, but savegames are not onderstood, thus atm not available.

## Progress:
<!-- 
Homepage used to create .gif images: https://ezgif.com/maker
-->
- got crispy-doom compiled
- created initial FPC_DOOM Lazarus project
- (2025.01.03) stored everything on Github
- able to extract icon from doom_icon.pas
- w_wad.pas can now "load" the .wad file
- (2025.01.09) able to store "patches" when drawn as .bmp files to harddisc, very first extracted image "M_DOOM" ![](documentation/doom.png)
- (2025.01.10) activate OpenGL Rendering default upscale = 2 ![](documentation/first_app_rendering.png)
- (2025.01.12) integrate keyboard event loop and main menu with quit button ![](documentation/Menu_first.gif)
- (2025.01.13) finish part of menues necessary to actually start a game ![](documentation/Menu_til_start.gif)
- (2025.01.20) finish wipe function ![](documentation/wipe.gif)
- (2025.01.22) able to create very first screenrendering ![](documentation/very_first_screenrender.png) <br> still missing flats..
- (2025.01.23) finally was able to enable flats ![](documentation/with_flats.png)
- (2025.01.24) add ability to rotate player, lets take a shy look around ;) ![](documentation/rotate.gif)
- (2025.01.25) enable sprite rendering ![](documentation/sprites.png)
- (2025.01.26) give the player a weapon ![](documentation/raise_pistol.gif) <br> still not able to shoot or move :(
- (2025.01.28) enable "normal" map preview ![](documentation/am_map_normal.gif)
- (2025.01.29) enable am map cheats, and finished am functions ![](documentation/am_map_finished.gif)
- (2025.01.30) enable forward walking and falling ![](documentation/walking.gif) <br> still no strafe / clipping or interaction with the map
- (2025.02.01) enable interaction with doors ![](documentation/open_door.gif)
- (2025.02.03) able to shoot barrels ![](documentation/shoot_barrel.gif)
- (2025.02.05) First version of .wad viewer ![](documentation/WAD_Viewer_001.png)
- (2025.02.06) enable SFX engine [Video](documentation/DOOM_Sound.mp4)
- (2025.02.08) reached finish screen of level 1 ![](documentation/Hanger_Finished.gif)
- (2025.02.09) reached level 2 ![](documentation/e1m2.png) <br> still no HUD and not all secrets in level 1 possible
- (2025.02.11) finally ported everything to play e1m1 with 100% (kills, items, secret) without using cheat codes ![](documentation/e1m1_100.png)
- (2025.02.12) enable HUD ![](documentation/HUD.png) <br> mapsize not yet scaleable
- (2025.02.18) enable "invisible" drawing ![](documentation/invisible.png)
- (2025.02.28) reached finish screen ![](documentation/finish_screen.png)