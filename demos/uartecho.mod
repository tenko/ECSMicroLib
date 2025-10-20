(** Test uart with echo of received characters. *)
MODULE Test;
IMPORT BoardConfig;

IN Micro IMPORT ARMv7M;

CONST
    Uart = BoardConfig.Uart;
    
VAR
    bus : Uart.Bus;
    x : CHAR;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    BoardConfig.InitUart(bus, 4800, Uart.parityNone, Uart.stopBits1);
    TRACE("Start");
    REPEAT
        ARMv7M.WFI;
        IF (bus.Any() > 0) & bus.TXDone() THEN
            IF bus.ReadChar(x) THEN
                IGNORE(bus.WriteChar(x));
            END;
        END;
    UNTIL FALSE
END Test.