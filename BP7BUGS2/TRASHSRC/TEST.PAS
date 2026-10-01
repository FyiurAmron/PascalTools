program test;

{ This program just does longint multiplies and reports any errors.
  If you use Prot386, you shouldn't see any. }

uses
  { prot386, }
  crt;

var
  x,y,z : longint;
begin
  x := 20;
  y := 6;
  repeat
    z := x*y;
    if z <> 120 then
      writeln('Longint error!  z=',z);
  until keypressed;
end.
