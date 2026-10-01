INTRFC - Program to dump TPU files. (March, 1994)

Version 7.0:  Dumps TPU, TPP and TPW format files.

     Written for the public domain by Milan Dadok.
     Internet: xdadok00@dcse.fee.vutbr.cz (till September 1995)

INTRODUCTION

     Several times I had to write the source of a tpu, because it was
     not available. I started to look for some documentation about TPU
     files and I found INTRFC from D.J. Murdoch, that works with TP 6.0
     tpu files (see history below). Because I needed to dump TPU files
     from BP 7.0 and I was wondering how tpu files are encoded, I
     upgraded it to BP 7.0 files. I also fixed same mistakes and added
     some new features (print enum and set constants etc).

     Because D.J. Murdoch does not plan to update INTRFC any more,
     please send bugs only to my Internet address.

     The reason I included source code is because it will serve as a bit
     of documentation for the TPU file format:  Borland will never
     publish it.  They want to be free to change the format, tweaking
     performance when they can.

     You must compile INTRFC in BP 7.0. Normally it will dump only BP
     7.0 (TPUQ) files. If you want to dump TP 6.0 (TPU9) files, you must
     recompile INTRFC with the symbol UNIT60 defined. Change SWITCHES.INC
     or compile with BPC: BPC intrfc.pas /b /DUNIT60


USAGE:
       INTRFC /options unit [output_file]
   where options are letters from the following:
     B - emitted code bytes
     C - initialized constant blocks
     D - code blocks
     E - routine entry records
     G - emitted global const bytes
     H - TPU header
     I - implementation section (if $D was used in compilation)
     L - proc/fn locals (if $L was used in compilation)
     M - source line number map
     N - names in interface
     O - const relocation records
     R - relocation records
     S - source file records
     U - unit list
     V - var blocks
     W - exported name records
     Z - browser section {$Y+}
     A - turn all options on

     Options are processed sequentially and toggle the display.
     Use /Tpath[;path] to set the Turbo directory for TURBO.TPL
      and referenced units.
     E.G. To see all but the relocation records in the system unit, use
        INTRFC /AR /T\bp\bin;\bp\units SYSTEM
     The default is just the names in the interface section.

LIMITATIONS

     There are tons of limitations to INTRFC.  It doesn't know how to
     print the values of typed constants. Etc. Etc. Etc. If you want it
     to do something differently just go ahead and change it!

     I recommend compiling with all possible checks turned on, since
     it's pretty easy to get lost in all those pointers and records.

FILES

     The following files should be included in this package.

      INTRFC70 DOC    This file
      TPU9     DOC    TPU structure outline (TP 6.0)
      TPUQ     DOC    TPU structure outline (BP 7.0)
      INTRFC   EXE    The executable to dump BP 7.0 tpu files

      INTRFC   PAS    Main program
      GLOBALS  PAS    Program globals

      HEAD     PAS    TPU header dumper
      NAMELIST PAS    Prints interface section
      NAMETYPE PAS    Type definitions for NAMELIST
      BLOCKS   PAS    Routines for code blocks, etc.
      SRCFILES PAS    Prints source files & line numbers
      RELOC    PAS    Prints relocation records
      CODE     PAS    Code and const dumper

      DUMP     PAS    Various dump routines
      LOADER   PAS    Reads in .TPU and .TPL files
      UTIL     PAS    Various utility routines
      TEST1    PAS    Test file
      TEST1    INC    Test include file
      TEST1    ASM    Test assembler file
      TEST1    OBJ    Test object file
      PARAMS   PAS    Parses parameters

     Have fun with INTRFC and Turbo (or Borland) Pascal.

Milan Dadok

HISTORY of INTRFC (by D.J. Murdoch)

     I started INTRFC because I got a library of Turbo Pascal 4.0
     subroutines which had some errors in the documentation.  One of the
     functions wanted its arguments to be a special type, but the docs
     didn't tell me which one.  TP gave me an error message saying I
     wasn't using the right type, but wouldn't tell me which one to use
     either.  I decided to decode the TPU file and figure out what TP
     wanted.  Once I got started, it was hard to stop. So, I ended up
     writing INTRFC, which printed out almost all the information you'll
     ever need about the interface to a TPU unit.

     When I upgraded INTRFC to TP 5.5 files, I got carried away again.
     Version 1.2 dumped the complete file, not just the interface
     section.

     The release of TP 6.0 made it necessary to upgrade again. This one
     was easy:  there aren't very many differences between version 5.5
     and 6.0 .TPU files.  I decided to fill in a couple of gaps in
     version 1.2, and the current one dumps everything in the file.
     However, I made a few mistakes in release 1.3; version 1.31 fixed
     those.

     When TP for Windows, version 1.0, came out, I was amazed that
     version 1.31 almost worked; it turns out that the file format for
     TP6 and TPW1 is identical.  There were a few errors in INTRFC 1.31
     because some of the Windows features had never showed up; version
     1.32 filled in those areas.  I also cleaned up the display a bit.

     In June '92, TPW 1.5 came out with completely compatible .TPU
     files. No need for an upgrade.  However, William Peavy pointed out
     the omission of the flag for "interrupt" procedures, so I added
     that in.  I also got tired of the terrible numbering scheme I'd
     stuck to for so long, and decided that instead of 1.33, I'd call
     the new one 6.3.

     Because of the way INTRFC has been written, i.e. entirely by
     guesswork, there are probably special cases that it doesn't handle
     properly.  That's one reason the source code is there - so other
     people can fix up my mistakes.

     The other reason I included source code is because it will serve as
     a bit of documentation for the TPU file format:  Borland will never
     publish it.  They want to be free to change the format, tweaking
     performance when they can.  (As you'll see if you study the .TPU
     design, the famous "obsolete .TPU" problem doesn't come from the
     frequent format changes; it's basic to the .TPU design itself.
     References to old SYSTEM and other units just can't be updated.)
     This reason has become a little obsolete now:  William Peavy has
     written a very complete description of the TP 6.0/TPW 1.x .TPU
     format; I highly recommend picking up a copy.

