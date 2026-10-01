program stripped;

{ Program to detect .EXE files which have been damaged by Borland's TDSTRIP. }
{ Searches complete directory tree of current disk. }

uses dos,objects;

procedure Syntax_Exit(msg:string);
begin
  writeln(msg);
  writeln;
  writeln('Syntax:  STRIPPED dir ');
  writeln(' will print list of files from in the dir and its subdirs which');
  writeln(' have bad initial minimum memory allocations, presumably because');
  writeln(' of damage by TDSTRIP.');
  halt(99);
end;

type
  exe_header = record
    sig,
    remainder,
    pages,
    relocs,
    header,
    min_extra,
    max_extra,
    stackseg,
    stackofs : word;
  end;

var
  currentdir : string;
  filecount,badfilecount : word;

procedure testdir;
{ Tests all files in current directory.  Assumes currentdir has trailing backslash }
var
  exe : TDOSStream;
  s : searchrec;
  header : exe_header;
  image : longint;
  extra : longint;
  stackneeds : longint;
  headersize : longint;
  foundbad : boolean;
begin
  foundbad := false;
  findfirst(currentdir + '*.exe',anyfile,s);
  while Doserror = 0 do
  begin
    exe.init(currentdir+s.name,stOpenRead);
    exe.read(header,sizeof(header));
    if exe.status <> stOK then
      writeln('Warning:  Unable to open',currentdir,s.name)
    else
    begin
      inc(filecount);
      if header.sig = $5A4d then
        with header do
        begin
          image := longmul(pages,512) - longmul(16,header);
          extra := longmul(16,min_extra);               { stack and heap }
          headersize := image + extra;
          stackneeds := longmul(stackseg,16) + stackofs;
          if headersize < (longmul(stackseg,16) + stackofs) then
          begin
            if not foundbad then
            begin
              foundbad := true;
              writeln(currentdir);
            end;
            writeln(s.name:30,headersize+256:15,  { Add in 256 byte PSP }
                    ' < RAM < ',stackneeds+256);
            inc(badfilecount);
          end
        end;
    end;
    exe.done;
    findnext(s);
  end;
end;

type
  string12 = string[12];

function realdir(name:string12):boolean;
begin
  realdir := (name <> '.') and (name <> '..');
end;

procedure addbackslash;
begin
  currentdir := currentdir + '\';
end;

procedure testalldirs;
var
  s : searchrec;
  oldlength : byte;

  procedure addsuffix(suffix:namestr);  { Separate proc to save stack space }
  begin
    currentdir := copy(currentdir,1,oldlength) + suffix;
  end;


begin
  oldlength := length(currentdir);
  testdir;
  addsuffix('*.*');
  findfirst(currentdir,directory,s);
  while doserror = 0 do
  begin
    if s.attr = directory then
    begin
      if realdir(s.name) then
      begin
        addsuffix(s.name);
        addbackslash;
        testalldirs;          { do directory recursively }
      end;
    end;
    findnext(s);
  end;
end;

begin
  writeln('STRIPPED - Check directories for files damaged by TDSTRIP.');
  if paramcount <> 1 then
    syntax_exit('No directory specified.');
  writeln('Dir','File  ':27,'Bad stack zone':27);
  filecount := 0;
  badfilecount := 0;
  currentdir := paramstr(1);
  if currentdir[length(currentdir)] <> '\' then
    addbackslash;
  testalldirs;
  writeln;
  if filecount > 0 then
  begin
    writeln('Tested ',filecount,' .EXE files.');
    if badfilecount > 0 then
    begin
      writeln('Found ',badfilecount,' files which will load when RAM is in the');
      writeln('given range but which won''t have space for a proper stack.');
    end
    else
      writeln('No bad headers found.');
  end
  else
    writeln('No .EXE files found in directory ',paramstr(1));
end.
