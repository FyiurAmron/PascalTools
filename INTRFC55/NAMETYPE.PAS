unit nametype;

{ Unit of type/const definitions for namelist unit }

interface
type
  type_def_ptr = ^type_def_rec;
  type_def_rec = record
    type_type : byte;
    other_byte : byte;
    size : word;
    case integer of
    1 : ( element_ofs,element_unit,index_ofs,index_unit: word );
    2 : ( hash_ofs, first_ofs :word;
  {3}     parent_ofs, parent_unit, vmt_size :word;
  {3}     handle,w7,self_type_ofs : word );
    7 : ( base_ofs,base_unit:word );
    6 : ( return_ofs,return_unit,num_args:word );
    8 : ( target_ofs,target_unit:word );
   15 : ( lower,upper : longint;
          type_ofs,type_unit:word
        );
   -1 : ( who_knows : array[3..8] of word
        );
  end;

  type_info_ptr = ^type_info_rec;
  type_info_rec = record
    type_def_ofs,type_unit : word;
  end;

  var_info_ptr = ^var_info_rec;
  var_info_rec = record
    c_or_v:byte;  { 0 = var, 1 = typed const }
    offset,  { within the appropriate section }
    in_unit, { either unit number if absolute, or data block number }
    type_def_ofs,type_unit : word;
  end;

  const_info_ptr = ^const_info_rec;
  const_info_rec = record
    type_def_ofs,type_unit : word;
    case integer of
    0:  (intval:longint);
    1:  (realval:real);    { never used? }
    2:  (stringval:string);
    3:  (extendval:extended);
    4:  (boolval:boolean);
    end;

  arg_ptr = ^arg_rec;
  arg_rec = record
    type_def_ofs,type_unit : word;
    var_or_val : byte;    {  2=by value, 6=by reference, i.e. var  }
  end;

  func_type_ptr = ^func_type_rec;
  func_type_rec = record
    type_def_ofs,type_unit,num_args : word;
  end;

  code_flags = set of (far_entry,inline_code,f4,external_code,method,construct,
                       destruct,f128);

  func_info_ptr = ^func_info_rec;
  func_info_rec = record
    code_type:code_flags;
    entry_ofs,parent_ofs,local_hash,vmt_entry,next_method,w6,w7:word;
    func_type : func_type_rec;
  end;


const
  record_id   =  2;
  object_id   =  3;
  const_id    = 80;
  type_id     = 81;
  var_id      = 82;
  proc_id     = 83;
  sys_proc_id = 84;
  sys_fn_id   = 85;
  sys_new_id  = 86;
  sys_port_id = 87;
  sys_mem_id  = 88;
  unit_id     = 89;
  init_id     = 128;   { Just hope that these haven't already been taken! }
  uses_id     = 129;
  local_id    = 130;
  referenced_id = 131;

implementation
end.