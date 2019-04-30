cd ~/downloads/day2;

for file in */results/tile*all*/bfast*.tif;
  do tile=`echo $file | cut -d'/' -f1`;
  cp -v $file $tile\_${file##*/};
done
