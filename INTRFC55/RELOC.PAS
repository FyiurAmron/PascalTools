unit reloc;
{ unit to print relocation records }

interface
uses dump,util,globals,loader,nametype,head;

type
  reloc_ptr = ^reloc_rec;
  reloc_rec = record
    unit_num,            { offset to unit in unit block }
    rtype : byte;
    rblock,roffset,offset : word;
  end;

const
  code_seg  = 0;
  code_data = 1;
  var_seg   = 2;
  const_seg = 3;

procedure print_reloc(seg:byte);
procedure write_reloc_type(rtype:byte);

implementation

uses
  blocks;

function ref_type(rtype:byte):byte;
begin
  ref_type := (rtype shr 4) and 3;
end;

function target_type(rtype:byte):byte;
begin
  target_type := rtype shr 6;
end;

procedure print_reloc(seg:byte);
var
  codebase,codeofs,codelimit,
  base,ofs,limit : word;
  block : reloc_ptr;
  code_block : block_ptr;
  target_unit : unit_list_ptr;
  entry_pt : entry_pt_ptr;
  target_unit_name : string;
  fake_unit_info : unit_ptr;
begin
  case seg of
  code_seg : begin
        if header^.reloc_size = 0 then
          exit;
        writeln;
        writeln('Code segment relocation records');
        codebase :=header^.ofs_code_blocks;
        codelimit := header^.ofs_const_blocks-codebase;
     end;

  const_seg : begin
        if header^.vmt_size = 0 then
          exit;
        writeln;
        writeln('Const segment relocation records');
        codebase :=header^.ofs_const_blocks;
        codelimit := header^.ofs_var_blocks-codebase;
     end;
  end;
  writeln('  Reloc');
  writeln('  Offset  Fixup Type    Unit       Block:Offset');
  base := 0;
  codeofs := 0;
  while codeofs < codelimit do
  begin
    code_block := add_offset(buffer,codebase+codeofs);
    write('---');
    case seg of
      code_seg:  write_code_block_name(code_block^.owner);
      const_seg: write_const_block_name(code_block^.owner);
    end;
    writeln('---');
    ofs := 0;
    limit := code_block^.relocbytes;
    while ofs < limit do
    begin
      block := add_offset(reloc_buf,base+ofs);
      with block^ do
      begin
        write(hexword2(codeofs),':',hexword(offset),' ');
        write_reloc_type(rtype);

        target_unit_name := unit_name(unit_num);
        write(target_unit_name:10);

        if target_type(rtype) = 0 then
        begin
          { It might be a good idea to try to add the unit to the unit_list
            here, but I don't think so.  Let it fail if it wants to. }

          target_unit := get_unit_by_name(target_unit_name);

          if (target_unit <> nil) and (target_unit^.buffer <> nil) then
            with target_unit^ do
            begin
              entry_pt := add_offset(buffer,
                           header_ptr(buffer)^.ofs_entry_pts+rblock);
              write(' ',hexword2(entry_pt^.code_block),':',
                    hexword(entry_pt^.offset));
            end
          else
            write(' entry',hexword(rblock));
        end
        else
          write(' ',hexword2(rblock),':',hexword(roffset));
        writeln;
      end;
      inc(ofs,sizeof(reloc_rec));
    end;
    inc(base,ofs);
    inc(codeofs,sizeof(block_rec));
  end;
end;

procedure write_reloc_type(rtype:byte);
begin
  if (rtype and $0F) <> 0 then
    write  ('Unknown type ',hexbyte(rtype):4);

  case ref_type(rtype) of
  0 : write('Relative ');
  1 : write('Offset   ');
  2 : write('Segment  ');
  3 : write('Pointer  ');
  end;

  case target_type(rtype) of
  code_seg  : write('Code    ');
  code_data : write('CS Const');
  var_seg   : write('Var     ');
  const_seg : write('DS Const');
  end;
end;

end.
