Unit d_event;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype
  ;

// Event structure.
Type

  // Input event types.
  evtype_t =
    (
    // Key press/release events.
    //    data1: Key code (from doomkeys.h) of the key that was
    //           pressed or released. This is the key as it appears
    //           on a US keyboard layout, and does not change with
    //           layout.
    // For ev_keydown only:
    //    data2: ASCII representation of the key that was pressed that
    //           changes with the keyboard layout; eg. if 'Z' is
    //           pressed on a German keyboard, data1='y',data2='z'.
    //           Not affected by modifier keys.
    //    data3: ASCII input, fully modified according to keyboard
    //           layout and any modifier keys that are held down.
    //           Only set if I_StartTextInput() has been called.
    ev_keydown,
    ev_keyup,

    // Mouse movement event.
    //    data1: Bitfield of buttons currently held down.
    //           (bit 0 = left; bit 1 = right; bit 2 = middle).
    //    data2: X axis mouse movement (turn).
    //    data3: Y axis mouse movement (forward/backward).
    ev_mouse,

    // Joystick state.
    //    data1: Bitfield of buttons currently pressed.
    //    data2: X axis mouse movement (turn).
    //    data3: Y axis mouse movement (forward/backward).
    //    data4: Third axis mouse movement (strafe).
    //    data5: Fourth axis mouse movement (look)
    //    data6: Dpad and analog stick direction.
    ev_joystick,

    // Quit event. Triggered when the user clicks the "close" button
    // to terminate the application.
    ev_quit
    );

  event_t = Record

    _type: evtype_t;

    // Event-specific data; see the descriptions given above.
    data1, data2, data3, data4, data5, data6: int;
  End;
  Pevent_t = ^event_t;

Procedure PushEvent(Const ev: event_t); // So kann die Anwendung "events" im Spiel Auslösen ;)

Function D_PopEvent(): Pevent_t;

Function GetTypedEmptyEvent(Const aType: evtype_t): event_t;

Implementation

Uses
  ufifo;

Type

  TEventFifo = specialize TBufferedFifo < Pevent_t > ;

Var
  EventFifo: TEventFifo = Nil;

Procedure PushEvent(Const ev: event_t);
Var
  p: Pevent_t;
Begin
  new(p);
  p^ := ev;
  EventFifo.Push(p);
End;

Function D_PopEvent(): Pevent_t;
Begin
  If EventFifo.isempty Then Begin
    result := Nil;
  End
  Else Begin
    result := EventFifo.Pop;
  End;
End;

Function GetTypedEmptyEvent(Const aType: evtype_t): event_t;
Begin
  FillChar(result, sizeof(result), 0);
  result._type := aType;
End;

Initialization
  EventFifo := TEventFifo.create(128);

Finalization
  EventFifo.free;
  EventFifo := Nil;

End.

