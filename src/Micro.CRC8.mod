MODULE CRC8 IN Micro;

	(*
		A. V. Shiryaev, 2013.01, 2014.11
        Modified by Tenko for use with ECS
	*)

	IMPORT SYSTEM;

	CONST
		init* = 0FFX;

	PROCEDURE Update* (crc8: CHAR; x: CHAR): CHAR;
		VAR i: INTEGER; cs: SET;
	BEGIN
		cs := SYSTEM.VAL(SET, ORD(crc8)) / SYSTEM.VAL(SET, ORD(x));
		i := 8;
		REPEAT
			cs := SYSTEM.VAL(SET, SYSTEM.LSH(SYSTEM.VAL(INTEGER, cs), 1));
			IF 8 IN cs THEN
				cs := cs / {0,4,5}
			END;
			DEC(i)
		UNTIL i = 0;
	RETURN CHR(SYSTEM.VAL(INTEGER, cs))
	END Update;

END CRC8.