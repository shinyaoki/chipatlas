#!/bin/sh
#$ -S /bin/sh

# sh $projectDir/sh/tgToHtml.sh "$tsv" $Genome

Size=25
SIZE=100
inFn="$1"   # inFn の種類: 抗原.tsv,  SRX.tsv,  STRING_抗原.tsv
Genome="$2"


qProt=`head -n1 "$inFn"| cut -f2| cut -d '|' -f1`         # POU5F1
fnHead=`basename "$inFn"| cut -d '.' -f1| cut -d '_' -f1` # 抗原 or SRX or STRING
Wkb=`basename "$inFn"| cut -d '.' -f2`                    # 1 5 10 (+- TSS kb)

url1="http://dbarchive.biosciencedbc.jp/kyushu-u/$Genome/target/"    # html へのリンク
url2="http://chip-atlas.org/view?id="                                  # 個別 SRX へのリンク
urlDoc="https://github.com/inutano/chip-atlas/wiki#5-target-genes"   # Document へのリンク
urlTSV="$url1$qProt.$Wkb.tsv"                                        # TSV へのリンク
urlYuT="https://youtu.be/UBOyoTlDAH4"                                # YouTube へのリンク
urlCA="http://chip-atlas.org"                                        # ChIP-Atlas へのリンク
urlTG="http://chip-atlas.org/target_genes"                           # Target Genes へのリンク

sortKey=`head -n1 "$inFn"| tr '\t' '\n'| awk -F '\t' -v fnHead=$fnHead -v qProt=$qProt '{
  if (fnHead ~ /^[SED]RX[0-9][0-9][0-9][0-9]/ && $1 ~ fnHead) printf "%s", $1
  else if (fnHead ~ "STRING" && $1 == "STRING") printf "%s|%s", qProt, $1
  else i++
} END {
  if (i == NR) printf "%s|Average", qProt
}'| sed 's/|/ | /'| tr '_' ' '`

Vspace=`head -n1 "$inFn"| tr '\t' '\n'| awk '{
  if (V < 5.2 * length($0) + 20) V = 5.2 * length($0) + 20
} END {
  printf "%d", V
}'`px

projectDir=`echo $0| sed 's[/sh/tgToHtml.sh[['`

wid=`head -n1 "$inFn"| awk -v Size=$Size -v SIZE=$SIZE '{printf "%d", SIZE*1 + (NF-1)*Size}'` # テーブル全体のサイズ

case $Wkb in
  1)  strKb='&#177; <b>1 kb</b>&nbsp;&nbsp;<a class=dist href="'"$url1$qProt.5.html"'">&#177; 5 kb</a>&nbsp;&nbsp;<a class=dist href="'"$url1$qProt.10.html"'">&#177; 10 kb</a>';;
  5)  strKb='<a class=dist href="'"$url1$qProt.1.html"'">&#177; 1 kb</a>&nbsp;&nbsp;&#177; <b>5 kb&nbsp;&nbsp;</b><a class=dist href="'"$url1$qProt.10.html"'">&#177; 10 kb</a>';;
  10) strKb='<a class=dist href="'"$url1$qProt.1.html"'">&#177; 1 kb</a>&nbsp;&nbsp;<a class=dist href="'"$url1$qProt.5.html"'">&#177; 5 kb</a>&nbsp;&nbsp;&#177; <b>10 kb</b>';;
esac

# html のヘッダ情報
# margin = 上 右 下 左 を指定
cat << DDD
<!DOCTYPE html>
<head>
<title>ChIP-Atlas | Target genes</title>

<FONT face="Helvetica Neue" color="333333">
  <style type="text/css">

  #rotate {
    -moz-transform:    rotate(-45deg);
    -webkit-transform: rotate(-45deg);
    -ms-transform:     rotate(-45deg);
    transform:         rotate(-45deg);
    -moz-transform-origin:    right;
    -webkit-transform-origin: right;
    -ms-transform-origin:     right;
    transform-origin:         right;
  }
  
  .nowrap{  
    white-space:nowrap;  
    overflow:hidden;  
  }
  
  .lineWidth {line-height: 180%;}
  .tableMargin {margin: $Vspace 0px 0px 0px ;}
  .bodyMargin {margin: 30px 0px 30px 30px ;}
  a.dist { color: rgb(70%,70%,70%); }

  </style>
</head>

<body class="bodyMargin">
<h1>ChIP-Atlas: Target genes</h1>
<h2>Potential target genes for $qProt</h2>

<div class="lineWidth"><b>Query protein: </b>$qProt</div>
<div class="lineWidth"><b>Distance from TSS: </b>$strKb</div>
<div class="lineWidth"><b>Sort key: </b>$sortKey</div>
<div class="lineWidth">&nbsp;</div>

<div class="lineWidth"><b>Color legends</b></div>
<table border=0 height="25" style="table-layout: fixed;"><tr>
<td align="right" valign="middle"  width="25" >&nbsp;</td>
<td align="center" valign="middle" width="50" bgcolor="ff0000">1000</td>
<td align="center" valign="middle" width="50" bgcolor="ffff00">750</td>
<td align="center" valign="middle" width="50" bgcolor="00ff00">500</td>
<td align="center" valign="middle" width="50" bgcolor="00ffff">250</td>
<td align="center" valign="middle" width="50" bgcolor="0000ff">1</td>
<td align="center" valign="middle" width="50" bgcolor="808080">0</td>
<td align="center" valign="middle">&nbsp;(Values = Binding scores of MACS2 and STRING)</td>
</tr></table>
<br>

<div class="lineWidth"><b>Download: </b><a target="_blank" href="$urlTSV">TSV</a><a> (text)</a></div>
<div class="lineWidth"><b>Links: </b><a target="_blank" href="$urlYuT">Movie</a><a> and </a><a target="_blank" href="$urlDoc">Document</a><a> for </a><a target="_blank" href="$urlCA">ChIP-Atlas</a><a> </a><a target="_blank" href="$urlTG">Target Genes</a></div>

<table class="tableMargin" id="mainTable" border=0 width="$wid" style="table-layout: fixed;">
DDD


# 入力: 各 SRX でソートした TSV ファイル
proteinList="$projectDir/lib/string/protein.aliases.v10.$Genome.txt"
expList="$projectDir/lib/assembled_list/experimentList.tab"

head -n 1001 "$inFn"| awk -F '\t' -v inFn="$inFn" -v Size=$Size -v SIZE=$SIZE -v URL1="$url1" -v URL2="$url2"\
                                  -v proteinList="$proteinList" -v fnHead=$fnHead -v Wkb=$Wkb -v expList=$expList -v Genome=$Genome '
BEGIN {
  while ((getline < proteinList) > 0) {
    if (!proteinID[$2]) {   # ID の重複を避ける
      sub(SUBSEP, ".", $1)
      proteinID[$2] = $1    # proteinID["POU5F1"] = 9606.ENSP00000259915
    }
  }
  while ((getline < expList) > 0) {
    if ($2 == Genome && $3 == "TFs and others") tfs[$4]++   # tfs["POU5F1"]++
  }
} {
  print "<tr>"
  for (i=1; i<=NF; i++) {
    if (NR == 1) { # 1 行目
      # 1 列目
      split($2, qProt, "|")
      if (i == 1) print "<td width=" SIZE*1 " height=" Size "><b>" qProt[1] "</b>\047s Target genes</td>"
      if (i == 1) print "<td width=" Size*1 " height=" Size "><p id=\"rotate\">" "</p></td>"
      
      # 2 列目 以降
      if (i > 1) {
        split($i, tag, "|")      # tag[1] = 抗原 or SRX or STRING, tag[2] = 細胞小
        if (fnHead == tag[1]) {
          boldA = "<b>"      # ソートキーを太字
          boldB = "</b>"     # ソートキーを太字
          triag = "&#9699;"  # 下向き三角
        } else {
          boldA = " "
          boldB = " "
          triag = "&#9698;"  # 横向き向き三角
        }
        
        gsub("_", "\\&nbsp;", tag[2])
        if (i == 2)       Url = URL1 tag[1] "." Wkb ".html"   # URL1 = http://dbarchive.biosciencedbc.jp/kyushu-u/$Genome/target/
        else if (i == NF) Url = URL1 "STRING_" qProt[1] "." Wkb ".html"
        else              Url = URL1 tag[1] "." Wkb ".html"
        
        printf "<td width=%s height=%s>", Size, Size
        printf "%s", boldA  # ソートキーを太字
        printf "<p id=\"rotate\"><a title=\"Sort by this column...\""
        printf "href=\"%s\" style=\"text-decoration: none;\">%s&nbsp;</a><a ", Url, triag
        
        if (i < NF) { # tag[1] = 抗原 or SRX の場合
          First = tag[1]
          Second = tag[2]
          Comment = "Open info to " tag[1]
          srxUrl = URL2 tag[1]
        } else {      # tag[1] = STRING の場合
          First = qProt[1]
          Second = "STRING"
          Comment = "Serach " qProt[1] " in STRING."
          srxUrl = "http://string-db.org/newstring_cgi/show_network_section.pl?identifier=" proteinID[qProt[1]]
        }
          
        if (i > 2) printf "target=\"_blank\" title=\"%s\" style=\"text-decoration: none;\" href=\"%s\"", Comment, srxUrl
        gsub("-", "", First) # ハイフンがあると改行されてしまう
        print ">" First "</a><nobr>:&nbsp;" Second "</nobr></p>" boldB "</td>"
        if (i == NF-1 || i == 2) printf "<td width=%s height=%s></td>", Size, Size  # Avreage と STRING は一列あける
      }
    } else { # 2 行目以降
      pUrl = URL1 $1 "." Wkb ".html"   # URL1 = http://dbarchive.biosciencedbc.jp/kyushu-u/$Genome/target/
      if (i == 1) print "<td width=" SIZE*1 " height=" Size "><i><nobr>" $1 "</nobr></i></td>"
      if (i == 1) {   # ↻ マークの動作設定 (Target gene があるときは pUrl, ないときはグレー表示)
        href = (tfs[$1] > 0)? " href=\"" pUrl "\"" : " class=\"dist\""
        print "<td title=\"Serach this target genes...\" width=" SIZE*1 " height=" Size "><b><a style=\"text-decoration: none\"" href ">&#x21BB</a></b></td>"
      }
      if (i > 1) {
        if (i == NF) {  # STRING の場合
          comment = "Serach " qProt[1] " and " $1 " in STRING."
          stringURL = "http://string-db.org/newstring_cgi/show_network_section.pl?identifiers=" proteinID[qProt[1]] "%250D" proteinID[$1]
          Symbol = "<a target=\"_blank\" title=\"" comment "\" style=\"text-decoration: none;\" href=\"" stringURL "\">&#8811;</a>"
        } else {
          Symbol = ""
        }
        print "<td align=\"center\" bgcolor=\"#" color($i) "\" width=" Size " height=" Size ">" Symbol "</td>"
      }
      if (i == NF-1 || i == 2) printf "<td width=%s height=%s></td>\n", Size, Size  # STRING は一列あける
    }
  }
  print "</tr>"
}
function color(x) {
  MAX=1000
  N=MAX/4
  b=255

  if(x==0) {
    R=128
    G=128
    B=128
  }
  else if(x<N) {
    R=0
    G=b/N*x
    B=b
  }
  else if (x>=N && x<2*N) {
    R=0
    G=b
    B=-b/N*x+2*b
  }
  else if (x>=2*N && x<3*N) {
    R=b/N*x-2*b
    G=b
    B=0
  }
  else if (x>=3*N && x<4*N) {
    R=255
    G=-b/N*x+4*b
    B=0
  }
  else if (x>=4*N) {
    R=255
    G=0
    B=0
  }
  return sprintf("%02x%02x%02x", int(R), int(G), int(B))
}'

cat << DDD
</table>
</FONT>

<script type="text/javascript">
(function (){
  var Tbl = document.getElementById('mainTable');
  for (var i = 1; i < Tbl.rows.length; i++) {
    for (var j = 2; j < Tbl.rows[i].cells.length; j++) {
      var Cells = Tbl.rows[i].cells[j];
      var Row = Tbl.rows[i].cells[0].innerHTML.replace("<i><nobr>", "").replace("</nobr></i>", "");
      var Col = Tbl.rows[0].cells[j].innerHTML.replace(/</g, ">").split(">");
      var srx = String(Col[8]);
      var cellType = String(Col[12]).replace(":&nbsp;", "").replace(/&nbsp;/g, " ");
      if (Col[8]) Cells.title = cellType + "\n(" + srx +")\n\n" + Row;
    }
  }
})();
</script>

DDD

