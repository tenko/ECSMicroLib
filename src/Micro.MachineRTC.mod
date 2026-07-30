(**
RTC interface.

Concrete implementations in MCU drivers should be passed to drivers.

Typical a RTC clock must also must be started.
*)
MODULE MachineRTC IN Micro;

TYPE
    RTC* = RECORD END;

(**
Set RTC Wakeup timer delay in seconds.

Setting delay to 0 disable the wakeup timer and interrupt.
*)
PROCEDURE (VAR rtc : RTC) WakeupS*(delay : INTEGER);
BEGIN END WakeupS;

END MachineRTC.
