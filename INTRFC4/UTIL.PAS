unit util;

interface
  uses dos;

  function add_offset(p:pointer; add:word):pointer;
  function minw(i,j:word):word;
  function maxw(i,j:word):word;
  function word_at(var b:byte):word;
  function read_file(filename: string;var buffer:pointer):word;
  { Attempts to read a file into buffer; returns nil if there was a problem }
  function roundup(n,r:word):word;
implementation
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

end.


