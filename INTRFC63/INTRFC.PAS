program intrfc;
{  Prints out the information contained in a TPU file  }

uses
  test1,nametype,util,globals,loader,head,blocks,namelist,srcfiles,code,
        reloc,dump,params;

var
  i,j,t:word;
  result : word;
  this_unit : obj_ptr;
  tpu_size : longint;
  main_list : list_ptr;
begin
  writeln('INTRFC version 6.3.  Written by D.J. Murdoch.');

  parse_params;

  writeln('Dump of file ',unitname,'.TPU');

  { Try to find whether this is for TP 6.0 or TPW 1.0 so that
    we know which library to look in.  Very little of the rest of the
    code depends on this decision. }

  read_file(unitname+'.tpu',pointer(header),0,sizeof(header_rec));
  if header = nil then
    read_file('TURBO.TPL',pointer(header),0,sizeof(header_rec));
  if header = nil then
    read_file('TPW.TPL',pointer(header),0,sizeof(header_rec));
  if header = nil then
    syntax_exit('Error:  can''t find unit '+unitname+'.tpu, TURBO.TPL, or TPW.TPL.')
  else
  begin
    if windows in header^.flags then
      tpl_name := 'TPW.TPL';
    dispose(header);
  end;

  read_file(tpl_name,pointer(tpl_buffer),0,65535);
  if tpl_buffer = nil then
    read_file(uses_path+tpl_name,pointer(tpl_buffer),0,65535);
  if tpl_buffer <> nil then
  begin
    got_tpl := true;
    tpl_size := last_file_size;
  end
  else
  begin
    got_tpl := false;
    writeln('Warning:  ',tpl_name,' not found.');
  end;

  num_known := 0;
  fillchar(unit_list,sizeof(unit_list),0);
  add_unit(unitname,nil);
  if not unit_list[1]^.has_symbols then
    syntax_exit('');

  buffer := unit_list[1]^.buffer;
  header := normalize(buffer);

  {Make this unit refer to itself}
  this_unit := add_offset(buffer,header^.ofs_this_unit);
  unit_ptr(add_offset(this_unit,length(this_unit^.name)+4))^.target := 1;

  add_referenced_units;

  with header^ do
    begin
      code_ofs  := roundup(sym_size,16);
      const_ofs := code_ofs + roundup(code_size,16);
      reloc_ofs := const_ofs + roundup(const_size,16);
      vmt_ofs   := reloc_ofs + roundup(reloc_size,16);
      tpu_size := longint(roundup(sym_size,16))
                 +longint(roundup(code_size,16))
                 +longint(roundup(const_size,16))
                 +longint(roundup(reloc_size,16))
                 +longint(roundup(vmt_size,16));
    end;


  hash_table := add_offset(buffer,header^.ofs_hashtable);
  if do_implementation in active_options then
    hash_table := add_offset(buffer,header^.ofs_full_hash);

  {Build main object list}

  build_list(main_list,buffer,hash_table);
  unit_list[1]^.obj_list := main_list;

  { Now print it }
  in_function := false;
  indentation := 0;
  if do_header in active_options then
    print_header;
  if [do_name_list,do_implementation]*active_options <> [] then
    print_name_list(main_list);
  if do_src_files in active_options then
    print_src_files;
  if do_src_lines in active_options then
    print_src_lines;
  if do_entry_pts in active_options then
    print_entries;
  if do_code_blocks in active_options then
    print_code_blocks;
  if do_const_blocks in active_options then
    print_const_blocks;
  if do_var_blocks in active_options then
    print_var_blocks;
  if do_dll_blocks in active_options then
    print_dll_blocks;
  if do_unit_blocks in active_options then
    print_unit_blocks;
  if do_code in active_options then
  begin
    read_file(unit_list[1]^.path,pointer(code_buf),code_ofs,header^.code_size);
    print_dump(code_seg);
    freemem(code_buf,header^.code_size);
  end;
  if do_const in active_options then
  begin
    read_file(unit_list[1]^.path,pointer(code_buf),const_ofs,header^.const_size);
    print_dump(const_seg);
    freemem(code_buf,header^.const_size);
  end;
  if do_reloc in active_options then
  begin
    read_file(unit_list[1]^.path,pointer(reloc_buf),reloc_ofs,header^.reloc_size);
    print_reloc(code_seg);
    freemem(reloc_buf,header^.reloc_size);
  end;
  if do_vmt in active_options then
  begin
    read_file(unit_list[1]^.path,pointer(reloc_buf),vmt_ofs,header^.vmt_size);
    print_reloc(const_seg);
    freemem(reloc_buf,header^.vmt_size);
  end;
end.
