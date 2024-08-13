MODULE CRC16CCITT1021 IN Micro;

	(* Alexander Shiryaev, 2014.11
       Modified by Tenko for use with ECS
    *)

	IMPORT SYSTEM;

	CONST init* = SIGNED32(0FFFFH);

	(*
		http://www.ccsinfo.com/forum/viewtopic.php?t=24977
		unsigned short crc_1021 (unsigned short crc, unsigned char data)
		{
			unhsigned short x;
			x = ((crc >> 8) ^ data) & 0xff;
			x ^= x >> 4;
			crc = (crc << 8) ^ (x << 12) ^ (x << 5) ^ x;
			return crc; /* & 0xffff */
		}
	*)
	PROCEDURE Update* (cs: INTEGER; x: CHAR): INTEGER;
		VAR y: INTEGER;
	BEGIN
		(* ASSERT 0 <= cs <= 0FFFFH *)
		x := CHR(SYSTEM.VAL(INTEGER,
			SYSTEM.VAL(SET, cs DIV 100H) / SYSTEM.VAL(SET, ORD(x))
		));
		y := SYSTEM.VAL(INTEGER,
			SYSTEM.VAL(SET, ORD(x)) / SYSTEM.VAL(SET, ORD(x) DIV 10H)
		);
	RETURN SYSTEM.VAL(INTEGER,
		SYSTEM.VAL(SET, cs * 100H) /
		SYSTEM.VAL(SET, y * 1000H) /
		SYSTEM.VAL(SET, y * 20H) /
		SYSTEM.VAL(SET, y) ) MOD 10000H
	END Update;

END CRC16CCITT1021.