{$N+} unit test1;

interface

type
  type1 = array[1..5] of byte;

  type2 = record
    b1 : byte;
    b2 : byte;
  end;

  type3 = object
    b1 : byte;
    b2 : byte;
    constructor c(a1,a2:byte);
    destructor  d;
    procedure m;
    procedure v; virtual;

    private

    pb1 : byte;
    procedure pm;
    procedure pv; virtual;
  end;

  type4 = file of byte;

  type5 = text;

  type6 = function : byte;

  type7 = set of byte;

  type8 = ^byte;

  type9 = string;

  type10 = comp;

  type11 = real;

  type12 = 1..6;

  type13 = boolean;

  type14 = char;

  type15 = (red, green, blue);

var
  v : byte;
  a : word absolute v;
const
  tc : byte = 1;
  { These constants should all be printable }
  i = 1;
  b = true;
  s = 'This is a string';
  f = 1.23;
  c = 'A';

procedure proc(v : byte; var r : byte);

function  fun(v : byte; var r : byte) : byte;

implementation
    constructor type3.c;  begin write('1') end;
    destructor  type3.d;  begin write('12') end;
    procedure   type3.m;  begin write('123') end;
    procedure   type3.v;  begin end;
    procedure   type3.pm; begin end;
    procedure   type3.pv; begin end;
    procedure   proc;
    var
      a : word absolute v;
    begin end;
{$i test1.inc}
end.

