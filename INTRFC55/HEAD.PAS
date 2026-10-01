unit head;
{ Header declarations and dumper }
interface

uses globals,util,dump;

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
    ofs_unit_list,                {14-15}
    ofs_src_name,                 {16-17}
    ofs_line_lengths,             {18-19}
    sym_size,                     {1A-1B}
    code_size,                    {1C-1D}
    const_size,                   {1E-1F}
    reloc_size,                   {20-21}
    vmt_size,                     {22-23}
    var_size,                     {24-25}
    ofs_full_hash: word;          {26-27}
    other : array[$28 div 2..$3F div 2] of word; {28-3F}
  end;

var
  header : ^header_rec;

procedure print_header;

implementation

procedure print_header;
var
  i:integer;
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

    writeln('Other:');
    for i := $28 div 2 to $3f div 2 do
      write(i:4,':',hexword2(other[i]):4,' ');
    writeln;
  end;
end;

end.
