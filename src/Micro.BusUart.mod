(**
U[S]ART generic module

Alexander Shiryaev, 2016.09, 2017.04, 2019.10, 2020.12
Modified by Tenko for use with ECS
*)
MODULE BusUart IN Micro;

IMPORT SYSTEM;

TYPE
    BYTE = SYSTEM.BYTE;
    Bus* = RECORD* END;

(** Return number of characters available in read buffer *)
PROCEDURE* (VAR this : Bus) Any*(): LENGTH;

(** Return FALSE if we are currently transmitting data *)
PROCEDURE* (VAR this : Bus) TXDone*(): BOOLEAN;

(** Read bytes into buffer with start and length. *)
PROCEDURE* (VAR this: Bus) ReadBytes*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH): LENGTH;

(** Read `CHAR` value. Return `TRUE` if success. *)
PROCEDURE* (VAR this: Bus) ReadChar*(VAR value : CHAR): BOOLEAN;

(** Write bytes from buffer with start and length. *)
PROCEDURE* (VAR this: Bus) WriteBytes*(VAR buffer : ARRAY OF BYTE; start, length: LENGTH): LENGTH;

(** Write `CHAR` value. Return `TRUE` if success. *)
PROCEDURE* (VAR this: Bus) WriteChar*(value : CHAR): BOOLEAN;

END BusUart.
