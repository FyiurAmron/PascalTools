unit dump;
{  Various routines to dump memory to system.output  }

interface

procedure dumpbytes(var loc;num:word);
function hexbyte(b:byte):string;
function hexword(w:word):string;

implementation

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

procedure dumpbytes(var loc;num:word);
var
  bytes:array[1..65520] of byte absolute loc;
  i:word;
begin
  for i:=1 to num do
    write(hexbyte(bytes[i]),' ');
  writeln;
end;

end.