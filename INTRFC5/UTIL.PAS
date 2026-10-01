unit util;

interface
  uses dos;

  function add_offset(p:pointer; add:word):pointer;

  function asciiz2s(var asciiz):string;

  function ptr_diff(p1,p2:pointer):longint;

  function minw(i,j:word):word;

  function maxw(i,j:word):word;

  function minl(i,j:longint):longint;

  function maxl(i,j:longint):longint;

  function word_at(var b:byte):word;

  function read_file(filename: string;var buffer:pointer):word;
  { Attempts to read a file into buffer; returns nil if there was a problem }

  function roundup(n,r:word):word;

  procedure get_load_path(var s:string);
  { Returns the path to the currently running program;  needs DOS 3+ }

  function get_unique_filename(var path:string; attr:word):word;
  { Creates new file in given directory, appends name to path, returns error }

  function is_a_file(var f):boolean;
  { Determines if the file in f is really a file, or is a device.
    f may be either a TP file type or a DOS file handle
    Assumes f is open
  }
  function freeheap:integer;
  { Frees memory from the heap pointer up to the top of the free list
    for use by other programs.  Will destroy the free list!
    Returns 0 if successful, dos error code if not.  Should always
    be successful?
  }
  function restoreheap:integer;
  { Restores memory freed by freeheap.
    Does not restore the free list;  will leave garbage in it.
    Returns 0 if successful, dos error code if not.  Will fail if memory
    is no longer free, e.g. a TSR was run in it.
  }

implementation

var
  regs : registers;

function add_offset(p:pointer; add:word):pointer;
var
  s,o:word;
  new:pointer;
begin
  { Normalize p }
  s := seg(p^);
  o := ofs(p^);
  if o > $f then
  begin
    s := s + o shr 4;
    o := o and $f;
  end;
  { Add new offset }
  o := o + add;
  add_offset := ptr(s,o);
end;

function asciiz2s(var asciiz):string;
var a:array[0..255] of char absolute asciiz;
    i:integer;
    s:string;
begin
 i:=0;
 while a[i]<>chr(0) do inc(i);
 {$r-}
 s[0]:=chr(i);
 move(a,s[1],i);
 {$r+}
 asciiz2s:=s
end;

function ptr_diff(p1,p2:pointer):longint;
begin
  ptr_diff := 16*(longint(seg(p1^))-longint(seg(p2^))) + ofs(p1^) - ofs(p2^);
end;

function minw(i,j:word):word;
begin
  if i<j then
    minw := i
  else
    minw := j;
end;

function maxw(i,j:word):word;
begin
  if i<j then
    maxw := j
  else
    maxw := i;
end;

function minl(i,j:longint):longint;
begin
  if i<j then
    minl := i
  else
    minl := j;
end;

function maxl(i,j:longint):longint;
begin
  if i<j then
    maxl := j
  else
    maxl := i;
end;

function word_at(var b:byte):word;
var
  p:^byte;
begin
  p := add_offset(@b,1);
  word_at := word(b) + word(p^) shl 8;
end;

function read_file(filename: string;var buffer:pointer):word;
{ Attempts to read a file into buffer; returns nil if there was a problem }
var
  f:file;
  size : word;
begin
  assign(f,filename);
  read_file := 0;
  buffer := nil;
  {$i-} reset(f,1); {$i+}
  if ioresult <> 0 then
    exit;
  if filesize(f) > 65521 then
  begin
    writeln('File ',filename,' too large.  File not read.');
    exit;
  end;
  if maxavail < filesize(f) then
  begin
    writeln('Out of memory.  File ',filename,' not read.');
    exit;
  end;
  getmem(buffer,filesize(f));
  blockread(f,buffer^,filesize(f),size);
  close(f);
  read_file := size;
end;

function roundup(n,r:word):word;
begin
  roundup := r*((n+r-1) div r);
end;

procedure get_load_path(var s:string);
{ Returns the path to the currently running program;  needs DOS 3+ }
var
  p,q:pointer;
  l:longint absolute p;
  len:byte;
begin
  p := ptr(prefixseg,$2c);    { Point to environment segment number }
  p := ptr(word(p^),0);       { Point to start of environment segment }
  while word(p^) <> 0 do      { Find terminating double 0 }
    inc(l);
  inc(l,4);                   { Skip double zero and count word }

  q := p;                     { Save start of string }
  len := 0;
  while byte(p^) <> 0 do
  begin
    inc(len);
    inc(l);
  end;
  s[0] := char(len);
  move(q^,s[1],len);
end;

function get_unique_filename(var path:string; attr:word):word;
{ Appends new name to path;  Returns error value or zero if ok }
begin
  path[length(path)+1] := char(0);
  regs.ah := $5A;
  regs.ds := seg(path[1]);
  regs.dx := ofs(path[1]);
  regs.cx := attr;
  msdos(regs);
  if ((regs.flags and fcarry) <> 0) then
    get_unique_filename := regs.ax
  else
  begin
    get_unique_filename := 0;
    path := asciiz2s(path[1]);
  end;
end;

function is_a_file(var f):boolean;
{ Determines if the file in f is really a file, or is a device
  Assumes f is open
}
var
  handle : word absolute f;
begin
  regs.ah := $44;  { IOCTL }
  regs.al :=   0;  { Get device information }
  regs.bx := handle;
  msdos(regs);
  if (regs.flags and fcarry) <> 0 then
    is_a_file := false
  else
    is_a_file := (regs.dx and (1 shl 7)) = 0;
end;

function freeheap:integer;
{ Frees memory from the heap pointer up to the top of the free list
  for use by other programs.  Will destroy the free list!
  Returns 0 if successful, dos error code if not.  Should always
  be successful?
}
begin
  regs.ah := $4a;   { Setblock }
  regs.bx := seg(heapptr^) + ofs(heapptr^) div 16 + 1 - prefixseg;
  regs.es := prefixseg;
  msdos(regs);
  if (regs.flags and fcarry) = 0 then
    freeheap := 0
  else
    freeheap := regs.ax;
end;

function restoreheap:integer;
{ Restores memory freed by freeheap.
  Does not restore the free list;  will leave garbage in it.
  Returns 0 if successful, dos error code if not.  Will fail if memory
  is no longer free, e.g. a TSR was run in it.
}
begin
  regs.ah := $4a;   { Setblock }
  regs.bx := seg(heapend^) - prefixseg;
  regs.es := prefixseg;
  msdos(regs);
  if (regs.flags and fcarry) = 0 then
    restoreheap := 0
  else
    restoreheap := regs.ax;
end;

end.


