unit srcfiles;

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
    entry,startline,numlines : word;
  end;

procedure print_src_files;
procedure print_src_lines;

implementation

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
  while ofs < header^.ofs_line_lengths do
  begin
    thisfile := add_offset(buffer,ofs);
    with thisfile^ do
    begin
      case filetype of
      3 : write('Includes ');
      4 : write('Main src ');
      5 : write('Links to ');
      6 : write('Resource ');
      else
          write('Unknown file type ',filetype,' ');
      end;
      write(filename);
      if packed_date <> 0 then
      begin
        unpacktime(packed_date,dt);
        with dt do
          write(' ':(15-length(filename)),tf(hour),':',tf(min),':',tf(sec),' ',monthname[month],' ',day,', ',year);
      end;
      if w1 <> 0 then
        write(' w1 = ',w1);
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
begin
  writeln;
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
      thisrec := add_offset(buffer,ofs);
      with thisrec^ do
      begin
        if owner_ofs <> 0 then
        begin
          obj := add_offset(buffer,owner_ofs);
          name := obj^.name;
        end
        else
          name := 'initialization code';
        src_file := add_offset(buffer,header^.ofs_src_name+src_ofs);
        writeln('Line number offsets for ',name,' in ',src_file^.filename);
        bytes_per_line := add_offset(thisrec,sizeof(src_line_rec));
        line := 0;
        i := 0;
        column := 0;
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

end.
