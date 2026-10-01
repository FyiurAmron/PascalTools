unit hash;

interface

  uses util,globals;

  procedure build_list(var obj_list:list_ptr;
                         buffer:byte_array_ptr;
                         hash_table:hash_ptr);

  procedure add_unit(obj:obj_ptr; info:unit_ptr);
  function  get_unit(unit_ofs:word):unit_list_ptr;

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

  const
    num_known : word = 0;

  procedure add_unit(obj:obj_ptr; info:unit_ptr);
  var
    i,size,total:word;
    header:^header_rec;
    unit_obj:obj_ptr;

  procedure load_buffer;
  begin
    with unit_list[i]^ do
    begin
      size := read_file(obj^.name+'.tpu',pointer(buffer));
      if buffer <> nil then
        exit;
      size := read_file(uses_path+obj^.name+'.tpu',pointer(buffer));
      if buffer <> nil then
        exit;
      if got_tpl then
      begin
        header := pointer(tpl_buffer);
        total := 0;
        repeat
          unit_obj := add_offset(header,header^.ofs_this_unit);
          if unit_obj^.name = obj^.name then
          begin
            buffer := pointer(header);
            exit;
          end;
          size := roundup(header^.sym_size,16)
                 +roundup(header^.code_size,16)
                 +roundup(header^.reloc_size,16)
                 +roundup(header^.const_size,16);
          total := total+size;
          header := add_offset(header,size);
        until total >= tpl_size + 16;
      end;
      writeln('Warning:  Can''t find unit ',obj^.name);
    end;
  end;

  begin
    for i:=1 to num_known do
      if unit_list[i]^.name = obj^.name then
        exit;

    inc(num_known);
    i := num_known;
    if info^.target <> 0 then
      writeln('Warning!!  unit ',obj^.name,' has non-zero target=',info^.target);
    info^.target := i;    {  Save our ID there, so references can find the information  }
    new(unit_list[i]);
    with unit_list[i]^ do
    begin
      name := obj^.name;
      obj_list := nil;
      if i > 1 then
        load_buffer
      else
        buffer := globals.buffer;
      if buffer <> nil then
      begin
        own_record := header_ptr(buffer)^.ofs_this_unit;
        inc(own_record,
            4+length(obj_rec(add_offset(buffer,own_record)^).name));
      end;
    end;
  end;

  function get_unit(unit_ofs:word):unit_list_ptr;
  begin
    get_unit := unit_list[word(add_offset(buffer,unit_ofs)^)];
  end;

end.