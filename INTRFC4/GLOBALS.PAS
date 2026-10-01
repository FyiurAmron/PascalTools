unit globals;

interface

type
  header_ptr = ^header_rec;
  header_rec = record
    file_id: array[0..3] of char; { 0-3 }
    i1,                           { 4-5 }
    i2,                           { 6-7 }
    ofs_this_unit,                { 8-9 }
    ofs_hashtable,                { A-B }
    i3,                           { C-D }
    i4,                           { E-F }
    ofs_srcfile,                  {10-11}
    i5,                           {12-13}
    sym_size,                     {14-15}
    code_size,                    {16-17}
    reloc_size,                   {18-19}
    const_size,                   {1A-1B}
    var_size                      {1C-1D}
      :word;
  end;

  obj_ptr = ^obj_rec;
  obj_rec = record
    next_obj: word;  { in case of a hash collision }
    name: string;
  end;

  list_ptr = ^list_rec;
  list_rec = record
    offset : word;
    hash : word;
    next : list_ptr;
  end;

  type_def_ptr = ^type_def_rec;
  type_def_rec = record
    type_type : byte;
    other_byte : byte;
    size : word;
    case integer of
    1 : ( element_ofs,element_unit,index_ofs,index_unit: word );
    2 : ( table_ofs : word;
          rec_junk : array[4..8] of word
        );
  3,5 : ( base_ofs,base_unit:word );
10,13 : ( lower,upper : longint;
          type_ofs,type_unit:word
        );
   -1 : ( who_knows : array[3..8] of word
        );
  end;

  type_info_ptr = ^type_info_rec;
  type_info_rec = record
    id:byte;
    type_def_ofs,type_unit : word;
  end;

  var_info_ptr = ^var_info_rec;
  var_info_rec = record
    id:byte;
    c_or_v,offset,in_unit,type_def_ofs,type_unit : word;
  end;

  func_info_ptr = ^func_info_rec;
  func_info_rec = record
    id:byte;
    q1,type_def_ofs,type_unit,ofs1,ofs2,num_args : word;
  end;

  const_info_ptr = ^const_info_rec;
  const_info_rec = record
    id:byte;
    type_def_ofs,type_unit : word;
    case integer of
    0:  (intval:longint);
    1:  (realval:real);
    2:  (stringval:string);
    3:  (extendval:extended);
    end;

  arg_ptr = ^arg_rec;
  arg_rec = record
    type_def_ofs,type_unit : word;
    var_or_val : byte;
    name:string;
  end;

  word_array_ptr = ^word_array;
  word_array=array[0..32760] of word;
  byte_array_ptr = ^byte_array;
  byte_array=array[0..65520] of byte;

  unit_ptr = ^unit_rec;
  unit_rec = record
    id:byte;
    unit_number : word;
    q1 : word;
  end;

  unit_list_ptr = ^unit_list_rec;
  unit_list_rec = record
    name : string;
    buffer : byte_array_ptr;
    obj_list : list_ptr;
  end;

  hash_ptr = ^hash_rec;
  hash_rec = record
    byte_len : word;
    table    : word_array;
  end;

const
  record_id   =  2;
  pointer_id  =  6;
  const_id = 81;
  type_id     = 82;
  var_id      = 83;
  proc_id     = 84;
  func_id     = 85;
  sys_proc_id = 86;
  sys_fn_id   = 87;
  sys_port_id = 88;
  sys_mem_id  = 89;
  unit_id     = 90;
  init_id     = 128;   { Just hope that these haven't already been taken! }
  uses_id     = 129;
var
  buffer,tpl_buffer : byte_array_ptr;
  tpl_size : word;
  header : ^header_rec;
  hash_table : hash_ptr;
  unit_list : array[64..255] of unit_list_ptr;
  obj_list : list_ptr;
  unitname : string;
  last_kind : byte;
  f:file;
  got_tpl : boolean;
  just_tpl : pointer;
  unit_size : word;
  uses_path : string;
implementation
{ just declarations! }

end.