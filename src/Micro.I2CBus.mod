MODULE I2CBus IN Micro;

	(* Alexander Shiryaev, 2016.12
       Modified by Tenko for use with ECS
    *)
    IMPORT SYSTEM;

	CONST
		(* read options *)
			opt0* = 0;

		(* res *)
			ok* = 0;

	TYPE
		WriteDone* = PROCEDURE (res: INTEGER);
		ReadDone* = PROCEDURE (a: ARRAY OF CHAR; len: INTEGER; res: INTEGER);

		Write* = PROCEDURE (addr: SYSTEM.ADDRESS; wAdr: SYSTEM.ADDRESS;
			wLen: INTEGER; c: WriteDone; VAR ok: BOOLEAN);

		Read* = PROCEDURE (addr: SYSTEM.ADDRESS; wAdr: SYSTEM.ADDRESS;
			wLen, rLen: INTEGER; opt: SET; c: ReadDone; VAR ok: BOOLEAN);

		Bus* = RECORD
			write*: Write;
			read*: Read
		END;

END I2CBus.