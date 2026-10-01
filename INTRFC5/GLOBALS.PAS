unit globals;

interface

type
  header_ptr = ^header_rec;
  header_rec = record
    file_id: array[0..3] of char; { 0-3 }
    i4,                           { 4-5 }
    i6,                           { 6-7 }
    ofs_this_unit,                { 8-9 }
    ofs_hashtable,                { A-B }
    ofs_3,                        { C-D }
    ofs_storage_req,              { E-F }
    ofs_5,                        {10-11}
    ofs_6,                        {12-13}
    ofs_src_name,                 {14-15}
    ofs_line_nums,                {16-17}
    sym_size,                     {18-19}
    code_size,                    {1A-1B}
    reloc_size,                   {1C-1D}
    const_size,                   {1E-1F}
    var_size,                     {20-21}
    ofs_localhash:word;           {22-23}
    float_flag:word;              {24-25}    { 0=N-, 1=N+ }
    other: array[$26 div 2..$3F div 2] of word; {26-3F}
  end;

  word_array_ptr = ^word_array;
  word_array=array[0..32760] of word;
  byte_array_ptr = ^byte_array;
  byte_array=array[0..65520] of byte;

  hash_ptr = ^hash_rec;
  hash_rec = record
    byte_len : word;
    table    : word_array;
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
    2 : ( first_ofs : word;       {  After each entry is a pointer to the next }
          hash_table : hash_rec );
  3,7 : ( base_ofs,base_unit:word );
  5,6 : ( return_ofs,return_unit,num_args:word );
    8 : ( target_ofs,target_unit:word;
          target_name:string );
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
    id,
    c_or_v:byte;  { 0 = var, 1 = typed const }
    offset,  { within the appropriate section }
    in_unit,
    type_def_ofs,type_unit : word;
  end;

  func_info_ptr = ^func_info_rec;
  func_info_rec = record
    id,always8:byte;
    ofs1,ofs2,local_hash,q1,q2,type_def_ofs,type_unit,num_args : word;
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
    var_or_val : byte;    {  2=by value, 6=by reference, i.e. var  }
    name:string;
  end;

  unit_ptr = ^unit_rec;
  unit_rec = record
    id:byte;
    target:word;
    q1:word;
    next_unit : word;
  end;

  unit_list_ptr = ^unit_list_rec;
  unit_list_rec = record
    name : string;
    buffer : byte_array_ptr;
    obj_list : list_ptr;
    own_record : word;
  end;

const
  record_id   =  2;
  pointer_id  =  6;
  const_id    = 81;
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
  local_id    = 130;
  referenced_id = 131;
var
  buffer,tpl_buffer : byte_array_ptr;
  tpl_size : word;
  header : ^header_rec;
  hash_table : hash_ptr;
  unit_list : array[1..255] of unit_list_ptr;
  obj_list : list_ptr;
  unitname : string;
  last_kind : byte;
  in_function : boolean;
  f:file;
  got_tpl : boolean;
  just_tpl : pointer;
  unit_size : word;
  uses_path : string;

implementation
{ just declarations! }

end.