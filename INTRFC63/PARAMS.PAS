unit params;
interface
  uses dos,globals,util;

  procedure syntax_exit(msg:string);
  procedure parse_params;

implementation

procedure syntax_exit(msg:string);
var
  junk : char;
begin
  writeln(msg);
  writeln('Syntax:');
  writeln('INTRFC /options unit');
  writeln('where options are letters from the following:');
  writeln('B - emitted code bytes');
  writeln('C - initialized constant blocks');
  writeln('D - code blocks');
  writeln('E - routine entry records');
  writeln('G - emitted global const bytes');
  writeln('H - TPU header');
  writeln('I - implementation section (if $D was used in compilation)');
  writeln('L - proc/fn locals (if $L was used in compilation)');
  writeln('M - source line number map');
  writeln('N - names in interface');
  writeln('O - object VMT records');
  writeln('R - relocation records');
  writeln('S - source file records');
  writeln('U - unit list');
  writeln('V - var blocks');
  writeln('W - windows DLL list');
  writeln('A - turn all options on');
  writeln('Options are processed sequentially and toggle the display.');
  write('<Hit Enter for more...>');
  read(junk);
  writeln('Use /Tpath to set the Turbo directory for ',tpl_name,' and referenced');
  writeln(' units.');
  writeln('E.G. To see all but the relocation records in the system unit, use');
  writeln('   INTRFC /AR /T\turbo SYSTEM ');
  writeln('The default is just the names in the interface section.');
  halt(1);
end;

procedure toggle(o:option);
begin
  if o in active_options then
    active_options := active_options - [o]
  else
    active_options := active_options + [o];
end;

procedure parse_params;
var
  p : string;
  i : integer;
  path : dirstr;
  name : namestr;
  ext : extstr;

begin
  i := 1;
  unitname := '';
  uses_path := '';
  for i := 1 to paramcount do
  begin
    p := paramstr(i);
    if p[1] <> '/' then
    begin
      unitname := upper(p);
      fsplit(unitname,path,name,ext);
      unitname := path+name;
    end
    else
    begin
      p := copy(p,2,255);   { strip off the / }
      while length(p) > 0 do
      begin
        case upcase(p[1]) of
        'A' : active_options := [do_header..do_locals];
        'B' : toggle(do_code);
        'C' : toggle(do_const_blocks);
        'D' : toggle(do_code_blocks);
        'E' : toggle(do_entry_pts);
        'G' : toggle(do_const);
        'H' : toggle(do_header);
        'I' : toggle(do_implementation);
        'L' : toggle(do_locals);
        'M' : toggle(do_src_lines);
        'N' : toggle(do_name_list);
        'O' : toggle(do_vmt);
        'R' : toggle(do_reloc);
        'S' : toggle(do_src_files);
        'U' : toggle(do_unit_blocks);
        'V' : toggle(do_var_blocks);
        'W' : toggle(do_dll_blocks);
        'T' : begin
                uses_path := copy(p,2,255);
                if uses_path[length(uses_path)] <> '\' then
                  uses_path := uses_path + '\';
                p := '';
              end;
        else
          syntax_exit('Unrecognized option '+paramstr(i)+'.');
        end;
        p := copy(p,2,255);
      end;
    end;
  end;
  if unitname = '' then
    syntax_exit('Unit name not specified.');
end;

end.
