program intrfc;
{  Prints out the information contained in a TPU file  }

uses
  util,globals,objstuff,test1,hash;

var
  i,j,t:word;
  result : word;

begin
  writeln('INTRFC version 1.1.  Written by D.J. Murdoch.');
  writeln('Hit break when done.');
  if paramcount > 0 then
    uses_path := paramstr(1)
  else
    uses_path := '.\';

  if uses_path[length(uses_path)] <> '\' then
    uses_path := uses_path + '\';

  tpl_size := read_file('turbo.tpl',pointer(tpl_buffer));
  if tpl_buffer = nil then
    tpl_size := read_file(uses_path+'turbo.tpl',pointer(tpl_buffer));
  if tpl_buffer <> nil then
    got_tpl := true
  else
  begin
    got_tpl := false;
    writeln('Warning:  TURBO.TPL not found.');
  end;

  repeat
    mark(just_tpl);
    repeat
      write('Enter filename (without .TPU): ');
      readln(unitname);
      unit_size := read_file(unitname+'.tpu',pointer(buffer));
    until buffer <> nil;

    header := pointer(buffer);
    heapptr := add_offset(buffer,header^.sym_size); { release all but symbols }
    hash_table := add_offset(buffer,header^.ofs_hashtable);

    {Build main object list}

    build_list(obj_list,buffer,hash_table);

    new(unit_list[64]);
    for i:=65 to 255 do
      unit_list[i] := nil;

    unit_list[64]^.name := unitname;
    unit_list[64]^.buffer := buffer;
    unit_list[64]^.obj_list := obj_list;

    { Now print it }
    print_obj_list;
    release(just_tpl);
  until false;
end.