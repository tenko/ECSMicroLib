MODULE MemFormatters IN Micro;

	(*
		A. V. Shiryaev, 2015.03

		LE: Little-Endian
		BE: Big-Endian
	*)

	IMPORT SYSTEM;

	(* Write *)

		PROCEDURE WriteIntLE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x);
			a[w + 1] := CHR(x DIV 100H);
			a[w + 2] := CHR(x DIV 10000H);
			a[w + 3] := CHR(x DIV 1000000H);
			INC(w, 4)
		END WriteIntLE;

		PROCEDURE WriteIntBE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x DIV 1000000H);
			a[w + 1] := CHR(x DIV 10000H);
			a[w + 2] := CHR(x DIV 100H);
			a[w + 3] := CHR(x);
			INC(w, 4)
		END WriteIntBE;

		PROCEDURE WriteInt24LE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x);
			a[w + 1] := CHR(x DIV 100H);
			a[w + 2] := CHR(x DIV 10000H);
			INC(w, 3)
		END WriteInt24LE;

		PROCEDURE WriteInt24BE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x DIV 10000H);
			a[w + 1] := CHR(x DIV 100H);
			a[w + 2] := CHR(x);
			INC(w, 3)
		END WriteInt24BE;

		PROCEDURE WriteInt16LE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x);
			a[w + 1] := CHR(x DIV 100H);
			INC(w, 2)
		END WriteInt16LE;

		PROCEDURE WriteInt16BE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x DIV 100H);
			a[w + 1] := CHR(x);
			INC(w, 2)
		END WriteInt16BE;

		PROCEDURE WriteInt8* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: INTEGER);
		BEGIN
			a[w] := CHR(x);
			INC(w)
		END WriteInt8;

		PROCEDURE WriteRealLE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: REAL);
		BEGIN
			WriteIntLE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteRealLE;

		PROCEDURE WriteRealBE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: REAL);
		BEGIN
			WriteIntBE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteRealBE;

		PROCEDURE WriteSetLE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: SET);
		BEGIN
			WriteIntLE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteSetLE;

		PROCEDURE WriteSetBE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: SET);
		BEGIN
			WriteIntBE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteSetBE;

		PROCEDURE WriteSet16LE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: SET);
		BEGIN
			WriteInt16LE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteSet16LE;

		PROCEDURE WriteSet16BE* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: SET);
		BEGIN
			WriteInt16BE(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteSet16BE;

		PROCEDURE WriteSet8* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: SET);
		BEGIN
			WriteInt8(a, w, SYSTEM.VAL(INTEGER, x))
		END WriteSet8;

		PROCEDURE WriteBool* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: BOOLEAN);
		BEGIN
			IF x THEN
				a[w] := 1X
			ELSE
				a[w] := 0X
			END;
			INC(w)
		END WriteBool;

(*
		PROCEDURE WriteXBool* (VAR a: ARRAY OF CHAR; VAR w: INTEGER; x: BOOLEAN);
		BEGIN
			IF x THEN
				a[w] := 55X
			ELSE
				a[w] := 0AAX
			END;
			INC(w)
		END WriteXBool;
*)

	(* Read *)

		PROCEDURE ReadIntLE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) + ORD(a[r + 1]) * 100H + ORD(a[r + 2]) * 10000H + ORD(a[r + 3]) * 1000000H;
			INC(r, 4)
		END ReadIntLE;

		PROCEDURE ReadIntBE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) * 1000000H + ORD(a[r + 1]) * 10000H + ORD(a[r + 2]) * 100H + ORD(a[r + 3]);
			INC(r, 4)
		END ReadIntBE;

		PROCEDURE ReadUInt24LE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) + ORD(a[r + 1]) * 100H + ORD(a[r + 2]) * 10000H;
			INC(r, 3)
		END ReadUInt24LE;

		PROCEDURE ReadUInt24BE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) * 10000H + ORD(a[r + 1]) * 100H + ORD(a[r + 2]);
			INC(r, 3)
		END ReadUInt24BE;

		PROCEDURE ReadSInt24LE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
(*
			x := ORD(a[r]) + ORD(a[r + 1]) * 100H + ORD(a[r + 2]) * 10000H;
			IF x >= 800000H THEN x := x - 1000000H END
*)
			x := SYSTEM.LSH(SYSTEM.LSH(
					ORD(a[r]) + ORD(a[r + 1]) * 100H + ORD(a[r + 2]) * 10000H,
				8), -8);
			INC(r, 3)
		END ReadSInt24LE;

		PROCEDURE ReadSInt24BE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
(*
			x := ORD(a[r]) * 10000H + ORD(a[r + 1]) * 100H + ORD(a[r + 2]);
			IF x >= 800000H THEN x := x - 1000000H END
*)
			x := SYSTEM.LSH(SYSTEM.LSH(
					ORD(a[r]) * 10000H + ORD(a[r + 1]) * 100H + ORD(a[r + 2]),
				8), -8);
			INC(r, 3)
		END ReadSInt24BE;

		PROCEDURE ReadUInt16LE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) + ORD(a[r + 1]) * 100H;
			INC(r, 2)
		END ReadUInt16LE;

		PROCEDURE ReadUInt16BE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]) * 100H + ORD(a[r + 1]);
			INC(r, 2)
		END ReadUInt16BE;

		PROCEDURE ReadSInt16LE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
(*
			x := ORD(a[r]) + ORD(a[r + 1]) * 100H;
			IF x >= 32768 THEN x := x - 65536 END
*)
			x := SYSTEM.LSH(SYSTEM.LSH(ORD(a[r]) + ORD(a[r + 1]) * 100H, 16), -16);
			INC(r, 2)
		END ReadSInt16LE;

		PROCEDURE ReadSInt16BE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
(*
			x := ORD(a[r]) * 100H + ORD(a[r + 1]);
			IF x >= 32768 THEN x := x - 65536 END
*)
			x := SYSTEM.LSH(SYSTEM.LSH(ORD(a[r]) * 100H + ORD(a[r + 1]), 16), -16);
			INC(r, 2)
		END ReadSInt16BE;

		PROCEDURE ReadUInt8* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
			x := ORD(a[r]);
			INC(r)
		END ReadUInt8;

		PROCEDURE ReadSInt8* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: INTEGER);
		BEGIN
(*
			x := ORD(a[r]);
			IF x >= 128 THEN x := x - 256 END
*)
			x := SYSTEM.LSH(SYSTEM.LSH(ORD(a[r]), 24), -24);
			INC(r)
		END ReadSInt8;

		PROCEDURE ReadRealLE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: REAL);
			VAR t: INTEGER;
		BEGIN
			ReadIntLE(a, r, t);
			x := SYSTEM.VAL(REAL, t)
		END ReadRealLE;

		PROCEDURE ReadRealBE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: REAL);
			VAR t: INTEGER;
		BEGIN
			ReadIntBE(a, r, t);
			x := SYSTEM.VAL(REAL, t)
		END ReadRealBE;

		PROCEDURE ReadSetLE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: SET);
			VAR t: INTEGER;
		BEGIN
			ReadIntLE(a, r, t);
			x := SYSTEM.VAL(SET, t)
		END ReadSetLE;

		PROCEDURE ReadSetBE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: SET);
			VAR t: INTEGER;
		BEGIN
			ReadIntBE(a, r, t);
			x := SYSTEM.VAL(SET, t)
		END ReadSetBE;

		PROCEDURE ReadSet16LE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: SET);
			VAR t: INTEGER;
		BEGIN
			ReadUInt16LE(a, r, t);
			x := SYSTEM.VAL(SET, t)
		END ReadSet16LE;

		PROCEDURE ReadSet16BE* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: SET);
			VAR t: INTEGER;
		BEGIN
			ReadUInt16BE(a, r, t);
			x := SYSTEM.VAL(SET, t)
		END ReadSet16BE;

		PROCEDURE ReadSet8* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: SET);
		BEGIN
			x := SYSTEM.VAL(SET, ORD(a[r]));
			INC(r)
		END ReadSet8;

		PROCEDURE ReadBool* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: BOOLEAN; VAR ok: BOOLEAN);
		BEGIN
			IF a[r] = 1X THEN
				x := TRUE;
				ok := TRUE
			ELSIF a[r] = 0X THEN
				x := FALSE;
				ok := TRUE
			ELSE
				ok := FALSE
			END;
			INC(r)
		END ReadBool;

(*
		PROCEDURE ReadXBool* (a: ARRAY OF CHAR; VAR r: INTEGER; VAR x: BOOLEAN; VAR ok: BOOLEAN);
		BEGIN
			IF a[r] = 55X THEN
				x := TRUE;
				ok := TRUE
			ELSIF a[r] = 0AAX THEN
				x := FALSE;
				ok := TRUE
			ELSE
				ok := FALSE
			END;
			INC(r)
		END ReadXBool;
*)

END MemFormatters.
