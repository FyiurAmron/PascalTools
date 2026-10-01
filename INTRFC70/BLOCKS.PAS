unit blocks;
{$I SWITCHES.INC}

interface

uses nametype,loader;

{$IFNDEF UNIT60}
type
  entry_flags = set of (ent_exported,ent_from_dll,ent_by_name,f08,f10,f20,f40,f80);
{$ELSE}
const
  ent_exported = exported;
  ent_from_dll = from_dll;
  ent_by_name = by_name;
type
  entry_flags = obj_flags;
{$ENDIF}
  entry_pt_ptr = ^entry_pt_rec;
  entry_pt_rec = record
    w1 : word;
    flags : entry_flags;
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

  unit_block60_ptr = ^unit_block60_rec;
  unit_block60_rec = record
    w1 : word;
    name : string;
  end;

  unit_block_ptr = ^unit_block_rec;
  unit_block_rec = record
    w1 : word;
{$IFNDEF UNIT60}
    refcount : word;
{$ENDIF}
    name : string;
  end;

  dll_block_ptr = ^dll_block_rec;
  dll_block_rec = record
    w1,w2 : word;
    name : string;
  end;

procedure print_entries;
procedure print_code_blocks;
procedure print_const_blocks;
procedure print_var_blocks;
procedure print_dll_blocks;
procedure print_unit_blocks;

function unit_name(ofs:word):string;
function dll_name(ofs:word):string;

procedure write_code_block_name(in_unit:unit_list_ptr;blocknum:word);
procedure write_const_block_name(info_ofs : word);

implementation

uses dump,util,globals,head,namelist,reloc,srcfiles;

procedure print_entries;
var
  block:entry_pt_ptr;
  base,limit,ofs : word;
  dll : dll_block_ptr;
  unknown_flags : entry_flags;
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
      block := add_only_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexwordblank(ofs):8);
        if ent_from_dll in flags then { external from dll }
        begin
          dll := add_only_offset(buffer,header^.ofs_dll_list+code_block);
          write(dll^.name:12,'.');
          if ent_by_name in flags then
          begin
            dll := add_only_offset(buffer,header^.ofs_dll_list+offset);
            write(dll^.name);
            if length(dll^.name)<=2 then
              write(tab);
          end
          else
            write(offset,tab);
        end
        else
          write(hexwordblank(block^.code_block):12,':',
                hexword(block^.offset));
        if ent_exported in flags then
          write(' exported')
        else
          write('         ');
        write(tab,find_proc_with_entry(unit_list[1],ofs));
        unknown_flags:=flags-[ent_from_dll,ent_by_name,ent_exported];
        if unknown_flags<>[] then
          WriteError(' Unrecognized code entry flags: '+hexbyte(byte(unknown_flags)));
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

procedure write_code_block_name(in_unit:unit_list_ptr;blocknum:word);
var
  block:entry_pt_ptr;
  base,limit,ofs : word;
  s:string;
begin
  { find entry proc }
  base:=header^.ofs_entry_pts;
  limit := header^.ofs_code_blocks;
  ofs := 0;
  while base+ofs<limit do
  begin
    block := add_only_offset(buffer,base+ofs);
    if (block^.code_block=blocknum) and not (ent_from_dll in block^.flags) then
    begin
      { find obj which own block^.entry (ofs) }
      write('  ',find_proc_with_entry(unit_list[1],ofs));
    end;
    inc(ofs,sizeof(entry_pt_rec));
  end;
end;

procedure write_const_block_name(info_ofs : word);
var
  obj : obj_ptr;
begin
  if info_ofs = 0 then
    exit;
  obj := find_type_or_proc(unit_list[1],info_ofs);
  if obj <> nil then
    write(obj^.name)
  else
    write('obj',hexword(info_ofs));
end;

procedure print_blocks(const blocktype:string; base,limit:word);
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
    if blocktype='Code' then
      writeln('Blocknum   Bytes  Relocrecs Lineinfo Owner')
    else
      writeln('Blocknum   Bytes  Relocrecs  Owner');
    ofs := 0;
    while base+ofs < limit do
    begin
      block := add_only_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexwordblank(ofs):8,hexwordblank(size):8,
              hexwordblank(relocbytes):8,hexwordblank(owner):8,'     ');
        if blocktype = 'Code' then
          write_code_block_name(unit_list[1],ofs)
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
  writeln('DLL exported names list');
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
      block := add_only_offset(buffer,base+ofs);
      with block^ do
      begin
        write(hexwordblank(ofs):8,'  ',name);
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
  block60 : unit_block60_ptr;
  block : unit_block_ptr;
  li:integer;
begin
  writeln;
  writeln('Unit list');
  base := header^.ofs_unit_list;
  limit := header^.ofs_src_name;
  if base >= limit then
    writeln('(none)')
  else
  begin
    write(' Offset    Name');
{$IFNDEF UNIT60}
      write('     References');
{$ENDIF}
    writeln;
    ofs := 0;
    while base+ofs < limit do
    begin
      block := add_only_offset(buffer,base+ofs);
{$IFDEF UNIT60}
        with unit_block60_ptr(block)^ do
        begin
          write(hexwordblank(ofs):8,'  ',name);
          if w1 <> 0 then
            write(' w1 = ',hexword(w1));
          writeln;
          Inc(ofs, 3 + length(name));
        end
{$ELSE}
        with block^ do
        begin
          write(hexwordblank(ofs):8,'  ',name);
          write('':8-length(name)+4,HexWordAsm(refcount div 4):5);
          if refcount mod 4<>0 then
            WriteError('unit references not multiple 4 '+HexWord(refcount));
          if w1 <> 0 then
            write(' w1 = ',hexword(w1));
          writeln;
          Inc(ofs,5 + length(name));
        end;
{$ENDIF}
    end;
  end;
end;

function unit_name(ofs:word):string;
begin
  unit_name := unit_block_ptr(
                add_only_offset(buffer,header^.ofs_unit_list+ofs))^.name;
end;

function dll_name(ofs:word):string;
begin
  dll_name := dll_block_ptr(
                add_only_offset(buffer,header^.ofs_dll_list+ofs))^.name;
end;

end.
