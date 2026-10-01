unit test1;
{$O+,G+,N+,Y+,L+,D+}
interface
uses Dos,Printer;

type
  ea1 = 0..2;
  ea = (rr,tt,yy);

const
  { These constants should all be printable }
  i = 1;
  b = true;
  s = 'This is a string';
  s_1 = #3'This is a string with control chars'#13#10'X'#0'0';
  f = 1.23;
  c = 'A';
  e = 1e3000;
  pp = ptr($40,8);
  bs = [0..32];
  cs = [#0..#32,'A','B','D'..'Z'];
  es = [rr..yy];
  ce = rr;

type
  type1  = array[rr..yy] of byte;
  type1_1 = array[1..43] of byte;
  type1_2 = array[#4..#56] of byte;
  type1_3 = array[False..True] of byte;
  type1_4 = array[wordbool] of byte;

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
    procedure vd; virtual 5;
{$IFDEF DPMI}
    procedure ve; virtual 7;
{$ENDIF}

    private

    pb1 : byte;
    procedure pm;
    procedure pv; virtual;
  end;

  type3_1 = object
    b1 : byte;
    b2 : byte;
    constructor c;
    destructor  d;virtual;
  end;

  type4 = file of byte;
  type4_1 = file;
  type4_2 = file of array [0..2] of Extended;

  type5 = text;

  type6 = function : byte;
  type6_1 = procedure(var arg1:byte;arg2:type2;var arg3);

  type7 = set of byte;
  type7_1 = set of 1..3;

  type8 = ^byte;
  type8_1 = pointer;

  type9 = string;
  type9_1 = string[30];

  type10 = comp;

  type11 = real;

  type12 = 1..6;

  type13 = boolean;

  type14 = char;

  type15 = (red, green, blue);

var
  v : byte;
  ab : array [0..9] of byte;
  a : word absolute v;
  a_1 : word absolute $40:$50;

var
   testww:word;
procedure p1;inline($8a/<4/>64555/testww+1/seg0040);
procedure p2;
procedure p3;
{$IFDEF DPMI}
procedure p4;
procedure p41;
{$ENDIF}

function func(v : byte; var r : byte):Byte;
procedure proc(v : byte; var r : byte);

function  fun(v : byte; var r : byte) : byte;

implementation
{$L TEST1.OBJ}
{$IFDEF DPMI}
procedure Onesd;far;external 'Test' name 'zkouska';
procedure Onessd;far;external 'Test2' name 'z3kouska';
procedure Oness;far;external 'Test3' index 1;
{$ENDIF}
    procedure AA; external;
    constructor type3.c;  begin write('1') end;
    destructor  type3.d;  begin write(lst,'12') end;
    procedure   type3.m;  begin write(lst,'123') end;
    procedure   type3.v;  begin  end;
    procedure   type3.vd; begin  end;
    procedure   type3.pm; begin end;
    procedure   type3.pv; begin end;
{$IFDEF DPMI}
    procedure   type3.ve; external 'name' index 5;
{$ENDIF}
    constructor type3_1.c;  begin end;
    destructor  type3_1.d;  begin end;
    function func;
    procedure proc;
    begin
    end;

    begin
    end;

    procedure   proc;
    var
      a : word absolute v;
      {sds:pathstr;}
    begin
      {a:= fcarry;}
      a:=doserror;
      {Exec('','');}
      end;
{$i test1.inc}

  procedure aa;external;

  procedure p11;near;
  begin
  end;

  procedure p12;interrupt;
  begin
  end;

  procedure p2; assembler;
  asm
  end;

  procedure p3;
  procedure p12x;
  begin
    writeln(pos('4','4'));
  end;
  var datav:word;
  const datac:word=0;
  begin
    p11;
    p12x;
  end;
{$IFDEF DPMI}
  procedure p4;external 'name' index 4;
  procedure p41;external 'name' name 'test';
  procedure p44;export;begin p4;end;
{$ENDIF}

end.

