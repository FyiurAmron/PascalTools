unit dump;
{  Various routines to dump memory to system.output  }

interface

procedure dumpbytes(var loc;start,num:word);
procedure dumpwords(var loc;start,num:word);
function hexbyte(b:byte):string;
function hexword(w:word):string;
function hexword2(w:word):string;

implementation

uses
  util;

function hexbyte(b:byte):string;
const
  symbol : array[0..$f] of char = ('0','1','2','3','4','5','6','7',
                                   '8','9','A','B','C','D','E','F');
begin
  hexbyte := symbol[b shr 4] + symbol[b and $f];
end;

function hexword(w:word):string;
begin
  hexword := hexbyte(hi(w))+hexbyte(lo(w));
end;

function hexword2(w:word):string;
var
  i : byte;
  h : string;
begin
  h := hexword(w);
  for i:=1 to length(h)-1 do
  begin
    if h[i] <> '0' then
    begin
      hexword2 := h;
      exit;
    end;
    h[i] := ' ';
  end;
  hexword2 := h;
end;

function legal(b:byte):char;
begin
  if b<32 then
    legal := '.'
  else
    legal := char(b);
end;

procedure dumpbytes(var loc;start,num:word);
var
  bytes:array[0..65520] of byte absolute loc;
  i,j:word;
procedure dumpascii(last:word);
var
  j : word;
begin
  for j:=0 to last do
  begin
    write(legal(bytes[i+start-$F+j]));
  end;
end;
begin
  if num = 0 then
    exit;
  for i:=0 to num-1 do
  begin
    case i mod 16 of
    0: begin
         writeln;
         write(hexword(i+start),':');
       end;
    8: write(' ');
    end;
    write(hexbyte(bytes[i+start]):3);
    if i mod 16 = $F then
    begin
      write('  ');
      dumpascii($F);
    end;
  end;
  if (num-1) mod 16 < $F then
  begin
    for j := num mod 16 to $f do
    begin
      write('   ');
      if j = 8 then
      write(' ');
    end;
    write('  ');
    i := 16*((num-1) div 16) + $F;
    dumpascii((num-1) mod 16);
  end;
  writeln;
end;

procedure dumpwords(var loc;start,num:word);
var
  words:array[0..32760] of word absolute loc;
  i:word;
begin
  if num = 0 then
    exit;
  repeat
    write(hexword(start):4);
    for i:=1 to minw(15,num) do
      write(hexword(start+i):5);
    writeln;
    write(hexword(words[start]));
    for i:=1 to minw(15,num) do
      write(hexword(words[start+i]):5);
    writeln;
    inc(start,16);
    dec(num,16);
  until num > 65535 - 16;
end;

end.
