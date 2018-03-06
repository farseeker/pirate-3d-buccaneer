#! /usr/bin/env python
import re
import sys
pid = int(sys.argv[1])
path_maps = '/proc/%d/maps' % (pid)
path_mem = '/proc/%d/mem' % (pid)
maps_file = open(path_maps, 'r')
mem_file = open(path_mem, 'r', 0)
memchunks=0
memrange=6
for line in maps_file.readlines():  # for each mapped region
    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
    if m.group(3) == 'r':  # if this is a readable region
	for memchunks in range(0,memrange-1):
		if memchunks%2 == 0:
	    		start = int(m.group(1), 16)
	    		end = int(m.group(2), 16)
	    		mem_file.seek(start+(end-start)*memchunks/memrange)  # seek to region start
			#print start,end,((end-start)*(memchunks+1)/memrange),(end-start)
	    		chunk = mem_file.read((end-start)/memrange)  # read region contents
	    		print chunk,  # dump contents to standard output
maps_file.close()
mem_file.close()
