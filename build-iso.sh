scriptloc=$(dirname $0)
cp $scriptloc/ais.sh $scriptloc/arch-iso/releng/airootfs/install
mkarchiso -v -r -w /tmp/archiso-tmp -o $scriptloc/ $scriptloc/arch-iso/releng