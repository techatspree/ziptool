#!/bin/bash

shopt -s nullglob

if [ ]
CONFIG_DIR="/tmp/extractzip"
PATTERN_FILE="$CONFIG_DIR/patterns.txt"
INPUT_DIR="$CONFIG_DIR/input"
WORK_DIR="$CONFIG_DIR/work"
TMP_DIR="$CONFIG_DIR/tmp"
SCRIPT_DIR="$CONFIG_DIR/scripts"
OUTPUT_DIR="$CONFIG_DIR/output"

mkdir -p $INPUT_DIR
mkdir -p $WORK_DIR
mkdir -p $TMP_DIR
mkdir -p $SCRIPT_DIR
mkdir -p $OUTPUT_DIR

function getFindPattern() {
  local patterns
  local i=0

  if [[ -f "$PATTERN_FILE" ]] ; then
    patterns=$(cat $PATTERN_FILE)
  else
    patterns=$(cat << __EOF__
\*.zip
\*.ear
\*.sar
\*.war
\*.jar
\*.ejb
__EOF__
)
  fi

  echo "Looking for ZIP files matching ${patterns//$'\n'/ } in $INPUT_DIR"

  for arg in $patterns; do
    findArgs[$i]="-o -name $arg"
    ((++i))
  done

  findArgs[0]=$(echo "${findArgs[0]}" | cut -c3-100)
}

function extract() {
	if [[ -f "$1" ]] ; then
		echo "Unzipping $1..."

		mv "$1" jens
		mkdir -p "$1"
		mv jens "$1/"

		(cd "$1" || exit ; unzip jens ; rm jens)
	fi
}

function list() {
    local currentDir=$PWD

    echo "Searching for matching files in $currentDir"

    # Workaround: Create temporary script
    echo find . "${findArgs[@]}" -type f > $TMP_DIR/script.sh

    for file in $(sh $TMP_DIR/script.sh) ; do
      	echo "Extracting $file in $currentDir..."
      	extract "${file}"
      	echo "Extracting $file in $currentDir DONE"

      	cd "${file}" || exit
      	list
      	cd "$currentDir" || exit
    done

    rm -f $TMP_DIR/script.sh
}

# shellcheck disable=SC2164
(cd $INPUT_DIR ; tar cf - .) | (cd $WORK_DIR ; tar xf -)

getFindPattern

# shellcheck disable=SC2164
cd $WORK_DIR
list