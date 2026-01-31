scriptloc=$(dirname $0)
cp -r /usr/share/archiso/configs/releng/ $scriptloc
cp $scriptloc/ais.sh $scriptloc/releng/airootfs/install
sed -i '$ d' $scriptloc/releng/profiledef.sh
echo '["/install"]="0:0:777"' >> $scriptloc/releng/profiledef.sh
echo ')' >> $scriptloc/releng/profiledef.sh
mkarchiso -v -r -w /tmp/archiso-tmp -o $scriptloc/../ $scriptloc/releng && rm -rf $scriptloc