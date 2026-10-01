unit globals;

interface

type
  word_array_ptr = ^word_array;
  word_array=array[0..32760] of word;
  byte_array_ptr = ^byte_array;
  byte_array=array[0..65520] of byte;
  option = (do_header,do_src_files,do_src_lines,
             do_name_list,do_implementation,do_entry_pts,
             do_code_blocks,do_const_blocks,do_dll_blocks,
             do_var_blocks,do_unit_blocks,
             do_code,do_const,do_reloc,do_vmt,do_locals);
const
  tpl_name : string[12] = 'TURBO.TPL';
var
  buffer,tpl_buffer : byte_array_ptr;
  code_buf,const_buf,reloc_buf,vmt_buf : byte_array_ptr;
  code_ofs,const_ofs,reloc_ofs,vmt_ofs : longint;
  tpl_size : longint;
  f:file;
  got_tpl : boolean;
  just_tpl : pointer;
  unit_size : word;
  unitname,uses_path : string;
  indentation : word;

const
  active_options : set of option = [do_name_list];
  tab = ^I;
  oneindent = '  ';

procedure indent;

implementation

procedure indent;
var
  count : word;
begin
  for count := 1 to indentation do
    write(oneindent);
end;

end.
