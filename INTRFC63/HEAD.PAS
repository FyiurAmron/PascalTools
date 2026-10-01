unit head;
{ Header declarations and dumper }
interface

uses globals,util,dump;

type
  unit_flags = set of (ieee_reals,overlays,windows,f8,moveable,f20,preload,f80,
                       f100,f200,f400,f800,discardable,f2000,f4000,f8000);
type
  header_ptr = ^header_rec;
  header_rec = record
    file_id: array[0..3] of char; { 0-3 }
    i4,                           { 4-5 }
    i6,                           { 6-7 }
    ofs_this_unit,                { 8-9 }
    ofs_hashtable,                { A-B }
    ofs_entry_pts,                { C-D }
    ofs_code_blocks,              { E-F }
    ofs_const_blocks,             {10-11}
    ofs_var_blocks,               {12-13}
    ofs_dll_list,                 {14-15}
    ofs_unit_list,                {16-17}
    ofs_src_name,                 {18-19}
    ofs_line_lengths,             {1A-1B}
    sym_size,                     {1C-1D}
    code_size,                    {1E-1F}
    const_size,                   {20-21}
    reloc_size,                   {22-23}
    vmt_size,                     {24-25}
    var_size,                     {26-27}
    ofs_full_hash: word;          {28-29}
    flags : unit_flags;           {2A-2B}
    other : array[$2C..$3F] of byte; {2C-3F}
  end;

var
  header : ^header_rec;

procedure print_header;

implementation

procedure print_header;
var
  i:integer;
  new_flags : unit_flags;
begin
  with header^ do
  begin
    writeln('file_id:':20,file_id);
    writeln('i4:':20,hexword2(i4));
    writeln('i6:':20,hexword2(i6));
    writeln('ofs_this_unit:':20,hexword2(ofs_this_unit));
    writeln('ofs_hashtable:':20,hexword2(ofs_hashtable));
    writeln('ofs_entry_pts:':20,hexword2(ofs_entry_pts));
    writeln('ofs_code_blocks:':20,hexword2(ofs_code_blocks));
    writeln('ofs_const_blocks:':20,hexword2(ofs_const_blocks));
    writeln('ofs_var_blocks:':20,hexword2(ofs_var_blocks));
    writeln('ofs_dll_list:':20,hexword2(ofs_dll_list));
    writeln('ofs_unit_list:':20,hexword2(ofs_unit_list));
    writeln('ofs_src_name:':20,hexword2(ofs_src_name));
    writeln('ofs_line_lengths:':20,hexword2(ofs_line_lengths));
    writeln('sym_size:':20,hexword2(sym_size));
    writeln('code_size:':20,hexword2(code_size));
    writeln('const_size:':20,hexword2(const_size));
    writeln('reloc_size:':20,hexword2(reloc_size));
    writeln('vmt_size:':20,hexword2(vmt_size));
    writeln('var_size:':20,hexword2(var_size));
    writeln('ofs_full_hash:':20,hexword2(ofs_full_hash));
    write('flags:':20);
    if ieee_reals in flags then
      write('N+':4)
    else
      write('N-':4);
    new_flags := flags - [ieee_reals];
    writeln;
    if windows in flags then
    begin
      write('TPW options $C:':20);
      if moveable in flags then
        write('Moveable ')
      else
        write('Fixed ');
      if preload in flags then
        write('Preload ')
      else
        write('Demandload ');
      if discardable in flags then
        write('Discardable ')
      else
        write('Permanent ');
      new_flags := flags - [windows,moveable,preload,discardable];
    end
    else
    begin
      write('TP for DOS options:':20);
      if overlays in flags then
        write('O+':4)
      else
        write('O-':4);
      new_flags := flags - [overlays];
    end;
    if new_flags <> [] then
      write('unknown flags ',hexword(word(new_flags)));
    writeln;

    writeln('Other:');
    dumpbytes(header^,$2c,$3f-$2b);
    writeln;
  end;
end;

end.
