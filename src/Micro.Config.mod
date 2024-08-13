MODULE Config IN Micro;

	(*
		Alexander Shiryaev, 2015.02
        Modified by Tenko for use with ECS
	*)

	IMPORT SYSTEM;
    IN Micro IMPORT CRC := CRC16CCITT1021, MF := MemFormatters;

	CONST
		maxTLen = 32;
		minConfigWords = 3;
		maxConfigWords = 128; (* 512 B *)
			(* 0 <= maxConfigWords - minConfigWords < 65536 *)
			(* maxConfigWords * 4 - 6 <= 4095 (CRC16 limit) *)

		(* Store result *)
			ok* = 0; notModified* = -1; verifyFailed* = -2;

	TYPE
		Externalizer* =
			PROCEDURE (VAR a: ARRAY OF CHAR; VAR w: INTEGER);
		Internalizer* =
			PROCEDURE (a: ARRAY OF CHAR; r, len: INTEGER; VAR ok: BOOLEAN);
		Write* =
			PROCEDURE (adr: SYSTEM.ADDRESS; words: INTEGER; VAR res: INTEGER);

	VAR
		configKey: INTEGER;
		configAdr: SYSTEM.ADDRESS; write: Write;
		(* consumers *)
			tLen: INTEGER;
			keys: ARRAY maxTLen OF INTEGER;
			exts: ARRAY maxTLen OF Externalizer;
			ints: ARRAY maxTLen OF Internalizer;
			defs: ARRAY maxTLen OF PROCEDURE;

	PROCEDURE CheckSum0 (fAdr, tAdr: INTEGER): INTEGER;
		VAR cs: INTEGER;
			x: CHAR;
	BEGIN
		cs := CRC.init;
		WHILE fAdr < tAdr DO
			SYSTEM.GET(fAdr, x);
			cs := CRC.Update(cs, x);
			INC(fAdr)
		END;
	RETURN cs
	END CheckSum0;

	PROCEDURE Cmp0 (adr0, adr1: INTEGER; n: INTEGER): BOOLEAN;
		VAR x0, x1: INTEGER;
	BEGIN
		ASSERT(n > 0);
		REPEAT DEC(n);
			SYSTEM.GET(adr0, x0); INC(adr0, 4);
			SYSTEM.GET(adr1, x1); INC(adr1, 4)
		UNTIL (x0 # x1) OR (n = 0);
	RETURN x0 = x1
	END Cmp0;

	(*
		res:
			ok: write success
			notModified: configuration not modified (no write). This is not error
			verifyFailed: write verification failed
			else: write result
	*)
	PROCEDURE Store* (VAR res: INTEGER);
		VAR i, w, w1: INTEGER;
			cs: INTEGER;
			a: ARRAY maxConfigWords * 4 OF CHAR;
	BEGIN
		SYSTEM.PUT(SYSTEM.ADR(a), configKey);

		(* externalize *)
			a[8] := CHR(tLen);
			w := 9;
			i := 0;
			WHILE i < tLen DO
				MF.WriteIntLE(a, w, keys[i]);
				INC(w);
				w1 := w;
				exts[i](a, w);
				ASSERT(w >= w1);
				ASSERT(w - w1 < 100H);
				ASSERT(w <= maxConfigWords * 4);
				a[w1 - 1] := CHR(w - w1);
				INC(i)
			END;

		(* alignment *)
			WHILE w MOD 4 # 0 DO a[w] := 0X; INC(w) END;

		(* length *)
			w1 := w DIV 4 - minConfigWords;
			ASSERT(w1 DIV 10000H = 0);
			a[6] := CHR(w1); a[7] := CHR(w1 DIV 100H);

		(* checksum *)
			cs := CheckSum0(INTEGER(SYSTEM.ADR(a) + 6), INTEGER(SYSTEM.ADR(a) + w));
			a[4] := CHR(cs); a[5] := CHR(cs DIV 100H);

		IF Cmp0(INTEGER(SYSTEM.ADR(a)), INTEGER(configAdr), w DIV 4) THEN res := notModified
		ELSE
			write(SYSTEM.ADR(a), w DIV 4, res);
			IF (res = ok) & ~Cmp0(INTEGER(SYSTEM.ADR(a)), INTEGER(configAdr), w DIV 4) THEN
				res := verifyFailed
			END
		END
	END Store;

	(*
		return value:
			-1: configuration is valid
			else: number of configuration words
	*)
	PROCEDURE Load0 (): INTEGER;
		VAR x, n: INTEGER;
			res: BOOLEAN;
	BEGIN n := -1;
		SYSTEM.GET(configAdr, x);
		IF x = configKey THEN
			SYSTEM.GET(configAdr + 4, x);
			n := x DIV 10000H MOD 10000H + minConfigWords;
			IF ~((n <= maxConfigWords) & (CheckSum0(INTEGER(configAdr + 6), INTEGER(configAdr + n * 4)) = x MOD 10000H)) THEN n := -1
			END
		END;
	RETURN n
	END Load0;

	(*
		res = {}: ok
	*)
	PROCEDURE Load* (VAR res: SET);
		VAR i, n: INTEGER;
			ok: BOOLEAN;
			a: ARRAY (maxConfigWords - 2) * 4 OF CHAR;

		PROCEDURE Internalize (i: INTEGER; a: ARRAY OF CHAR; VAR ok: BOOLEAN);
			VAR r, j, n: INTEGER;

			PROCEDURE Read (a: ARRAY OF CHAR; r: INTEGER): INTEGER;
				VAR x: INTEGER;
			BEGIN MF.ReadIntLE(a, r, x);
			RETURN x
			END Read;

		BEGIN n := ORD(a[0]); r := 1; j := 0;
			WHILE (j < n) & ~(Read(a, r) = keys[i]) DO
				INC(r, 5 + ORD(a[r+4]));
				INC(j)
			END;
			ok := FALSE;
			IF j < n THEN ints[i](a, r + 5, ORD(a[r+4]), ok) END
		END Internalize;

	BEGIN
		IF tLen > 0 THEN res := {0..tLen-1};
			n := Load0();
			IF n # -1 THEN
				SYSTEM.MOVE(configAdr + 8, SYSTEM.ADR(a), n - 2);
				i := 0;
				WHILE i < tLen DO
					Internalize(i, a, ok);
					IF ok THEN EXCL(res, i) END;
					INC(i)
				END
			END;

			i := 0; WHILE i < tLen DO IF i IN res THEN defs[i] END; INC(i) END
		ELSE res := {}
		END
	END Load;

	(*
		key: entire configuration key
		adr: address of memory where configuration stored
		wr: memory write procedure, must return res = 0 (ok) on write success
	*)
	PROCEDURE Init* (key: INTEGER; adr: SYSTEM.ADDRESS; wr: Write);
	BEGIN
		configKey := key;
		configAdr := adr;
		write := wr;
		tLen := 0
	END Init;

	PROCEDURE Add* (key: INTEGER; ext: Externalizer; int: Internalizer; def: PROCEDURE);
		VAR i: INTEGER;
	BEGIN
		i := 0; WHILE (i < tLen) & (keys[i] # key) DO INC(i) END;
			ASSERT(i = tLen);
		keys[tLen] := key; exts[tLen] := ext; ints[tLen] := int; defs[tLen] := def;
		INC(tLen)
	END Add;

	PROCEDURE Default*;
		VAR i: INTEGER;
	BEGIN
		i := 0; WHILE i < tLen DO defs[i]; INC(i) END
	END Default;

END Config.
