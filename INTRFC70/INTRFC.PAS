program intrfc;
{  Prints out the information contained in a TPU file  }
{$I SWITCHES.INC}

uses
  test1,nametype,util,globals,loader,head,blocks,namelist,srcfiles,code,
        reloc,dump,params;

var
  i,j,t:word;
  result : word;
  this_unit : obj_ptr;
  tpu_size : longint;
  main_list : list_ptr;
  s:string;
begin
  WriteOutput('INTRFC version 7.00.  Written by D.J. Murdoch & M. Dadok.');

  parse_params;

  writeln('Dump of file ',unitname,unit_ext);

  S:=unitname+unit_ext;
  ReadPathFile(S,header);
  if header = nil then
  begin
    S:=tpl_name;
    ReadPathFile(S,header);
  end;
  if header = nil then
    syntax_exit('Error: can''t find unit '+unitname+unit_ext+', '+
                'TURBO.TPL, TPP.TPL or TPW.TPL.');
  dispose(header);

  loadtpl;
  num_known := 0;
  fillchar(unit_list,sizeof(unit_list),0);
  add_unit(unitname,nil);
  if not unit_list[1]^.has_symbols then
    syntax_exit('');

  buffer := unit_list[1]^.buffer;
  header := header_ptr(buffer);

  {Make this unit refer to itself}
  this_unit := add_only_offset(buffer,header^.ofs_this_unit);
  unit_ptr(add_only_offset(buffer,
           header^.ofs_this_unit+length(this_unit^.name)+4))^.target := 1;

  with header^ do
    begin
{$IFDEF UNIT60}
      code_ofs  := roundup(sym_size,16);
{$ELSE}
      browser_ofs := roundup(sym_size,16);
      code_ofs  := browser_ofs + roundup(browser_size,16);
{$ENDIF}
      const_ofs := code_ofs + roundup(code_size,16);
      reloc_ofs := const_ofs + roundup(const_size,16);
      const_reloc_ofs   := reloc_ofs + roundup(reloc_size,16);
      tpu_size := longint(roundup(sym_size,16))
{$IFNDEF UNIT60}
                 +longint(roundup(browser_size,16))
{$ENDIF}
                 +longint(roundup(code_size,16))
                 +longint(roundup(const_size,16))
                 +longint(roundup(reloc_size,16))
                 +longint(roundup(const_reloc_size,16));
    end;

  hash_table := add_only_offset(buffer,header^.ofs_hashtable);
  if do_implementation in active_options then
    hash_table := add_only_offset(buffer,header^.ofs_full_hash);

  {Build main object list}

  build_list(main_list,buffer,hash_table);
  unit_list[1]^.obj_list := main_list;

  { Now print it }
  in_function := false;
  NowEnum := nil;
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
{$IFNDEF UNIT60}
  if do_browser in active_options then
  begin
    read_file(unit_list[1]^.path,pointer(browser_buf),browser_ofs,header^.browser_size);
    print_browser;
    freemem(browser_buf,header^.browser_size);
  end;
{$ENDIF}
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
    read_file(unit_list[1]^.path,pointer(reloc_buf),const_reloc_ofs,header^.const_reloc_size);
    print_reloc(const_seg);
    freemem(reloc_buf,header^.const_reloc_size);
  end;

  ErrorStatus;
end.
