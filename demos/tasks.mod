(** Simple coroutine demo with round-robin type scheduler *)
MODULE Test;
IMPORT BoardConfig;

IN Std IMPORT Coroutine(256, UNSIGNED32);
IN Std IMPORT UInt := ADTBasicType(UNSIGNED32);
IN Std IMPORT TaskQueue := ADTVector(Coroutine.TaskEntry);

IN Micro IMPORT ARMv7M;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

CONST Pins = BoardConfig.Pins;

TYPE
    Task1 = RECORD (Coroutine.Task) END;
    Task2 = RECORD (Coroutine.Task) END;
    
VAR
    queue : TaskQueue.Vector;
    task1: Task1;
    task2: Task2;
    pin : Pins.Pin;
    tasks : INTEGER;

PROCEDURE TaskCompare(left-, right- : Coroutine.TaskEntry): INTEGER;
BEGIN RETURN UInt.Compare(right.time, left.time);
END TaskCompare;

PROCEDURE (VAR task: Task1) Call;
BEGIN
    WHILE TRUE DO
        pin.On;
        TRACE("Task1.On");
        task.Sleep(200);
        
        pin.Off;
        TRACE("Task1.Off");
        task.Sleep(800);
    END;
END Call;

PROCEDURE (VAR task: Task2) Call;
BEGIN
    WHILE TRUE DO
        task.Sleep(250);
        
        pin.On;
        TRACE("Task2.On");
        task.Sleep(50);
        
        pin.Off;
        TRACE("Task2.Off");
        task.Sleep(200);
    END;
END Call;

PROCEDURE AddTask(VAR task: Coroutine.Task);
VAR
    entry : Coroutine.TaskEntry;
BEGIN
    task.time := 0;
    entry.task := PTR(task);
    entry.time := SysTick.GetTicks() + tasks;
    queue.HeapInsert(TaskCompare, entry);
    INC(tasks);
END AddTask;

PROCEDURE Run;
VAR
    entry : Coroutine.TaskEntry;
BEGIN
    TRACE("Loop start");
    (* run loop until task queue is empty *)
    LOOP
        IF queue.Size() = 0 THEN EXIT END;
        queue.Get(0, entry);
        LOOP
            IF SysTick.GetTicks() >= entry.time THEN
                (* remove task from queue *)
                IGNORE(queue.HeapPop(TaskCompare, entry));
                IF entry.task.Await() THEN
                    (* Reschedule task *)
                    entry.time := SysTick.GetTicks() + entry.task.time;
                    queue.HeapInsert(TaskCompare, entry);
                END;
                EXIT; (* Get next task *)
            END;
            ARMv7M.WFI; (* Idle *)
        END;
    END;
    TRACE("Loop finished");
END Run;

BEGIN
	TRACE("START");
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);

    SysTick.Init(BoardConfig.HCLK, 1000);
    
    tasks := 0;
    queue.Init(2);
    AddTask(task1);
    AddTask(task2);
    Run;
END Test.