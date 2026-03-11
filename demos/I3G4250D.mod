(* Test I3G4250D MEMS motion sensor, 3-axis digital output gyroscope *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;

TYPE
    BYTE = SYSTEM.BYTE;
    
CONST
    SysTick = BoardConfig.SysTick;
    Pins = BoardConfig.Pins;
    SPI5 = BoardConfig.SPI5;

VAR
    bus : SPI5.Bus;
    cs : Pins.Pin;
    txbuffer : ARRAY 4 OF BYTE;
    rxbuffer : ARRAY 4 OF BYTE;

PROCEDURE Test;
BEGIN
    TRACE('test');
    cs.Off;
    SysTick.Delay(500); 
    txbuffer[0] := 08FX;
    txbuffer[1] := 00X;
    rxbuffer[0] := 00X;
    rxbuffer[1] := 00X;
    bus.ReadWrite(rxbuffer, txbuffer, 0, 0, 2);
    cs.On;
    TRACE(rxbuffer[1]);
    TRACE(bus.res);
    TRACE("test.end");
END Test;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    
    cs.Init(Pins.C, 1, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    cs.On;
    
    BoardConfig.InitI3G4250DSPI(bus);
    
    TRACE("Start");
    WHILE TRUE DO
        SysTick.Delay(1000);
        Test;
    END;
END Test.