Unit f_finale;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure F_StartFinale();

Implementation

Uses
  doomstat, doomdef
  , am_map
  , d_mode
  , g_game
  ;

//
// F_StartFinale
//

Procedure F_StartFinale();
Var
  i: size_t;
Begin
  gameaction := ga_nothing;
  gamestate := GS_FINALE;
  viewactive := false;
  automapactive := false;
  Raise exception.create('Port me.');

  //    if (logical_gamemission == doom)
  //    {
  //        S_ChangeMusic(mus_victor, true);
  //    }
  //    else
  //    {
  //        S_ChangeMusic(mus_read_m, true);
  //    }
  //
  //    // Find the right screen and set the text and background
  //
  //    for (i=0; i<arrlen(textscreens); ++i)
  //    {
  //        textscreen_t *screen = &textscreens[i];
  //
  //        // Hack for Chex Quest
  //
  //        if (gameversion == exe_chex && screen->mission == doom)
  //        {
  //            screen->level = 5;
  //        }
  //
  //        if (logical_gamemission == screen->mission
  //         && (logical_gamemission != doom || gameepisode == screen->episode)
  //         && gamemap == screen->level)
  //        {
  //            finaletext = screen->text;
  //            finaleflat = screen->background;
  //        }
  //    }
  //
  //    // Do dehacked substitutions of strings
  //
  //    finaletext = DEH_String(finaletext);
  //    finaleflat = DEH_String(finaleflat);
  //    // [crispy] do the "char* vs. const char*" dance
  //    if (finaletext_rw)
  //    {
  //	free(finaletext_rw);
  //	finaletext_rw = NULL;
  //    }
  //    finaletext_rw = M_StringDuplicate(finaletext);
  //
  //    finalestage = F_STAGE_TEXT;
  //    finalecount = 0;
End;

End.

