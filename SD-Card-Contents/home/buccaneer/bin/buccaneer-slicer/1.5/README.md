Usage: slicer.sh -c "ini filepath" -i "input stl filepath" -o "output gcode filepath"


Run directly from command line (without using script):

With .ini file

python2 Cura/cura.py -s -i "ini filepath" -o "gcode filepath" "stl filepath"



With parameters, without .ini file

python2 Cura/cura.py -s -t [1,0,0,0,1,0,0,0,1] -p "param1=value1,param2=value2...paramN=valueN" -o "gcode filepath" "stl filepath"



