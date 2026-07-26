(**
External pin interrupt base interface to be used by devices.
Concrete implementations in MCU drivers should be passed to drivers.
*)
MODULE MachinePinExtInt IN Micro;

TYPE
    PinExtInt* = RECORD
        count* : UNSIGNED32; (* Trigger count *)
        flag* : BOOLEAN;
        isrHandle- : PROCEDURE;
    END;

(** Set pin value to 1 *)
PROCEDURE (VAR p : PinExtInt) On*;
BEGIN END On;

(** Set interrupt callback handle *)
PROCEDURE (VAR ext : PinExtInt) SetHandle*(handle : PROCEDURE);
BEGIN ext.isrHandle := handle
END SetHandle;

(** Check if interrupt is triggered. Clear flag if set. *)
PROCEDURE (VAR ext : PinExtInt) OnTrigger* (): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
	res := ext.flag; IF res THEN ext.flag := FALSE END;
    RETURN res
END OnTrigger;

(** Software trigger of interrupt *)
PROCEDURE (VAR ext : PinExtInt) Trigger*;
BEGIN END Trigger;

(** Disable interrupt *)
PROCEDURE (VAR ext : PinExtInt) Disable*;
BEGIN END Disable;

(** Enable interrupt *)
PROCEDURE (VAR ext : PinExtInt) Enable*;
BEGIN END Enable;

END MachinePinExtInt.
