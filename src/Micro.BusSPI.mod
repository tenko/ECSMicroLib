(* Alexander Shiryaev, 2016.12
    Modified by Tenko for use with ECS
*)
MODULE BusSPI IN Micro;

IMPORT SYSTEM;

CONST
    (* res values: *)
    OK* = 0;
    ErrorTimeout* = -1;

TYPE
    ADDRESS = SYSTEM.ADDRESS;
    BYTE = SYSTEM.BYTE;
    
    Bus* = RECORD
        res*, maxTransferSize*: INTEGER;
    END;

(** Callback during transfer idle *)
PROCEDURE (VAR this : Bus) Idle*;
BEGIN
END Idle;

(**
General transfer routine.
 - rxAdr : address to read buffer. Can be 0 for tx only.
 - txAdr : address to write buffer. Can be 0 for rx only.
 - txConst : if TRUE then tx constant value.
 - dataSize : 8 or 16 bit.
 - len : length of buffer
 *)
PROCEDURE (VAR this : Bus) Transfer* (rxAdr, txAdr : ADDRESS; txConst : BOOLEAN; dataSize, len : LENGTH);
BEGIN END Transfer;

(** Read length bytes to buffer begining at start index and send TXByte *)
PROCEDURE (VAR this : Bus) Read*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH; TXByte : BYTE);
BEGIN
END Read;

(** Write length bytes from buffer begining at start index *)
PROCEDURE (VAR this : Bus) Write*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH);
BEGIN
END Write;

(**
Write length bytes from buffer begining at TXStart index
and at the same time read length bytes to buffer begining
at RXStart index.
*)
PROCEDURE (VAR this : Bus) ReadWrite*(VAR RXBuffer : ARRAY OF BYTE;VAR TXBuffer : ARRAY OF BYTE; RXStart, TXStart, length : LENGTH);
BEGIN
END ReadWrite;

END BusSPI.