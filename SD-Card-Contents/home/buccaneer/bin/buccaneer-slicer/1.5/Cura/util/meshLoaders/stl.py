from __future__ import absolute_import
__copyright__ = "Copyright (C) 2013 David Braam - Released under terms of the AGPLv3 License"

import sys
import os
import struct
import time
import numpy

from util import mesh
from util import profile

def _loadAscii(m, f):
	f.seek(0,2)
        total=f.tell()/1024
        f.seek(0,0)

        total_2percent = total/50

	cnt = 0

	prev_pos = 0
        ### stdout for 0% done.
        sys.stdout.write("Loading: %d%%\n" % ((f.tell()/1024)*50/total,))
        sys.stdout.flush()
	

	for lines in f:
		current_pos = f.tell()/1024
                if (current_pos - prev_pos > total_2percent):
                        sys.stdout.write("Loading: %d%%\n" % ((f.tell()/1024)*50/total,))
                        sys.stdout.flush()
			prev_pos = current_pos

		for line in lines.split('\r'):
			if 'vertex' in line:
				cnt += 1

	### stdout for 100% done.
        sys.stdout.write("Loading: %d%%\n" % ((f.tell()/1024)*50/total,))
        sys.stdout.flush()

	m._prepareFaceCount(int(cnt) / 3)
	f.seek(5, os.SEEK_SET)
	cnt = 0
	data = [None,None,None]
	prev_pos = 5
	for lines in f:
		current_pos = f.tell()/1024
                if (current_pos - prev_pos > total_2percent):
                        sys.stdout.write("Loading: %d%%\n" % (50+((f.tell()/1024)*50/total),))
                        sys.stdout.flush()
			prev_pos = current_pos

		for line in lines.split('\r'):
			if 'vertex' in line:
				data[cnt] = line.split()[1:]
				cnt += 1
				if cnt == 3:
					m._addFace(float(data[0][0]), float(data[0][1]), float(data[0][2]), float(data[1][0]), float(data[1][1]), float(data[1][2]), float(data[2][0]), float(data[2][1]), float(data[2][2]))
					cnt = 0

	### stdout for 100% done.
        sys.stdout.write("Loading: %d%%\n" % (50+((f.tell()/1024)*50/total),))
        sys.stdout.flush()
        print('\n')

def _loadBinary(m, f):
	#Skip the header
	f.read(80-5)
	faceCount = struct.unpack('<I', f.read(4))[0]
	m._prepareFaceCount(faceCount)

	faceCount_1percent = faceCount/100
        prev_idx = 0

        sys.stdout.write("Loading: 0%\n")
        sys.stdout.flush()

	for idx in xrange(0, faceCount):
		if (idx-prev_idx > faceCount_1percent):
                        sys.stdout.write("Loading: %d%%\n" % ((idx*100/faceCount),))
                        sys.stdout.flush()
                        prev_idx = idx

		data = struct.unpack("<ffffffffffffH", f.read(50))
		m._addFace(data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11])
	sys.stdout.write("Loading: 100%\n")
        sys.stdout.flush()
        print('\n')

def isStlBinary(m,f):

	f.seek(0,2)
        size=f.tell()

	f.seek(5, os.SEEK_SET)
	f.read(80-5)
        faceCount = struct.unpack('<I', f.read(4))[0]

        face_size = (32 / 8 * 3) + ((32 / 8 * 3) * 3) + (16 / 8);
    	expect = 80 + (32 / 8) + (faceCount * face_size);
 #   	sys.stdout.write("expect: %i size: %i\n" % (int(expect/1024),int(size/1024)));
#	sys.stdout.flush()

    	if (expect==size):
		return 1
    	return 0


def loadScene(filename, userScale = None):
	obj = mesh.printableObject(filename)
	m = obj._addMesh()

	f = open(filename, "rb")
	if f.read(5).lower() == "solid":
		if isStlBinary(m,f)==1:
			f.seek(5, os.SEEK_SET)
			_loadBinary(m, f)
		else:
			_loadAscii(m, f)
	else:
		_loadBinary(m, f)

#       stlBinary = isStlBinary(m,f)
#
#       if (stlBinary):
#               _loadBinary(m,f)
#       else:
#               _loadAscii(m, f)

	f.close()
	obj._postProcessAfterLoad()
	obj.setPosition(numpy.array([0.0, 0.0]))
	machineSize = numpy.array([profile.getMachineSettingFloat('machine_width'), profile.getMachineSettingFloat('machine_depth'), profile.getMachineSettingFloat('machine_height')])
	size=machineSize - numpy.array(profile.calculateObjectSizeOffsets() + [0.0], numpy.float32) * 2 - numpy.array([1,1,1], numpy.float32)
	obj.scaleUpTo(size, userScale)
	
	#current_scale=obj.getScale()[0]
	return [obj]

def saveScene(filename, objects):
	f = open(filename, 'wb')
	saveSceneStream(f, objects)
	f.close()

def saveSceneStream(stream, objects):
	#Write the STL binary header. This can contain any info, except for "SOLID" at the start.
	stream.write(("CURA BINARY STL EXPORT. " + time.strftime('%a %d %b %Y %H:%M:%S')).ljust(80, '\000'))

	vertexCount = 0
	for obj in objects:
		for m in obj._meshList:
			vertexCount += m.vertexCount

	#Next follow 4 binary bytes containing the amount of faces, and then the face information.
	stream.write(struct.pack("<I", int(vertexCount / 3)))
	for obj in objects:
		for m in obj._meshList:
			vertexes = m.getTransformedVertexes(True)
			for idx in xrange(0, m.vertexCount, 3):
				v1 = vertexes[idx]
				v2 = vertexes[idx+1]
				v3 = vertexes[idx+2]
				stream.write(struct.pack("<fff", 0.0, 0.0, 0.0))
				stream.write(struct.pack("<fff", v1[0], v1[1], v1[2]))
				stream.write(struct.pack("<fff", v2[0], v2[1], v2[2]))
				stream.write(struct.pack("<fff", v3[0], v3[1], v3[2]))
				stream.write(struct.pack("<H", 0))
