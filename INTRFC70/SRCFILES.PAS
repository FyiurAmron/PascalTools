unit srcfiles;
{$I SWITCHES.INC}

interface

uses dos,globals,util,dump,loader,head;

type
  src_file_ptr = ^src_file_rec;
  src_file_rec = record
    filetype : byte;
    w1 : word;
    packed_date : longint;
    filename : string;
  end;

  src_line_ptr = ^src_line_rec;
  src_line_rec = record
    owner_ofs,
    src_ofs,
{$IFNDEF UNIT60}
    header_line,
{$ENDIF}
    entry,startline,numlines : word;
  end;

  src_lines_count_ptr = ^src_lines_count_rec;
  src_lines_count_rec = record
    w0,w1,
    count:word;
  end;

   browser_ptr = ^browser_rec;
   browser_rec = record
     ofs,
     line:word;
   end;

procedure print_src_files;
procedure print_src_lines;
procedure print_browser;

implementation

uses blocks;

function tf(w:word):string;  { Time format of a number }
var
  result : string[3];   { Use length 3 in to show errors }
begin
  str(w,result);
  if length(result) = 1 then
    tf := '0'+result
  else
    tf := result;
end;

procedure print_src_files;
const
  monthname : array[1..12] of string[9] = ('January','February',
                                            'March','April','May',
                                            'June','July','August',
                                            'September','October',
                                            'November','December');
var
  thisfile : src_file_ptr;
  ofs : word;
  dt : datetime;
begin
  writeln;
  writeln('Source File Records');
  ofs := header^.ofs_src_name;
{$IFDEF UNIT60}
  while ofs < header^.ofs_line_lengths do
{$ELSE}
  while ofs < header^.ofs_line_count do
{$ENDIF}
  begin
    thisfile := add_only_offset(buffer,ofs);
    with thisfile^ do
    begin
      case filetype of
      3 : write('Includes ');
      4 : write('Main src ');
      5 : write('Links to ');
      6 : write('Resource ');
      else
          WriteError('Unknown file type '+DecWord(filetype)+' ');
      end;
      write(filename);
      if packed_date <> 0 then
      begin
        unpacktime(packed_date,dt);
        with dt do
          write(' ':(15-length(filename)),tf(hour),':',tf(min),':',tf(sec),' ',monthname[month],' ',day,', ',year);
      end;
      if w1 <> 0 then
        WriteError(' unknown w1 = '+HexWord(w1));
      writeln;
      inc(ofs,sizeof(src_file_rec)-255+length(filename));
    end;
  end;
end;

procedure print_src_lines;
var
  ofs : word;
  line,i,codeofs : word;
  thisrec : src_line_ptr;
  obj : obj_ptr;
  bytes_per_line : byte_array_ptr;
  name : string;
  src_file : src_file_ptr;
  column : byte;
  src_lines_count: src_lines_count_ptr;
begin
  writeln;
{$IFNDEF UNIT60}
  src_lines_count := add_only_offset(buffer,header^.ofs_line_count);
  writeln('Total lines: ',src_lines_count^.Count);
  if src_lines_count^.w0<>0 then
    WriteError('Count lines w0<>0');
  if src_lines_count^.w1<>0 then
    WriteError('Count lines w1<>0');
  writeln;
{$ENDIF}
  writeln('Source Line Numbers');
  column := 1;
  ofs := header^.ofs_line_lengths;
  if ofs = header^.sym_size then
    writeln('(none)')
  else
  begin
    writeln;
    while ofs < header^.sym_size do
    begin
      thisrec := add_only_offset(buffer,ofs);
      with thisrec^ do
      begin
        if owner_ofs <> 0 then
        begin
          obj := add_only_offset(buffer,owner_ofs);
          name := obj^.name;
        end
        else
          name := 'initialization code';
        src_file := add_only_offset(buffer,header^.ofs_src_name+src_ofs);
        if (owner_ofs=0) and (src_file^.filetype=3) then
          writeln('Line number offsets in ',src_file^.filename)
        else
          writeln('Line number offsets for ',name,' in ',src_file^.filename);
        bytes_per_line := add_only_offset(thisrec,sizeof(src_line_rec));
{$IFNDEF UNIT60}
        write(header_line:6,':Head');
        column := 1;
{$ELSE}
        column := 0;
{$ENDIF}
        line := 0;
        i := 0;
        codeofs := entry;
        while line < numlines do
        begin
          if bytes_per_line^[i] > 0 then
          begin
            write(startline+line:6,':',hexword(codeofs):4);
            inc(column);
            if column = 7 then
            begin
              column := 0;
              writeln;
            end;
            if bytes_per_line^[i] >= $80 then
            begin
              inc(codeofs,$100*(bytes_per_line^[i]-$80)
                               +bytes_per_line^[i+1]);
              inc(i);
            end
            else
              inc(codeofs,bytes_per_line^[i]);
          end;
          inc(line);
          inc(i);
        end;
        inc(ofs,sizeof(thisrec^)+i);
      end;
      if column <> 0 then
        writeln;
    end;
  end;
end;
procedure print_browser;
var
  br_item:browser_ptr;
  i,i2,line:word;
  obj:obj_ptr;
  base,ofs,limit:word;
  block : unit_block_ptr;
  buf : byte_array_ptr;
  unit_ptr:unit_list_ptr;
begin
{$IFNDEF UNIT60}
  writeln;
  writeln('Browser information');
  if header^.browser_size = 0 then
  begin
    writeln('(none)');
    exit;
  end;
  i:=0;
  line:=0;
  write('    Line Declared symbols');
  while i<header^.br_defs_end do
  begin
    br_item:=add_only_offset(browser_buf,i);
    if br_item^.line<>line then
    begin
      Writeln;
      line:=br_item^.line;
      Write(line:8);
    end;
    obj:=add_only_offset(buffer,br_item^.ofs);
    write(' ',obj^.name);
    inc(i,sizeof(br_item^));
  end;
  writeln;
  ofs := 0;
  base := header^.ofs_unit_list;
  limit := header^.ofs_src_name;
  i2:=0;
  while base+ofs < limit do
  begin
    block := add_only_offset(buffer,base+ofs);
    with block^ do
    begin
      Writeln;
      Write('    Line Referenced symbols from unit ',name);
      unit_ptr:=get_unit_by_name(name);
      if (unit_ptr<>nil) and (unit_ptr^.buffer<>nil) then
      begin
        buf:=unit_ptr^.buffer;
        i:=0;
        line:=0;
        while i<refcount do
        begin
          br_item:=add_only_offset(browser_buf,i+i2+header^.br_defs_end);
          if br_item^.line<>line then
          begin
            Writeln;
            line:=br_item^.line;
            Write(line:8);
          end;
          obj:=add_only_offset(buf,br_item^.ofs);
          write(' ',obj^.name);
          inc(i,sizeof(br_item^));
        end;
      end;
      Inc(i2,refcount);
      Inc(ofs,5 + length(name));
      writeln;
    end;
  end;
{$ENDIF}
end;


end.
