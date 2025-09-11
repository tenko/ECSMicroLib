(**
Pin base module
*)
MODULE Pin IN Micro;

TYPE
    Pin* = RECORD END;

PROCEDURE (VAR p : Pin) On*;
BEGIN END On;

PROCEDURE (VAR p : Pin) Off*;
BEGIN END Off;

PROCEDURE (VAR p : Pin) Value*(): BOOLEAN;
BEGIN RETURN FALSE
END Value;

PROCEDURE (VAR p : Pin) Toggle*;
BEGIN END Toggle;

END Pin.
