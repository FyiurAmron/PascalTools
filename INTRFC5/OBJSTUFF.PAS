unit objstuff;
{ These are the object oriented routines }

interface

uses
  util,globals,hash;

procedure print_obj_list;
procedure print_obj(obj:obj_ptr);
procedure write_type_def(def:type_def_ptr);
procedure write_type_info(var name:string; info:type_info_ptr);
function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
procedure write_var_type(type_unit,type_def_ofs:word);
procedure write_var_info(var name:string; info:var_info_ptr);
procedure write_args(arg:arg_ptr; num_args:word);
procedure write_func_info(var name:string; info:func_info_ptr);
procedure write_proc_info(var name:string; info:func_info_ptr);
procedure write_const_info(var name:string; info:const_info_ptr);
procedure write_general(kind:byte; title,name,suffix:string);

implementation

const
  semicrlf = ';'+^M+^J;
  colontab = ':'+^I;

function obj_ofs(obj:pointer):word;
begin
  obj_ofs := ptr_diff(obj,buffer);
end;

procedure write_type_def(def:type_def_ptr);
var
  i : integer;
  l : longint;
  save_kind : byte;
  field_list : list_ptr;
  current : list_ptr;
  obj : obj_ptr;
begin
  with def^ do
    case type_type of
      0 : write('untyped');
      1 : begin                  {Array}
            write('array[');
            write_var_type(index_unit,index_ofs);
            write('] of ');
            write_var_type(element_unit,element_ofs);
          end;
      2 : begin                  {Record}
            save_kind := last_kind;
            last_kind := record_id;
            writeln ('Record ');

            build_list(field_list,buffer,@hash_table);

            current := field_list;
            while current^.offset < $ffff do
            begin
              obj := add_offset(buffer,current^.offset);
              write(^I);
              print_obj(obj);
              current := current^.next;
            end;

            write(^I,'end');
            last_kind := save_kind;
          end;
      3 : begin                  {File}
            write('file');
            if base_unit <> 0 then
            begin
              write(' of ');
              write_var_type(base_unit,base_ofs);
            end;
          end;
      4 : write('built-in text file');  {Text}
      5 : begin                  {procedure}
            write('procedure');
            write_args(arg_ptr(add_offset(def,10)),num_args);
          end;
      6 : begin                  {function}
            write('function');
            write_args(arg_ptr(add_offset(def,10)),num_args);
            write(':');
            write_var_type(return_unit,return_ofs);
          end;
      7 : begin                  {Set}
            write('set of ');
            write_var_type(base_unit,base_ofs);
          end;
      8 : begin                  {Pointer}
            write('^',target_name);
          end;

      9 : begin                  {String}
            write('string[',size-1,']');
            {N.B. actually record is like array of char, but "string" with
                  no length is different.}
          end;
     10 : write('built-in 8087 type');    {8087}
     11 : write('built-in 6-byte real');
     12 : begin                  {Range}
            write(lower,'..',upper);
          end;
     13 : write('built-in boolean');
     14 : write('built-in char');
     15 : begin                  {Enumeration}
            write('(');
            {  Assume following records are constant declarations  }
            obj := add_offset(def,16);
            for l:=lower to upper-1 do
            begin
              write(obj^.name,',');
              obj:=add_offset(obj,12+length(obj^.name));
            end;
            write(obj^.name,')');
          end;
     else
          begin
            writeln('Type definition of type ',type_type, 'otherbyte=',
                    other_byte,'size=',size);
            write(' junk=');
            for i:=3 to 8 do
              write(who_knows[i]:6);
            writeln;
          end;
    end;
end;

procedure write_type_info(var name:string; info:type_info_ptr);
begin
  if (last_kind <> record_id) and (last_kind <> type_id) then
  begin
    writeln('type');
    last_kind := type_id;
  end;
  write(^I,name,'=',^I);
  with info^,get_unit(info^.type_unit)^ do
  begin
    if buffer <> nil then
      write_type_def(add_offset(buffer,type_def_ofs))
    else
      write(name,'.ofs',type_def_ofs);
    writeln(';');
  end;
end;

function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
var
  current:list_ptr;
  obj : obj_ptr;
  obj_info : type_info_ptr;
begin
  with unit_rec^ do
  begin
    if obj_list = nil then
      build_list(obj_list,buffer,add_offset(buffer,header_ptr(buffer)^.ofs_hashtable));
    current := obj_list;
    while current^.offset < $ffff do
    begin
      obj := add_offset(buffer,current^.offset);
      obj_info := add_offset(obj,3+length(obj^.name));
      if     (obj_info^.id = type_id)
         and (obj_info^.type_def_ofs = def_ofs)
         and (obj_info^.type_unit = own_record) then
      begin
        find_type := obj;
        exit;
      end;
      current := current^.next;
    end;
    find_type := nil;
  end;
end;

function find_name(unit_rec:unit_list_ptr;info_ofs:word):string;
{  Unreliable way to get a name from a pointer to its info }
var
  i:word;
  name:string;
begin
  with unit_rec^ do
  begin
    for i:=info_ofs-2 downto 0 do
      if i+buffer^[i]+2 = info_ofs then
      begin
        move(buffer^[i],name[0],buffer^[i]+1);
        find_name := name;
        exit;
      end;
  end;
  find_name := '';
end;

procedure write_var_type(type_unit,type_def_ofs:word);
var
  type_obj : obj_ptr;
begin
  if type_unit > 0 then
  begin
    with get_unit(type_unit)^ do
    begin
      if buffer <> nil then
      begin
        type_obj := find_type(get_unit(type_unit),type_def_ofs);
        if type_obj <> nil then
          write(type_obj^.name)
        else
          write_type_def(add_offset(buffer,type_def_ofs));
      end
      else
        write(name,'.ofs',type_def_ofs);
    end;
  end
  else
    write('type_unit not found');
end;

procedure write_var_info(var name:string; info:var_info_ptr);
var
  orig_unit:unit_list_ptr;
begin
  with info^ do
  begin
    if last_kind <> record_id then
      case c_or_v and $FFEF of
        0 : write_general(var_id,'var',name,colontab);
        1 : write_general(const_id,'const',name,colontab);
        2 : write_general(local_id,'local var',name,colontab);
        6 : write_general(referenced_id,'referenced var',name,colontab);
        else write('C_or_V=',c_or_v,^I,name,colontab);
      end
    else
      write(^I,name,colontab);

    write_var_type(type_unit,type_def_ofs);

    if (c_or_v and $10) <> 0 then
    begin
      write(' absolute ');
      orig_unit := get_unit(in_unit);
      if orig_unit <> nil then
      begin
        if orig_unit <> unit_list[1] then
          write(orig_unit^.name,'.');
        write(find_name(orig_unit,offset));
        info := add_offset(orig_unit^.buffer,offset-1);
      end
      else
        write('?????');
    end;
  end;
  with info^ do
  begin
    if c_or_v = 1 then
      write('=',^I,'?');
    if in_function then
      write(';',^I,'{BP ofs ',integer(offset))
    else
    begin
      write(';',^I,'{ofs ',offset);
      if (in_unit <> 0) and (last_kind <> record_id) then
        writeln(' in unit ',get_unit(in_unit)^.name);
    end;
    writeln('}');
  end;
end;

procedure write_args(arg:arg_ptr;num_args:word);
var
  i:word;
begin
  writeln('(');
  for i:=1 to num_args do
  begin
    with arg^ do
    begin
      write(^I);
      case var_or_val of
      2 : write('    ');
      6 : write('var ');
      else
        writeln('var_or_val=',var_or_val,', not 2 or 6!');
      end;
      write(name,':',^I);
      write_var_type(type_unit,type_def_ofs);
      writeln(';');
    end;
    arg := add_offset(arg,6+length(arg^.name));
  end;
  write(^I,^I,')');
end;

procedure write_locals(var name:string; info:func_info_ptr);
var
  save_list : list_ptr;
  save_in_function : boolean;
begin
  if info^.local_hash = 0 then
    exit;
  save_list := obj_list;
  save_in_function := in_function;
  in_function := true;
  build_list(obj_list,buffer,add_offset(buffer,info^.local_hash));
  writeln('{ ',name,' locals begin...}');
  print_obj_list;
  writeln('{ ...',name,' locals end.}');
  writeln;
  obj_list := save_list;
  in_function := save_in_function;
end;

procedure write_func_info(var name:string; info:func_info_ptr);
begin
  write('function',^I,name);
  if info^.num_args > 0 then
    write_args(arg_ptr(add_offset(info,sizeof(func_info_rec))),
               info^.num_args);
  write(':',^I);
  write_var_type(info^.type_unit,info^.type_def_ofs);
  writeln(';');

  write_locals(name,info);
end;

procedure write_proc_info(var name:string; info:func_info_ptr);
begin
  write('procedure',^I,name);
  if info^.num_args > 0 then
    write_args(arg_ptr(add_offset(info,sizeof(func_info_rec))),
               info^.num_args);
  writeln(';');


  write_locals(name,info);
end;

procedure write_const_info(var name:string; info:const_info_ptr);
var
  type_obj : obj_ptr;
begin
  if (last_kind <> record_id) and (last_kind <> const_id) then
  begin
    writeln('Const');
    last_kind := const_id;
  end;
  write(^I,name,'=',^I);
  with info^,get_unit(type_unit)^ do
  begin
    if buffer <> nil then
    begin
      type_obj := find_type(get_unit(type_unit),type_def_ofs);
      if type_obj <> nil then
      begin
        with type_obj^ do
        begin
          if name = 'LONGINT' then
            write(intval)
          else if name = 'REAL' then
            write(realval)
{         else if name = 'EXTENDED' then  } {put this in only if compiled with}
{           write(extendval)              } { N+ option }
          else
            write(name,' value ',intval); {Don't know correct way to print}
        end;
      end
      else
      begin
        if (type_def_ofs = 134)   { Risky to fix this, but can't see any
                                  other way to detect string constants }
           and (get_unit(type_unit)^.name = 'SYSTEM') then
           write('''',stringval,'''')
        else
          write('?');
      end;
    end
    else
      write('?');
  end;
  writeln(';');
end;

procedure write_general(kind:byte; title,name,suffix:string);
begin
  if last_kind <> kind then
  begin
    writeln(title);
    last_kind := kind;
  end;
  write(^I,name,suffix);
end;

procedure print_obj(obj:obj_ptr);
var
  j:word;
  obj_info : ^byte_array;
  new_entry : list_ptr;
  info_len,info_ofs : word;
const
  known_types : set of byte = [81..90];

begin
  info_ofs := 3+length(obj^.name);
  obj_info := add_offset(obj,info_ofs);

  if obj_info^[0] in known_types then
  begin
    if obj_info^[0] = unit_id then
      add_unit(obj,unit_ptr(obj_info));

    case obj_info^[0] of
       const_id : write_const_info(obj^.name,pointer(obj_info));
       type_id : write_type_info(obj^.name,pointer(obj_info));

       var_id  : write_var_info(obj^.name,pointer(obj_info));

       proc_id : begin
                   write_proc_info(obj^.name,pointer(obj_info));
                   last_kind := proc_id;
                 end;
       func_id : begin
                   write_func_info(obj^.name,pointer(obj_info));
                   last_kind := func_id;
                 end;

       sys_proc_id : write_general(sys_proc_id,'built-in procedure',obj^.name,semicrlf);

       sys_fn_id : write_general(sys_fn_id,'built-in function',obj^.name,semicrlf);

       sys_port_id : write_general(sys_port_id,'port array',obj^.name,semicrlf);

       sys_mem_id : write_general(sys_mem_id,'memory array',obj^.name,semicrlf);

       unit_id :   if obj_ofs(obj) = header^.ofs_this_unit then
                   begin
                     writeln('Unit',^I,obj^.name,';');
                     last_kind := init_id;
                   end
                   else
                   begin
                     if last_kind = unit_id then
                       writeln(^I,',',obj^.name)
                     else
                     begin
                       writeln('Uses',^I,obj^.name);
                       last_kind := unit_id;
                     end;
                   end;

    end; {case}
  end
  else
  begin
    writeln('Unknown kind ',obj_info^[0],^I,obj^.name,' with info at ',obj_ofs(obj_info));
            ;
    for j:=0 to 15 do
      write(obj_info^[j]:5);
    writeln;
    last_kind := obj_info^[0];
  end;
end;

procedure print_obj_list;
var
  obj : obj_ptr;
  current : list_ptr;
  bytes : ^byte_array;
  j : integer;
begin
  last_kind := init_id;
  current := obj_list;
  while current^.offset < $ffff do
  begin
    obj := add_offset(buffer,current^.offset);
    print_obj(obj);
    current := current^.next;
  end;
end;

end.