#!/bin/bash

usage() { echo "Usage: slicer.sh -c <ini filepath> -i <input stl filepath> -o <output gcode filepath>" 1>&2; exit 1; }

while getopts ":c:i:o:" p; do
    case "${p}" in
        c)
            iniPath=${OPTARG}
            ;;
        i)
            inputPath=${OPTARG}
            ;;
	o)
	    outputPath=${OPTARG}
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${iniPath}" ] || [ -z "${inputPath}" ] || [ -z "${outputPath}" ]; then
    usage
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PIDS1=`ps auxwww | grep $DIR/Cura/cura.py | grep -v "grep" | awk '{print $2}'`
PIDS2=`ps auxwww | grep $DIR/CuraEngine/CuraEngine | grep -v "grep" | awk '{print $2}'`

if [ -z "$PIDS1" ]; then
	echo "Starting slicing..."
	python2 $DIR/Cura/cura.py -s -i "$iniPath" -o "$outputPath" "$inputPath" 1>&2

else
	echo "Slicer busy"

fi

exit 0
