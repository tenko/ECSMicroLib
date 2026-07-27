(**
RTC base interface.
Concrete implementations in MCU drivers.
*)
MODULE MachineRTC IN Micro;

TYPE
    RTC* = RECORD END;

(** Set RTC Wakeup timer delay in seconds.
Setting delay to 0 disable the wakeup timer.
*)
PROCEDURE (VAR rtc : RTC) WakeupS*(delay : INTEGER);
BEGIN END WakeupS;

END MachineRTC.
