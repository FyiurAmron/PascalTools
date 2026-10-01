program TrashRep;

{ The trash report }

function HexB(b:byte):string;
const
  hexdigit : array[0..15] of char = ('0','1','2','3','4','5','6','7',
                                     '8','9','A','B','C','D','E','F');
begin
  HexB := hexdigit[b shr 4] + hexdigit[b and $F];
end;

function HexW(w:word):string;
begin
  HexW := HexB(hi(w)) + HexB(lo(w));
end;

type
  regs = (reax,rebx,recx,redx,resi,redi,rebp,rfs,rgs);
  TIntRec = record   { This record must be exactly 16 bytes long!!! }
    oldisr : pointer;
    counts : array[regs] of byte;
    junk   : array[14..16] of byte;
  end;

  TIntRecArray = array[0..15] of TIntRec;
  PIntRecArray = ^TIntRecArray;


const
  sigstart : longint = $73696854; { "This" }
  sigend = ' is the Trash Detector!';
  intnum : array[0..15] of byte = (8,9,$A,$B,$C,$D,$E,$F,
                                  $70,$71,$72,$73,$74,$75,$76,$77);
  regname : array[regs] of string[3] = ('EAX','EBX','ECX','EDX','ESI','EDI',
                                        'EBP','FS','GS');

var
  table : PIntRecArray;
  segment : word;
  sig : pointer;
  sigrest : array[1..23] of char;
  i : integer;
  r : regs;
  found,trashed : boolean;
begin
  writeln('TrashRep - Report on trashed extended registers.');
  writeln('Written by D.J. Murdoch, January 1993, for the public domain.');
  writeln;
  found := false;
  for segment := $0 to $FFFF do
  begin
    sig := ptr(segment,256);
    if longint(sig^) = sigstart then
    begin
      sig := ptr(segment,256+4);
      move(sig^,sigrest,23);
      if sigrest = sigend then
      begin
        writeln('Trash detector found at segment ',HexW(segment));
        trashed := false;
        found := true;
        table := ptr(segment,0);
        for i:=0 to 15 do
          for r := reax to rgs do
            if table^[i].counts[r] <> 0 then
            begin
              writeln('Interrupt ',HexB(intnum[i]),' trashed register ',regname[r],' ',
                      table^[i].counts[r],' times.');
              trashed := true;
            end;
        if not trashed then
          writeln('No problems detected (yet :-).');
      end;
    end;
  end;
  if not found then
    writeln('Trash detector not found.  Run TRASHDET.');
end.
