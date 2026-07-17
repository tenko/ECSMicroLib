MODULE ARMv8M IN Micro;
(*
    ARMv8-M Architecture Reference Manual
        https://developer.arm.com/documentation/ddi0553/latest/
*)

IMPORT SYSTEM;

TYPE ADDRESS = SYSTEM.ADDRESS;

CONST
    (* B11.1 SysTick Timer *)
    SYST_CSR*    = ADDRESS(0E000E010H); (* SysTick Control and Status Register *)
    SYST_RVR*    = ADDRESS(0E000E014H); (* SysTick Reload Value Register *)
    SYST_CVR*    = ADDRESS(0E000E018H); (* SysTick Current Value Register *)
    SYST_CALIB*  = ADDRESS(0E000E01CH); (* SysTick Calibration Value Register *)
    (* D1.1.11 System Control Block *)
    AIRCR*  = ADDRESS(0E000ED0CH); (* Application Interrupt and Reset Control Register *)

PROCEDURE WFI*();
BEGIN SYSTEM.ASM("wfi")
END WFI;

PROCEDURE Reset*();
BEGIN
    SYSTEM.ASM("dsb");
    SYSTEM.PUT(AIRCR, SIGNED32(05FA0004H)); (* SYSRESETREQ *)
    SYSTEM.ASM("dsb");
    REPEAT UNTIL FALSE
END Reset;

END ARMv8M.
