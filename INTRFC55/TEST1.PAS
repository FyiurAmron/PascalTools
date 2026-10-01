{$A-,B-,D+,E-,F-,I+,L+,N+,O-,R-,S+,V+}
{$M 16384,0,655360}
unit test1;

interface

uses objects;

const
  w : word = 3;

type obj = object(TObject) { base instead of TObject in 5.5 }
  procedure firstproc; virtual;
  procedure secondproc; virtual;
end;


type rec = record
  junk : word;
end;

function f:byte;

implementation
var
  o : obj;

type descend = object(obj)
  procedure firstproc; virtual;
  procedure thirdproc; virtual;
end;

procedure obj.firstproc;
begin
end;
procedure obj.secondproc;
begin
  writeln('hi');
end;
procedure descend.firstproc;
begin
  writeln('hi');
end;
procedure descend.thirdproc;
begin
  writeln('hi');
end;

function f;
begin
  f := 1;
end;
begin
  w := 4;
end.
