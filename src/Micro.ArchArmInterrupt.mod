(**
Templated interrupt module to redirect ISR to handle.
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

(** Disable interrupt *)
PROCEDURE Disable*;
BEGIN ArchArm.DisableIRQ(Int)
END Disable;

(** Enable interrupt *)
PROCEDURE Enable*;
BEGIN ArchArm.EnableIRQ(Int)
END Enable;

END ArchArmInterrupt.