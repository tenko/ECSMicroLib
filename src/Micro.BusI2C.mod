MODULE BusI2C IN Micro;

IMPORT SYSTEM;

TYPE
    BYTE = SYSTEM.BYTE;
    Bus* = RECORD* END;

(**
Probe address adr for device respons.
Return 0 if device responded.
*)
PROCEDURE* (VAR this: Bus) Probe*(adr : INTEGER): INTEGER;

(**
Read into buffer from the peripheral specified by addr.
The number of bytes read is length and the data is written
to the buffer starting from start index.
The function returns the number of bytes that were received.
*)
PROCEDURE* (VAR this: Bus) Read*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH): LENGTH;

(**
Write bytes from the buffer to the peripheral specified by addr.
The number of bytes written is length and starting from start index.
The function returns the number of bytes that were sent.
*)
PROCEDURE* (VAR this: Bus) Write*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH; stop : BOOLEAN): LENGTH;

END BusI2C.