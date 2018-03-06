#!/usr/bin/python
"""
This page is in the table of contents.
==Overview==
===Introduction===
Cura is a AGPL tool chain to generate a GCode path for 3D printing. Older versions of Cura where based on Skeinforge.
Versions up from 13.05 are based on a C++ engine called CuraEngine.
"""
from __future__ import absolute_import
__copyright__ = "Copyright (C) 2013 David Braam - Released under terms of the AGPLv3 License"

from optparse import OptionParser

from util import profile
from util import mesh
import sys
import numpy
from util import mesh

def main():
	parser = OptionParser(usage="usage: %prog [options] <filename>.stl")
	parser.add_option("-i", "--ini", action="store", type="string", dest="profileini",
		help="Load settings from a profile ini file")
	parser.add_option("-r", "--print", action="store", type="string", dest="printfile",
		help="Open the printing interface, instead of the normal cura interface.")
	parser.add_option("-p", "--profile", action="store", type="string", dest="profile",
		help="Internal option, do not use!")
	parser.add_option("-x", "--scale", action="store", type="string", dest="scale",
                help="scale the stl object")
	parser.add_option("-s", "--slice", action="store_true", dest="slice",
		help="Slice the given files instead of opening them in Cura")
	parser.add_option("-o", "--output", action="store", type="string", dest="output",
		help="path to write sliced file to")
        parser.add_option("-t", "--transform", action="store", type="string", dest="transform",
		help="rotate and transform the object")

	(options, args) = parser.parse_args()

	#print "load preferences from " + profile.getPreferencePath()
	profile.loadPreferences(profile.getPreferencePath())

	#default_profile_string = profile.getProfileString()
	#print("default_profile_string = %s" % (default_profile_string))

	#profile.setProfileFromString(default_profile_string)

	if options.profile is not None:
		profile.loadProfile(r"/home/buccaneer/bin/buccaneer-slicer/current/slicer.ini")
		#profile.setProfileFromString(options.profile)
		#print("options.profile Input\n\n")
		#print(options.profile)
		custom_params = []
		for param in options.profile.split(','):
			param = param.replace("++"," ")
			custom_params.append(param)
		#print(custom_params)
		profile.setProfileFromString(custom_params)
	elif options.profileini is not None:
		profile.loadProfile(options.profileini)
	else:
		#print("Default Path: %s" % (profile.getDefaultProfilePath()))
		profile.loadProfile(r"/home/buccaneer/bin/buccaneer-slicer/current/slicer.ini")

	if options.printfile is not None:
		from Cura.gui import printWindow
		printWindow.startPrintInterface(options.printfile)
	
	elif options.slice is not None:
		from util import sliceEngine
		from util import objectScene
		from util import meshLoader
		from util import mesh
		import shutil
		import numpy as np

		def commandlineProgessCallback(progress, ready,loading):
                        if progress >= 0 and not ready and not loading:
                                sys.stdout.write("Slicing: %d%%\n" % (progress * 100,))
                                sys.stdout.flush()
                        elif progress >= 0 and not ready and loading:
                                sys.stdout.write("Loading: %d%%" % (progress * 100,))
                                sys.stdout.flush()

		profile.putMachineSetting('machine_name', 'Buccaneer')
                profile.putMachineSetting('machine_width', '138')
                profile.putMachineSetting('machine_depth', '112')
                profile.putMachineSetting('machine_height', '149.5')
                profile.putProfileSetting('nozzle_size', '0.4')
                profile.putProfileSetting('wall_thickness', float(profile.getProfileSettingFloat('nozzle_size')) * 2)
                profile.putMachineSetting('has_heated_bed', str(False))
                profile.putMachineSetting('machine_center_is_zero', str(False))
                profile.putMachineSetting('extruder_head_size_min_x', '0')
                profile.putMachineSetting('extruder_head_size_min_y', '0')
                profile.putMachineSetting('extruder_head_size_max_x', '0')
                profile.putMachineSetting('extruder_head_size_max_y', '0')
                profile.putMachineSetting('extruder_head_size_height', '0')
                profile.checkAndUpdateMachineName()

		scene = objectScene.Scene()
		scene.updateMachineDimensions()
		slicer = sliceEngine.Slicer(commandlineProgessCallback)
		matrix = []
		if options.transform is not None:
			transform_params = []
			for param in options.transform.split(','):
				param = param.replace("["," ")
				param = param.replace("]"," ")
				transform_params.append(param)
				data = np.array(transform_params)
				print data
			matrix = [[transform_params[0],transform_params[1],transform_params[2]], [transform_params[3], transform_params[4], transform_params[5]], [transform_params[6], transform_params[7], transform_params[8]]]

		if options.scale is not None:
			if (int(options.scale) >= 1):
				obj = meshLoader.loadMeshes(args[0], int(options.scale))
			else:
				obj=meshLoader.loadMeshes(args[0])
		
		else:
			obj=meshLoader.loadMeshes(args[0])

		for m in obj:
			scene.addNewMatrix(m,matrix)
		
		sys.stdout.write("Slicing: %d%%\n" % (0 * 100,))
                sys.stdout.flush()
		slicer.runSlicer(scene)
		slicer.wait()
		profile.replaceGCodeTagsFromSlicer(slicer.getGCodeFilename(), slicer)

		if options.output:
			shutil.copyfile(slicer.getGCodeFilename(), options.output)
			print 'GCode file saved : %s' % options.output
		else:
			shutil.copyfile(slicer.getGCodeFilename(), args[0] + '.gcode')
			print 'GCode file saved as: %s' % (args[0] + '.gcode')

		slicer.cleanup()
	else:
		from Cura.gui import app
		app.CuraApp(args).MainLoop()

if __name__ == '__main__':
	main()
