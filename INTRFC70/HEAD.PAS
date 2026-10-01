unit head;
{$I SWITCHES.INC}
{ NENI cely tisk DPMI, WINDOWS }
{ Header declarations and dumper }
interface

uses globals,util,dump;

type
  unit_flags = set of (ieee_reals,overlays,windows60,i286,moveable,
                       f20,preload,f80,
                       dpmi,windows,f400,f800,
                       discardable,f2000,f4000,f8000);
{$IFDEF UNIT60}
const
  tpu_file_id = 'TPU9';
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
    const_reloc_size,             {24-25}
    var_size,                     {26-27}
    ofs_full_hash: word;          {28-29}
    flags : unit_flags;           {2A-2B}
    other : array[$2C..$3F] of byte; {2C-3F}
  end;
{$ELSE}
  {BP 7.0}
const
  tpu_file_id = 'TPUQ';

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
    ofs_line_count,               {1A-1B}
    ofs_line_lengths,             {1C-1D}
    sym_size,                     {1E-1F}
    browser_size,                 {20-21}
    code_size,                    {22-23}
    const_size,                   {24-25}
    reloc_size,                   {26-27}
    const_reloc_size,             {28-29}
    var_size,                     {2A-2B}
    ofs_full_hash: word;          {2C-2D}
    flags : unit_flags;           {2E-2F}
    object_type_list,             {30-31}   { offset of last object type def
                                      previous object in previous_object_def }
    br_defs_end,                  {32-33}
    br_symbol_refxx1 : word;      {34-35}
    next_tpu,                     {36-39} { next pointers used in TPUMOVER }
    browser_ptr,                  {3A-3D}
    code_ptr,                     {3E-41}
    const_ptr,                    {42-45}
    reloc_ptr,                    {46-49}
    const_reloc_ptr : pointer;    {4A-4D}
    other : array[$4e..$5F] of byte; {4E-3F}
  end;
{$ENDIF}

var
  header : header_ptr;

procedure print_header;

implementation

procedure print_header;
var
  i:integer;
  new_flags : unit_flags;

procedure WriteSegments;
begin
  if moveable in new_flags then
    write('Moveable ')
  else
    write('Fixed ');
  if preload in new_flags then
    write('Preload ')
  else
    write('Demandload ');
  if discardable in new_flags then
    write('Discardable ')
  else
    write('Permanent ');
  new_flags := new_flags - [moveable,preload,discardable];
end;

begin
  with header^ do
  begin
    writeln('file_id:':20,file_id);
    writeln('i4:':20,hexwordblank(i4));
    writeln('i6:':20,hexwordblank(i6));
    writeln('ofs_this_unit:':20,hexwordblank(ofs_this_unit));
    writeln('ofs_hashtable:':20,hexwordblank(ofs_hashtable));
    writeln('ofs_entry_pts:':20,hexwordblank(ofs_entry_pts));
    writeln('ofs_code_blocks:':20,hexwordblank(ofs_code_blocks));
    writeln('ofs_const_blocks:':20,hexwordblank(ofs_const_blocks));
    writeln('ofs_var_blocks:':20,hexwordblank(ofs_var_blocks));
    writeln('ofs_dll_list:':20,hexwordblank(ofs_dll_list));
    writeln('ofs_unit_list:':20,hexwordblank(ofs_unit_list));
    writeln('ofs_src_name:':20,hexwordblank(ofs_src_name));
{$IFNDEF UNIT60}
      writeln('ofs_line_count:':20,hexwordblank(ofs_line_count));
{$ENDIF}
    writeln('ofs_line_lengths:':20,hexwordblank(ofs_line_lengths));
    writeln('sym_size:':20,hexwordblank(sym_size));
{$IFNDEF UNIT60}
    writeln('browser_size:':20,hexwordblank(browser_size));
{$ENDIF}
    writeln('code_size:':20,hexwordblank(code_size));
    writeln('const_size:':20,hexwordblank(const_size));
    writeln('reloc_size:':20,hexwordblank(reloc_size));
    writeln('const_reloc_size:':20,hexwordblank(const_reloc_size));
    writeln('var_size:':20,hexwordblank(var_size));
    writeln('ofs_full_hash:':20,hexwordblank(ofs_full_hash));
{$IFNDEF UNIT60}
    writeln('object_type_list:':20,hexwordblank(object_type_list));
    writeln('br_defs_end:':20,hexwordblank(br_defs_end));
    writeln('br_symbol_refxx1:':20,hexwordblank(br_symbol_refxx1));
{$ENDIF}

    write('flags:':20);
    new_flags := flags;

    if ieee_reals in new_flags then
      write('N+':4)
    else
      write('N-':4);
    Exclude(new_flags,ieee_reals);
    if i286 in new_flags then
      write('G+':4)
    else
      write('G-':4);
    Exclude(new_flags,i286);
    if overlays in new_flags then
      write('O+':4)
    else
      write('O-':4);
    Exclude(new_flags,overlays);
    writeln;

    if windows60 in new_flags then
    begin
      write('TPW 1.X options $C:':20);
      WriteSegments;
      Exclude(new_flags,windows60);
    end
    else if windows in new_flags then
    begin
      write('TPW options $C:':20);
      WriteSegments;
      Exclude(new_flags,windows);
    end
    else if dpmi in new_flags then
    begin
      write('BP DPMI options $C:':20);
      WriteSegments;
      Exclude(new_flags,dpmi);
    end
    else
    begin
      write('TP for DOS options:':20);


    end;

    if new_flags <> [] then
      WriteError('unknown flags '+hexword(word(new_flags)));
    writeln;
    writeln;

    writeln('Other: ');
{$IFDEF UNIT60}
    dumpbytes(header^,$30,$50-$30)
{$ELSE}
    dumpbytes(header^,ofs(header^.next_tpu)-ofs(header^),
            sizeof(header^)-(ofs(header^.next_tpu)-ofs(header^)));
{$ENDIF}
  end;
end;

end.
