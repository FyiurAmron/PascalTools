unit util;

interface
  uses dos;

  var
    last_file_size : longint;

  function minw(w1,w2:word):word;

  function normalize(p:pointer):pointer;

  function add_offset(p:pointer; add:word):pointer;

  function upper(var s:string):string;

  function ptr_diff(p1,p2:pointer):longint;

  procedure read_file(filename: string;var buffer:pointer;
                     offset:longint; size:word);
  { Attempts to read a file into buffer; returns nil if there was a problem }

  function roundup(n,r:word):word;

implementation

function minw(w1,w2:word):word;
begin
  if w1<w2 then
    minw := w1
  else
    minw := w2;
end;

function normalize(p:pointer):pointer;
var
  s,o : word;
begin
  s := seg(p^);
  o := ofs(p^);
  if o > $f then
  begin
    s := s + o shr 4;
    o := o and $f;
  end;
  normalize := ptr(s,o);
end;

function add_offset(p:pointer; add:word):pointer;
begin
  p := normalize(p);
  add_offset := ptr(seg(p^),ofs(p^)+add);
end;

function upper(var s:string):string;
var
  i:integer;
  result : string;
begin
  result[0] := s[0];
  for i:=1 to length(s) do
    result[i] := upcase(s[i]);
  upper := result;
end;

function ptr_diff(p1,p2:pointer):longint;
begin
  ptr_diff := 16*(longint(seg(p1^))-longint(seg(p2^))) + ofs(p1^) - ofs(p2^);
end;

procedure read_file(filename: string;var buffer:pointer;
                   offset:longint; size:word);
{ Attempts to read a file into buffer; returns nil if there was a problem }
var
  f:file;
  try_size : longint;
begin
  assign(f,filename);
  buffer := nil;
  {$i-} reset(f,1); {$i+}
  if ioresult <> 0 then
    exit;
  last_file_size := filesize(f);
  try_size := last_file_size-offset;
  if try_size < size then
    size := try_size;
  try_size := size;
  if size > 65521 then
  begin
    writeln('File size too large.  File not read.');
    exit;
  end;
  if maxavail < size then
  begin
    writeln('Out of memory.  File ',filename,' not read.');
    exit;
  end;
  getmem(buffer,size);
  seek(f,offset);
  blockread(f,buffer^,try_size,size);
  close(f);
end;

function roundup(n,r:word):word;
begin
  roundup := r*((n+r-1) div r);
end;

end.


