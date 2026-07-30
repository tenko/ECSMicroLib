(**
Common Pin interface.

Concrete implementations in MCU drivers should be passed to drivers.
*)
MODULE MachinePin IN Micro;

TYPE
    Pin* = RECORD END;

(** Set pin value to 1. *)
PROCEDURE (VAR p : Pin) On*;
BEGIN END On;

(** Set pin value to 0. *)
PROCEDURE (VAR p : Pin) Off*;
BEGIN END Off;

(** Return current pin value. *)
PROCEDURE (VAR p : Pin) Value*(): BOOLEAN;
BEGIN RETURN FALSE
END Value;

(** Toggle pin value. *)
PROCEDURE (VAR p : Pin) Toggle*;
BEGIN END Toggle;

END MachinePin.
