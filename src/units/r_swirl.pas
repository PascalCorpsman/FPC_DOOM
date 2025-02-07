Unit r_swirl;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure R_InitDistortedFlats();

Implementation

Const
  AMP = 2;
  AMP2 = 2;
  SPEED = 32;


Procedure R_InitDistortedFlats();
Begin
  Raise Exception.Create('Port me.');
  //  if (!offsets)
  //	{
  //		int i;
  //
  //		offsets = I_Realloc(offsets, SEQUENCE * FLATSIZE * sizeof(*offsets));
  //		offset = offsets;
  //
  //		for (i = 0; i < SEQUENCE; i++)
  //		{
  //			int x, y;
  //
  //			for (x = 0; x < 64; x++)
  //			{
  //				for (y = 0; y < 64; y++)
  //				{
  //					int x1, y1;
  //					int sinvalue, sinvalue2;
  //
  //					sinvalue = (y * swirlfactor + i * SPEED * 5 + 900) & FINEMASK;
  //					sinvalue2 = (x * swirlfactor2 + i * SPEED * 4 + 300) & FINEMASK;
  //					x1 = x + 128
  //					   + ((finesine[sinvalue] * AMP) >> FRACBITS)
  //					   + ((finesine[sinvalue2] * AMP2) >> FRACBITS);
  //
  //					sinvalue = (x * swirlfactor + i * SPEED * 3 + 700) & FINEMASK;
  //					sinvalue2 = (y * swirlfactor2 + i * SPEED * 4 + 1200) & FINEMASK;
  //					y1 = y + 128
  //					   + ((finesine[sinvalue] * AMP) >> FRACBITS)
  //					   + ((finesine[sinvalue2] * AMP2) >> FRACBITS);
  //
  //					x1 &= 63;
  //					y1 &= 63;
  //
  //					offset[(y << 6) + x] = (y1 << 6) + x1;
  //				}
  //			}
  //
  //			offset += FLATSIZE;
  //		}
  //	}

End;

End.

