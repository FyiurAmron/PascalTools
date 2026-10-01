unit loader;
{$I SWITCHES.INC}
interface

  uses util,dump,globals,head,objects,dos;

type

  hash_ptr = ^hash_rec;
  hash_rec = record
    byte_len : word;
    table    : word_array;
  end;

  list_ptr = ^list_rec;
  list_rec = record
    offset : word;
    hash : word;
    next : list_ptr;
  end;

  proc_list_ptr = ^proc_list_rec;
  proc_list_rec = record
    entry : word;
    name : pstring;
    next : proc_list_ptr;
  end;

  unit_ptr = ^unit_rec;
  unit_rec = record
    target:word;
    checksum:word;
    prev_unit,next_unit : word;
    in_interface : boolean;
  end;

  unit_list_ptr = ^unit_list_rec;
  unit_list_rec = record
    name : string;
    path : string;
    obj_list : list_ptr;
    proc_list : proc_list_ptr;
    own_record : word;
    checksum : word;
    buffer     : byte_array_ptr;
    has_symbols : boolean;
  end;

  tpl_item_ptr = ^tpl_item_rec;
  tpl_item_rec = record
    buffer : byte_array_ptr;
    size : word;
    next : tpl_item_ptr;
  end;

  tpl_list_ptr = ^tpl_list_rec;
  tpl_list_rec = record
    path : string;
    first : tpl_item_ptr;
  end;

  obj_ptr = ^obj_rec;
  obj_rec = record
    next_obj: word;  { in case of a hash collision }
    obj_type : byte;
    name: string;
  end;

var
  hash_table : hash_ptr;

  unit_list : array[1..255] of unit_list_ptr;
  num_known : word;

  tpl_buffer : tpl_list_rec;

  procedure build_list(var obj_list:list_ptr;
                         buffer:byte_array_ptr;
                         hash_table:hash_ptr);
  procedure destroy_list(obj_list:list_ptr);

  procedure add_unit(const objname:string;info:unit_ptr);
  function  get_unit(unit_ofs:word):unit_list_ptr;
  function  get_unit_buffer(buffer:pointer;unit_ofs:word):unit_list_ptr;
  function  get_unit_name(unit_ofs:word):String;
  function  get_unit_by_name(const name:string):unit_list_ptr;
  function  get_unit_num(name:string):word;

  procedure loadtpl;
  procedure ReadPathFile(var path:string;var Header:header_ptr);

implementation

  procedure build_list(var obj_list:list_ptr;
                         buffer:byte_array_ptr;
                         hash_table:hash_ptr);
  var
    i,j,t:word;
    current,new_entry : list_ptr;
    obj : obj_ptr;
  begin
    new(obj_list);
    with obj_list^ do
    begin
      offset := $ffff;     { set up a sentinel record }
      next := nil;
    end;

    with hash_table^ do
      for i := 0 to byte_len div 2 do
        if table[i] <> 0 then
        begin
          t := table[i];
          repeat
            current := obj_list;
            while t > current^.offset do
              current := current^.next;
            new(new_entry);
            new_entry^ := current^;
            current^.offset := t;
            current^.hash := i;
            current^.next := new_entry;
             obj := add_only_offset(buffer,t);
             { get the next object... }
            t := obj^.next_obj;
          until t = 0;
        end;
  end;

  procedure destroy_list(obj_list:list_ptr);
  var aux:list_ptr;
  begin
    while obj_list<>nil do
    begin
      aux:=obj_list;
      obj_list:=obj_list^.next;
      dispose(aux);
    end;
  end;

  procedure ReadPathFile(var path:string;var Header:header_ptr);
  var dir,unit_dirs:string;
      i:integer;
  begin
    header:=nil;
    read_file(path,pointer(header),0,sizeof(header^));
    if header = nil then
    begin
      unit_dirs:=uses_path;
      while (unit_dirs<>'') and (header=nil) do
      begin
        i:=pos(';',unit_dirs);
        if i=0 then
          i:=length(unit_dirs)+1;
        dir := copy(unit_dirs,1,i-1);
        unit_dirs := copy(unit_dirs,i+1,255);
        if dir[length(dir)] <> '\' then
          dir := dir + '\';
        read_file(dir+path,pointer(header),0,sizeof(header^));
      end;
      if header<>nil then
        path:=dir+path;
    end;
  end;

  procedure add_unit(const objname:string;info : unit_ptr);
  var
    size,total:word;
    header:header_ptr;
    unit_obj:obj_ptr;
    junk : pointer;
    obj_info : unit_ptr;
    info_ofs,offset : word;
    tpl_item : tpl_item_ptr;

  procedure load_buffer;
  var i:integer;
  begin
    with unit_list[num_known]^ do
    begin
      path := objname+unit_ext;
      ReadPathFile(path,header);
      if header <> nil then
      begin
        if header^.file_id <> tpu_file_id then
        begin
          HaltError('Error:  file '+path+' is not a TP '+
{$IFDEF UNIT60}
           '6.0'
{$ELSE}
           '7.0'
{$ENDIF}
                   +' .TPU file!');
        end;
        read_file(path,pointer(buffer),0,header^.sym_size);
        if buffer <> nil then
        begin
          has_symbols := true;
          header:=header_ptr(buffer);
        end;
        exit;
      end;
      path := '';
      tpl_item := tpl_buffer.first;
      while tpl_item<>nil do
      begin
        header := header_ptr(tpl_item^.buffer);
        if (header^.file_id <> tpu_file_id) then
        begin
          HaltError('Error searching '+tpl_name+'.  It is not a TP library!');
        end;
        unit_obj := add_only_offset(header,header^.ofs_this_unit);
        if upper(unit_obj^.name) = upper(objname) then
        begin
          buffer := pointer(header);
          has_symbols := true;
          exit;
        end;
        tpl_item:=tpl_item^.next;
      end;
      WriteOutput('Warning:  Can''t find unit '+objname);
    end;
  end;

  var
    existing : unit_list_ptr;
    D: DirStr;
    N: NameStr;
    E: ExtStr;
  begin
    existing := get_unit_by_name(objname);
    if existing <> nil then
      with existing^ do
      begin
        if   (info <> nil)
         and (existing^.buffer <> nil)
         and (checksum <> info^.checksum) then
        begin
          writeln('Warning:  checksum for unit ',name,' is ',hexword(checksum),' in ',
                  path);
          has_symbols := false;
          freemem(buffer,header^.sym_size);
          buffer := nil;
        end;
        exit;
      end;

    inc(num_known);
    new(unit_list[num_known]);
    with unit_list[num_known]^ do
    begin
      name := upper(objname);
      obj_list := nil;
      proc_list := nil;
      buffer := nil;
      has_symbols := false;
      load_buffer;
      if has_symbols then
      begin
        FSplit(name, D, N, E);
        name:=N;
        own_record := header_ptr(buffer)^.ofs_this_unit;
        inc(own_record,
            4+length(obj_rec(add_only_offset(buffer,own_record)^).name));
        checksum := unit_ptr(add_only_offset(buffer,own_record))^.checksum;
        { add the uses units to the unit_list }
        offset := header_ptr(buffer)^.ofs_this_unit;
        while offset <> 0 do
        begin
          unit_obj := add_only_offset(buffer,offset);
          info_ofs := sizeof(obj_rec)-sizeof(string)+1+length(unit_obj^.name);
          obj_info := add_only_offset(buffer,offset+info_ofs);
          add_unit(unit_obj^.name,nil);
          obj_info^.target := get_unit_num(unit_obj^.name);
          offset := obj_info^.next_unit;
        end;
      end;

    end;
  end;

  function get_unit(unit_ofs:word):unit_list_ptr;
  var
    the_unit : unit_ptr;
  begin
    if unit_ofs > unit_list[1]^.own_record then
    begin
      the_unit := add_only_offset(buffer,unit_ofs);
      get_unit := unit_list[the_unit^.target];
    end
    else
      get_unit := unit_list[1];
  end;

  function  get_unit_name(unit_ofs:word):String;
  var
    the_unit : unit_ptr;
  begin
    if unit_ofs > unit_list[1]^.own_record then
    begin
      the_unit := add_only_offset(buffer,unit_ofs);
      get_unit_name := unit_list[the_unit^.target]^.name;
    end
    else
      get_unit_name := unit_list[1]^.name;
  end;

  function get_unit_buffer(buffer:pointer;unit_ofs:word):unit_list_ptr;
  var
    the_unit : unit_ptr;
  begin
    the_unit := add_only_offset(buffer,unit_ofs);
    get_unit_buffer := unit_list[the_unit^.target];
  end;

  function get_unit_by_name(const name:string):unit_list_ptr;
  var
    i : word;
  begin
    i := get_unit_num(name);
    if i <> 0 then
      get_unit_by_name := unit_list[i]
    else
      get_unit_by_name := nil;
  end;

  function get_unit_num(name:string):word;
  var
    i : word;
  begin
    name:=upper(name);
    for i:=1 to num_known do
      if unit_list[i]^.name = name then
      begin
        get_unit_num := i;
        exit;
      end;
    get_unit_num := 0;
  end;

  procedure LoadTpl;
  var
    total:longint;
    header:header_ptr;
    i : integer;

  procedure InsertToList(offset:longint;size:word);
  var Aux:tpl_item_ptr;
  begin
    Aux:=New(tpl_item_ptr);
    Aux^.Size:=size;
    read_file(tpl_buffer.path,pointer(Aux^.buffer),offset,size);

    Aux^.Next:=tpl_buffer.First;
    tpl_buffer.First:=Aux;
  end;

  begin
    with tpl_buffer do
    begin
      path := tpl_name;
      first := nil;
      total := 0;
      ReadPathFile(path,header);
      if header <> nil then
      begin
        while header<>nil do
        begin
          if header^.file_id<>tpu_file_id then
          begin
            WriteOutput('Warning:  '+path+' versiom mismatch.');
            exit;
          end;

          InsertToList(total,header^.sym_size);
          freemem(header,sizeof(header^));

          header:=header_ptr(First^.Buffer);
          Inc(total,
                  roundup(header^.sym_size,16)
{$IFNDEF UNIT60}
                 +roundup(header^.browser_size,16)
{$ENDIF}
                 +roundup(header^.code_size,16)
                 +roundup(header^.reloc_size,16)
                 +roundup(header^.const_size,16)
                 +roundup(header^.const_reloc_size,16));
          read_file(path,pointer(header),total,sizeof(header^));
        end;
      end;
    end;
  end;
end.

