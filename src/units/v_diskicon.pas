Unit v_diskicon;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure V_RestoreDiskBackground();

Implementation

Procedure V_RestoreDiskBackground();
Begin
  //    if (disk_drawn)
  //    {
  //        // Restore the background.
  //        CopyRegion(DiskRegionPointer(), SCREENWIDTH,
  //                   saved_background, LOADING_DISK_W,
  //                   LOADING_DISK_W, LOADING_DISK_H);
  //
  //        disk_drawn = false;
  //    }
End;



End.

