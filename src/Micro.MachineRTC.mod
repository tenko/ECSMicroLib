(**
RTC interface.

Concrete implementations in MCU drivers should be passed to drivers.

Typical a RTC clock must also must be started.
*)
MODULE MachineRTC IN Micro;

TYPE RTC* = RECORD END;

(**
Set RTC Wakeup timer delay in seconds.

Setting delay to 0 disable the wakeup timer and interrupt.
*)
PROCEDURE (VAR rtc : RTC) WakeupS*(delay : INTEGER);
BEGIN END WakeupS;

(** Get current date and time *)
PROCEDURE (VAR rtc : RTC) Now*(VAR year, month, day, hour, min, sec : INTEGER);
BEGIN END Now;

(** Set current date and time *)
PROCEDURE (VAR rtc : RTC) SetDateTime*(year, month, day, hour, min, sec : INTEGER);
BEGIN END SetDateTime;

(** Set RTC alarm at future date time dt. *)
PROCEDURE (VAR rtc : RTC) Alarm*(year, month, day, hour, min, sec : INTEGER);
BEGIN END Alarm;

END MachineRTC.


