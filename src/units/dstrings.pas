Unit dstrings;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  NUM_QUITMESSAGES = 8;

  SAVEGAMENAME = 'doomsav';

  doom1_endmsg: Array Of String =
  (
    'are you sure you want to\nquit this great game?',
    'please don''t leave, there''s more\ndemons to toast!',
    'let''s beat it -- this is turning\ninto a bloodbath!',
    'i wouldn''t leave if i were you.\ndos is much worse.',
    'you''re trying to say you like dos\nbetter than me, right?',
    'don''t leave yet -- there''s a\ndemon around that corner!',
    'ya know, next time you come in here\ni''m gonna toast ya.',
    'go ahead and leave. see if i care.'
    );

  doom2_endmsg: Array Of String =
  (
    // QuitDOOM II messages
    'are you sure you want to\nquit this great game?',
    'you want to quit?\nthen, thou hast lost an eighth!',
    'don''t go now, there''s a \ndimensional shambler waiting\nat the dos prompt!',
    'get outta here and go back\nto your boring programs.',
    'if i were your boss, i''d \n deathmatch ya in a minute!',
    'look, bud. you leave now\nand you forfeit your body count!',
    'just leave. when you come\nback, i''ll be waiting with a bat.',
    'you''re lucky i don''t smack\nyou for thinking about leaving.'
    );

Implementation

End.

