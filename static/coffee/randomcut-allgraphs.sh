#!/bin/bash

find ../../graphdata -iname \*.dimacs |
while read fname; do
  fname=$(echo $fname | sed s@^../../@@)
  # TODO: what about multiple
  outfname="out/"$fname".result"
  matfname="out/"$fname".cut"
  #graphdata/graphLib_ours/hsugrid/hsu-4x4.dimacs
  mkdir -p $(dirname $outfname)
  echo "Processing $fname"
  phantomjs randomcut-phantomjs.js $fname > $outfname
  python randomcut-reformat.py $outfname > $matfname
done
