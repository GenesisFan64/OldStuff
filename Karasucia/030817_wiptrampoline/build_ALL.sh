clear
echo "****** Building resources ******"
./build_res.sh
echo " "

#echo "* Compiling Z80 *"
#./build_z80.sh

echo "****** Compiling MD ******"
./build_md.sh
echo " "

echo "****** Compiling MCD ******"
./build_cd.sh
echo " "

echo "****** Compiling MARS ******"
./build_mars.sh
echo " "
