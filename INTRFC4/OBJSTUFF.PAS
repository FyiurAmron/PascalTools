unit objstuff;
{ These are the object oriented routines }

interface

uses
  util,globals,hash;

procedure print_obj_list;
procedure print_obj(obj:obj_ptr);
procedure write_type_def(def:type_def_ptr);
procedure write_type_info(name:string; info:type_info_ptr);
function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
procedure write_var_type(type_unit,type_def_ofs:word);
procedure write_var_info(name:string; info:var_info_ptr);
procedure write_args(info:func_info_ptr);
procedure write_func_info(name:string; info:func_info_ptr);
procedure write_proc_info(name:string; info:func_info_ptr);
procedure write_const_info(name:string; info:const_info_ptr);

implementation

procedure write_type_def(def:type_def_ptr);
var
  i : integer;
  l : longint;
  hash_table : hash_ptr;
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
            hash_table := add_offset(buffer,table_ofs);

            build_list(field_list,buffer,hash_table);

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
      4 : write('built-in text file');    {Text}
      5 : begin                  {Set}
            write('set of ');
            write_var_type(base_unit,base_ofs);
          end;
      6 : begin                  {Pointer}
            write('^',string(add_offset(def,16)^));
          end;

      7 : begin                  {String}
            write('string[',size-1,']');
            {N.B. actually record is like array of char, but "string" with
                  no length is different.}
          end;
      8 : write('built-in 8087 type');    {8087}
      9 : write('built-in 6 byte real');  {Real}
     10 : begin                  {Range}
            write(lower,'..',upper);
          end;
     11 : write('built-in boolean');
     12 : write('built-in char');
     13 : begin                  {Enumeration}
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

procedure write_type_info(name:string; info:type_info_ptr);
begin
  if (last_kind <> record_id) and (last_kind <> type_id) then
  begin
    writeln('type');
    last_kind := type_id;
  end;
  write(^I,name,'=',^I);
  with info^,unit_list[info^.type_unit]^ do
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
         and (obj_info^.type_unit = 64) then
      begin
        find_type := obj;
        exit;
      end;
      current := current^.next;
    end;
    find_type := nil;
  end;
end;

procedure write_var_type(type_unit,type_def_ofs:word);
var
  type_obj : obj_ptr;
begin
  with unit_list[type_unit]^ do
  begin
    if buffer <> nil then
    begin
      type_obj := find_type(unit_list[type_unit],type_def_ofs);
      if type_obj <> nil then
        write(type_obj^.name)
      else
        write_type_def(add_offset(buffer,type_def_ofs));
    end
    else
      write(name,'.ofs',type_def_ofs);
  end;
end;

procedure write_var_info(name:string; info:var_info_ptr);
begin
  with info^ do
  begin
    if last_kind <> record_id then
      case c_or_v of
        0 : begin
              if last_kind <> var_id then
              begin
                writeln('Var');
                last_kind := var_id;
              end;
            end;

        255: if last_kind <> const_id then
             begin
               writeln('Const');
               last_kind := const_id;
             end;
        else writeln('C_or_V=',c_or_v,' ');
      end;
    write(^I,name,':',^I);
    write_var_type(type_unit,type_def_ofs);
    if c_or_v = 255 then
      write('=',^I,'?');
    write(';',^I,'{ofs ',offset);
    if in_unit > 64 then              { Records use 0; this unit is 64}
      write(' in ',unit_list[in_unit]^.name,' unit');
    writeln('}');
  end;
end;

procedure write_args(info:func_info_ptr);
var
  i:word;
  arg : arg_ptr;
begin
  writeln('(');
  arg := add_offset(info,sizeof(func_info_rec));
  for i:=1 to info^.num_args do
  begin
    with arg^ do
    begin
      write(^I);
      case var_or_val of
      0 : write('    ');
      1 : write('var ');
      else
        writeln('var_or_val=',var_or_val,', not 0 or 1!');
      end;
      write(name,':',^I);
      write_var_type(type_unit,type_def_ofs);
      writeln(';');
    end;
    arg := add_offset(arg,6+length(arg^.name));
  end;
  write(^I,^I,')');
end;

procedure write_func_info(name:string; info:func_info_ptr);
begin
  write('function',^I,name);
  if info^.num_args > 0 then
    write_args(info);
  write(':',^I);
  write_var_type(info^.type_unit,info^.type_def_ofs);
  writeln(';');
end;

procedure write_proc_info(name:string; info:func_info_ptr);
begin
  write('procedure',^I,name);
  if info^.num_args > 0 then
    write_args(info);
  writeln(';');
end;

procedure write_const_info(name:string; info:const_info_ptr);
var
  type_obj : obj_ptr;
begin
  if (last_kind <> record_id) and (last_kind <> const_id) then
  begin
    writeln('Const');
    last_kind := const_id;
  end;
  write(^I,name,'=',^I);
  with info^,unit_list[type_unit]^ do
  begin
    if buffer <> nil then
    begin
      type_obj := find_type(unit_list[type_unit],type_def_ofs);
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
        if (type_def_ofs = 164)   { Risky to fix this, but can't see any
                                  other way to detect string constants }
           and (unit_list[type_unit]^.name = 'SYSTEM') then
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

procedure print_obj(obj:obj_ptr);
var
  j:word;
  obj_info : ^byte_array;
  new_entry : list_ptr;
  info_len,info_ofs : word;
begin
  info_ofs := 3+length(obj^.name);
  obj_info := add_offset(obj,info_ofs);

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

     sys_proc_id : begin
                 writeln('built-in procedure ',word_at(obj_info^[1]),
                         ^I,obj^.name,';');
                 last_kind := sys_proc_id;
               end;

     sys_fn_id : begin
                 writeln('built-in function ',word_at(obj_info^[1]),
                         ^I,obj^.name,';');
                 last_kind := sys_fn_id;
               end;

     sys_port_id : begin
                   writeln('Port array',^I,obj^.name,';');
                   last_kind := sys_port_id;
                 end;

     sys_mem_id : begin
                    writeln('Memory array',^I,obj^.name,';');
                    last_kind := sys_mem_id;
                  end;

     unit_id :   if unit_ptr(obj_info)^.unit_number = 64 then
                 begin
                   writeln('Unit',^I,obj^.name,';');
                   last_kind := init_id;
                 end
                 else
                   case last_kind of
                   unit_id : writeln(^I,',',obj^.name);
                   else      begin
                               writeln('Uses',^I,obj^.name);
                               last_kind := unit_id;
                             end;
                   end;
     else
               begin
                 writeln('Unknown kind ',obj_info^[0],^I,obj^.name);
                 for j:=0 to 15 do
                   write(obj_info^[j]:5);
                 writeln;
                 last_kind := obj_info^[0];
               end;
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