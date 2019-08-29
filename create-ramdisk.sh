cd $OUT/root
find ./ | cpio -H newc -o > ../ramdisk.cpio
cd ..
gzip ramdisk.cpio
mv ramdisk.cpio.gz  ramdisk.img
cp ramdisk.img $OUT/aem
cp ramdisk.img $OUT/aem-mod
