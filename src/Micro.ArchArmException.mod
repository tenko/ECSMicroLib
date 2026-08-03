(**
Templated exception module to redirect ISR to handle or enter infinite loop.
*)
MODULE ArchArmException (Name) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ArchArm;

VAR isrHandle : PROCEDURE;

PROCEDURE ISR [Name];
BEGIN
    IF isrHandle # NIL THEN isrHandle() END;
    REPEAT UNTIL FALSE;
END ISR;

(** Set ISR handle *)
PROCEDURE SetHandle*(handle : PROCEDURE);
BEGIN isrHandle := handle
END SetHandle;

END ArchArmException.