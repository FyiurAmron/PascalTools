{$N+}
unit namelist;
{ These are the routines that print the name definitions }

interface

uses
  dump,util,globals,loader,head,nametype;

var
  last_kind : byte;
  in_function : boolean;

procedure print_name_list(obj_list:list_ptr);
procedure print_obj(obj:obj_ptr);
procedure write_type_def(def:type_def_ptr);
procedure write_type_info(var name:string; obj:obj_ptr; info:type_info_ptr);
function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
procedure write_var_type(type_unit,type_def_ofs:word);
procedure write_var_info(var name:string; info:var_info_ptr);
procedure write_args(arg:arg_ptr; num_args:word);
procedure write_proc_type(var name:string; flags:code_flags; info:func_type_ptr);
procedure write_proc_info(var name:string; info:func_info_ptr);
procedure write_const_info(var name:string; info:const_info_ptr);
procedure write_system_type(var name:string; kind:byte; info:system_info_ptr);
procedure write_general(kind:byte; title,name,suffix:string);
function find_name(unit_rec:unit_list_ptr;info_ofs:word):string;
{  Unreliable way to get a name from a pointer to its info }

implementation

uses
  blocks;

const
  semicrlf = ';'+^M+^J;

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
  no_name : string;
  save_in_array : boolean;
begin
  with def^ do
  begin
    if base_type in [1,2,4,6,8,$a,$e,$f,$10,$11,$12,$13,$15,$18,$1a,$1b,
                     $21,$22,$23] then
      case base_type of
        1 : write('untyped');
        2 : write('shortint');
        4 : write('integer');
        6 : write('longint');
        8 : write('byte');
       $a : write('word');
       $e : write('single');
       $f : write('double');
      $10 : write('extended');
      $11 : write('real');
      $12 : write('boolean');
      $13 : write('char');
      $15 : write('comp');
      $18 : write('text');
      $1a : write('pointer');
      $1b : write('string');
      { TPW types }
      $21 : write('wordbool');
      $22 : write('longbool');
      $23 : write('pchar');
    end
    else
    begin
      if base_type <> 0 then
        write('{ unrecognized base type ',hexbyte(base_type),'}');
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

              build_list(field_list,buffer,add_offset(buffer,hash_ofs));

              current := field_list;
              inc(indentation,2);
              while current^.offset < $ffff do
              begin
                obj := add_offset(buffer,current^.offset);
                print_obj(obj);
                current := current^.next;
              end;
              dec(indentation);
              indent;
              dec(indentation);
              write('end');
              last_kind := save_kind;
            end;

        3 : begin                  {Object}
              save_kind := last_kind;
              last_kind := object_id;
              write ('Object');
              if parent_unit <> 0 then
              begin
                write('(');
                write_var_type(parent_unit,parent_ofs);
                write(')');
              end;
              write(tab,'{ vmt block ',hexword(handle));
              if w10 <> 0 then
                write(' w10=',hexword(w10));
              writeln('}');

              build_list(field_list,buffer,add_offset(buffer,hash_ofs));

              inc(indentation,2);
              current := field_list;
              while current^.offset < $ffff do
              begin
                obj := add_offset(buffer,current^.offset);
                print_obj(obj);
                current := current^.next;
              end;
              dec(indentation);
              indent;
              write('end');
              dec(indentation);
              last_kind := save_kind;
            end;

        4 : begin                  {File}
              write('file');
              if base_unit <> 0 then
              begin
                write(' of ');
                write_var_type(base_unit,base_ofs);
              end;
            end;
        5 : write('built-in text type');
        6 : begin                  {function/procedure}
              no_name := '';
              write_proc_type(no_name,[],func_type_ptr(addr(return_ofs)));
              writeln;
            end;
        7 : begin                  {Set}
              write('set of ');
              write_var_type(base_unit,base_ofs);
            end;
        8 : begin                  {Pointer}
              write('^');
              write_var_type(target_unit,target_ofs);
            end;

        9 : begin                  {String}
              write('string[',size-1,']');
              {N.B. actually record is like array of char, but "string" with
                    no length is different.}
            end;
       10 : write('built-in ',size,' byte 8087 type');    {8087}
       11 : write('built-in 6-byte real');
       12 : begin                  {Range}
              write(lower,'..',upper);
            end;
       13 : write('built-in boolean');
       14 : write('built-in char type');
       15 : begin                  {Enumeration or subrange}
              if (type_unit = unit_list[1]^.own_record)
                 and (type_ofs = obj_ofs(def)) then
              begin
                { Must be first definition }
                write('(');
                {  Assume following records are constant declarations  }
                obj := add_offset(def,30);
                for l:=lower to upper-1 do
                begin
                  write(obj^.name,',');
                  obj:=add_offset(obj,12+length(obj^.name));
                end;
                write(obj^.name,')');
              end
              else
              begin
                { Must be subrange }
                obj := add_offset(get_unit(type_unit)^.buffer,type_ofs);
                obj := add_offset(obj,24);
                i := 0;
                while i < def^.lower do
                begin
                  obj:=add_offset(obj,12+length(obj^.name));
                  inc(i);
                end;
                write(obj^.name);
                while i < def^.upper do
                begin
                  obj:=add_offset(obj,12+length(obj^.name));
                  inc(i);
                end;
                write('..',obj^.name);
              end;
            end;
       else
            begin
              writeln('Type definition of type ',type_type, 'otherbyte=',
                      other_byte,'size=',size);
              indent;
              write(' junk=');
              for i:=3 to 8 do
                write(who_knows[i]:6);
              writeln;
            end;
      end;
    end;
  end;
end;

procedure write_type_info(var name:string; obj:obj_ptr; info:type_info_ptr);
var
  def_obj : obj_ptr;
begin
  indent;
  if (last_kind <> record_id) and (last_kind <> type_id) then
  begin
    writeln('type');
    indent;
    last_kind := type_id;
  end;
  write(oneindent,name,'=',oneindent);
  with info^ do
    if obj = find_type(get_unit(type_unit),type_def_ofs) then
      write_type_def(add_offset(buffer,type_def_ofs))
    else
      write_var_type(type_unit,type_def_ofs);
  writeln(';');
end;

function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
var
  current:list_ptr;
  obj : obj_ptr;
  obj_info : type_info_ptr;
begin
  with unit_rec^ do
  begin
    if (obj_list = nil) and (buffer <> nil) then
      build_list(obj_list,buffer,add_offset(buffer,header_ptr(buffer)^.ofs_hashtable));
    if obj_list <> nil then
    begin
      current := obj_list;
      while current^.offset < $ffff do
      begin
        obj := add_offset(buffer,current^.offset);
        obj_info := add_offset(obj,4+length(obj^.name));
        if     (obj^.obj_type = type_id)
           and (obj_info^.type_def_ofs = def_ofs)
           and (obj_info^.type_unit = own_record) then
        begin
          find_type := obj;
          exit;
        end;
        current := current^.next;
      end;
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
    if buffer <> nil then
      for i:=info_ofs-2 downto 0 do
        if i+buffer^[i]+1 = info_ofs then
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
  unit_ptr : unit_list_ptr;
begin
  if type_unit > 0 then
  begin
    unit_ptr := get_unit(type_unit);
    with unit_ptr^ do
    begin
      if buffer <> nil then
      begin
        type_obj := find_type(unit_ptr,type_def_ofs);
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
  f : var_flags;
begin
  indent;
  with info^ do
  begin
    if not (last_kind in [object_id,objpriv_id,record_id]) then
    begin
      f := flags*[const_flag,local,referenced];
      if f = [] then
        write_general(var_id,'var',name,':'+oneindent)
      else if f = [const_flag] then
        write_general(const_id,'const',name,':'+oneindent)
      else if f = [local] then
        write_general(local_id,'local var',name,':'+oneindent)
      else if f = [local,referenced] then
        write_general(referenced_id,'referenced var',name,':'+oneindent)
      else
        write(' var flags = ',hexbyte(byte(flags)),oneindent);
      end
    else
      write(name,':',oneindent);

    write_var_type(type_unit,type_def_ofs);

    if absolute in flags then
    begin
      write(' absolute ');
      orig_unit := get_unit(in_unit);
      if orig_unit <> nil then
      begin
        if orig_unit <> unit_list[1] then
          write(orig_unit^.name,'.');
        writeln(find_name(orig_unit,offset),';');
      end
      else
        writeln('?????;');
    end
    else
    begin
      if const_flag in flags then
        write('=',oneindent,'?');
      if in_function then
        write(';',tab,'{BP ofs ',integer(offset))
      else
      begin
        write(';',tab,'{ofs ',hexword2(offset));
        if not (last_kind in [record_id,object_id,objpriv_id]) then
          write(' in block ',hexword2(in_unit));
      end;
      writeln('}');
    end;
  end;
end;

procedure write_args(arg:arg_ptr;num_args:word);
var
  i:word;
begin
  writeln('(');
  inc(indentation);
  for i:=1 to num_args do
  begin
    with arg^ do
    begin
      indent;
      if referenced in flags then
        write('var ')
      else
        write('    ');
      if flags - [referenced] <> [local] then
      begin
        writeln('{ flags =',hexbyte(byte(flags)),' }');
        indent;
      end;
      write('arg',i,':',oneindent);
      write_var_type(type_unit,type_def_ofs);
      writeln(';');
    end;
    arg := add_offset(arg,sizeof(arg_rec));
  end;
  indent;
  write(')');
  dec(indentation);
end;

procedure write_locals(var name:string; info:func_info_ptr);
var
  obj_list : list_ptr;
  save_in_function : boolean;
begin
  if info^.local_hash = 0 then
    exit;
  save_in_function := in_function;
  in_function := true;
  build_list(obj_list,buffer,add_offset(buffer,info^.local_hash));
  inc(indentation);
  indent; writeln('{ ',name,' locals begin...}');
  print_name_list(obj_list);
  indent; writeln('{ ...',name,' locals end.}');
  writeln;
  dec(indentation);
  in_function := save_in_function;
end;


procedure write_proc_type(var name:string; flags:code_flags; info:func_type_ptr);
var
  proc : boolean;
begin
  with info^ do
  begin
    if (type_def_ofs = 0) and (type_unit = 0) then
      proc := true
    else
      proc := false;
    if construct in flags then
      write('constructor',oneindent,name)
    else if destruct in flags then
      write('destructor',oneindent,name)
    else
      if proc then
        write('procedure',oneindent,name)
      else
        write('function',oneindent,name);
    if info^.num_args > 0 then
      write_args(arg_ptr(add_offset(info,sizeof(func_type_rec))),
                 info^.num_args);
    if not proc then
    begin
      write(':',oneindent);
      write_var_type(type_unit,type_def_ofs);
    end;
  end;
  write(';');
end;

procedure write_proc_info(var name:string; info:func_info_ptr);
var
  entry_pt : entry_pt_ptr;
  code : ^word;
  i : word;
  unknown_flags : obj_flags;
begin
  indent;
  with info^ do
  begin
    write_proc_type(name,code_type,func_type_ptr(addr(func_type)));
    entry_pt := add_offset(buffer,header^.ofs_entry_pts+entry_ofs);

    if vmt_entry > 0 then
    begin
      write(' virtual');
      if dynamic in obj_type then
        write(' ',vmt_entry);
      write(';');
    end;

    if external_code in code_type then
      write(' external;');
    if assembler in code_type then
      write(' assembler;');
    if interrupt in code_type then
      write(' interrupt;');

    if exported in obj_type then
      write(' export;');
    if windows_frame in obj_type then
      write(' W+;');

    if from_dll in obj_type then
    begin
      write(' external ''',dll_name(entry_pt^.code_block),'''');
      if by_name in obj_type then
        write(' name ''',dll_name(entry_pt^.offset),'''')
      else
        write(' index ',entry_pt^.offset);
      write(';');
    end
    else
      if by_name in obj_type then
        write(' Unexpected by_name flag!');

    if local_code in obj_type then
      write(' local code;');

    unknown_flags := obj_type - [exported,windows_frame,from_dll,by_name,
                                  dynamic,local_code];
    if unknown_flags <> [] then
      write(' Unrecognized object flags: ',hexbyte(byte(unknown_flags)));
    if not (inline_code in code_type) then
    begin
      write(tab,'{ Proc ',hexword2(entry_ofs));
      if not (from_dll in obj_type) then
        write(' Entry ',hexword2(entry_pt^.code_block),':',
                            hexword(entry_pt^.offset));
      writeln('}');
    end
    else
    begin
      writeln;
      indent;
      write(' Inline(');
      code := add_offset(info,sizeof(func_info_rec)
                             +func_type.num_args*sizeof(arg_rec));
      for i:=1 to entry_ofs div 2 - 1 do
      begin
        write('$',hexbyte(hi(code^)):2,'/');
        if lo(code^) <> 0 then
          writeln('Low byte not zero!');
        code := add_offset(code,sizeof(word));
      end;
      writeln('$',hexbyte(hi(code^)):2,');');
      if lo(code^) <> 0 then
        writeln('Low byte not zero!');
    end;
    if do_locals in active_options then
      write_locals(name,info);
  end;
end;

procedure write_const_info(var name:string; info:const_info_ptr);
var
  type_obj : obj_ptr;
begin
  indent;
  if (last_kind <> record_id) and (last_kind <> const_id) then
  begin
    writeln('Const');
    indent;
    last_kind := const_id;
  end;
  write(oneindent,name,'=',oneindent);
  with info^,get_unit(type_unit)^ do
  begin
    if name = 'SYSTEM' then
    case type_def_ofs of
                { Risky to fix these, but can't see any
                                  other way to type constants }
        $a0:   write('''',stringval,'''');
        $c0:   write(extendval);
       $114:   write(intval);
       $130:   write(boolval);
       $14c:   write('''',charval,'''');

        else
          write('?');
    end
    else
      write('?');
  end;
  writeln(';');
end;

procedure write_unit_info(var name:string; info:unit_ptr; self:boolean);
begin
  indent;
  if self then
  begin
    write('Unit',oneindent,name,';');
    last_kind := init_id;
  end
  else
  begin
    if last_kind = unit_id then
      write(oneindent,',',name)
    else
    begin
      write('Uses',oneindent,name);
      last_kind := unit_id;
    end;
  end;
  with info^ do
  begin
    writeln(tab,'{ checksum = ',hexword(checksum),'}');
  end;
end;

procedure write_system_type(var name:string; kind:byte; info:system_info_ptr);
begin
  case kind of
  sys_proc_id : write('procedure');
  sys_fn_id   : write('function');
  end;
  with info^ do
  begin
    write(oneindent,name,tab,'{ Special index ',hexbyte(addr_ofs));
    if flags <> 0 then
      write(oneindent,'Flags ',hexbyte(flags));  { What are those flags!!??! }
    writeln(' }');
  end;
  last_kind := kind;
end;

procedure write_general(kind:byte; title,name,suffix:string);
begin
  if last_kind <> kind then
  begin
    writeln(title);
    last_kind := kind;
    indent;
  end;
  write(oneindent,name,suffix);
end;

procedure print_obj(obj:obj_ptr);
var
  j:word;
  obj_info : ^byte_array;
  new_entry : list_ptr;
  info_len,info_ofs : word;
  obj_type : byte;
const
  known_types : set of byte = [var_id,unit_id,const_id,type_id,proc_id,
                               sys_proc_id,sys_fn_id,sys_mem_id,sys_port_id,
                               sys_new_id];
  dump_types  : set of byte = [];
begin
  info_ofs := sizeof(obj_rec)-sizeof(string)+1+length(obj^.name);
  obj_info := add_offset(obj,info_ofs);
  obj_type := obj^.obj_type;
  if (obj_type and $80) <> 0 then
  begin
    if last_kind <> objpriv_id then
    begin
      dec(indentation);
      indent;
      inc(indentation);
      writeln('private');
      last_kind := objpriv_id;
    end;
    obj_type := obj_type and $7F;
  end;

  if obj_type in known_types then
  begin
    if obj_type = unit_id then
    begin
      add_unit(obj^.name,unit_ptr(obj_info));
      if unit_ptr(obj_info)^.target = 0 then
        unit_ptr(obj_info)^.target := get_unit_num(obj^.name);
             {  Save our ID there, so references can find the information  }
    end;

    case obj_type of  { Strip private bit }
       const_id : write_const_info(obj^.name,pointer(obj_info));
       type_id : write_type_info(obj^.name,obj,pointer(obj_info));

       var_id  : write_var_info(obj^.name,pointer(obj_info));

       proc_id : begin
                   write_proc_info(obj^.name,pointer(obj_info));
                   if not (last_kind in [object_id,objpriv_id]) then
                     last_kind := proc_id;
                 end;

       sys_proc_id,
       sys_fn_id : write_system_type(obj^.name,obj_type,pointer(obj_info));

       sys_port_id : begin
                       write_general(sys_port_id,'port array',obj^.name,semicrlf);
                     end;
       sys_mem_id : begin
                      write_general(sys_mem_id,'memory array',obj^.name,semicrlf);
                    end;
       sys_new_id : begin
                      write_general(sys_new_id,'system allocator',obj^.name,semicrlf);
                    end;
       unit_id :   write_unit_info(obj^.name,pointer(obj_info),
                     obj_ofs(obj) = header^.ofs_this_unit)

    end; {case}
  end
  else
  begin
    writeln('Unknown kind ',obj_type,oneindent,obj^.name,' with info at ',
            hexword(obj_ofs(obj_info)));
    last_kind := obj_type;
  end;
  if obj_type in dump_types then
  begin
    for j:=0 to 15 do
      write(hexword(obj_ofs(obj_info)+j):5);
    for j:=0 to 15 do
      write(hexbyte(obj_info^[j]):5);
    for j:=16 to 31 do
      write(hexword(obj_ofs(obj_info)+j):5);
    for j:=16 to 31 do
      write(hexbyte(obj_info^[j]):5);
  end;
end;

procedure print_name_list(obj_list:list_ptr);
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

end.
