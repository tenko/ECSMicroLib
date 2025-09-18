(* Test ILI9341 LCD Display *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT DeviceILI9341;
IN Gfx IMPORT Canvas;

CONST
    Pins = BoardConfig.Pins;
    SPI5 = BoardConfig.SPI5;

    SIZE = 8;

    FBMonoSize = 240*320 DIV 8;
    FBBlockSize = 240*SIZE;

TYPE
    BYTE = SYSTEM.BYTE;
    BYTEARRAY = ARRAY OF BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    
    FramebufferMono* = RECORD (Canvas.Canvas)
        pixels : POINTER TO VAR BYTEARRAY;
		stride- : INTEGER;
    END;
    
VAR
    fbMonoData : ARRAY FBMonoSize OF BYTE;
    fbMono : FramebufferMono;
    fbBlockData : ARRAY FBBlockSize OF UNSIGNED16;
    
    bus : SPI5.Bus;
    cs, rst, dc : Pins.Pin;
    dev : DeviceILI9341.ILI9341;
    col, fg, bg : INTEGER;

(*
VAR ^ Background- ["background"]: ARRAY 76800 OF UNSIGNED16;
*)
  
(** Set pixel to color at location x, y. *)
PROCEDURE (VAR this : FramebufferMono) SetPixel*(x, y, color : INTEGER);
VAR
    s : SET8;
    idx : LENGTH;
BEGIN
	IF (x >= 0) & (x < this.width) & (y >= 0) & (y < this.height) THEN
	   idx := SYSTEM.LSH(x, -3) + SYSTEM.LSH(y*this.stride, -3);
	   s := SYSTEM.VAL(SET8, this.pixels[idx]);
	   IF color = 0 THEN EXCL(s, 7 - (x MOD 8))
	   ELSE INCL(s, 7 - (x MOD 8)) END;
	   this.pixels[idx] := SYSTEM.VAL(BYTE, s);
	END
END SetPixel;

(** Get pixel color at location x, y. *)
PROCEDURE (VAR this : FramebufferMono) GetPixel*(x, y : INTEGER): INTEGER;
VAR
    s : SET8;
    idx : LENGTH;
BEGIN
	IF (x >= 0) & (x < this.width) & (y >= 0) & (y < this.height) THEN
	   idx := SYSTEM.LSH(x, -3) + SYSTEM.LSH(y*this.stride, -3);
	   s := SYSTEM.VAL(SET8, this.pixels[idx]);
	   IF (7 - (x MOD 8)) IN s THEN RETURN 1
	   ELSE RETURN 0 END;
	ELSE
		RETURN 0
	END
END GetPixel;

(** Fill framebuffer with color *)
PROCEDURE (VAR this : FramebufferMono) Fill*(color : INTEGER);
VAR i : LENGTH;
BEGIN
    FOR i := 0 TO LEN(this.pixels^) - 1 DO
        IF col > 0 THEN this.pixels^[i] := 0FFX
        ELSE this.pixels^[i] := 00X END;
    END;
END Fill;

(** Draw a filled rectangle at the given location, size and color. *)
PROCEDURE (VAR this : FramebufferMono) FillRect(x, y, w, h, color : INTEGER);
VAR
	s : SET8;
	i, idx, advance: LENGTH;
BEGIN
	advance := SYSTEM.LSH(this.stride, -3);
	WHILE w > 0 DO
        idx := SYSTEM.LSH(x, -3) + y*advance;
		FOR i := 0 TO h - 1 DO
			s := SYSTEM.VAL(SET8, this.pixels^[idx]);
			IF color = 0 THEN EXCL(s, 7 - (x MOD 8))
			ELSE INCL(s, 7 - (x MOD 8)) END;
			this.pixels^[idx] := SYSTEM.VAL(BYTE, s);
			idx := idx + advance;
		END;
		INC(x); DEC(w);
	END;
END FillRect;

PROCEDURE Init(VAR fb : FramebufferMono; width, height : INTEGER);
BEGIN
    fb.pixels := PTR(fbMonoData);
    fb.SetSize(width, height);
    fb.stride := dev.width;
END Init;

PROCEDURE Draw;
VAR
    x, y, yoff, i, c : INTEGER;
    t0, t1 : UNSIGNED32;
    j, k, l, m : LENGTH;
    s : SET8;
BEGIN 
    fbMono.Fill(0);
    (* col := 1 - col; *)
    fbMono.Line(0, 0, 240, 320, 1);
    fbMono.Line(0, 320, 240, 0, 1);
    (* fbMono.FillRect(50, 50, 50, 50, 1); *)
    SysTick.Delay(1); (* crash without! *)

    t0 := SysTick.GetTicks();
    yoff := 0;
    FOR i := 0 TO (dev.height DIV SIZE) - 1 DO
        FOR y := 0 TO SIZE - 1 DO
            j := y*dev.width;
            k := SYSTEM.LSH((y + yoff)*dev.width, -3);
            x := 0;
            WHILE x < dev.width DO
                s := SYSTEM.VAL(SET8, fbMonoData[k + SYSTEM.LSH(x, -3)]);
                m := 0;
                WHILE (x < dev.width) & (m < 8) DO
                    IF (7 - (x MOD 8)) IN s THEN
                        fbBlockData[j + x] := SYSTEM.VAL(UNSIGNED16, fg);
                    ELSE
                        fbBlockData[j + x] := SYSTEM.VAL(UNSIGNED16, bg);
                        (* fbBlockData[j + x] := Background[x * (y + yoff)]; *)
                    END;
                    INC(x); INC(m);
                END;
            END;
        END;
        dev.BlitRaw(0, yoff, dev.width, SIZE, SYSTEM.ADR(fbBlockData[0]));
        SysTick.Delay(1); (* crash without! *)
        INC(yoff, SIZE);
    END;
    t1 := SysTick.GetTicks();
    (*
    OSStream.StdOut.WriteString("redraw in ");
    OSStream.StdOut.FormatInteger(INTEGER(t1 - t0), 0, {});
    OSStream.StdOut.WriteString("ms.");
    OSStream.StdOut.WriteNL;
    *)
END Draw;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    SysTick.Init(BoardConfig.HCLK, 1000);
    
    BoardConfig.InitILI9341SPI(bus, rst, cs, dc);
    DeviceILI9341.Init(dev, bus, rst, cs, dc);
    dev.Config;
    
    Init(fbMono, dev.width, dev.height);
    
    col := 0;
    fg := dev.ColorRGB(255,255,255);
    bg := dev.ColorRGB(0,0,0);
    
	SysTick.Delay(1000);
    
    TRACE("Start");
    WHILE TRUE DO
        Draw;
    END;
END Test.