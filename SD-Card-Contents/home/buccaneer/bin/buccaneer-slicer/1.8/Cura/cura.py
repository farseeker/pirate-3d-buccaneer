import re
import math
import struct
from optparse import OptionParser

# For pads and scale control
# mechanical dimensions
max_x = 130
max_y = 98
max_z = 139

def update_ranges(r,v):
	for i in range(0,6,2):
		if(r[i]>float(v[i/2])):
			r[i]=float(v[i/2])
	for i in range(1,6,2):
		if(r[i]<float(v[i/2])):
			r[i]=float(v[i/2])

def to_float_list(bytes12):
	if len(bytes12)<12: # broken STL file!?
		return [0,0,0]
	v=[]
	for i in range(0,3):
		v.append(float(struct.unpack("<f",bytes12[4*i:4*(i+1)])[0]))
	return v

# End 'For pads and scale control'


# Set here defaults of configuration parameters, but read them from slicer.ini and/or command line
# for updating them.
# PUT THEM IN FLOAT WHENEVER POSSIBLE!
settings_dictionary = {'bottom_layer_speed' : 20.0,
	'bottom_thickness' : 0.4,
	'brim_line_count' : 10,
	'cool_head_lift' : 'False',
	'cool_min_feedrate' : 10.0,
	'cool_min_layer_time' : 10.0,
	'fan_enabled' : 'True',
	'fan_full_height' : 0.5,
	'fan_speed' : 100.0,
	'fan_speed_max' : 100.0,
	'filament_diameter' : 1.75,
	'filament_diameter2' : 0,
	'filament_diameter3' : 0,
	'filament_diameter4' : 0,
	'filament_flow' : 100.0,
	'fill_density' : 20.0,
	'fill_overlap' : 15.0,
	'fix_horrible_union_all_type_a' : 'False',
	'fix_horrible_union_all_type_b' : 'False',
	'fix_horrible_use_open_bits' : 'False',
	'fix_horrible_extensive_stitching' : 'False',
	'infill_speed' : 0.0,
	'layer_height' : 0.17,
	'nozzle_size' : 0.35,
	'ooze_shield' : 'False',
	'object_sink' : 0.0,
	'overlap_dual' : 0.2,
	'platform_adhesion' : 'None',
	'print_speed' : 50.0,
	'print_bed_temperature' : 40.0,
	'raft_margin' : 5,
	'raft_base_thickness' : 0.3,
	'raft_base_linewidth' : 0.7,
	'raft_interface_thickness' : 0.2,
	'raft_interface_linewidth' : 0.2,
	'raft_line_spacing' : 1.0,
	'retraction_amount' : 1.0,
	'retraction_combing' : 'True',
	'retraction_dual_amount' : 16.5,
	'retraction_enable' : 'True',
	'retraction_minimal_extrusion' : 0.5,
	'retraction_min_travel' : 1.5,
	'retraction_speed' : 40.0,
	'skirt_gap' : 3.0,
	'skirt_line_count' : 1,
	'skirt_minimal_length' : 150.0,
	'solid_bottom' : 'True',
	'solid_layer_thickness' : 0.8,
	'solid_top' : 'True',
	'spiralize' : 'False',
	'support' : 'None',
	'support_angle' : 45,
	'support_dual_extrusion' : 'Both',
	'support_fill_rate' : 15.0,
	'support_xy_distance' : 0.7,
	'support_z_distance' : 0.15,
	'travel_speed' : 150.0,
	'wall_thickness' : 1.0,
	'wipe_tower' : 'False'}

def calculateSolidLayerCount(dictionary):
	layerHeight = dictionary['layer_height']
	solidThickness = dictionary['solid_layer_thickness']
	if layerHeight == 0.0:
		return 1
	return int(math.ceil(solidThickness / (layerHeight - 0.0001)))

def calculateEdgeWidth(dictionary):
	wallThickness = dictionary['wall_thickness']
	nozzleSize = dictionary['nozzle_size']
	if dictionary['spiralize'] == 'True':
		return wallThickness
	if wallThickness < 0.01:
		return nozzleSize
	if wallThickness < nozzleSize:
		return wallThickness
	lineCount = int(wallThickness / (nozzleSize - 0.0001))
	if lineCount == 0:
		return nozzleSize
	lineWidth = wallThickness / lineCount
	lineWidthAlt = wallThickness / (lineCount + 1)
	if lineWidth > nozzleSize * 1.5:
		return lineWidthAlt
	return lineWidth
	
def calculateLineCount(dictionary):
	wallThickness = dictionary['wall_thickness']
	nozzleSize = dictionary['nozzle_size']
	if wallThickness < 0.01:
		return 0
	if wallThickness < nozzleSize:
		return 1
	if dictionary['spiralize'] == 'True':
		return 1
	lineCount = int(wallThickness / (nozzleSize - 0.0001))
	if lineCount < 1:
		lineCount = 1
	lineWidth = wallThickness / lineCount
	lineWidthAlt = wallThickness / (lineCount + 1)
	if lineWidth > nozzleSize * 1.5:
		return lineCount + 1
	return lineCount

def minimalExtruderCount(dictionary):
	if dictionary['support'] == 'None':
		return 1
	if dictionary['support_dual_extrusion'] == 'Second extruder':
		return 2
	return 1

def calculateEdgeWidth(dictionary):
	wallThickness = dictionary['wall_thickness']
	nozzleSize = dictionary['nozzle_size']
	if dictionary['spiralize'] == 'True':
		return wallThickness
	if wallThickness < 0.01:
		return nozzleSize
	if wallThickness < nozzleSize:
		return wallThickness
	lineCount = int(wallThickness / (nozzleSize - 0.0001))
	if lineCount == 0:
		return nozzleSize
	lineWidth = wallThickness / lineCount
	lineWidthAlt = wallThickness / (lineCount + 1)
	if lineWidth > nozzleSize * 1.5:
		return lineWidthAlt
	return lineWidth

# read slicer.ini or other provided configuration file
def loadSettings(settings_dictionary,settingsFile):
	mode = 'Profile'
	with open(settingsFile) as f:
		for line in f:
			if '[profile]' in line:
				mode = 'Profile'
			elif '[alterations]' in line:
				mode = 'Alterations'
			else:
				if mode=='Profile':
					param = re.findall(r"[A-Za-z0-9\_\-]+ =",line)
					if len(param)>0:
						param = re.findall(r"[A-Za-z0-9\_\-]+",param[0])
						value = re.findall(r"= [A-Za-z0-9\_\-.]+",line)
						if len(value)>0:
							value = re.findall(r"[A-Za-z0-9\_\-.]+",value[0])
							value[0] = type(settings_dictionary[param[0]])(value[0])
							if settings_dictionary[param[0]] != value[0]:
								#print param[0]+" = "+value[0]+" !="+ settings_dictionary[param[0]] # debug!
								settings_dictionary[param[0]] = value[0]
				#else: # mode == 'Alterations' # nothing to do: the state machine is providing them.
	f.close()

# update settings.
def overwriteSettings(dictionary,params):
	for p in params.split(','):
		a=p.split('=')
		a[1]=a[1].replace('++',' ')
		print a[0]+' = '+a[1]
		dictionary[a[0]] = type(dictionary[a[0]])(a[1])


# main program starts

parser = OptionParser(usage="usage: %prog -s [options] <filename>.stl")
parser.add_option("-i", "--ini", action="store", type="string", dest="slicerini",
	help="Load settings from a profile ini file")
parser.add_option("-p", "--param", action="store", type="string", dest="param",
	help="Pass parameters from command line")
parser.add_option("-s", "--slice", action="store_true", dest="slice",
	help="Slice the given file")
parser.add_option("-o", "--output", action="store", type="string", dest="output",
	help="path to write sliced file to")
parser.add_option("-t", "--transform", action="store", type="string", dest="transform",
	help="rotate and scale the object through a matrix")

(options, args) = parser.parse_args()

if options.slice is None or options.output is None:
	print "usage: python2 cura.py -s [options] -o <output> <filename>.stl"
	quit()

settingsFile = '/home/buccaneer/bin/buccaneer-slicer/current/slicer.ini'	

if options.slicerini is not None:
	settingsFile = options.slicerini

loadSettings(settings_dictionary,settingsFile)

if options.param is not None:
	overwriteSettings(settings_dictionary,options.param)
	
# parameters for the binary program; pass them each with -s
parameters = {
	'coolHeadLift': 1 if settings_dictionary['cool_head_lift'] == 'True' else 0,
	'downSkinCount': int(calculateSolidLayerCount(settings_dictionary)) if settings_dictionary['solid_bottom'] == 'True' else 0,
	'enableCombing': 1 if settings_dictionary['retraction_combing'] == 'True' else 0,
	#'extruderOffset': ..., we are not using it!
	'extrusionWidth': int(calculateEdgeWidth(settings_dictionary) * 1000),
	'fanSpeedMax': int(settings_dictionary['fan_speed_max']) if settings_dictionary['fan_enabled'] == 'True' else 0,
	'fanSpeedMin': int(settings_dictionary['fan_speed']) if settings_dictionary['fan_enabled'] == 'True' else 0,
	'filamentDiameter': int(settings_dictionary['filament_diameter'] * 1000),
	'filamentFlow': int(settings_dictionary['filament_flow']),
	'fixHorrible': 0,
	'infillOverlap': int(settings_dictionary['fill_overlap']),
	'infillSpeed': int(settings_dictionary['infill_speed']) if int(settings_dictionary['infill_speed']) > 0 else int(settings_dictionary['print_speed']),
	'initialLayerSpeed': int(settings_dictionary['bottom_layer_speed']),
	'initialLayerThickness': int(settings_dictionary['bottom_thickness'] * 1000) if settings_dictionary['bottom_thickness'] > 0.0 else int(settings_dictionary['layer_height'] * 1000),
	'initialSpeedupLayers': int(4),
	'insetCount': int(calculateLineCount(settings_dictionary)),
	'layerThickness': int(settings_dictionary['layer_height'] * 1000),
	'minimalExtrusionBeforeRetraction': int(settings_dictionary['retraction_minimal_extrusion'] * 1000),
	'minimalFeedrate': int(settings_dictionary['cool_min_feedrate']),
	'minimalLayerTime': int(settings_dictionary['cool_min_layer_time']),
	'moveSpeed': int(settings_dictionary['travel_speed']),
	'multiVolumeOverlap': int(settings_dictionary['overlap_dual'] * 1000),
	'objectSink': int(settings_dictionary['object_sink'] * 1000),
	'printSpeed': int(settings_dictionary['print_speed']),
	'retractionAmount': int(settings_dictionary['retraction_amount'] * 1000) if settings_dictionary['retraction_enable'] == 'True' else 0,
	'retractionAmountExtruderSwitch': int(settings_dictionary['retraction_dual_amount'] * 1000),
	'retractionMinimalDistance': int(settings_dictionary['retraction_min_travel'] * 1000),
	'retractionSpeed': int(settings_dictionary['retraction_speed']),
	#'skirtDistance': done after
	#'skirtLineCount': done after
	#'skirtMinLength': done after
	#'sparseInfillLineDistance': done after
	'supportAngle': int(-1) if settings_dictionary['support'] == 'None' else int(settings_dictionary['support_angle']),
	'supportEverywhere': int(1) if settings_dictionary['support'] == 'Everywhere' else int(0),
	'supportExtruder': 0 if settings_dictionary['support_dual_extrusion'] == 'First extruder' else (1 if settings_dictionary['support_dual_extrusion'] == 'Second extruder' and minimalExtruderCount(settings_dictionary) > 1 else -1),
	'supportLineDistance': int(100 * calculateEdgeWidth(settings_dictionary) * 1000 / settings_dictionary['support_fill_rate']) if settings_dictionary['support_fill_rate'] > 0 else -1,
	'supportXYDistance': int(1000 * settings_dictionary['support_xy_distance']),
	'supportZDistance': int(1000 * settings_dictionary['support_z_distance']),
	'upSkinCount': int(calculateSolidLayerCount(settings_dictionary)) if settings_dictionary['solid_top'] == 'True' else 0,
}

# these other parameters should be set after the previous initialization, for avoiding loops of variable definitions.
fanFullHeight = int(settings_dictionary['fan_full_height'] * 1000)
parameters['fanFullOnLayerNr'] = (fanFullHeight - parameters['initialLayerThickness'] - 1) / parameters['layerThickness'] + 1
if parameters['fanFullOnLayerNr'] < 0:
	parameters['fanFullOnLayerNr'] = 0
if settings_dictionary['fill_density'] == 0:
	parameters['sparseInfillLineDistance'] = -1
elif settings_dictionary['fill_density'] == 100:
	parameters['sparseInfillLineDistance'] = parameters['extrusionWidth']
	#Set the up/down skins height to 10000 if we want a 100% filled object.
	# This gives better results then normal 100% infill as the sparse and up/down skin have some overlap.
	parameters['downSkinCount'] = 10000
	parameters['upSkinCount'] = 10000
else:
	parameters['sparseInfillLineDistance'] = int(100 * calculateEdgeWidth(settings_dictionary) * 1000 / settings_dictionary['fill_density'])
if settings_dictionary['platform_adhesion'] == 'Brim':
	parameters['skirtDistance'] = 0
	parameters['skirtLineCount'] = int(settings_dictionary['brim_line_count'])
elif settings_dictionary['platform_adhesion'] == 'Raft':
	parameters['skirtDistance'] = 0
	parameters['skirtLineCount'] = 0
	parameters['raftMargin'] = int(settings_dictionary['raft_margin'] * 1000)
	parameters['raftLineSpacing'] = int(settings_dictionary['raft_line_spacing'] * 1000)
	parameters['raftBaseThickness'] = int(settings_dictionary['raft_base_thickness'] * 1000)
	parameters['raftBaseLinewidth'] = int(settings_dictionary['raft_base_linewidth'] * 1000)
	parameters['raftInterfaceThickness'] = int(settings_dictionary['raft_interface_thickness'] * 1000)
	parameters['raftInterfaceLinewidth'] = int(settings_dictionary['raft_interface_linewidth'] * 1000)
else:
	parameters['skirtDistance'] = int(settings_dictionary['skirt_gap'] * 1000)
	parameters['skirtLineCount'] = int(settings_dictionary['skirt_line_count'])
	parameters['skirtMinLength'] = int(settings_dictionary['skirt_minimal_length'] * 1000)
if settings_dictionary['fix_horrible_union_all_type_a'] == 'True':
	parameters['fixHorrible'] |= 0x01
if settings_dictionary['fix_horrible_union_all_type_b'] == 'True':
	parameters['fixHorrible'] |= 0x02
if settings_dictionary['fix_horrible_use_open_bits'] == 'True':
	parameters['fixHorrible'] |= 0x10
if settings_dictionary['fix_horrible_extensive_stitching'] == 'True':
	parameters['fixHorrible'] |= 0x04
if parameters['layerThickness'] <= 0:
	parameters['layerThickness'] = 1000
if settings_dictionary['spiralize'] == 'True':
	parameters['spiralizeMode'] = 1
if settings_dictionary['wipe_tower'] == 'True':
	parameters['wipeTowerSize'] = int(math.sqrt(settings_dictionary['wipe_tower_volume'] * 1000 * 1000 * 1000 / parameters['layerThickness']))
if settings_dictionary['ooze_shield'] == 'True':
	parameters['enableOozeShield'] = 1



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### anti-warping pads start
import os
executable_path_n_name = "/home/buccaneer/bin/buccaneer-slicer/current/anti-warper.out"

# min & max x, y and z ranges
ranges = [0,0,0,0,0,0]


# check the STL file format and, if needed, fix it
f=open(args[0],"r")
header=f.read(5)

if os.system("file '%s' | grep ': data'" % (args[0])) == 0:
	# binary STL
	if header=="solid":
		# broken header; to be fixed
		print "fixing header..."
		os.system("cat '%s' | sed s/solid/dilos/ > /tmp/fixed.temp ; mv /tmp/fixed.temp '%s'" % (args[0],args[0])) # this will not mess up with the file pointer.
	# continue processing binary STL
	print "binary STL"
	drop=f.read(80-5)
	triangles=int(struct.unpack("<i",f.read(4))[0])
	for i in range(0,triangles):
		normal=f.read(12)
		for j in range(0,3):
			point=f.read(12)
			values=to_float_list(point)
			update_ranges(ranges,values)
		drop=f.read(2)
elif header=="solid":
	# ASCII STL
	print "ASCII STL"
	for line in f:
		if "vertex" in line:
			values = re.findall(r"[-+]?\d*\.\d+|\d+",line);
			update_ranges(ranges,values)
	if ranges == [0,0,0,0,0,0]:
		print "BROKEN STL FILE FORMAT!"
		f.close()
		quit()
else:
	print "BROKEN STL FILE FORMAT!"
	f.close()
	quit()
f.close()

if options.transform == "[1,0,0,0,1,0,0,0,1]" or options.transform == "[1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0]":
	# then the app, may be, hasn't checked the scaling...
	print "checking scale..."
	x_out = max_x/(ranges[1]-ranges[0])
	y_out = max_y/(ranges[3]-ranges[2])
	z_out = max_z/(ranges[5]-ranges[4])
	if min(x_out,y_out,z_out)<1:
		scale=str(min(x_out,y_out,z_out))[0:4]
		print "automatically scaling down to "+scale
	else:
		scale=1
	options.transform = "["+str(scale)+",0,0,0,"+str(scale)+",0,0,0,"+str(scale)+"]"
# else it's already scaled good by the app

if options.transform is not None:
	tp = []
	for param in options.transform.split(','):
		param = param.replace("["," ")
		param = param.replace("]"," ")
		tp.append(param)
else:
	options.transform = "[1,0,0,0,1,0,0,0,1]"
	tp = [1,0,0,0,1,0,0,0,1]

print "%s '%s' %s %s %s %s %s %s %s %s %s %s %s" % (executable_path_n_name,args[0],max_x,max_y,tp[0],tp[1],tp[2],tp[3],tp[4],tp[5],tp[6],tp[7],tp[8])
return_value = os.system("%s '%s' %s %s %s %s %s %s %s %s %s %s %s" % (executable_path_n_name,args[0],max_x,max_y,tp[0],tp[1],tp[2],tp[3],tp[4],tp[5],tp[6],tp[7],tp[8]))
if return_value==0:
	args[0] = "/home/buccaneer/data/.with_anti_warping_pads.stl"
	print "written .with_anti_warping_pads.stl"
	options.transform = "[1,0,0,0,1,0,0,0,1]"
	tp = [1,0,0,0,1,0,0,0,1]
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### anti-warping pads end



# launch the CuraEngine with all his command line options
executable_path_n_name = "/home/buccaneer/bin/buccaneer-slicer/current/CuraEngine/CuraEngine"
params = ""
for p in parameters:
	params += "-s "+p+"="+str(parameters[p])+" "
command = "rm /tmp/link.stl ; ln -s $(realpath '%s') /tmp/link.stl ; %s %s -m %s,%s,%s,%s,%s,%s,%s,%s,%s -o %s /tmp/link.stl" % (args[0],executable_path_n_name,params,tp[0],tp[1],tp[2],tp[3],tp[4],tp[5],tp[6],tp[7],tp[8],options.output)
print command
result = os.system(command)
if result==0:
	print "Slicing: 100%" # better to have one more confirmation, a part from the one provided by CuraEngine
	print "GCode file saved : %s" % options.output
else:
	print "%s error" % executable_path_n_name # output also the path: more feedback is better.
