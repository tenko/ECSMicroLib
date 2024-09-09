(**
U[S]ART generic module

Alexander Shiryaev, 2016.09, 2017.04, 2019.10, 2020.12
Modified by Tenko for use with ECS
*)
MODULE BusUart IN Micro;

IMPORT SYSTEM;

CONST
    outBufLen* = 512; (* 2^n *)
    inBufLen* = 128; (* 2^n *)

TYPE
    ADDRESS = SYSTEM.ADDRESS;

    Bus* = RECORD
        (* out *)
            outFree*: INTEGER;
            (* W *)
                outW*: INTEGER; (* writer *)
            (* R *)
                outR*: INTEGER; (* reader *)
            outBusy*: BOOLEAN;

        (* in *)
            inFree*: INTEGER;
            (* W *)
                inW*: INTEGER; (* writer *)
            (* R *)
                inR*: INTEGER; (* reader *) 

        inBuf*: ARRAY inBufLen OF CHAR;
        outBuf*: ARRAY outBufLen OF CHAR
    END;

(** Return number of characters available in read buffer *)
PROCEDURE (VAR b- : Bus) Any*(): LENGTH;
BEGIN RETURN inBufLen - b.inFree END Any;

(** Return TRUE if write buffer can accomodate len characters *)
PROCEDURE (VAR b- : Bus) WriteAvailable*(len: LENGTH) : BOOLEAN;
BEGIN RETURN b.outFree >= len (* outFree access is safe here *)
END WriteAvailable;

(** Callback on idle condition *)
PROCEDURE (VAR b- : Bus) OnIdle*;
BEGIN END OnIdle;

(** Read n bytes to memory buffer at adr. done contains actual read bytes. *)
PROCEDURE (VAR b : Bus) Read*(adr: ADDRESS; len: LENGTH; VAR done: LENGTH);
BEGIN END Read;

(** Write len bytes memory buffer at adr. done contains actual written bytes. *)
PROCEDURE (VAR b : Bus) Write* (adr: ADDRESS; len: LENGTH; VAR done: LENGTH);
BEGIN END Write;

END BusUart.
