{$define counter}  { Delete this define if you want to create TrashFix
                     instead of TrashDet; it doesn't do the counting,
                     so it's a bit smaller and faster. }


program TrashDetector;

{ TSR to detect hardware ISRs that trash the 386 extended registers }

uses
  Dos;

type
  regs = (reax,rebx,recx,redx,resi,redi,rebp,rfs,rgs);
  TIntRec = record   { This record must be exactly 16 bytes long!!! }
    oldisr : pointer;
    counts : array[regs] of byte;
    junk   : array[14..16] of byte;
  end;

  TIntRecArray = array[0..15] of TIntRec;
  PIntRecArray = ^TIntRecArray;

{ Put the data in the code segment so we can discard the RTL when
  we go resident. }

procedure InterruptRecs; assembler;
{ The first 8 records are in the PSP, so we need 128 bytes here.}
asm
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7,8
  dd 1,2,3,4,5,6,7
  db 1,2,3
end;  { RET is the last byte }

procedure signature; assembler;
asm
  db 'xxxx is the Trash Detector!'   { "xxxx" is replaced with "This"
                                       at run-time, to avoid false alarms. }
end;

const
  { These constants allow us to code 386-specific instructions }
  Op32   = $66;
  PushFS = $A00F;
  PushGS = $A80F;
  PopFS  = $A10F;
  PopGS  = $A90F;
  MovAXFS= $E08C;
  MovAXGS= $E88C;

  PtrOfs = 15*sizeof(TIntRec) - $80;
  CountOfs = PtrOfs + 4;


procedure CountingISR; far; assembler;
{ This ISR counts all cases where the extended registers get trashed.
  Use this one if you want to run TrashRep.  Uses 26 bytes of stack
  space. }
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
  db Op32; push si
  pop si
  db Op32; push di
  pop di
  db Op32; push bp
  pop bp
  dw PushFS
  dw PushGS

  push word ptr [bp+6]           { old flags }
  mov bp,[bp]                    { and restore BP }
  call dword ptr cs:InterruptRecs[PtrOfs]
  push ax
  pushf
  pop ax                     { Now flags are in AX }

  push bp                    { Save the ISR's BP }
  mov bp,sp                  { Set up our frame again }
  add bp,22
  mov word ptr [bp+6],ax      { This way flags on our return will be
                                   as the old ISR returned them. }
  pop ax
  mov word ptr [bp],ax        { as will BP }

  { AX is still on the stack }
  dw MovAXGS
  cmp word ptr[BP - 18],ax
  je @l7
  inc byte ptr cs:InterruptRecs[CountOfs+rgs]
@l7:

  dw MovAXFS
  cmp word ptr[BP - 16],ax
  je @l8
  inc byte ptr cs:InterruptRecs[CountOfs+rfs]
@l8:

  pop ax
  dw PopGS
  dw PopFS

  push bp
  db Op32; cmp word ptr[BP - 16],bp
  je @l9
  inc byte ptr cs:InterruptRecs[CountOfs+rebp]
@l9:
  db Op32; pop bp

  push di
  db Op32; cmp word ptr[BP - 14],di
  je @l1
  inc byte ptr cs:InterruptRecs[CountOfs+redi]
@l1:
  db Op32; pop di

  push si
  db Op32; cmp word ptr[BP - 12],si
  je @l2
  inc byte ptr cs:InterruptRecs[CountOfs+resi]
@l2:
  db Op32; pop si

  push dx
  db Op32; cmp word ptr[BP - 10],dx
  je @l3
  inc byte ptr cs:InterruptRecs[CountOfs+redx]
@l3:
  db Op32; pop dx

  push cx
  db Op32; cmp word ptr[BP - 8],cx
  je @l4
  inc byte ptr cs:InterruptRecs[CountOfs+recx]
@l4:
  db Op32; pop cx

  push bx
  db Op32; cmp word ptr[BP - 6],bx
  je @l5
  inc byte ptr cs:InterruptRecs[CountOfs+rebx]
@l5:
  db Op32; pop bx

  push ax
  db Op32; cmp word ptr[BP - 4],ax
  je @l6
  inc byte ptr cs:InterruptRecs[CountOfs+reax]
@l6:
  db Op32; pop ax

  pop bp
  iret
end;

procedure FixupISR; far; assembler;
{ This ISR saves and restores the high word of EAX,EBX,ECX,EDX,ESI, and EDI.
  Use it to fix up a bad handler.  Uses 26 bytes of stack space. }
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
  db Op32; push si
  pop si
  db Op32; push di
  pop di
  db Op32; push bp
  pop bp
  dw PushFS
  dw PushGS

  push word ptr [bp+6]           { old flags }
  mov bp,[bp]                    { and restore BP }
  call dword ptr cs:InterruptRecs[PtrOfs]
  push ax
  pushf
  pop ax                     { Now flags are in AX }

  push bp                    { Save the ISR's BP }
  mov bp,sp                  { Set up our frame again }
  add bp,22
  mov word ptr [bp+6],ax      { This way flags on our return will be
                                   as the old ISR returned them. }
  pop ax
  mov word ptr [bp],ax        { as will BP }

  pop ax
  dw PopGS
  dw PopFS
  push bp
  db Op32; pop bp
  push di
  db Op32; pop di
  push si
  db Op32; pop si
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

procedure Marker; assembler;
asm
end;

var
  IntRecs : PIntRecArray;
  int,irq : byte;

procedure InstallHandler;
var
  addr : pointer;
  segmod : byte;
begin
  GetIntVec(int,IntRecs^[irq].OldIsr);
  segmod := 15-irq;
{$ifdef counter}
  Addr := Ptr(Seg(CountingISR)-segmod, Ofs(CountingISR)+16*segmod);
{$else}
  Addr := Ptr(Seg(FixupISR)-segmod, Ofs(FixupISR)+16*segmod);
{$endif}
  SetIntVec(int,Addr);
end;

const
  sigstart : longint = $73696854; { "This" }

var
  paras : word;
  envseg : word;
begin
{$ifdef counter}
  MemL[Seg(Signature):Ofs(Signature)] := sigstart;  { Complete the signature }
  write('TrashDet - Detects');
{$else}
  write('TrashFix - Corrects');
{$endif}
  writeln(' trashing of extended registers during interrupt servicing');
  writeln('Written by D.J. Murdoch, January, 1993, for the public domain');

  if test8086 < 2 then
    writeln('Program only works (and is only needed) on a 386 or higher.')
  else
  begin
    SwapVectors;

    IntRecs := Ptr(PrefixSeg,$80);
    FillChar(IntRecs^,sizeof(IntRecs^),0);

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

    { Release the environment }
    envseg := memw[Prefixseg:$2C];
    asm
      mov ah,$49
      mov es,envseg
      int $21
    end;

    paras := (ofs(Marker) + 15) div 16 + 16;

    write('Going resident...');
{$ifdef counter}
    writeln('run TrashRep for report.');
{$endif}
    asm
      mov ax,$3100
      mov dx,paras
      int $21
    end;
    writeln('Failed!!');
  end;
end.