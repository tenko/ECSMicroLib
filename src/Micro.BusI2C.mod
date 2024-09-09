MODULE BusI2C IN Micro;

(* Alexander Shiryaev, 2016.12
    Modified by Tenko for use with ECS
*)
IMPORT SYSTEM;

CONST
    (* read options *)
    opt0* = 0;

    (* res *)
    ok* = 0;
    
    outBufLen* = 128;
	inBufLen* = 128;

TYPE
    ADDRESS = SYSTEM.ADDRESS;
    
    Bus* = RECORD
        outBuf: ARRAY outBufLen OF CHAR;
		inBuf: ARRAY inBufLen OF CHAR;
    END;

(** Callback on operation completion *)
PROCEDURE (VAR b- : Bus) OnComplete*;
BEGIN END OnComplete;

(** Read len bytes to memory location adr from peripheral specified by addr *)
PROCEDURE (VAR b : Bus) Read*(addr: INTEGER; adr: ADDRESS; len: LENGTH; VAR ok: BOOLEAN);
BEGIN END Read;

(**
Read len bytes to memory location adr from peripheral specified by addr starting
from the memory address maddr.
*)
PROCEDURE (VAR b : Bus) ReadMem*(addr, maddr: INTEGER; adr: ADDRESS; len: LENGTH; VAR ok: BOOLEAN);
BEGIN END ReadMem;

(** Write len bytes from memory location adr to peripheral specified by addr *)
PROCEDURE (VAR b : Bus) Write*(addr: INTEGER; adr: ADDRESS; len: LENGTH; VAR ok: BOOLEAN);
BEGIN END Write;

(**
Write len bytes to memory location adr to peripheral specified by addr starting
from the memory address maddr.
*)
PROCEDURE (VAR b : Bus) WriteMem*(addr, maddr: INTEGER; adr: ADDRESS; len: LENGTH; VAR ok: BOOLEAN);
BEGIN END WriteMem;

END BusI2C.