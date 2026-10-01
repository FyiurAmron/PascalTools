unit namelist;
{$I SWITCHES.INC}
{ These are the routines that print the name definitions }

interface

uses
  dump,util,globals,loader,head,nametype;

var
  last_kind : byte;
  in_function : boolean;
  NowEnum: type_def_ptr;

procedure print_name_list(obj_list:list_ptr);
procedure print_obj(obj:obj_ptr);
procedure write_type_info(var name:string; obj:obj_ptr; info:type_info_ptr);
function find_type(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
function find_type_or_proc(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
function find_proc_with_entry(in_unit:unit_list_ptr;entry:word):string;
procedure write_var_type(type_unit,type_def_ofs:word);
procedure write_var_info(var name:string; info:var_info_ptr);
procedure write_enum_const(type_obj:type_def_ptr;val:longint);
procedure write_const_type(var Val;type_unit,type_def_ofs:word;buffer:pointer);
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
  blocks,objects;

const
  semicrlf = ';'+^M+^J;


function obj_ofs(obj:pointer):word;
begin
  obj_ofs := ptr_diff(obj,buffer);
end;

function get_buffer(obj:pointer):pointer;
begin
  get_buffer := ptr(seg(obj^),0);
end;

{$IFDEF UNIT60}
procedure write_type_def(def:type_def_ptr);far;
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
    if base_type in [1,2,4,6,8,$a,$e,$f,$10,$11,$12,$13,$15,$18,$19,$1a,$1b,
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
      $19 : write('file');
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
        WriteError('{ unrecognized base type '+hexbyte(base_type)+'}');
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

              build_list(field_list,buffer,add_only_offset(buffer,hash_ofs));

              current := field_list;
              inc(indentation,2);
              while current^.offset < $ffff do
              begin
                obj := add_only_offset(buffer,current^.offset);
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

              build_list(field_list,buffer,add_only_offset(buffer,hash_ofs));

              inc(indentation,2);
              current := field_list;
              while current^.offset < $ffff do
              begin
                obj := add_only_offset(buffer,current^.offset);
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
                NowEnum:=type_def_ptr(Def);
                {  Assume following records are constant declarations  }
                obj := add_only_offset(def,30);
                for l:=lower to upper-1 do
                begin
                  write(obj^.name,',');
                  obj:=add_only_offset(obj,12+length(obj^.name));
                end;
                write(obj^.name,')');
              end
              else
              begin
                { Must be subrange }
                obj := add_only_offset(get_unit(type_unit)^.buffer,type_ofs);
                obj := add_only_offset(obj,24);
                i := 0;
                while i < def^.lower do
                begin
                  obj:=add_only_offset(obj,12+length(obj^.name));
                  inc(i);
                end;
                write(obj^.name);
                while i < def^.upper do
                begin
                  obj:=add_only_offset(obj,12+length(obj^.name));
                  inc(i);
                end;
                write('..',obj^.name);
              end;
            end;
       else
            begin
              WriteError('Type definition of type '+decword(type_type));
              writeln(' otherbyte=',other_byte,'size=',size);
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
{$ELSE}
procedure write_type_def(def:type_def_ptr);far;
var
  i : integer;
  l : longint;
  save_kind : byte;
  field_list : list_ptr;
  current : list_ptr;
  obj : obj_ptr;
  type_obj : type_def_ptr;
  no_name : string;
  save_in_array : boolean;
  bt:byte;
begin
  with def^ do
  begin
    if base_type in [1,2,4,6,8,$a,$e,$f,$10,$11,$12,$13,$15,$18,$19,$1a,$1b,
                     $21,$22,$23] then
    begin
      bt:=255;
      case base_type of
        1 : begin write('untyped');  bt:=0    end;
        2 : begin write('shortint'); bt:=12;  end;
        4 : begin write('integer');  bt:=12;  end;
        6 : begin write('longint');  bt:=12;  end;
        8 : begin write('byte');     bt:=12;  end;
       $a : begin write('word');     bt:=12;  end;
       $e : begin write('single');   bt:=10;  end;
       $f : begin write('double');   bt:=10;  end;
      $10 : begin write('extended'); bt:=10;  end;
      $11 : begin write('real');     bt:=11;  end;
      $12 : begin write('boolean');  bt:=13;  end;
      $13 : begin write('char');     bt:=14;  end;
      $15 : begin write('comp');     bt:=10;  end;
      $18 : begin write('text');     bt:=5;   end;
      $19 : begin write('file');     bt:=4;   end;
      $1a : begin write('pointer');  bt:=8;   end;
      $1b : begin write('string');   bt:=9;   end;
      { TPW types }
      $21 : begin write('wordbool'); bt:=13;  end;
      $22 : begin write('longbool'); bt:=13;  end;
      $23 : begin write('pchar');    bt:=8;   end;
      end;
      if type_type<>bt then
        Write('{base type <-> type_type error}');
    end
    else
    begin
      if base_type <> 0 then
        WriteError('{ unrecognized base type '+hexbyte(base_type)+'}');
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

              build_list(field_list,buffer,add_only_offset(buffer,hash_ofs));

              current := field_list;
              inc(indentation,2);
              while current^.offset < $ffff do
              begin
                obj := add_only_offset(buffer,current^.offset);
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

              build_list(field_list,buffer,add_only_offset(buffer,hash_ofs));

              inc(indentation,2);
              current := field_list;
              while current^.offset < $ffff do
              begin
                obj := add_only_offset(buffer,current^.offset);
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
       12,13,14 : begin                  {Range}
              write_const_type(lower,type_unit,type_ofs,
                               get_buffer(def));
              write('..');
              write_const_type(upper,type_unit,type_ofs,
                               get_buffer(def));
            end;
       15 : begin                  {Enumeration or subrange}
              if (type_unit = unit_list[1]^.own_record)
                 and (type_ofs = obj_ofs(def)) then
              begin
                { Must be first definition }
                write('(');
                {  Assume following records are constant declarations  }
                for l:=lower to upper do
                begin
                  if l<>lower then write(',');
                  write_enum_const(def,l);
                end;
                NowEnum:=def;
                write(')');
              end
              else
              begin
                { Must be subrange }
                type_obj := add_only_offset(get_unit(type_unit)^.buffer,type_ofs);
                write_enum_const(type_obj,def^.lower);
                write('..');
                write_enum_const(type_obj,def^.upper);
              end;
            end;
       else
            begin
              WriteError('Type definition of type '+decword(type_type));
              writeln(' otherbyte=',other_byte,'size=',size);
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
{$ENDIF}

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
      write_type_def(add_only_offset(buffer,type_def_ofs))
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
      build_list(obj_list,buffer,add_only_offset(buffer,header_ptr(buffer)^.ofs_hashtable));
    if obj_list <> nil then
    begin
      current := obj_list;
      while current^.offset < $ffff do
      begin
        obj := add_only_offset(buffer,current^.offset);
        obj_info := add_only_offset(obj,4+length(obj^.name));
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

function find_type_or_proc(unit_rec:unit_list_ptr;def_ofs:word):obj_ptr;
var
  current:list_ptr;
  obj : obj_ptr;
  obj_info : type_info_ptr;
begin
  with unit_rec^ do
  begin
    if (obj_list = nil) and (buffer <> nil) then
      build_list(obj_list,buffer,add_only_offset(buffer,header_ptr(buffer)^.ofs_hashtable));
    if obj_list <> nil then
    begin
      current := obj_list;
      while current^.offset < $ffff do
      begin
        obj := add_only_offset(buffer,current^.offset);
        obj_info := add_only_offset(obj,4+length(obj^.name));
        if     ((obj^.obj_type = type_id)
             and (obj_info^.type_def_ofs = def_ofs)
             and (obj_info^.type_unit = own_record))
          or
             ((obj^.obj_type = proc_id)
             and (ofs(obj^)=def_ofs))
             then
        begin
          find_type_or_proc := obj;
          exit;
        end;
        current := current^.next;
      end;
    end;
    find_type_or_proc := nil;
  end;
end;

procedure make_proc_list_entry(var in_unit:unit_list_ptr);
var
  buffer:byte_array_ptr;
  lname:string;

procedure fpe(obj_list:list_ptr;var proc_list:proc_list_ptr);
var
  current:list_ptr;
  obj : obj_ptr;
  obj_info : func_info_ptr;
  obj_list2:list_ptr;
  fp:string;
  def:type_def_ptr;
  lastlen:integer;
procedure Insert(const name:string;Entry:word);
var Aux:proc_list_ptr;
begin
  New(Aux);
  Aux^.name:=NewStr(name);
  Aux^.Entry:=Entry;
  Aux^.Next:=proc_list;
  proc_list:=aux;
end;

begin
  if obj_list <> nil then
  begin
    current := obj_list;
    while current^.offset < $ffff do
    begin
      obj := add_only_offset(buffer,current^.offset);
      obj_info := add_only_offset(obj,4+length(obj^.name));
      if (obj^.obj_type = type_id) then
      begin
        if get_unit_buffer(buffer,type_info_ptr(obj_info)^.type_unit)^.buffer=buffer then
        begin {only types defined in this unit }
          def:=add_only_offset(buffer,type_info_ptr(obj_info)^.type_def_ofs);
          if (def^.type_type=3) and (def^.hash_ofs<>0) then { object }
          begin
            build_list(obj_list2,buffer,add_only_offset(buffer,def^.hash_ofs));
            lastlen:=length(lname);
            lname:=lname+obj^.name+'.';
            fpe(obj_list2,proc_list);
            lname[0]:=char(lastlen);
            destroy_list(obj_list2);
          end;
        end
      end
      else if ((obj^.obj_type and $7f) = proc_id) then
      begin
        Insert(lname+obj^.name,obj_info^.entry_ofs);
        if (obj_info^.local_hash<>0) then
        begin
          build_list(obj_list2,buffer,add_only_offset(buffer,obj_info^.local_hash));
          lastlen:=length(lname);
          lname:=lname+obj^.name+'.';
          fpe(obj_list2,proc_list);
          lname[0]:=char(lastlen);
          destroy_list(obj_list2);
        end;
      end;
      current := current^.next;
    end;
  end;
end;

begin
  with in_unit^ do
  begin
    if (obj_list = nil) and (buffer <> nil) then
      build_list(obj_list,buffer,add_only_offset(buffer,header_ptr(buffer)^.ofs_hashtable));
  end;
  buffer:=in_unit^.buffer;
  in_unit^.proc_list:=nil;
  lname:='';
  fpe(in_unit^.obj_list,in_unit^.proc_list);
end;

function find_proc_with_entry(in_unit:unit_list_ptr;entry:word):string;
var
  act:proc_list_ptr;
begin
  if entry=0 then
  begin
    find_proc_with_entry:='Startup code';
    exit;
  end;
  find_proc_with_entry := '';
  with in_unit^ do
  begin
    if (proc_list = nil) and (buffer <> nil) then
      make_proc_list_entry(in_unit);
  end;
  act:=in_unit^.proc_list;
  while act<>nil do
  begin
    if act^.entry=entry then
    begin
      find_proc_with_entry:=act^.name^;
      break;
    end;
    act:=act^.next;
  end;
end;


function find_name(unit_rec:unit_list_ptr;info_ofs:word):string;
{  Unreliable way to get a name from a pointer to its info }
var
  i:word;
  fname:string;
begin
  with unit_rec^ do
  begin
    if buffer <> nil then
      for i:=info_ofs-2 downto 0 do
        if i+buffer^[i]+1 = info_ofs then
        begin
          move(buffer^[i],fname[0],buffer^[i]+1);
          find_name := fname;
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
          write_type_def(add_only_offset(buffer,type_def_ofs));
      end
      else
        write(name,'.ofs',type_def_ofs);
    end;
  end
  else
    WriteError('type_unit not found');
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
      f := flags*[const_flag,local,referenced,const_arg];
      if f = [] then
        write_general(var_id,'var',name,':'+oneindent)
      else if f = [const_flag] then
        write_general(const_id,'const',name,':'+oneindent)
      else if f = [const_flag,local] then
        write_general(var_id,'var',name,':'+oneindent)
      else if f = [local] then
        write_general(local_id,'local var',name,':'+oneindent)
      else if f = [local,referenced] then
        write_general(referenced_id,'referenced var',name,':'+oneindent)
      else if f = [local,referenced,const_arg] then
        write_general(refconst_id,'referenced const',name,':'+oneindent)
      else
        WriteError(' var flags = '+hexbyte(byte(flags))+oneindent);
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
        WriteError('?????;');
    end
    else
    begin
      if const_flag in flags then
        if local in flags then
          write(' absolute $'+hexword(in_unit)+':$'+hexword(offset))
        else
          write('=',oneindent,'?');
      if in_function and not (const_flag in flags) then
      begin
        write(';',tab,'{BP ofs ');
        if integer(offset)<0 then
          write('-')
        else
          write('+');
        write(hexwordasm(abs(integer(offset))));
        writeln('}');
      end
      else
      begin
        write(';');
        if flags<>[const_flag,local] then
        begin
          write(tab,'{ofs ',hexwordblank(offset));
          if not (last_kind in [record_id,object_id,objpriv_id]) then
            write(' in block ',hexwordblank(in_unit));
          write('}');
        end;
        writeln;
      end;
    end;
    if v128 in flags then
      WriteError('Unknown variable flag '+HexWord(Byte(flags)));
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
        write('var   ')
      else if const_arg in flags then
        write('const ')
      else
        write('      ');
      if flags - [referenced,const_arg] <> [local] then
      begin
        WriteError('{ flags ='+hexbyte(byte(flags))+' }');
        indent;
      end;
      write('arg',i,':',oneindent);
      write_var_type(type_unit,type_def_ofs);
      if i<>num_args then
        writeln(';')
      else
        writeln;
    end;
    arg := add_only_offset(arg,sizeof(arg_rec));
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
  build_list(obj_list,buffer,add_only_offset(buffer,info^.local_hash));
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
      write_args(arg_ptr(add_only_offset(info,sizeof(func_type_rec))),
                 info^.num_args);
    if not proc then
    begin
      write(':',oneindent);
      write_var_type(type_unit,type_def_ofs);
    end;
  end;
  if Name<>'' then
    write(';');
end;

{$IFDEF UNIT60}
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
    entry_pt := add_only_offset(buffer,header^.ofs_entry_pts+entry_ofs);

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
      write(tab,'{ Proc ',hexwordblank(entry_ofs));
      if not (from_dll in obj_type) then
        write(' Entry ',hexwordblank(entry_pt^.code_block),':',
                            hexword(entry_pt^.offset));
      if (vmt_entry > 0) and not (dynamic in obj_type) then
        write(' vmt index ',hexword(vmt_entry),'h');
      writeln('}');
    end
    else
    begin
      writeln;
      indent;
      write(' Inline(');
      code := add_only_offset(info,sizeof(func_info_rec)
                             +func_type.num_args*sizeof(arg_rec));
      for i:=1 to entry_ofs div 2 - 1 do
      begin
        write('$',hexbyte(hi(code^)):2,'/');
        if lo(code^) <> 0 then
          writeln('Low byte not zero!');
        code := add_only_offset(code,sizeof(word));
      end;
      writeln('$',hexbyte(hi(code^)):2,');');
      if lo(code^) <> 0 then
        writeln('Low byte not zero!');
    end;
    if do_locals in active_options then
      write_locals(name,info);
  end;
end;
{$ELSE}

procedure write_proc_info(var name:string; info:func_info_ptr);
type
  inline_data_ptr = ^inline_data;
  inline_data = record
    itype:byte;
    case integer of
      0:(b:byte);
      1:(w:word);
      2:(offset,block,block_unit:word);
    end;
var
  entry_pt : entry_pt_ptr;
  code_ptr,codestart : inline_data_ptr;
  i : word;
  unknown_flags : obj_flags;
begin
  indent;
  with info^ do
  begin
    write_proc_type(name,code_type,func_type_ptr(addr(func_type)));
    entry_pt := add_only_offset(buffer,header^.ofs_entry_pts+entry_ofs);

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

    if not (not_from_dll in obj_type) and
       ([inline_code,external_code,interrupt,assembler]*code_type=[]) then
    begin
      write(' external ''',dll_name(entry_pt^.code_block),'''');
      if ent_by_name in entry_pt^.flags then
        write(' name ''',dll_name(entry_pt^.offset),'''')
      else
        write(' index ',entry_pt^.offset);
      write(';');
    end;

    unknown_flags := obj_type - [exported,windows_frame,not_from_dll,
                                  dynamic];
    if unknown_flags <> [] then
      WriteError(' Unrecognized object flags: '+hexbyte(byte(unknown_flags)));
    if not (inline_code in code_type) then
    begin
      write(tab,'{ Proc ',hexwordblank(entry_ofs));
      if not_from_dll in obj_type then
        write(' Entry ',hexwordblank(entry_pt^.code_block),':',
                            hexword(entry_pt^.offset));
      if (vmt_entry > 0) and not (dynamic in obj_type) then
        write(' vmt index ',hexword(vmt_entry),'h');
      writeln('}');
    end
    else
    begin
      writeln;
      indent;
      write(' Inline(');
      codestart := add_only_offset(info,sizeof(func_info_rec)
                             +func_type.num_args*sizeof(arg_rec));
      i:=0;
      while i<entry_ofs do
      begin
        code_ptr := add_only_offset(codestart,i);
        case code_ptr^.itype of
        0 : begin
              write('<$',hexbyte(code_ptr^.b):2);
              Inc(i,2);
            end;
        1 : begin
              write('>$',hexword(code_ptr^.w):4);
              Inc(i,3);
            end;
        2,3 : begin
              write('{ofs ',hexwordblank(code_ptr^.offset),' in ');
              if code_ptr^.itype=2 then
                write('var')
              else
                write('const');
              write(' block ',hexwordblank(code_ptr^.block));
              write(' in unit ',get_unit_name(code_ptr^.block_unit));
              writeln('}');
              write('':10);
              Inc(i,7);
            end;
        else
          WriteError('Inline code unknown type!');
          Inc(i,1);
        end;
        if i=entry_ofs then
          writeln(');')
        else
          write('/');
      end;
    end;
    if (next_method<>0) and not (method in code_type) then
      WriteError('Unknown next_method value');
    if (w4<>$0d06) then
      WriteError('Unknown w4 value');
    if not (((w5=4) and not (method in code_type)) or
            ((w5=8) and (method in code_type))) then
      WriteError('Unknown w5 value');
    if (w6<>0) then
      WriteError('Unknown w6 value');
    if do_locals in active_options then
      write_locals(name,info);
  end;
end;
{$ENDIF}

procedure write_enum_const(type_obj:type_def_ptr;val:longint);
var obj : obj_ptr;
    i : integer;
begin
  if type_obj^.type_type<>15 then
  begin
    WriteError('Not enum const!?');
    exit;
  end;
  obj := add_only_offset(type_obj,32);
  i := 0;
  while i < val do
  begin
    obj:=add_only_offset(obj,12+length(obj^.name));
    inc(i);
  end;
  write(obj^.name);
end;

procedure write_const_type(var Val;type_unit,type_def_ofs:word;buffer:pointer);
var type_obj:type_def_ptr;
    last,l:longint;
    count,i,state:Integer;
    range:boolean;
    unit_ptr:unit_list_ptr;
begin
  if buffer<>nil then
    unit_ptr:=get_unit_buffer(buffer,type_unit)
  else
    unit_ptr:=get_unit(type_unit);
  with  unit_ptr^ do
  begin
    if buffer<>nil then
    begin
      type_obj:=add_only_offset(buffer,type_def_ofs);
      case type_obj^.type_type of
      9   { string }
         : begin
             state:=0;
             for i:=1 to length(string(val)) do
             begin
               if string(val)[i]<' ' then
                 case state of
                 0: begin
                     state:=2;
                     write('#$',hexbyte(ord(string(val)[i])));
                    end;
                 1: begin
                      write('''#$',hexbyte(ord(string(val)[i])));
                      state:=2;
                    end;
                 2: write('#$',hexbyte(ord(string(val)[i])));
                 end
               else
                 case state of
                 0,2: begin
                     state:=1;
                     write('''',string(val)[i]);
                    end;
                 1: write(string(val)[i]);
                 end;
             end;
           if state=1 then
             write('''');
           end;
      15  { enum }
         : begin
             if NowEnum=nil then
               write_enum_const(type_obj,longint(val))
             else
               write(integer(val));
           end;
      12  { int }
         : write(longint(val));
      13  { bool }
         : write(boolean(val));
      14  { char }
         : if (char(val)<' ') or (char(val)>#$fe) then
             write('#$',hexbyte(byte(val)))
           else
             write('''',char(val),'''');
      10  { extend }
         : write(extended(val));
      8   { pointer }
         : write('ptr($'+hexword(seg(pointer(val)^))+
                 ',$'+hexword(ofs(pointer(val)^))+')');
      7   { set }
         : begin
             write('[');
             Count:=0;
             last:=-2;
             Range:=False;
             for l:=0 to 255 do
               if l in tbyteset(val) then
               begin
                 if Range or (last=l-1) then
                   Range:=True
                 else
                 begin
                   inc(Count);
                   if Count>1 then
                     write(',');
                   write_const_type(l,type_obj^.base_unit,type_obj^.base_ofs,buffer);
                   last:=l;
                 end
               end
               else
               begin
                 if Range then
                 begin
                   Range:=False;
                   if last=l-2 then
                   begin
                     last:=l-1;
                     write(',');
                     write_const_type(last,type_obj^.base_unit,type_obj^.base_ofs,buffer);
                   end
                   else
                   begin
                     last:=l-1;
                     write('..');
                     write_const_type(last,type_obj^.base_unit,type_obj^.base_ofs,buffer);
                   end;
                 end;
                 last:=-2;
               end;
             write(']');
           end;
      else
        WriteError('Unknown type of constant');
      end;
    end
    else
      Write('?');
  end;
end;

procedure write_const_info(var name:string; info:const_info_ptr);
var
  type_obj : type_def_ptr;
begin
  indent;
  if (NowEnum<>nil) and ((info^.type_def_ofs<>Ofs(NowEnum^)) or
     (Seg(get_unit(info^.type_unit)^.buffer^)<>Seg(NowEnum^))) then
  begin
    Writeln('*)');
    NowEnum:=nil;
    last_kind:=init_id;
  end;
  if (last_kind <> record_id) and (last_kind <> const_id) then
  begin
    if NowEnum<>nil then
      Write('(* ');
    writeln('Const');
    indent;
    last_kind := const_id;
  end;
  write(oneindent,name,'=',oneindent);
  write_const_type(info^.allval,info^.type_unit,info^.type_def_ofs,nil);
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
    begin
      writeln;
      write(oneindent,',',name);
    end
    else
    begin
      write('Uses',oneindent,name);
      last_kind := unit_id;
    end;
  end;
  with info^ do
  begin
    write(tab,'{ checksum = ',hexword(checksum),'}');
    if self then
    begin
      writeln;
      writeln('interface');
    end;
  end;
end;

procedure write_system_type(var name:string; kind:byte; info:system_info_ptr);
begin
  if kind=sys_proc_id then
    write('procedure')
  else if kind=sys_fn_id  then
    write('function');

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
  dump_types  : set of byte = [];
begin
  info_ofs := sizeof(obj_rec)-sizeof(string)+1+length(obj^.name);
  obj_info := add_only_offset(obj,info_ofs);
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
    if last_kind<>obj_type then
    begin
      if (obj_type<>const_id) and (NowEnum<>nil) then
      begin
        if last_kind=const_id then
          Writeln('*)');
        NowEnum:=nil;
      end;
      if last_kind=unit_id then
        writeln(';');
    end;
    if obj_type=const_id then
    begin
      write_const_info(obj^.name,pointer(obj_info));
    end
    else if obj_type=type_id then
    begin
      write_type_info(obj^.name,obj,pointer(obj_info));
    end
    else if obj_type=var_id then
    begin
      write_var_info(obj^.name,pointer(obj_info));
    end
    else if obj_type=proc_id then
    begin
      write_proc_info(obj^.name,pointer(obj_info));
      if not (last_kind in [object_id,objpriv_id]) then
        last_kind := proc_id;
    end
    else if (obj_type=sys_proc_id) or (obj_type=sys_fn_id) then
    begin
      write_system_type(obj^.name,obj_type,pointer(obj_info));
    end
    else if obj_type=sys_port_id then
    begin
      write_general(sys_port_id,'type {port array}',obj^.name,':'+oneindent);
      if byte_array_ptr(obj_info)^[0]=0 then
        writeln('Byte;')
      else
        writeln('Word;')
    end
    else if obj_type=sys_mem_id then
    begin
      write_general(sys_mem_id,'type {memory array}',obj^.name,':'+oneindent);
      write_type_def(add_only_offset(buffer,type_info_ptr(obj_info)^.type_def_ofs));
      writeln(';');
    end
    else if obj_type=sys_new_id then
    begin
      write_general(sys_new_id,'system allocator '+obj^.name+';','',#13#10);
    end
{$IFNDEF UNIT60}
    else if obj_type=sys_openstr_id then
    begin
      write_general(sys_openstr_id,'system open string type:'+obj^.name+';','',#13#10);
    end
{$ENDIF}
    else if obj_type=unit_id then
    begin
      write_unit_info(obj^.name,pointer(obj_info),
                     obj_ofs(obj) = header^.ofs_this_unit)
    end;
  end
  else
  begin
    WriteError('Unknown kind '+DecWord(obj_type)+oneindent+obj^.name+
               ' with info at '+hexword(obj_ofs(obj_info)));
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
    obj := add_only_offset(buffer,current^.offset);
    print_obj(obj);
    current := current^.next;
  end;
end;

end.
