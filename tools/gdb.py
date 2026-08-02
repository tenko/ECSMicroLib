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
    
    cidx = 0
    matches = 0
    for line in fh:
        m = regex.match(line)
        if not m is None:
            matches += 1
            typ = m.group("type")
            address = int(m.group("address"), 16)
            typ = m.group("type")
            if typ == "const":
                name = "const%d" % cidx
                cidx += 1
            else:
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

class MapLoadCmd(gdb.Command):
    """readmap filename : Read and parses ECS .map file"""
    def __init__(self):
        super(MapLoadCmd, self).__init__("mapload", gdb.COMMAND_DATA, gdb.COMPLETE_FILENAME)
    
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

class MapInfoCmd(gdb.Command):
    """Read object"""
    def __init__(self):
        super(MapInfoCmd, self).__init__("mapinfo", gdb.COMMAND_USER)
    
    def invoke(self, arg, from_tty):
        argv = gdb.string_to_argv(arg)
        if len(argv) != 1:
            print("Error : Expected single argument")
            return
        
        name = argv[0]
        for address, item in items.items():
            if item.name == name:
                if item.type == "data":
                    if item.size == 1:
                        gdb.execute("x/bd 0x%x" % address)
                    elif item.size == 2:
                        gdb.execute("x/hd 0x%x" % address)
                    elif item.size == 4:
                        gdb.execute("x/wd 0x%x" % address)
                    elif item.size == 8:
                        gdb.execute("x/gd 0x%x" % address)
                    else:
                        gdb.execute("x/%dbx 0x%x" % (item.size, address))
                elif item.type == "const":
                    gdb.execute("x/%dbx 0x%x" % (item.size, address))
                else:
                    gdb.execute("disassemble /r 0x%x,0x%x" % (address, address + item.size))
                return
                
        print("Error : could not find object '%s'" % name)
    
    def complete(self, text, word):
        text = text.lstrip()
        left = -1
        # '.' and ':' is a break in the completion
        try:
            left = text.rindex('.')
        except ValueError:
            try:
                left = text.rindex(':')
            except ValueError:
                pass
        
        candiates = [
            item.name[left + 1:] for item in items.values()
            if item.name.lower().startswith(text.lower())
        ]
        if len(candiates) == 0:
            gdb.COMPLETE_NONE
        else:
            return candiates
        
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

# Custom stop handler to try to find procedure at fram PC
def stop_handler (event):
    if isinstance(event, (gdb.SignalEvent, gdb.StopEvent)):
        frame = gdb.newest_frame()
        if not frame.is_valid(): return
        proc = tryFindProcedure(frame.pc())
        ofs = 0 ; args = (0, '')
        if not proc is None:
            ofs = frame.pc() - proc.address
            args = ofs, proc.name
        if isinstance(event, gdb.SignalEvent):
            if event.stop_signal == 'SIGINT':
                if proc is None:
                    print("Stopped execution at unkown address")
                else:
                    print("Stopped execution at offset %d in PROCEDURE %s" % args)
        else:
            if proc is None:
                print("Trap/Breakpoint at unkown address")
            else:
                print("Trap/Breakpoint at offset %d in PROCEDURE %s" % args)

gdb.events.stop.connect(stop_handler)     
MapInfoCmd()
MapLoadCmd()
