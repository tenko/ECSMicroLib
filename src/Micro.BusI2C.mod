MODULE BusI2C IN Micro;

IMPORT SYSTEM;

CONST
    NoError* = 0;
    ErrorTimeout* = -1;
    ErrorNoDevice* = -2;
    ErrorArgs* = -3;
    
TYPE
    BYTE = SYSTEM.BYTE;
    
    GetTicks* = PROCEDURE (): UNSIGNED32;
    Bus* = RECORD
        getTicks*: GetTicks;
        timeout*: UNSIGNED32;
        error*: INTEGER;
    END;

(** Read or Write data *)
PROCEDURE (VAR this: Bus) Transfer*(adr : INTEGER; rd : BOOLEAN; VAR buf : ARRAY OF BYTE; start, len : LENGTH; stop : BOOLEAN): LENGTH;
BEGIN RETURN ErrorArgs END Transfer;

(**
Probe address adr for device respons.
Return 0 if device responded.
*)
PROCEDURE (VAR this: Bus) Probe*(adr : INTEGER): INTEGER;
BEGIN RETURN ErrorArgs END Probe;

(**
Read into buffer from the peripheral specified by addr.
The number of bytes read is length and the data is written
to the buffer starting from start index.
The function returns the number of bytes that were received.
*)
PROCEDURE (VAR this: Bus) Read*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH): LENGTH;
BEGIN RETURN ErrorArgs END Read;

(**
Write bytes from the buffer to the peripheral specified by addr.
The number of bytes written is length and starting from start index.
The function returns the number of bytes that were sent.
*)
PROCEDURE (VAR this: Bus) Write*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH; stop : BOOLEAN): LENGTH;
BEGIN RETURN ErrorArgs END Write;

END BusI2C.