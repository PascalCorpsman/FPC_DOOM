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
if (x = 2) then begin
  result := 1;
  exit;
end;
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
var X:integer;
..
x := fancy_functioncall();
if (x <> 0) then 
begin
  ..
end;
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
type 
  cheatseq_t = record
    // settings for this cheat
    sequence: String;
    parameter_chars: integer;

    // state used during the game
    chars_read: integer; 
    parameter_buf:String;
  end;
``` 
⚠️ But be carefull, as you now shifted the readindex of the first character from C = 0 to FPC = 1 ⚠️

## Loops

### repeat vs. while
```cpp
do
{
..
} while (running);
```
Translates to this:

```pascal
repeat
..
until (not running); // Attention you need to invert the condition here!
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
var
  sectors: array of int;
  i, numsectors: integer;
..
for i := 0 to numsectors - 1 do 
begin
  sectors[i] := i + 1;
end;
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
var
  i:array[0..9] of integer;
  j:^integer;
begin
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
var
  lines: array of lines_t;
  ld: ^lines_t;
  index: integer;
// lets assume lines is correct defined and somewhere in the code ld was set to one of its elements
index := (ptrint(ld) - ptrint(@lines[0])) Div sizeof(lines[0]);
```
### accessing to a substruct whithin a strucr

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
type 
  big_data_t = record
    a: integer;
    b: integer;
    c: integer;
  end;
  small_data_t = record
    b: integer;
    c: integer;
  end;
var
  a: ^big_data_t;
  b: ^small_data_t;
begin
  // Let point a to something valid
  b := pointer(a) + sizeof(integer);
```

### TBytes is not PByte

When dealing with array's of byte do not use the TBytes datatype, use PByte instead !
Reason for this, is that FPC "knows" the size of the array thats behind of TBytes (by reading the int in the negative address of the first element). A C PByte does not have stored this information, therefore the lenght information will be invalid!


### invalid array type declaration

The datatype patch_t in DOOM has a field columnofs, which is declared as array of eight elements in code. This is not true, the columnofs holds width element. When porting this to FPC you get a out of bound error, when accessing to the nineth element.

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
    columnofs: P_int; // only [width] used
  End; 
```
<!---
Backlog:

for (p = line; *p != '\0' && !isspace(*p) && *p != '='; ++p)

for (i = 9, k = 0; i < 18 && k < 5; i += 2, k++)

for (i = lumphash[hash]; i != -1; i = lumpinfo[i]->next)

unions

-->