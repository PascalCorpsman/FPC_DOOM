# Lessons learned

This is a small collection of the "most" made mistakes during porting crispy DOOM to FPC. Goal is not to blame C / C++ but more to give a list on which points you have to be special carefull when porting C / C++ code to FPC.

If you want to test the code snippets right away, you can use this [online compiler](https://www.onlinegdb.com/online_c_compiler).

### return

The return statement in c is also the exit statement.

```cpp
if (x == 2)
return 1;
return 0;
```
Translates to this:

```pascal
// Pascal
If (x = 2) Then Begin
  result := 1;
  exit;
End;
result := 0;
```

### Assignments of variables

The position of the ++ does matter in c, when further processed (this is also relevant for loops)!

```cpp
// C / CPP
int i = 0;
int x = 0;
if (++i)
  x = 1; 
// i is 1, x is 1 (like expected)

i = 0;
if (i++)
  x = 2; 
// i is 2, x is still 1 (most FPC programmer would not expect this)
```

### Assignments during boolean evaluations

Assigning and checking a value at the same time, this not possible in FPC.
```cpp
// C / CPP
int x;
..
if (x = fancy_functioncall())
{
  ..
}
```
Translates to this:

```pascal
// Pascal
Var X:integer;
..
x := fancy_functioncall();
If (x <> 0) Then Begin
  ..
End;
```

### >> is not Shr for signed datatypes
In DOOM there are no floating point numbers, instead so called "fixed" comma numbers are used. The dataformat currency is used more or less the same way, but with decimal shifting.
Here is a example:

Lets say you want to deal with floating point numbers but you do not have access to a machine with a numerical coprocessor (so it was on most machines during development of DOOM, and it is still when developing embedded software for µ-Controllers). Let say you only need to know if a value is .5  or .0 at the right side of the decimal separator. Easiest way is to multiply the value by two and do all calculations in integers. Only at the very end, when plotting to the screen you need to convert the number now to float (and there are tricks to not do this as well..).

Here is how this looks in code:

```pascal
Var 
  x: single;
  y: integer;
Begin
  x := 1.5;
  y := 3;    // 3 is 1.5 Shl 2

```
As long as you divide y by 2 or shr it by 1 when prompting, x and y are the same. But y has the benefit, that calculations with y do not need a floating point unit. There are also downsides when dealing with fixed comma numbers, this comes in when multiplying them or with the fact that you reduce the available numbers per bit. If you want to play a little with fixed comma values i recomend this [example](https://github.com/PascalCorpsman/mini_projects/tree/main/miniprojects/Fixed_Comma).


So whats the point, C has >> and FPC has shr ? As long as you deal with positive numbers everything behaves the same. The problem is when dealing with negative numbers.

```cpp
typedef unsigned int angle_t;
typedef int fixed_t;

angle_t a = 16;
fixed_t b = 16;
fixed_t c = -1;

a >>= 1; // a is now 8
b >>= 1; // b is now 8
c >>= 1; // c is now -1
```
Translates to this:

```pascal
Type angle_t = uint32;
Type fixed_t = int32;

Var
  a: angle_t;
  b, c: fixed_t;
Begin
  a := 16;
  b := 16;
  c := -1;
  a := a Shr 1; // a is now 8
  b := SarLongint(b, 1); // b is now 8
  c := SarLongint(c, 1); // c is now -1
  c := -1;
  c := c Shr 1; // c is now 2147483647 and this is wrong, that is because the Shr operator does not take the highes bit into account !
  // if you are using int64 you need the SarInt64 function
```

### Evaluation of boolean expressions

The "!" is small and can be overseen easily, also c does not require braces here nor is the bit test masked.

```cpp
#define ML_BLOCKMONSTERS (8)
// This is a NULL pointer check, and a "bit set" test

if ( !tmthing->player && ld->flags & ML_BLOCKMONSTERS )
  return false; // block monsters only
```    

Translates to this:

```pascal
const ML_BLOCKMONSTERS = 8;

if (tmthing^.player = Nil) and ((ld^.flags and ML_BLOCKMONSTERS) <> 0) then begin
  result := false; // block monsters only
  exit;
end;
```

### Strings

Most of the time a *char is simple a string.

```cpp
typedef struct
{
    // settings for this cheat

    char sequence[MAX_CHEAT_LEN];
    size_t sequence_len;
    int parameter_chars;

    // state used during the game

    size_t chars_read;
    int param_chars_read;
    char parameter_buf[MAX_CHEAT_PARAMS];
} cheatseq_t;
``` 
Can be reduced to:

```pascal
Type 
  cheatseq_t = Record
    // settings for this cheat
    sequence: String;
    parameter_chars: integer;

    // state used during the game
    chars_read: integer; 
    parameter_buf: String;
  end;
``` 
⚠️ But be carefull, as you now shifted the readindex of the first character from C = 0 to FPC = 1 ⚠️

## Loops

### Repeat vs. While
```cpp
do
{
..
} while (running);
```
Translates to this:

```pascal
Repeat
..
Until (Not running); // Attention you need to invert the condition here!
```

### iterating through an array

```cpp
int *sectors; // the array that holds the elements
int *sector; // element that iterates through the array
int numsectors; // number of elements in sectors
for (int i = 0, sector = sectors; i < numsectors; i++, sector++)
{
  *sector = i + 1;
}
```

Translates to this:

```pascal
Var
  sectors: array of int;
  i, numsectors: integer;
..
For i := 0 To numsectors - 1 Do 
Begin
  sectors[i] := i + 1;
End;
```

## Pointers

### get a slice of an array

```cpp
int i[10];
int *j;
j = i + 2; // j points now to the 3. element
```

Translates to this:

```pascal
Var
  i: Array[0..9] Of integer;
  j: ^integer;
Begin
  // j := @i + 2; // This is wrong !!!
  j := @i[2];
```

### calculating the index of a array by a pointer of a element

```cpp
lines_t *lines; //This is the array that holds lots of elements of lines_t
lines_t *ld;
// lets assume lines is correct defined and somewhere in the code ld was set to one of its elements
int index = ld-lines;
```
Translates to this:

```pascal
Var
  lines: Array Of lines_t;
  ld: ^lines_t;
  index: integer;
// lets assume lines is correct defined and somewhere in the code ld was set to one of its elements
index := (ptrint(ld) - ptrint(@lines[0])) Div sizeof(lines[0]);
```
### accessing to a substruct whithin a struct

```cpp
typedef struct
{
  int a;
  int b;
  int c;
} big_data_t;

typedef struct
{
  int b;
  int c;
} small_data_t;

big_data_t *a;
small_data_t *b;
// Let point a to something valid
b = a + 4; // This is the worst, as the sizeof operator is not used ! better would be sizeof(int)
```
Translates to this:
```pascal
Type 
  big_data_t = Record
    a: integer;
    b: integer;
    c: integer;
  End;
  small_data_t = Record
    b: integer;
    c: integer;
  End;
Var
  a: ^big_data_t;
  b: ^small_data_t;
Begin
  // Let point a to something valid
  b := pointer(a) + sizeof(integer);
```

### TBytes is not PByte

When dealing with array's of byte do not use the TBytes datatype, use PByte instead !
Reason for this, is that FPC "knows" the size of the array thats behind of TBytes (by reading the int in the negative address of the first element). A C PByte does not have stored this information, therefore the length information will be invalid!


### invalid array type declaration

The datatype patch_t in DOOM has a field columnofs, which is declared as array of eight elements in code. This is not true, the columnofs holds width elements. When porting this to FPC you get a out of bound error, when accessing to the nineth element.

```cpp
typedef PACKED_STRUCT (
{
    short		width;		// bounding box size
    short		height;
    short		leftoffset;	// pixels to the left of origin
    short		topoffset;	// pixels below the origin
    int			columnofs[8];	// only [width] used
    // the [0] is &columnofs[width]
}) patch_t;
```
Translates to this:
```pascal
  patch_t = Packed Record
    width: short; // bounding box size
    height: short;
    leftoffset: short; // pixels to the left of origin
    topoffset: short; // pixels below the origin
    columnofs: Array[0 .. 65535] Of int; // only [width] used <- this is actually wrong but disables the upper range check for all DOOM usecases and thats what we want here.
  End; 
```
<!---
Backlog:

for (p = line; *p != '\0' && !isspace(*p) && *p != '='; ++p)

for (i = 9, k = 0; i < 18 && k < 5; i += 2, k++)

for (i = lumphash[hash]; i != -1; i = lumpinfo[i]->next)

unions

-->
