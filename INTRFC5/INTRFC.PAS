program intrfc;
{  Prints out the information contained in a TPU file  }

uses
  util,globals,objstuff,test1,hash,dump;

procedure dump_header;
var
  i:integer;
begin
  with header^ do
  begin
    writeln('file_id:',^I,file_id);
    writeln('i4:',^I,i4);
    writeln('i6:',^I,i6);
    writeln('ofs_this_unit:',^I,ofs_this_unit);
    writeln('ofs_hashtable:',^I,ofs_hashtable);
    writeln('ofs_3:',^I,ofs_3);
    dumpbytes(add_offset(buffer,ofs_3)^,minw(ofs_storage_req-ofs_3,20));
    writeln('ofs_storage_req:',^I,ofs_storage_req);
    dumpbytes(add_offset(buffer,ofs_storage_req)^,minw(ofs_5-ofs_storage_req,20));
    writeln('ofs_5:',^I,ofs_5);
    writeln('ofs_6:',^I,ofs_6);
    writeln('ofs_src_name:',^I,ofs_src_name);
    writeln('ofs_line_nums:',^I,ofs_line_nums);
    writeln('sym_size:',^I,sym_size);
    writeln('code_size:',^I,code_size);
    writeln('reloc_size:',^I,reloc_size);
    writeln('const_size:',^I,const_size);
    writeln('var_size:',^I,var_size);
    writeln('ofs_localhash:',^I,ofs_localhash);
    writeln('float_flag:',^I,float_flag);

    for i := $26 div 2 to $3f div 2 do
      writeln('word ',i,':',^I,other[i]);
  end;
end;

var
  i,j,t:word;
  result : word;
  this_unit : obj_ptr;

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
    dump_header;

    {  Record this unit in the unit list  }
    fillchar(unit_list,sizeof(unit_list),0);
    this_unit := add_offset(buffer,header^.ofs_this_unit);
    add_unit(this_unit,add_offset(this_unit,3+length(this_unit^.name)));

{    hash_table := add_offset(buffer,header^.ofs_localhash); }
    hash_table := add_offset(buffer,header^.ofs_hashtable);

    {Build main object list}

    build_list(obj_list,buffer,hash_table);

    { Now print it }
    in_function := false;
    print_obj_list;
    release(just_tpl);
  until false;
end.