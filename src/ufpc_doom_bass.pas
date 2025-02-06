(*
 * Auslagerung der Sound Engine in eine eigene Datei damit das nicht ganz so
 * Chaotisch ist ;)
 *)
Unit ufpc_doom_bass;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, bass, sounds;

Type

  TSoundBuffer = Record
    Available: Boolean; // True = Verfügbar und Initialisiert
    Index: Integer; // Der UserPointer für Bass zurück in den FSoundBuffer Array
    DMXSoundBuf: PByte; // Die "Roh"daten
    DMXSoundBufLen: Integer; // Die Anzahl der Gültigen DatenBytes
    DMXSoundBufIndex: integer; // Der Index wieviel Byte Aktuell an Bass übermittelt wurden
    PreviewStream: HSTREAM; // Der Bass Stream wird im Constructor initialisiert
  End;

  { TBassSoundManager }

  TBassSoundManager = Class
  private
    fSoundBuffer: Array[0..integer(NUMSFX) - 1] Of TSoundBuffer;
  public
    Constructor Create(); virtual;
    Destructor Destroy(); override;
    Procedure StartSound(sfxinfo: Psfxinfo_t);
  End;

Var
  BassSoundManager: TBassSoundManager = Nil;

Implementation

Uses
  i_sdlsound, i_system
  , w_wad
  ;
Const
  PadLen = 32;

Type
  // Quelle: https://doomwiki.org/wiki/Sound
  TDMXSound = Packed Record
    Format: UInt16;
    SampleRate: UInt16;
    NumberOfSamples: UInt32;
    PADDING1: Array[0..15] Of ShortInt; // Die ersten 16 und letzten 16 Byte werden nicht genutzt.
    SOUND: Array[0..high(Integer)] Of ShortInt; // Der ist also Gültig im Bereich [0..NumberOfSamples - PadLen - 1]
    // Padding2: Array [0..15] of ShortInt;
  End;

  // Hier kommt eine Angebliche Stack Overflow exception, wenn man das Überwacht aber eigentlich geht alles 1a ..

Function GetPreviewData(handle: HSTREAM; buffer: Pointer; length: DWORD; user: Pointer): DWORD{$IFDEF Windows} stdcall{$ELSE} cdecl{$ENDIF};
Var
  cnt: integer;
  src, buf: PByte;
  i, j: integer;
Begin

  i := PInteger(user)^;
  buf := buffer;
  If (BassSoundManager.fSoundBuffer[i].DMXSoundBufIndex + length) < (BassSoundManager.fSoundBuffer[i].DMXSoundBufLen - 1) Then Begin
    cnt := length;
  End
  Else Begin
    cnt := (BassSoundManager.fSoundBuffer[i].DMXSoundBufLen) - (BassSoundManager.fSoundBuffer[i].DMXSoundBufIndex);
  End;
  src := BassSoundManager.fSoundBuffer[i].DMXSoundBuf;
  inc(src, BassSoundManager.fSoundBuffer[i].DMXSoundBufIndex);
  For j := 0 To cnt - 1 Do Begin
    buf^ := src^;
    inc(buf);
    inc(src);
  End;

  BassSoundManager.fSoundBuffer[i].DMXSoundBufIndex := BassSoundManager.fSoundBuffer[i].DMXSoundBufIndex + cnt;
  result := cnt;
  If cnt <> length Then Begin
    result := result Or BASS_STREAMPROC_END;
  End;
End;

{ TBassSoundManager }

Constructor TBassSoundManager.Create;
Var
  i: integer;
  lumpIndex: integer;
  DMXSound: ^TDMXSound;
Begin
  Inherited Create;
  For i := 0 To integer(NUMSFX) - 1 Do Begin
    lumpIndex := I_SDL_GetSfxLumpNum(@s_sfx[i]);
    fSoundBuffer[i].Available := lumpIndex <> -1;
    If fSoundBuffer[i].Available Then Begin
      DMXSound := W_CacheLumpNum(lumpIndex, 0);
      fSoundBuffer[i].Index := i;
      fSoundBuffer[i].DMXSoundBuf := @DMXSound^.SOUND[0];
      fSoundBuffer[i].DMXSoundBufLen := DMXSound^.NumberOfSamples - PadLen;
      fSoundBuffer[i].DMXSoundBufIndex := 0;
      fSoundBuffer[i].PreviewStream := BASS_StreamCreate(DMXSound^.SampleRate, 1, BASS_SAMPLE_8BITS, @GetPreviewData, @fSoundBuffer[i].Index);
    End;
  End;
End;

Destructor TBassSoundManager.Destroy;
Var
  i: integer;
Begin
  For i := 0 To integer(NUMSFX) - 1 Do Begin
    If fSoundBuffer[i].Available Then Begin
      If BASS_ChannelIsActive(fSoundBuffer[i].PreviewStream) <> 0 Then Begin
        BASS_ChannelStop(fSoundBuffer[i].PreviewStream);
      End;
      BASS_StreamFree(fSoundBuffer[i].PreviewStream);
    End;
    fSoundBuffer[i].Available := false;
  End;
End;

Procedure TBassSoundManager.StartSound(sfxinfo: Psfxinfo_t);
Var
  Index: Integer;
Begin
  Index := (pointer(sfxinfo) - pointer(@s_sfx[0])) Div sizeof(s_sfx[0]);
  If Not fSoundBuffer[Index].Available Then exit;

  If BASS_ChannelIsActive(fSoundBuffer[Index].PreviewStream) <> 0 Then Begin
    BASS_ChannelStop(fSoundBuffer[Index].PreviewStream);
  End;
  fSoundBuffer[Index].DMXSoundBufIndex := 0;
  If Not BASS_ChannelPlay(fSoundBuffer[Index].PreviewStream, true) Then Begin
    I_Error('Unable to start sfx stream.');
  End;
End;

Finalization
  If assigned(BassSoundManager) Then
    BassSoundManager.free;
  BassSoundManager := Nil;

End.

