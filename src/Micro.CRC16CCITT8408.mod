MODULE CRC16CCITT8408 IN Micro;

	(* Alexander Shiryaev, 2013.09, 2014.11
       Modified by Tenko for use with ECS
    *)

	IMPORT SYSTEM;

	CONST init* = SIGNED32(0FFFFH);

    	(*
		http://ru.wikibooks.org/wiki/%D0%9F%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%BD%D1%8B%D0%B5_%D1%80%D0%B5%D0%B0%D0%BB%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D0%B8_%D0%B2%D1%8B%D1%87%D0%B8%D1%81%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F_CRC#CRC-16
		/*
			Name: CRC-16 CCITT
			Poly: 0x8408
			Init: 0xFFFF
			Revert: false
			XorOut: 0x0000
			Check: 0x6F91 ("123456789")
			MaxLen: 4095 B (32767 bits) - detection of single, double, triple and all odd errors
		*/
		unsigned short crc_8408 (unsigned short crc, unsigned char data)
		{
			unsigned short t;
			data ^= crc & 0xff;
			data ^= data << 4;
			t = (((unsigned short)data << 8) | ((crc >> 8) & 0xff));
			t ^= (unsigned char)(data >> 4);
			t ^= ((unsigned short)data << 3);
			return t;
		}
	*)
	PROCEDURE Update* (cs: INTEGER; x: CHAR): INTEGER;
	BEGIN
		(* ASSERT 0 <= cs <= 0FFFFH *)
		x := CHR(SYSTEM.VAL(INTEGER,
			SYSTEM.VAL(SET, ORD(x)) / SYSTEM.VAL(SET, cs MOD 100H)
		));
		x := CHR(SYSTEM.VAL(INTEGER,
			SYSTEM.VAL(SET, ORD(x)) / SYSTEM.VAL(SET, ORD(x) * 10H)
		));
	RETURN SYSTEM.VAL(INTEGER,
		(SYSTEM.VAL(SET, ORD(x) * 100H) + SYSTEM.VAL(SET, cs DIV 100H))
		/ SYSTEM.VAL(SET, ORD(x) DIV 10H) / SYSTEM.VAL(SET, ORD(x) * 8)
	)
	END Update;

END CRC16CCITT8408.