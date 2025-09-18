(**
Interrupt module to redirect ISR to handle.
*)
MODULE ARMv7MInterrupt (Name, Int) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;

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
	SYSTEM.PUT(ARMv7M.NVICICER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
	ARMv7M.ISB;
END Disable;

(** Enable interrupt *)
PROCEDURE Enable*;
BEGIN
	SYSTEM.PUT(ARMv7M.NVICISER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
END Enable;

END ARMv7MInterrupt.