#!/usr/bin/env -S python
import re
from bisect import bisect_right
from collections import namedtuple

try:
    import gdb
except ImportError as e:
    raise ImportError("This script must be run in GDB: ", str(e))

regex = re.compile(r'^(?P<address>\S+)\s+(?P<type>\S+)\s+(\"(?P<name>.+)\")\s+(?P<size>\S+)\s*$')
codeStart = []
items = {}
data = {}
const = {}
Item = namedtuple('Item', ['address', 'type', 'name', 'size'])

def tryLoadMapFile(filename):
    try:
        fh = open(filename, 'r')
    except FileNotFoundError:
        print("file '%s' not found" % filename)
        return False
    
    matches = 0
    for line in fh:
        m = regex.match(line)
        if not m is None:
            matches += 1
            typ = m.group("type")
            address = int(m.group("address"), 16)
            typ = m.group("type")
            name = m.group("name").replace(r'\\\"', '"')
            item = Item(address, typ, name, int(m.group("size")))
            items[address] = item
            if typ == "data":
                data[name] = address
            elif typ == "const":
                const[name] = address
            elif typ == "code":
                codeStart.append(address)

    fh.close()
    codeStart.sort()
    return matches > 0

class ReadMapCmd(gdb.Command):
    """readmap filename : Read and parses ECS .map file"""
    def __init__(self):
        super(ReadMapCmd, self).__init__("readmap", gdb.COMMAND_DATA, gdb.COMPLETE_FILENAME, prefix = True)
    
    def invoke(self, arg, from_tty):
        argv = gdb.string_to_argv(arg)
        if len(argv) != 1:
            print("Error : Expected single argument")
            return
        
        codeStart.clear()
        items.clear()
        data.clear()
        const.clear()

        filename = argv[0]
        if not tryLoadMapFile(filename):
            print("Error : Failed to load data from file '%s'" % filename)
        else:
            print("Map file '%s' parsed. %d items added." % (filename, len(items)))

# Search for procedure at address return None if not found
def tryFindProcedure(address):
    idx = bisect_right(codeStart, address)
    if idx > 0:
        start = codeStart[idx - 1]
        item = items[start]
        # Check if inside bounds of start + size
        if address <= start + item.size:     
            return item
    return None

def stop_handler (event):
    if isinstance(event, gdb.SignalEvent):
        frame = gdb.newest_frame()
        proc = tryFindProcedure(frame.pc())
        if event.stop_signal == 'SIGINT':
            if not proc is None:
                print("Stopped execution in PROCEDURE '%s'" % proc.name)
        elif event.stop_signal == 'SIGTRAP':
            if not proc is None:
                print("Trap/Breakpoint in PROCEDURE '%s'" % proc.name)
        
if __name__ == "__main__":
    ReadMapCmd()
    gdb.events.stop.connect(stop_handler)
