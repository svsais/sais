scriptloc=$(dirname $0)
cp -r /usr/share/archiso/configs/releng/ $scriptloc
cp $scriptloc/ais.sh $scriptloc/releng/airootfs/install
mkarchiso -v -r -w /tmp/archiso-tmp -o $scriptloc/../ $scriptloc/releng && rm -rf $scriptloc