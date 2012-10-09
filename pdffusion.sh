#!/usr/bin/env sh
#
# pdffusion
#
# Dependencies: pdfjam
#
# Takes two PDF files as input and fuses their pages side-by-side. So
# if you have a file A with paged A1-A2-A3 and a file B with pages
# B1-B2-B3 it will produce a file with pages A1B1-A2B2-A3B3. At the end
# the corresponding pages of the original file will be on one page, right
# next to each other.
#
# The script first splits the files in individual pages, fuses them
# page by page and then recombines them for the final output.
#
# Usage: pdffuse <file1> <file2> <outfile> <papersize>
#
# The parameter <papersize> is a size definition of the output file
# as used in LaTeX. Therefore, it is written as '{height,width}'.
#
# Example: pdffusion slides.pdf notes.pdf slides-and-notes.pdf '{96mm,256mm}'
#
# This creates an output file with a height of 9.6cm and a width of 25.9cm.

FILE1=$1
FILE2=$2
OUTFILE=$3
PAPERSIZE=$4

# Correct number of arguments?
if [ $# -ne 4 ]
then
	echo "Usage: `basename $0` <file1> <file2> <outfile> <papersize>"
	echo "With: <papersize> as LaTeX paper size, i.e. '{height,width}' as in"
	echo "     '{96mm,256mm}' for double LaTeX beamer slides"
	E_BADARGS=65
	exit $E_BADARGS
fi

# Make sure both files have the same number of pages
NPAGES1=`pdfinfo $1 | grep '^Pages:' | sed -e 's/.*[^0-9]//'`
NPAGES2=`pdfinfo $2 | grep '^Pages:' | sed -e 's/.*[^0-9]//'`
if [ $NPAGES1 -ne $NPAGES2 ]; then
	echo "The specified files have different number of pages, aborting."
	echo "$FILE1: $NPAGES1"
	echo "$FILE2: $NPAGES2"
	exit 1
fi 

NPAGES=$NPAGES1
echo "Both files have $NPAGES pages"

# Create a temporary directory
TMPDIR=`mktemp -d`

# Separate all pages
pdfseparate $1 $TMPDIR/1-$1-%d.pdf
pdfseparate $2 $TMPDIR/2-$2-%d.pdf

# Create a fused pages for all pages and prepare the
# joining command.
p=1;
JOINCMD="pdfjoin --quiet -o $OUTFILE "
while [ $p -le $NPAGES ]; do
	echo "Fusing page $p"
	FUSEDFILE="fused-$p.pdf"
	CMD="pdfnup --quiet --nup 2x1 --keepinfo --papersize '$PAPERSIZE' $TMPDIR/1-$1-$p.pdf $TMPDIR/2-$2-$p.pdf -o $TMPDIR/$FUSEDFILE"
	eval $CMD
	# Add fused file to joining command
	JOINCMD="$JOINCMD $TMPDIR/$FUSEDFILE"
	# increment page number
	p=$((p + 1))
done

# Combine all fused pages to one output PDF
echo "Joining all $NPAGES pages into $OUTFILE"
eval $JOINCMD

# Remove temporary directory
echo "Cleaning up"
rm -rf $TMPDIR

# Everything went well
echo "Done"
exit 0
