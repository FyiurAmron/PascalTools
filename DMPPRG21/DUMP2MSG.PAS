program Dump2Msg;
{ Message filter for use with DUMPPROG in the Borland Pascal IDE
  (and possibly the BC IDE, but I haven't tried it).  Suggested
  tool menu command line:

   $CAP MSG(dump2msg)               necessary to invoke filter
   $SAVE PROMPT                     so that Dumpprog doesn't see stale
                                    source
   $PROMPT                          Optional; lets you fiddle with the
                                    args to Dumpprog
   $EXENAME                         The current program
   $CURTOKEN                        Selects the token the cursor is on
   $EDNAME#$LINE                    Selects the source line the cursor
                                    is on.

  These should all be put onto one big line; be sure to compile with the
  Linker Options set for a detailed .MAP file.
}


{$I-,S-}

var
  LineNo, E: Word;
  Line: String;
  InputBuffer: array[0..4095] of Char;
  OutputBuffer: array[0..4095] of Char;

procedure WriteHeader;
begin
  Write('BI#PIP#OK'#0);
end;

procedure WriteNewFile(const FileName: String);
begin
  Write(#0, FileName, #0);
end;

procedure WriteMessage(Line, Col: Word; const Message: String);
begin
  Write(#1, Chr(Lo(Line)), Chr(Hi(Line)), Chr(Lo(Col)), Chr(Hi(Col)),
    Message, #0);
end;

procedure WriteEnd;
begin

  Write(#127);
end;

function TrimLeft(S:String): String;
var
  i: Integer;
  n: String;
begin
  i := 1;
  while (i <= Length(s)) and (s[i] = #32) do Inc(i);
  if i <= Length(s) then
  begin
    Move(s[i], n[1], Length(s) - i + 1);
    n[0] := Char(Length(s) - i + 1);
  end
  else n[0] := #0;
  TrimLeft := n;
end;

var
  hashpos,colonpos : word;
  filename,newname : string;
begin
  SetTextBuf(Input, InputBuffer);
  SetTextBuf(Output, OutputBuffer);
  WriteHeader;
  if not Eof then
  begin
    Readln(line);
    WriteMessage(0,0, '  '+TrimLeft(Line)); { Copies banner }
  end;

  while (not Eof) and (pos('Selection',line) = 0) do
    ReadLn(line);                           { Skips other header lines }
  if not Eof then
    WriteMessage(0,0, '  '+TrimLeft(Line)); { Writes selection line }

  filename := '';
  LineNo   := 0;

  while not Eof do
  begin
    ReadLn(Line);
    if Line <> '' then
    begin
      hashpos := pos('#',line);
      colonpos := Pos(':', Line);
      if (hashpos > 0) and (colonpos > hashpos) then
      begin
        newname := Copy(Line, 1, hashpos-1);
        if newname <> filename then
        begin
          filename := newname;
          WriteNewFile(Copy(Line, 1, hashpos-1));
        end;
        Val(Copy(Line,Hashpos+1,colonpos-hashpos-1), LineNo, E);
        if E = 0 then WriteMessage(LineNo, 1, TrimLeft(Copy(Line,colonpos+1,132)));
      end
      else
        WriteMessage(LineNo, 1, '  '+TrimLeft(Line));
    end;
  end;
  WriteEnd;
end.
