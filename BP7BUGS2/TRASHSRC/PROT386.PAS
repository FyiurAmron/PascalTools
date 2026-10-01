unit Prot386;

{ Protects 386 calculations from nasty ISRs that trash the 386 registers.
  Just "use prot386" and interrupt handlers will be installed to protect
  calculations. }

interface

implementation

uses
  Dos;

const
  Op32 = $66;

type
  regs = (reax,rebx,recx,redx);
  TIntRec = record   { This record must be exactly 16 bytes long!!! }
    oldisr : pointer;
    junk : array[1..12] of byte;
  end;

  TIntRecArray = array[0..15] of TIntRec;
  PIntRecArray = ^TIntRecArray;

{ Put the oldisr pointers in the code segment to make the ISR simple. }

procedure InterruptRecs; assembler;
{ We need 256 bytes here.  Most of it is unused, but it'd make the ISR
  too complicated if I got rid of the Junk field.}
asm
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7
  db 1,2,3
end;  { RET is the last byte }

const
  PtrOfs = 15*sizeof(TIntRec);

procedure FixupISR; assembler;
{ This ISR saves and restores the high word of EAX,EBX,ECX,EDX.
  Use it to fix up a bad handler.  Uses 14 bytes of stack space. }
asm
  push bp
  mov bp,sp
  db Op32; push ax
  pop ax
  db Op32; push bx
  pop bx
  db Op32; push cx
  pop cx
  db Op32; push dx
  pop dx
  push word ptr [bp+6]      { This pushes the old flags again }
  mov bp,[bp]                { Restore BP for the old interrupt }
  call dword ptr cs:InterruptRecs[PtrOfs]
  push ax
  pushf
  pop ax                     { Now flags are in AX }

  push bp                    { Save the ISR's BP }
  mov bp,sp                  { Set up our frame again }
  add bp,12
  mov word ptr [bp+6],ax      { This way flags on our return will be
                                   as the old ISR returned them. }
  pop ax
  mov word ptr [bp],ax        { as will BP }
  pop ax

  push dx
  db Op32; pop dx
  push cx
  db Op32; pop cx
  push bx
  db Op32; pop bx
  push ax
  db Op32; pop ax
  pop bp
  iret
end;

procedure Install;
var
  int,irq : byte;
  IntRecs : PIntRecArray;

  procedure InstallHandler;
  var
    addr : pointer;
    segmod : byte;
  begin
    GetIntVec(int,IntRecs^[irq].OldIsr);
    segmod := 15-irq;
    Addr := Ptr(Seg(FixupISR)-segmod, Ofs(FixupISR)+16*segmod);
    SetIntVec(int,Addr);
  end;

begin
  IntRecs := @InterruptRecs;
  for int := 8 to $F do
  begin
    irq := int-8;
    installhandler;
  end;
  for int := $70 to $77 do
  begin
    irq := int-$70+8;
    installhandler;
  end;
end;

procedure UnInstall;
var
  int,irq : byte;
  IntRecs : PIntRecArray;

  procedure UnInstallHandler;
  begin
    SetIntVec(int,IntRecs^[irq].OldIsr);
  end;

begin
  IntRecs := @InterruptRecs;
  for int := 8 to $F do
  begin
    irq := int-8;
    uninstallhandler;
  end;
  for int := $70 to $77 do
  begin
    irq := int-$70+8;
    uninstallhandler;
  end;
end;

var
  OldExitProc : pointer;

procedure MyExitProc; far;
begin
  ExitProc := OldExitProc;
  Uninstall;
end;

begin
  if test8086 >= 2 then
  begin
    Install;
    OldExitProc := ExitProc;
    ExitProc := @MyExitProc;
  end;
end.
