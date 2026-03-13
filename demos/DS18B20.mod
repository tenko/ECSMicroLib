(** DS18B20 1-Wire Digital Thermometer demo *)
MODULE Test;

IMPORT BoardConfig;
IN Micro IMPORT DeviceDS18B20;

CONST
    SysTick = BoardConfig.SysTick;
    OWire = BoardConfig.OWire;
    
VAR
    bus : OWire.Bus;
    dev : DeviceDS18B20.DS18B20;
    ID : UNSIGNED64;
    temp : REAL;
    res : INTEGER;
	
BEGIN
    BoardConfig.Init;
    BoardConfig.InitOWire(bus);
    
    DeviceDS18B20.Init(dev, bus);
    dev.bus := PTR(bus); (* probably bug in ECS *)
    
    TRACE(bus.Reset()); (* Return TRUE if device on owbus *)
    
    (* Search for ROM ID *)
    ID := 0;
    
    bus.ResetSearch();
    WHILE bus.Next() DO
        bus.GetROM(ID);
    END;
    TRACE(ID);
    
    (* Set maximum resolution *)
    TRACE(dev.WriteResolution(ID, 12));
    SysTick.Delay(1000);
    TRACE(dev.ReadResolution(ID, res));
    TRACE(res);

    temp := -999;
    WHILE TRUE DO
        (* Start conversion *)
        TRACE(dev.Start(ID));
        
        (* Should delay atleast 750ms for temperature conversion to complete *)
        SysTick.Delay(1000);
        
        (* read data *)
        TRACE(dev.Read(ID, temp));
        TRACE(temp);
        SysTick.Delay(1000);
    END;
END Test.