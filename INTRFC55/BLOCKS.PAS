unit blocks;

interface

type
  entry_pt_ptr = ^entry_pt_rec;
  entry_pt_rec = record
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

  debug_block_ptr = ^debug_block_rec;
  debug_block_rec = record
    obj_ofs, w2, w3, startline, len : word;
    bytes_per_line : array[1..1] of byte;
  end;

procedure print_entries;
procedure print_code_blocks;
procedure print_const_blocks;
procedure print_var_blocks;
procedure print_unit_blocks;

function unit_name(ofs:word):string;
procedure write_code_block_name(debug_ofs : word);
procedure write_const_block_name(info_ofs : word);

procedure add_referenced_units;

implementation

uses dump,util,globals,head,loader,namelist,nametype,reloc;

procedure print_entries;
var
  block:entry_pt_ptr;
  ofs,limit : word;
begin
  ofs := 0;
  limit := header^.ofs_code_blocks-header^.ofs_entry_pts;
  if ofs<limit then
  begin
    writeln('Entry records');
    writeln('    Proc     Code block:offset');
  end;
  while ofs<limit do
  begin
    block := add_offset(buffer,header^.ofs_entry_pts+ofs);
    writeln(hexword2(ofs):8,
            hexword2(block^.code_block):12,':',hexword(block^.offset));
    inc(ofs,sizeof(block^));
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
  ofs := 0;
  if ofs < limit then
  begin
    writeln(blocktype,' blocks');
    writeln('Blocknum   Bytes  Relocrecs   Owner');
  end;
  while ofs < limit do
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
      writeln;
      if w1 <> 0 then
        writeln(' w1 = ',hexword(w1));
    end;
    inc(ofs,sizeof(block_rec));
  end;
end;

procedure print_code_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_code_blocks;
  limit := header^.ofs_const_blocks - base;
  print_blocks('Code',base,limit);
end;

procedure print_const_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_const_blocks;
  limit := header^.ofs_var_blocks - base;
  print_blocks('Const',base,limit);
end;

procedure print_var_blocks;
var
  base,limit:word;
begin
  base := header^.ofs_var_blocks;
  limit := header^.ofs_unit_list - base;
  print_blocks('Var',base,limit);
end;

procedure print_unit_blocks;
var
  base,ofs,limit:word;
  block : unit_block_ptr;
begin
  base := header^.ofs_unit_list;
  ofs := 0;
  limit := header^.ofs_src_name - ofs;
  writeln('Unit list');
  writeln(' Offset    w1     Name');
  while base+ofs < limit do
  begin
    block := add_offset(buffer,base+ofs);
    with block^ do
    begin
      writeln(hexword2(ofs):8,hexword2(w1):8,'  ',name);
      ofs := ofs + 3 + length(name);
    end;
  end;
end;

function unit_name(ofs:word):string;
begin
  unit_name := unit_block_ptr(
                add_offset(buffer,header^.ofs_unit_list+ofs))^.name;
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
    add_unit(block^.name);
    ofs := ofs + 3 + length(block^.name);
  end;
end;

end.
