unit code;
{$I SWITCHES.INC}
interface

procedure print_dump(seg:byte);

implementation

uses globals,head,blocks,reloc,dump,util,loader;

procedure print_dump(seg:byte);
var
  codebase,codeofs,codelimit,
  base,ofs,limit : word;
  code_block : block_ptr;
  block : byte_array_ptr;
begin
  case seg of
  code_seg : begin
        if header^.code_size = 0 then
          exit;
        writeln;
        writeln('Emitted code');
        codebase :=header^.ofs_code_blocks;
        codelimit := header^.ofs_const_blocks-codebase;
     end;

  const_seg : begin
        if header^.const_size = 0 then
          exit;
        writeln;
        writeln('Emitted consts');
        codebase :=header^.ofs_const_blocks;
        codelimit := header^.ofs_var_blocks-codebase;
     end;
  end;
  base := 0;
  codeofs := 0;
  while codeofs < codelimit do
  begin
    code_block := add_only_offset(buffer,codebase+codeofs);
    write('---');
    case seg of
      code_seg:  write_code_block_name(unit_list[1],codeofs);
      const_seg: write_const_block_name(code_block^.owner);
    end;
    write('---(block ',hexwordblank(codeofs),')');
    ofs := 0;
    limit := code_block^.size;
    dumpbytes(add_only_offset(code_buf,base)^,0,limit);
    inc(base,limit);
    inc(codeofs,sizeof(block_rec));
  end;
end;

end.