(**
Templated interrupt module to redirect ISR to handle or just ignore the interrupt.
*)
MODULE ArchArmInterrupt (Name, Int) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ArchArm;

VAR isrHandle : PROCEDURE;

PROCEDURE ISR [Name];
BEGIN IF isrHandle # NIL THEN isrHandle() END;
END ISR;

(** Set ISR handle *)
PROCEDURE SetHandle*(handle : PROCEDURE);
BEGIN isrHandle := handle
END SetHandle;

(** Set interrupt priority *)
PROCEDURE SetPriority*(priority : UNSIGNED8);
BEGIN ArchArm.IRQSetPriority(Int, priority)
END SetPriority;

(** Clear pending interrupt *)
PROCEDURE ClearPending*;
BEGIN ArchArm.IRQClearPending(Int)
END ClearPending;

(** Disable interrupt *)
PROCEDURE Disable*;
BEGIN ArchArm.IRQDisable(Int)
END Disable;

(** Enable interrupt *)
PROCEDURE Enable*;
BEGIN ArchArm.IRQEnable(Int)
END Enable;

END ArchArmInterrupt.