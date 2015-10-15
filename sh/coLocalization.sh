#!/bin/sh
#$ -S /bin/sh

# 初期モード
# sh chipatlas/sh/coLocalization.sh INITIAL chipatlas

if [ $1 = "INITIAL" ]; then
  projectDir=$2
  for Genome in `ls $projectDir/results`; do
    rm -rf $projectDir/results/$Genome/colo tmpDirForColo
    mkdir $projectDir/results/$Genome/colo tmpDirForColo
  done
  qVal=`cat $projectDir/sh/preferences.txt| awk '$1 == "qVal" {printf "%s", $2}'`
  IFS_BACKUP=$IFS
  IFS=$'\n'
  
  # すべての細胞大分類で Colo を投入
  for Param in `cat $projectDir/lib/assembled_list/fileList.tab| awk -F '\t' -v qVal="$qVal" '{
    #   抗原大                     抗原小        細胞小        qVal          細胞大 (Others は含む)
    if ($3 == "TFs and others" && $4 == "-" && $6 == "-" && $7 == qVal && $5 != "All cell types" && $5 != "No description" && $5 != "Unclassified") {
      gsub(" ", "_", $5)
      print $2 " " $5 " " $8  # Genome 細胞大 SRX   <- 細胞大はスペースをアンダーバーに置換
    }
  }'`; do
    IFS=$IFS_BACKUP
    nMem=`echo "$Param"| awk '{
      N = int(gsub("," "", $0) / 100) + 4
      if (N >= 4) N = 4
      printf "%dG", N*4
    }'`
    nSRX=`echo "$Param"| awk '{printf "%d", gsub("," "", $0)}'`
    if [ "$nSRX" -lt 500 ]; then
      short=`sh $projectDir/sh/QSUB.sh shortOrweek`
    else
      short=" "
    fi
    qsub -l s_vmem=$nMem -l mem_req=$nMem $short $projectDir/sh/coLocalization.sh $projectDir "$Param"
    IFS=$'\n'
  done
  IFS=$IFS_BACKUP
  exit
fi

####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################
projectDir=$1
Genome=`echo $2| cut -d ' ' -f1`
ctL=`echo $2| cut -d ' ' -f2`   # 細胞大はスペースをアンダーバーに置換
SRX=`echo $2| cut -d ' ' -f3| tr ',' '\n'| awk -F '\t' -v projectDir=$projectDir -v Genome=$Genome '
BEGIN {
  geneList = projectDir "/lib/geneList/" Genome ".txt"
  expList =  projectDir "/lib/assembled_list/experimentList.tab"
  while ((getline < geneList) > 0) g[$1] = 1  # g[NRF1] = 1
  while ((getline < expList) > 0)  s[$1] = $4  # s[SRX150388] = NRF1
} {
  if (g[s[$1]] == 1) SRX = SRX " " $1
} END {
  sub(" ", "", SRX)
  printf "%s", SRX
}'`  # SRX リスト (geneList にないものは削除。スペース区切り)

HLM="3 2 1" # High, Middle, Low の値
qVal=`cat $projectDir/sh/preferences.txt| awk '$1 == "qVal" {printf "%s", $2}'` # 最大の qVal (= 05)
jobDir="tmpDirForColo/$JOB_ID"
mkdir -p $jobDir/inBed


# 対象となる Bed ファイルをコピー
for srx in `echo "$SRX"`; do
  cut -f 1-3,5 $projectDir/results/$Genome/Bed$qVal/Bed/$srx.$qVal.bed > "$jobDir/inBed/$JOB_ID@$srx.bed"
done

# CoLo 用のファイルリストを作成
echo "$SRX"| tr ' ' '\t'| awk -F '\t' -v projectDir=$projectDir -v tmpDir="$jobDir/inBed/" -v JI="$JOB_ID" '
BEGIN {
  experimentList = projectDir "/lib/assembled_list/experimentList.tab"
  while ((getline < experimentList) > 0) {
    gsub(" ", "_", $0)
    SRX[$1]    = $1
    Genome[$1] = $2
    ag[$1]     = $4
    cell[$1]   = $6
  }
} {
  for (i=1; i<=NF; i++) {
    print tmpDir JI "@" SRX[$i] ".bed\t" cell[$i] "\tNA\t" ag[$i] "\t" JI "@" SRX[$i] "\t" ag[$i] "_" Genome[$i]
  }
}'| sort -k4 > $jobDir/list.tab
# tmpDirForColo/123456/inBed/SRX100441.bed	hESC_H1	NA	BCL11A	SRX100441	BCL11A_hg19

# CoLo の実行
mem=`echo $SGE_HGR_mem_req| tr -d 'G'| awk '{printf "-Xmx%dm", 1000*$1*0.8}'`
echo "AAAAA" $mem $SGE_HGR_mem_req $NSLOTS `cat $jobDir/list.tab| wc -l ` $ctL $Genome

java $mem -jar $projectDir/bin/coloCA.jar $jobDir/list.tab $jobDir/colo.txt $jobDir/colo.gml

# CoLo が作った gml ファイルを整形
outGml=`echo $projectDir/results/$Genome/colo/$ctL.gml| tr ' ' '_'`
cat $jobDir/colo.gml| awk -v JI="$JOB_ID" '{
  if ($1 == "label" && NR != 3) {
    ag = $5
    st = $6
    no = $2
    sub("\"", "", st)
    sub("\"No.", "_", no)
    print "label \"" ag no "\""
  } else if ($1 == "path"){
    regExp = JI "@"
    sub(regExp, "", $0)
    N = split($3, a, "/")
    split(a[N], b, "_")
    print "srx \"" b[1] "\""
  } else {
    print
  }
  if ($1 == "cellType") {
    print "antigen \"" ag "\""
    print "strength \"" st "\""
  }
}' > $outGml


# 整形した gml ファイルをもとに web 用にランキングを作成
for outTSV in $(cat $outGml| awk -v outGml=$outGml -v valHLM="$HLM" -v Genome=$Genome -v projectDir=$projectDir -v jobDir=$jobDir -v ctL=$ctL '
BEGIN {
  # gml ファイル前半部の読み込み
  while ((getline < outGml) > 0) {
    gsub("\"", "", $0)
    if ($1 == "id") id = $2
    if ($1 == "srx") SRX[id] = $2   # SRX[254] = SRX56789
    if ($1 == "cellType") cell[SRX[id]] = $2  # cell[SRX56789] = hESC_H1
    if ($1 == "antigen") {
      Atg[SRX[id]] = $2  # Atg[SRX56789] = SIX5
      if (!srxList[SRX[id]]++) atgSrx[$2] = atgSrx[$2] "," SRX[id]  # atgSrx[SIX5] = ,SRX12345,SRX56456,SRX96852
    }
    split(valHLM, valhlm, " ")
    if ($1 == "strength") {
      if ($2 == "High")   hlm[id] = valhlm[1]
      if ($2 == "Middle") hlm[id] = valhlm[2]
      if ($2 == "Low")    hlm[id] = valhlm[3]
    }
  }
  
  # STRING データの読み込み
  stringList = projectDir "/lib/string/protein.actions.v10." Genome ".txt"
  FS = "\t"
  while ((getline < stringList) > 0) {      # stringList の内容: POU5F1    NANOG   binding    inhibition    0/1   360
    if (atgSrx[$1] && atgSrx[$2] && $3 == "binding") {  # 注1
      if (String[$1,$2] < $6) String[$1,$2] = $6    # 同じ抗原の組み合わせの binding が複数あるときは最大値を採用
    }                                               # String["POU5F1","NANOG"] = 360
  }
} {
  FS = " "
  if ($1 == "source") s = $2
  if ($1 == "target") {
    t = $2
    if (Val[SRX[s],SRX[t]] < hlm[s] * hlm[t]) Val[SRX[s],SRX[t]] = hlm[s] * hlm[t]  # H > M > L の優先順位
    if (Val[SRX[t],SRX[s]] < hlm[s] * hlm[t]) Val[SRX[t],SRX[s]] = hlm[s] * hlm[t]  # H > M > L の優先順位
  }
} END {
  FS = "\t"
  cmd1 = "sort -f"
  for (TF in atgSrx) {
    if (!atgSrx[TF]) continue  # 注1 のところで、空の atgSrx[TF] がたくさん作られている
    # 出力 tsv ファイル名の決定  例: tmpDirForColo/$JOB_ID/CTCF.Pluripotent_stem_cell.tsv
    outTSV = jobDir "/" TF "." ctL ".tsv"
    
    # ヘッダの作成
    printf "Experiment\tCell_subclass\tProtein\t%s|Average", TF > outTSV
    sub(",", "", atgSrx[TF]) # 頭のコンマを除去
    N = split(atgSrx[TF], x, ",") # x[1] = SRX12345, x[2] = SRX56456, ....
    for (i=1; i<=N; i++) print cell[x[i]] "\t" x[i] |& cmd1  # 細胞クラスでソート
    close(cmd1, "to")
    j = 0
    while ((cmd1 |& getline) > 0) {
      j++ # j = 列の数
      srtSrx[j] = $2  # srtSrx[1] = SRX5678, srtSrx[2] = SRX1234, ...
      printf "\t%s|%s", $2, $1 >> outTSV  # SRX56789|hESC_H1 (細胞名でソート)
    }
    close(cmd1)
    printf "\tSTRING\n" >> outTSV
    
    # 表部の作成
    cmd2 = "sort -nr -k" N+4 " -k" N+5
    for (srx in srxList) {
      Sum = 0
      Num = N
      printf "%s\t%s\t%s", srx, cell[srx], Atg[srx] |& cmd2  # $1 = SRX, $2 = 細胞小, $3 = 抗原名
      for (k=1; k<=N; k++) {
        if (srtSrx[k] == srx) {     # 行と列が同じ SRX の場合は、Val = 10, 平均の算出には加えない
          Val[srtSrx[k],srx] = 10
          Num--
        } else if (!Val[srtSrx[k],srx]) {
          Val[srtSrx[k],srx] = 0
        } else {
          Sum = Sum + Val[srtSrx[k],srx]
        }
        printf "\t%s", Val[srtSrx[k],srx] |& cmd2
      }
      if (Num == 0) Avr = 0   # 一列しかなく、行と列が同じ SRX の場合
      else          Avr = Sum / Num
      printf "\t%f", Avr |& cmd2
      
      # STRING データ の出力
      printf "\t%d\n", String[TF,Atg[srx]] |& cmd2
    }
    close(cmd2, "to")
    while ((cmd2 |& getline) > 0) {
      printf "%s\t%s\t%s\t%s", $1, $2, $3, $(N+4) >> outTSV  # 細胞  SRX  TF  平均
      for (i=1; i<=N; i++) printf "\t%s", $(i+3) >> outTSV   # Colo 値
      printf "\t%s\n", $(N+5) >> outTSV                      # STRING 値
    }
    close(cmd2)
    print outTSV # outTSV のファイル名：tmpDirForColo/$JOB_ID/CTCF.Pluripotent_stem_cell.tsv
  }              # Experiment  Cell_class  Protein  CTCF|Average  SRX017278|hESC_H1  SRX031244|hESC_H1  SRX038524|hESC_H1...  STRING
}'); do
  # outTSV を各 SRX 列でソートする
  i=4
  TF=`basename "$outTSV"| cut -d '.' -f1`
  Header=`head -n1 "$outTSV"`
  NF=`echo "$Header"| awk '{printf "%d", NF}'`
  for srxCell in `echo "$Header"| cut -f5-`; do
    let i=$i+1
    SRX=`echo "$srxCell"| cut -d '|' -f1`
    echo "$Header" > "$jobDir/$SRX.tsv"
    tail -n+2 "$outTSV"| sort -nr -k"$i" -k4 -k"$NF" >> "$jobDir/$SRX.tsv"
  done
  mv "$jobDir/$SRX.tsv" "$jobDir/STRING_$TF.$ctL.tsv" # 一番最後は STRING でソートしたものなので、ファイル名を STRING_TF.ctL.tsv に変更
done

# html 形式に変換
for tsv in `ls "$jobDir/"*tsv`; do            # tsv の種類: 抗原.細胞大.tsv,  SRX.tsv,  STRING_抗原.細胞大.tsv
  SRX=`basename "$tsv"| cut -d '.' -f1`       # SRX の種類: 抗原,            SRX,      STRING_抗原
  outfn=`echo "$tsv"| sed 's/\.tsv$/.html/'`  #html の種類: 抗原.細胞大.html, SRX.html, STRING_抗原.細胞大.html
  sh $projectDir/sh/coloToHtml.sh "$tsv" "$HLM" "$ctL" $Genome > "$outfn"
  mv "$tsv" $projectDir/results/$Genome/colo/
  mv "$outfn" $projectDir/results/$Genome/colo/
done

cat coLocalization.sh.o$JOB_ID coLocalization.sh.e$JOB_ID > $jobDir/log.txt
rm coLocalization*$JOB_ID




