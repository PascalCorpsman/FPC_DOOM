Unit usdl_wrapper;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, Graphics;
//Uses Forms, Graphics, config, IntfGraphics, FPImage, unit1;

Type
  SDL_Surface = TBitmap;
  SDL_Window = Pointer; // TODO: Noch Klären was das sein könnte ;)

  // Nicht 1:1 implementiert, aber funktioniert ;)
  // https://wiki.libsdl.org/SDL2/SDL_CreateRGBSurfaceFrom
Function SDL_CreateRGBSurfaceFrom(
  pixels: P_unsigned_int;
  width: int;
  height: int;
  depth: int;
  pitch: int;
  RMask: UInt32;
  GMask: UInt32;
  BMask: UInt32;
  AMask: UInt32
  ): SDL_Surface;

// https://wiki.libsdl.org/SDL2/SDL_FreeSurface
Procedure SDL_FreeSurface(surface: SDL_Surface);

// https://wiki.libsdl.org/SDL2/SDL_SetWindowTitle
Procedure SDL_SetWindowTitle(window: SDL_Window; title: String);

// https://wiki.libsdl.org/SDL2/SDL_SetWindowIcon
Procedure SDL_SetWindowIcon(window: SDL_Window; icon: SDL_Surface);

Implementation

Uses unit1, forms, IntfGraphics, FPImage;

function SDL_CreateRGBSurfaceFrom(pixels: P_unsigned_int; width: int;
  height: int; depth: int; pitch: int; RMask: UInt32; GMask: UInt32;
  BMask: UInt32; AMask: UInt32): SDL_Surface;
Var
  i, j: Integer;
  col: unsigned_int;
  fcol: TFPColor;
  TempIntfImg: TLazIntfImage;
Begin
  result := TBitmap.Create;
  result.Width := width;
  result.Height := height;
  TempIntfImg := TLazIntfImage.Create(0, 0);
  TempIntfImg.LoadFromBitmap(result.Handle, result.MaskHandle);
  // TODO: Kann sein, dass das mit dem Alpha noch nicht ganz stimmt, aber prinzipiel gehts :)
  For i := 0 To width - 1 Do Begin
    For j := 0 To height - 1 Do Begin
      col := pixels[j * height + i];
      fcol.Red := (col Shr 16) And $FF00;
      fcol.Green := (col Shr 8) And $FF00;
      fcol.Blue := (col) And $FF00;
      fcol.Alpha := (col Shr 8) And $FF00;
      TempIntfImg.Colors[i, j] := fcol;
    End;
  End;
  result.LoadFromIntfImage(TempIntfImg);
  TempIntfImg.free;
End;

procedure SDL_FreeSurface(surface: SDL_Surface);
Begin
  If assigned(surface) Then surface.Free;
End;

procedure SDL_SetWindowTitle(window: SDL_Window; title: String);
Begin
  Application.Title := title;
  form1.Caption := Application.Title;
End;

procedure SDL_SetWindowIcon(window: SDL_Window; icon: SDL_Surface);
Begin
  Application.Icon.Assign(icon);
End;

End.

