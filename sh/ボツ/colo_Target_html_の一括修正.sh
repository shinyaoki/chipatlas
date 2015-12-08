# tgToHtml, coloToHtml を変更し、tsv から html を再修正する時に実行。

##################################################################################################################
# Target Genes の場合、以下をコピペ
##################################################################################################################
projectDir=chipatlas
for Genome in `ls chipatlas/results/`; do
  for tsv in `ls $projectDir/results/$Genome/targetGenes/*tsv`; do            # tsv の種類: 抗原.tsv,  SRX.tsv,  STRING_抗原.tsv
    outfn=`echo "$tsv"| sed 's/\.tsv$/.html/'`  #html の種類: 抗原.html, SRX.html, STRING_抗原.html
    echo sh $projectDir/sh/tgToHtml.sh \""$tsv"\" $Genome '>' \""$outfn"\"
  done
done > tg_sh



rm -rf tg_shDir
mkdir tg_shDir
cd tg_shDir
split -l 100 ~/tg_sh
cd

for fn in `ls tg_shDir/*`; do
  cat $fn| qsub -o /dev/null -e /dev/null
done

# 全部終わったら
rm -rf tg_shDir
rm tg_sh







##################################################################################################################
# Colo の場合、以下をコピペ
##################################################################################################################

ls chipatlas/results/*/colo/*tsv| awk -F '\t' '
BEGIN {
  while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
    x[$1] = $5
    gsub(" ", "_", x[$1])
  }
} {
  split($1, arr, "/")
  genome = arr[3]
  tsv = $1
  sub(".tsv", ".html", $1)
  html = $1
  N = split(arr[5], b, ".")
  ctL = (N > 2) ? b[N-1] : x[b[1]]
  print "sh chipatlas/sh/coloToHtml.sh \"" tsv "\" \"3 2 1\" \"" ctL "\" " genome " > \"" html "\""
}' > colo_sh

rm -rf colo_shDir
mkdir colo_shDir
cd colo_shDir
split -l 100 ~/colo_sh
cd

for fn in `ls colo_shDir/*`; do
  cat $fn| qsub -o /dev/null -e /dev/null
done


# 全部終わったら
rm -rf colo_shDir
rm colo_sh



# 上記全部終わったら転送
sh chipatlas/sh/transferDDBJtoNBDC.sh "analysed"  # <<=== コマンド (DDBJ)  colo, target, 全対応表を NBDC に転送
