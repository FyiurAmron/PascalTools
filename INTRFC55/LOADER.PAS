unit loader;

interface

  uses util,globals,head;

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

  unit_ptr = ^unit_rec;
  unit_rec = record
    target:word;
    checksum:word;
    prev_unit,next_unit : word;
  end;

  unit_list_ptr = ^unit_list_rec;
  unit_list_rec = record
    name : string;
    path : string;
    obj_list : list_ptr;
    own_record : word;
    buffer     : byte_array_ptr;
    has_symbols : boolean;
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

  procedure build_list(var obj_list:list_ptr;
                         buffer:byte_array_ptr;
                         hash_table:hash_ptr);

  procedure add_unit(var objname:string);
  function  get_unit(unit_ofs:word):unit_list_ptr;
  function  get_unit_by_name(var name:string):unit_list_ptr;
  function  get_unit_num(var name:string):word;

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
             obj := add_offset(buffer,t);
             { get the next object... }
            t := obj^.next_obj;
          until t = 0;
        end;
  end;

  procedure add_unit(var objname:string);
  var
    size,total:word;
    header:^header_rec;
    unit_obj:obj_ptr;
    junk : pointer;

  procedure load_buffer;
  begin
    with unit_list[num_known]^ do
    begin
      path := objname+'.tpu';
      read_file(path,pointer(header),0,sizeof(header^));
      if header = nil then
      begin
        path := uses_path+path;
        read_file(path,pointer(header),0,sizeof(header^));
      end;
      if header <> nil then
      begin
        read_file(path,pointer(buffer),0,header^.sym_size);
        if buffer <> nil then
          has_symbols := true;
        exit;
      end;
      path := '';
      if got_tpl then
      begin
        header := pointer(tpl_buffer);
        total := 0;
        repeat
          unit_obj := add_offset(header,header^.ofs_this_unit);
          if unit_obj^.name = objname then
          begin
            buffer := pointer(header);
            has_symbols := true;
            exit;
          end;
          size := roundup(header^.sym_size,16)
                 +roundup(header^.code_size,16)
                 +roundup(header^.reloc_size,16)
                 +roundup(header^.const_size,16)
                 +roundup(header^.vmt_size,16);
          total := total+size;
          header := add_offset(header,size);
        until (total >= tpl_size) or (size = 0);
      end;
      writeln('Warning:  Can''t find unit ',objname);
    end;
  end;

  begin
    if get_unit_by_name(objname) <> nil then
      exit;

    inc(num_known);
    new(unit_list[num_known]);
    with unit_list[num_known]^ do
    begin
      name := objname;
      obj_list := nil;
      buffer := nil;
      has_symbols := false;
      getmem(junk,16-ofs(heapptr^) and $F);  { make it load at a paragraph }
      load_buffer;
      if has_symbols then
      begin
        own_record := header_ptr(buffer)^.ofs_this_unit;
        inc(own_record,
            4+length(obj_rec(add_offset(buffer,own_record)^).name));
      end;
    end;
  end;

  function get_unit(unit_ofs:word):unit_list_ptr;
  begin
    if unit_ofs > unit_list[1]^.own_record then
      get_unit := unit_list[word(add_offset(buffer,unit_ofs)^)]
    else
      get_unit := unit_list[1];
  end;

  function get_unit_by_name(var name:string):unit_list_ptr;
  var
    i : word;
  begin
    i := get_unit_num(name);
    if i <> 0 then
      get_unit_by_name := unit_list[i]
    else
      get_unit_by_name := nil;
  end;

  function get_unit_num(var name:string):word;
  var
    i : word;
  begin
    for i:=1 to num_known do
      if unit_list[i]^.name = name then
      begin
        get_unit_num := i;
        exit;
      end;
    get_unit_num := 0;
  end;
end.