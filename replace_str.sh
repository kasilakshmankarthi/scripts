#!/bin/bash
#OLD=".\/fakebrowser_3.28"
#NEW=".\/fakebrowser_3.28 --fast-context-switch=1"

#OLD="\${NEW_LINE}"
#OLD="MYPATH=\/prj\/qct\/qctps\/modeling\/ral_modeling\/benchmarks\/octane\/octane2\/64bit\/android\/webtech\/1.0"
#NEW="MYPATH=\/prj\/qct\/qctps\/modeling\/ral_workloads\/linux\/ModelWorkloads\/64bit\/Octane\/W4_I.2.4_Android_L\/unverified"
OLD="\/prj\/qct\/qctps\/modeling\/ral_armv8\/usr\/kasilka\/www\/html"
NEW="http:\/\/localhost"

DPATH="/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/www/html/*"
for f in $DPATH
do
  if [ -f $f ]; then
     #Line substitution
     sed -i "s/${OLD}/${NEW}/g" ${f}
     
     #Line insertion in the beginning of all files
     #sed -i -e '1iMYPATH=\/prj\/qct\/qctps\/modeling\/ral_modeling\/benchmarks\/antutu\/64bit\/android\/1.0\' ${f}
   else
     echo "Error: Cannot read ${f}"
   fi
done

DPATH="/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/www/html/script/*"
for f in $DPATH
do
  if [ -f $f ]; then
     #Line substitution
     sed -i "s/${OLD}/${NEW}/g" ${f}
     
     #Line insertion in the beginning of all files
     #sed -i -e '1iMYPATH=\/prj\/qct\/qctps\/modeling\/ral_modeling\/benchmarks\/antutu\/64bit\/android\/1.0\' ${f}
   else
     echo "Error: Cannot read ${f}"
   fi
done

DPATH="/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/www/html/cgi-bin/*"
for f in $DPATH
do
  if [ -f $f ]; then
     #Line substitution
     sed -i "s/${OLD}/${NEW}/g" ${f}
     
     #Line insertion in the beginning of all files
     #sed -i -e '1iMYPATH=\/prj\/qct\/qctps\/modeling\/ral_modeling\/benchmarks\/antutu\/64bit\/android\/1.0\' ${f}
   else
     echo "Error: Cannot read ${f}"
   fi
done
