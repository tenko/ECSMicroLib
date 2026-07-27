(**
Machine module

Procedures and variables here must be implemented in other
MCU dependent module. This module exists to disconnect from
MCU depenedent import in general drivers.
*)
MODULE Machine IN Micro;

IMPORT SYSTEM;

CONST
    (* resetCause constants *)
    RESET_UNKNOWN* = 0;
    RESET_PWRON* = 1;
    RESET_HARD* = 2;
    RESET_WDT* = 3;
    RESET_DEEPSLEEP* = 4;
    RESET_SOFT* = 5;

(** CPU frequency value *)
VAR ^ cpuFreq- ["_cpu_freq"]: INTEGER;

(** Reset cause *)
VAR ^ resetCause- ["_reset_cause"]: INTEGER;

(** Enable interrupts *)
PROCEDURE ^ IRQEnable* ["irq_enable"]();

(** Disable interrupts *)
PROCEDURE ^ IRQDisable*["irq_disable"] ();

(** System reset *)
PROCEDURE ^ Reset* ["reset"] ();

(** Idle until interrupt is triggered *)
PROCEDURE ^ Idle* ["idle"] ();

(** Enter light sleep *)
PROCEDURE ^ SleepLight* ["sleep_light"] ();

(** Enter deep sleep *)
PROCEDURE ^ SleepDeep* ["sleep_deep"] ();

(** Delay delta seconds *)
PROCEDURE ^ DelayS* ["delay_s"] (delta : UNSIGNED32);

(** Delay delta milli seconds *)
PROCEDURE ^ DelayMS* ["delay_ms"] (delta : UNSIGNED32);

(** Delay delta micro seconds *)
PROCEDURE ^ DelayUS* ["delay_us"] (delta : UNSIGNED32);

(** Milli seconds ticker value *)
PROCEDURE ^ TicksMS* ["ticks_ms"] (): UNSIGNED32;

(** CPU ticker value *)
PROCEDURE ^ TicksCPU* ["ticks_cpu"] (): UNSIGNED32;

END Machine.
