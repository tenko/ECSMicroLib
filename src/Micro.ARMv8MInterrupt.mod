(**
Interrupt module to redirect ISR to handle.
*)
MODULE ARMv8MInterrupt (Name, Int) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv8M;

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
BEGIN
	SYSTEM.PUT(ARMv8M.NVICICER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
	SYSTEM.ASM("isb")
END Disable;

(** Enable interrupt *)
PROCEDURE Enable*;
BEGIN
	SYSTEM.PUT(ARMv8M.NVICISER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
END Enable;

END ARMv8MInterrupt.