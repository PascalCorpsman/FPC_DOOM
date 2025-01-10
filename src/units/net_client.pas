Unit net_client;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Var
  // true if the client code is in use
  net_client_connected: Boolean;

  // Connected but not participating in the game (observer)
  drone: boolean = false;

Implementation

End.

