(* Test ILI9341 LCD Display *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;
IN Std IMPORT Cardinal, OSStream;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT DeviceILI9341;

CONST
    Pins = BoardConfig.Pins;
    SPI5 = BoardConfig.SPI5;

    Points = 0;
    FRects = 1;
    Fills = 2;
    
VAR
    bus : SPI5.Bus;
    cs, rst, dc : Pins.Pin;
    dev : DeviceILI9341.ILI9341;
    i : INTEGER;

PROCEDURE RandInt(range : INTEGER): INTEGER;
BEGIN RETURN INTEGER(Cardinal.RandomRange(range))
END RandInt;

PROCEDURE Draw(type : INTEGER);
VAR
    cnt : LENGTH;
    t0, t1 : UNSIGNED32;
    col, x1, x2, y1, y2: INTEGER;
    name : ARRAY 32 OF CHAR;
    
    PROCEDURE Swap(VAR x, y : INTEGER);
	VAR tmp : INTEGER;
	BEGIN
		tmp := x;
		x := y;
		y := tmp;
	END Swap;
BEGIN
    dev.Fill(dev.ColorRGB(0,0,0));
    cnt := 0;
    t0 := SysTick.GetTicks();
    IF type = Points THEN
        name := " points ";
        LOOP
            col := dev.ColorRGB(RandInt(255), RandInt(255),RandInt(255));
            dev.SetPixel(RandInt(dev.width - 1), RandInt(dev.height - 1), col);
            
            IF SysTick.GetTicks() - t0 >= 1000 THEN
                t1 := SysTick.GetTicks();
                EXIT
            END;
            INC(cnt);
        END;
    ELSIF type = FRects THEN
        name := " filled rectangles ";
        LOOP
            col := dev.ColorRGB(RandInt(255), RandInt(255),RandInt(255));
            x1 := RandInt(dev.width - 1);
            x2 := RandInt(dev.width - 1);
            IF x2 < x1 THEN Swap(x1, x2) END;
            y1 := RandInt(dev.height - 1);
            y2 := RandInt(dev.height - 1);
            IF y2 < y1 THEN Swap(y1, y2) END;
            dev.FilledRect(x1, y1, x2 - x1, y2 - y1, col);
            IF SysTick.GetTicks() - t0 >= 1000 THEN
                t1 := SysTick.GetTicks();
                EXIT
            END;
            INC(cnt);
        END;
    ELSE
        name := " fills ";
        LOOP
            col := dev.ColorRGB(RandInt(255), RandInt(255),RandInt(255));
            dev.Fill(col);
            IF SysTick.GetTicks() - t0 >= 1000 THEN
                t1 := SysTick.GetTicks();
                EXIT
            END;
            INC(cnt);
        END;
    END;
    OSStream.StdOut.FormatInteger(cnt, 0, {});
    OSStream.StdOut.WriteString(name);
    OSStream.StdOut.WriteString("drawn in ");
    OSStream.StdOut.FormatInteger(INTEGER(t1 - t0), 0, {});
    OSStream.StdOut.WriteString("ms.");
    OSStream.StdOut.WriteNL;
END Draw;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    SysTick.Init(BoardConfig.HCLK, 1000);
    
    BoardConfig.InitILI9341SPI(bus, rst, cs, dc);
    DeviceILI9341.Init(dev, bus, rst, cs, dc);
    dev.Config;
	SysTick.Delay(1000);
	
    TRACE("Start");
    WHILE TRUE DO
        Draw(Points);
        SysTick.Delay(500);
        Draw(FRects);
        SysTick.Delay(500);
        Draw(Fills);
        SysTick.Delay(500);
    END;
END Test.