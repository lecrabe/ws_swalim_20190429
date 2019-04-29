cd ~/downloads/swalim_savi_NNJ_2013_2019;

for file in */results/tile*0000000-000*/bfast*.tif;
  do tile=`echo $file | cut -d'/' -f1`;
  cp -v $file $tile\_${file##*/};
done
