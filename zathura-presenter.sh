#!/bin/bash
#
# This tool can be used to control two zathura instances at the same time. If
# you have, for instance, two PDF files and display them in zathura, you can use
# this tool to change pages in both at the same time. This is useful for
# presentations where one PDF file contains the actual slides, while the other
# one contains the presentation notes.
#
# Usage:
#
# zathura-presenter.sh <pattern1> <pattern2>
#
# Both patterns are a text string that are part of the process name. The
# following, for instance, would let the tool refer to two zathura instances
# with one having the file slides.pdf loaded and the other one notes.pdf:
#
# zathura-presenter.sh "zathura slides.pdf" "zathura notes.pdf"
#
# Tom Kazimiers <tom@voodoo-arts.net> / 2015 /Beer-ware

EXPECTED_ARGS=2

# Test arguments
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` {pattern1} {pattern2}"
  exit 1
fi

PAGE=0
PID1=`ps aux | grep $1 | grep -v grep | head -n 1 | tr -s ' ' | cut -d ' ' -f 2`
PID2=`ps aux | grep $2 | grep -v grep | head -n 1 | tr -s ' ' | cut -d ' ' -f 2`

echo "Slides PID: $PID1"
echo "Notes PID: $PID2"

while [ 1 ]; do
    read -sn 1 key
    echo "Key: $key"
    case "$key" in
        ''|'f'|'2')
            PAGE=$((PAGE + 1))
            ;;
        'h'|'v'|'0')  # home: first item
            PAGE=0
            ;;
        'b'|'1'|'z')  # home: first item
            PAGE=$((PAGE - 1))
            ;;
    esac

    echo $PAGE

    dbus-send --type=method_call --dest=org.pwmt.zathura.PID-$PID1 /org/pwmt/zathura org.pwmt.zathura.GotoPage uint32:$PAGE
    dbus-send --type=method_call --dest=org.pwmt.zathura.PID-$PID2 /org/pwmt/zathura org.pwmt.zathura.GotoPage uint32:$PAGE
done
