unit blocks;

interface

uses nametype;

type
  entry_pt_ptr = ^entry_pt_rec;
  entry_pt_rec = record
    w1 : word;
    flags : obj_flags;
    b1 : byte;
    code_block, offset : word;
  end;

  block_ptr = ^block_rec;
  block_rec = record
    w1,size : word;
    relocbytes,owner : word;
  end;

  const_block_ptr = ^const_block_rec;
  const_block_rec = record
    w1,size : word;
    relocbytes,obj_ofs : word;
  end;

  vmt_block_ptr = ^vmt_block_rec;
  vmt_block_rec = record
    unitnum,rtype : byte;
    entrynum,w3,vmt_ofs : word;
  end;

  unit_block_ptr = ^unit_block_rec;
  unit_block_rec = record
    w1 : word;
    name : string;
  end;

  dll_block_ptr = ^dll_block_rec;
  dll_block_rec = record
    w1,w2 : word;
    name : string;
  end;

  debug_block_ptr = ^debug_block_rec;
  debug_block_rec = record
    obj_ofs, w2, w3, startline, len : word;
    bytes_per_line : array[1..1] of byte;
  end;

procedure print_entries;
procedure print_code_blocks;
procedure print_const_blocks;
procedure print_var_blocks;
procedure print_dll_blocks;
procedure print_unit_blocks;

function unit_name(ofs:word):string;
function dll_name(ofs:word):string;

procedure write_code_block_name(debug_ofs : word);
procedure write_const_block_name(info_ofs : word);

procedure add_referenced_units;

implementation

uses dump,util,globals,head,loader,namelist,reloc;

procedure print_entries;
var
  block:entry_pt_ptr;
  base,limit,ofs : word;
  dll : dll_block_ptr;
begin
  writeln;
  writeln('Entry records');
  base  := header^.ofs_entry_pts;
  limit := header^.ofs_code_blocks;
  if base>=limit then
    writeln('(none)')
  else
  begin
    writeln('    Proc    Code block:offset');
    ofs := 0;
    while base+ofs<limit do
    begin
      block := add_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexword2(ofs):8);
        if from_dll in flags then
        begin
          dll := add_offset(buffer,header^.ofs_dll_list+code_block);
          write(dll^.name:12,' ');
          if by_name in flags then
          begin
            dll := add_offset(buffer,header^.ofs_dll_list+offset);
            write('Name ',dll^.name:8);
          end
          else
            write('Index ',offset:7);
        end
        else
          write(hexword2(block^.code_block):12,':',hexword(block^.offset));
        if w1 <> 0 then
          write('w1 = ',hexword(w1));
        if b1 <> 0 then
          write('b1 = ',hexbyte(b1));
        writeln;
      end;
      inc(ofs,sizeof(block^));
    end;
  end;
end;

procedure write_code_block_name(debug_ofs : word);
var
  debug : debug_block_ptr;
  obj : obj_ptr;
  info : func_info_ptr;
  parent_info : word;
  parent_obj : obj_ptr;
begin
  if debug_ofs = $FFFF then
    exit;
  debug := add_offset(buffer,header^.ofs_line_lengths+debug_ofs);
  if debug^.obj_ofs = 0 then
    write('Startup code')
  else
  begin
    obj := add_offset(buffer,debug^.obj_ofs);
    if obj^.obj_type = proc_id then
    begin
      info := add_offset(obj,4+length(obj^.name));
      parent_info := info^.parent_ofs;
      if parent_info <> 0 then
      begin
        parent_obj := find_type(unit_list[1],parent_info);
        if parent_obj <> nil then
          write(parent_obj^.name,'.')
        else
          write('obj',hexword(parent_info),'.');
      end;
    end;
    write(obj^.name);
  end;
end;

procedure write_const_block_name(info_ofs : word);
var
  obj : obj_ptr;
begin
  if info_ofs = 0 then
    exit;
  obj := find_type(unit_list[1],info_ofs);
  if obj <> nil then
    write(obj^.name)
  else
    write('obj',hexword(info_ofs));
end;

procedure print_blocks(blocktype:string; base,limit:word);
var
  ofs : word;
  block : block_ptr;
begin
  writeln;
  writeln(blocktype,' blocks');
  if base >= limit then
    writeln('(none)')
  else
  begin
    writeln('Blocknum   Bytes  Relocrecs   Owner');
    ofs := 0;
    while base+ofs < limit do
    begin
      block := add_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexword2(ofs):8,hexword2(size):8,hexword2(relocbytes):8,
                  hexword2(owner):8,' ');
        if blocktype = 'Code' then
          write_code_block_name(owner)
        else if blocktype = 'Const' then
          write_const_block_name(owner);
        if w1 <> 0 then
          write(' w1 = ',hexword(w1));
        writeln;
      end;
      inc(ofs,sizeof(block_rec));
    end;
  end;
end;

procedure print_code_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_code_blocks;
  limit := header^.ofs_const_blocks;
  print_blocks('Code',base,limit);
end;

procedure print_const_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_const_blocks;
  limit := header^.ofs_var_blocks;
  print_blocks('Const',base,limit);
end;

procedure print_var_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_var_blocks;
  limit := header^.ofs_dll_list;
  print_blocks('Var',base,limit);
end;

procedure print_dll_blocks;
var
  base,ofs,limit:word;
  block : dll_block_ptr;
begin
  writeln;
  writeln('DLL name list');
  base := header^.ofs_dll_list;
  limit := header^.ofs_unit_list;
  if base >= limit then
    writeln('(none)')
  else
  begin
    writeln(' Offset    Name');
    ofs := 0;
    while base+ofs < limit do
    begin
      block := add_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexword2(ofs):8,'  ',name);
        if w1 <> 0 then
          write(' w1= ',hexword(w1));
        if w2 <> 0 then
          write(' w2= ',hexword(w2));
        writeln;
        ofs := ofs + 5 + length(name);
      end;
    end;
  end;
end;

procedure print_unit_blocks;
var
  base,ofs,limit:word;
  block : unit_block_ptr;
begin
  writeln;
  writeln('Unit list');
  base := header^.ofs_unit_list;
  limit := header^.ofs_src_name;
  if base >= limit then
    writeln('(none)')
  else
  begin
    writeln(' Offset    Name');
    ofs := 0;
    while base+ofs < limit do
    begin
      block := add_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexword2(ofs):8,'  ',name);
        if w1 <> 0 then
          write(' w1 = ',hexword(w1));
        writeln;
        ofs := ofs + 3 + length(name);
      end;
    end;
  end;
end;

function unit_name(ofs:word):string;
begin
  unit_name := unit_block_ptr(
                add_offset(buffer,header^.ofs_unit_list+ofs))^.name;
end;

function dll_name(ofs:word):string;
begin
  dll_name := dll_block_ptr(
                add_offset(buffer,header^.ofs_dll_list+ofs))^.name;
end;

procedure add_referenced_units;
var
  block : unit_block_ptr;
  ofs   : word;
begin
  ofs := header^.ofs_unit_list;
  while ofs < header^.ofs_src_name do
  begin
    block := add_offset(buffer,ofs);
    add_unit(block^.name,nil);
    ofs := ofs + 3 + length(block^.name);
  end;
end;

end.
