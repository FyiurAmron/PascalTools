unit nametype;
{$I SWITCHES.INC}
{ Unit of type/const definitions for namelist unit }

interface
type

  tbyteset = set of byte;

{$IFDEF UNIT60}
  type_def_ptr = ^type_def_rec;
  type_def_rec = record
    type_type : byte;
    other_byte : byte;
    size : word;
    base_type : word;
    case integer of
    1 : ( element_ofs,element_unit,index_ofs,index_unit: word );
    2 : ( hash_ofs, first_ofs :word;
  {3}     parent_ofs, parent_unit, vmt_size :word;
  {3}     handle,w10,self_type_ofs : word );
    7 : ( base_ofs,base_unit:word );
    6 : ( return_ofs,return_unit,num_args:word );
    8 : ( target_ofs,target_unit:word );
   15 : ( lower,upper : longint;
          type_ofs,type_unit:word
        );
   -1 : ( who_knows : array[3..8] of word
        );
  end;
{$ELSE}
  { BP 7.0 }
  type_def_ptr = ^type_def_rec;
  type_def_rec = record
    type_type : byte;
    other_byte : byte;
    size : word;
    owner : word;
    base_type : word;
    case integer of
    1 : ( element_ofs,element_unit,index_ofs,index_unit: word );
    2 : ( hash_ofs, first_ofs :word;
  {3}     parent_ofs, parent_unit, vmt_size :word;
  {3}     handle,w10,self_type_ofs,previous_object_def : word );
    7 : ( base_ofs,base_unit:word );
    6 : ( return_ofs,return_unit,num_args:word );
    8 : ( target_ofs,target_unit:word );
   15 : ( lower,upper : longint;
          type_ofs,type_unit:word
        );
   -1 : ( who_knows : array[3..8] of word
        );
  end;
{$ENDIF}

  type_info_ptr = ^type_info_rec;
  type_info_rec = record
    type_def_ofs,type_unit : word;
  end;

  var_flags = set of (const_flag,      { initialized data }
                      local,           { on the stack     }
                      referenced,      { var parameter    }
                      field,           { field of a record or object }
                      absolute,        { declared absolute something else }
                      argument,        { an argument to the func/proc }
                      const_arg,       { constant argument }
                      v128);

  var_info_ptr = ^var_info_rec;
  var_info_rec = record
    flags : var_flags;
    offset,  { within the appropriate section }
    in_unit, { either unit number if absolute, or data block number }
{$IFNDEF UNIT60}
    next_field, { next fiels in record etc. }
{$ENDIF}
    type_def_ofs,type_unit : word;
  end;

  const_info_ptr = ^const_info_rec;
  const_info_rec = record
    type_def_ofs,type_unit : word;
    case integer of
    -1: (allval:byte);
    0:  (intval:longint);
    1:  (realval:real);    { never used? }
    2:  (stringval:string);
    3:  (extendval:extended);
    4:  (boolval:boolean);
    5:  (charval:char);
    6:  (ptrval:pointer);
    7:  (setval:tbyteset);
    end;

  arg_ptr = ^arg_rec;
  arg_rec = record
    type_def_ofs,type_unit : word;
    flags : var_flags;
  end;

  func_type_ptr = ^func_type_rec;
  func_type_rec = record
    type_def_ofs,type_unit,num_args : word;
  end;

  code_flags = set of (far_entry,inline_code,interrupt,external_code,method,construct,
                       destruct,assembler);
{$IFDEF UNIT60}
  obj_flags  = set of (exported,windows_frame,from_dll,by_name,
                       dynamic,local_code,f40,f80);
{$ELSE}
  obj_flags  = set of (exported,windows_frame,dynamic,not_from_dll,
                       f10,f20,f40,f80);
{$ENDIF}
  func_info_ptr = ^func_info_rec;
  func_info_rec = record
    code_type:code_flags;
    obj_type :obj_flags;
    entry_ofs,parent_ofs,local_hash,vmt_entry,
{$IFNDEF UNIT60}
    w4,w5,w6,
    next_method:word;
{$ELSE}
    next_method,w6,w7:word;
{$ENDIF}
    func_type : func_type_rec;
  end;

  system_info_ptr = ^system_info_rec;
  system_info_rec = record
    addr_ofs, flags : byte;
  end;


const
  record_id   =  2;
  object_id   =  3;
  objpriv_id  =  4;
{$IFDEF UNIT60}
  const_id     = 80;
  type_id      = 81;
  var_id       = 82;
  proc_id      = 83;
  sys_proc_id  = 84;
  sys_fn_id    = 85;
  sys_new_id   = 86;
  sys_port_id  = 87;
  sys_mem_id   = 88;
  unit_id      = 89;
{$ELSE}
  {BP 7.0}
  const_id     = $4f;
  type_id      = $50;
  var_id       = $51;
  proc_id      = $52;
  unit_id      = $53;

  sys_proc_id  = $56;
  sys_fn_id    = $57;
  sys_new_id   = $58;
  sys_port_id  = $59;
  sys_mem_id   = $5a;
  sys_openstr_id = $5b;
{$ENDIF}
  init_id     = 128;   { Just hope that these haven't already been taken! }
  uses_id     = 129;
  local_id    = 130;
  referenced_id = 131;
  refconst_id = 132;

var
  known_types : tbyteset;

  dump_types  : tbyteset;

implementation

begin
  known_types :=   [var_id,unit_id,const_id,type_id,proc_id,
                    sys_proc_id,sys_fn_id,sys_mem_id,sys_port_id,
                    sys_new_id
{$IFNDEF UNIT60}
                    ,sys_openstr_id
{$ENDIF}
                    ];

  dump_types  :=   [0..255] - known_types;
end.
