unit util;
{$I SWITCHES.INC}
interface
  uses dos;

  var
    last_file_size : longint;

  function minw(w1,w2:word):word;

  function add_only_offset(p:pointer; add:word):pointer;

  function upper(const s:string):string;

  function ptr_diff(p1,p2:pointer):longint;

  procedure read_file(filename: string;var buffer:pointer;
                     offset:longint; size:word);
  { Attempts to read a file into buffer; returns nil if there was a problem }

  function roundup(n,r:word):word;

  { error routines }

  procedure PrintStrErr(const S: String);

  procedure WriteError(const S:string);

  procedure WriteOutput(const S:string);

  procedure HaltError(const S:string);

  procedure ErrorStatus;

implementation

uses Memory;

function minw(w1,w2:word):word;
begin
  if w1<w2 then
    minw := w1
  else
    minw := w2;
end;

function add_only_offset(p:pointer; add:word):pointer;
begin
  add_only_offset := ptr(seg(p^),ofs(p^)+add);
end;

function upper(const s:string):string;
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
  if seg(p1^)<>seg(p2^) then
    HaltError('Internal error : util.ptr_diff');
  ptr_diff :=  ofs(p1^) - ofs(p2^);
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
  if size=0 then
    exit;
  if size > 65521 then
  begin
    WriteError('File size too large.  File not read.');
    exit;
  end;
  if maxavail < size then
  begin
    WriteError('Out of memory.  File '+filename+' not read.');
    exit;
  end;
  buffer:=MemAllocSeg(size);
  seek(f,offset);
  {$I-}
  blockread(f,buffer^,try_size,size);
  {$I+}
  if size<>try_size then
  begin
    freemem(buffer,try_size);
    buffer:=nil;
  end;
  close(f);
end;

function roundup(n,r:word):word;
begin
  roundup := r*((n+r-1) div r);
end;

function IsDevice(var F:text):Boolean; assembler;
asm
   les   di,F
   mov   bx,TextRec(ES:[DI]).Handle
   mov   ax,4400h
   int   21h
   xor   ax,ax
   and   dx,0080h
   je    @@0
   inc   ax
@@0:
end;

procedure PrintStrErr(const S: String); assembler;
asm
	PUSH	DS
        LDS	SI,S
	CLD
	LODSB
	XOR	AH,AH
        XCHG	AX,CX
        MOV	AH,40H
        MOV	BX,1
        MOV	DX,SI
        INT	21H
        POP	DS
end;

procedure WriteOutput(const S:string);
begin
  Writeln(output,S);
  if not IsDevice(output) then
    PrintStrErr(S+#13#10);
end;

procedure HaltError(const S:string);
begin
  WriteOutput(S);
  WriteOutput('Halting.');
  Halt;
end;

const Errors:longint=0;

procedure WriteError(const S:string);
begin
  WriteOutput(S);
  Inc(Errors);
end;

procedure ErrorStatus;
var S:string;
begin
  if Errors<>0 then
  begin
    Str(Errors,S);
    WriteOutput('');
    WriteOutput(' Errors :'+S);
  end;
end;

end.


