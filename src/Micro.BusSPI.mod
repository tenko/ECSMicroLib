(* Alexander Shiryaev, 2016.12
    Modified by Tenko for use with ECS
*)
MODULE BusSPI IN Micro;

IMPORT SYSTEM;

CONST
    (* res values: *)
    resComplete* = 0;
    resNotStarted* = 1;
    resStarted* = 2;
    resError* = 3;

TYPE
    ADDRESS = SYSTEM.ADDRESS;
    
    Bus* = RECORD
        res*, err*: INTEGER;
		n*: INTEGER;
		overruns*: INTEGER;
    END;

(** Callback on operation completion *)
PROCEDURE (VAR b- : Bus) OnComplete*;
BEGIN END OnComplete;

(** Read len bytes to memory location in adr and send TXChar *)
PROCEDURE (VAR b : Bus) Read* (adr: ADDRESS; len: LENGTH; TXChar : CHAR);
BEGIN END Read;

(** Write len bytes from memory location in adr *)
PROCEDURE (VAR b : Bus) Write* (adr: ADDRESS; len: LENGTH);
BEGIN END Write;

(** Write and read len bytes from/to memory locations in txAdr and rxArd *)
PROCEDURE (VAR b : Bus) ReadWrite* (txAdr, rxAdr: ADDRESS; len: LENGTH);
BEGIN END ReadWrite;

END BusSPI.