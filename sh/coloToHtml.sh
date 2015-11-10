#!/bin/sh
#$ -S /bin/sh

# sh $projectDir/sh/coloToHtml.sh "$tsv" "$HLM" "$ctL" $Genome

Size=25
SIZE=100

inFn="$1"   # inFn の種類: 抗原.細胞大.tsv,  SRX.tsv,  STRING_抗原.細胞大.tsv
HLM="$2"
ctL="$3"
ctl=`echo $ctL| tr '_' ' '`
Genome="$4"
qProt=`head -n1 "$inFn"| cut -f4| cut -d '|' -f1`         # POU5F1

url1="http://dbarchive.biosciencedbc.jp/kyushu-u/$Genome/colo/"       # html へのリンク
url2="http://chip-atlas.org/view?id="                                 # 個別 SRX へのリンク
urlDoc="https://github.com/inutano/chip-atlas/wiki#6-colocalization"  # Document へのリンク
urlTSV=`echo "$url1$qProt.$ctl.tsv"| tr ' ' '_'`                      # TSV へのリンク

fnHead=`basename "$inFn"| cut -d '.' -f1| cut -d '_' -f1` # 抗原 or SRX or STRING
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

projectDir=`echo $0| sed 's[/sh/coloToHtml.sh[['`

wid=`head -n1 "$inFn"| awk -v Size=$Size -v SIZE=$SIZE '{printf "%d", SIZE*4 + (NF-3)*Size}'` # テーブル全体のサイズ


# html のヘッダ情報
# margin = 上 右 下 左 を指定
cat << DDD
<!DOCTYPE html>
<head>
<title>ChIP-Atlas | Colocalization</title>

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

  </style>
</head>

<body class="bodyMargin">
<h1>ChIP-Atlas: Colocalization analysis</h1>
<h2>Colocalization analysis for $qProt</h2>

<div class="lineWidth"><b>Query protein: </b>$qProt</div>
<div class="lineWidth"><b>Cell class: </b>$ctl</div>
<div class="lineWidth"><b>Sort key: </b>$sortKey</div>
<div class="lineWidth">&nbsp;</div>

<div class="lineWidth"><b>Color legends</b></div>
<table border=0 height="25" style="table-layout: fixed;"><tr>
<td align="right" valign="middle"  width="120" >ChIP-seq data:&nbsp;</td>
<td align="center" valign="middle" width="50" bgcolor="ff0000">H-H</td>
<td align="center" valign="middle" width="50" bgcolor="aaff00">H-M</td>
<td align="center" valign="middle" width="50" bgcolor="00ff38">M-M</td>
<td align="center" valign="middle" width="50" bgcolor="00ffaa">H-L</td>
<td align="center" valign="middle" width="50" bgcolor="00e2ff">M-L</td>
<td align="center" valign="middle" width="50" bgcolor="0071ff">L-L</td>
<td align="center" valign="middle" width="50" bgcolor="808080">N.D.</td>
<td align="center" valign="middle" width="50" bgcolor="000000"><font color="white">Same</font></td>
<td align="center" valign="middle">&nbsp;(Peak intensities are <b>H</b>igh, <b>M</b>iddle or <b>L</b>ow)</td>
</tr></table>
<br>
<table border=0 height="25" style="table-layout: fixed;"><tr>
<td align="right" valign="middle"  width="120" >STRING data:&nbsp;</td>
<td align="center" valign="middle" width="50" bgcolor="ff0000">1000</td>
<td align="center" valign="middle" width="50" bgcolor="ffff00">750</td>
<td align="center" valign="middle" width="50" bgcolor="00ff00">500</td>
<td align="center" valign="middle" width="50" bgcolor="00ffff">250</td>
<td align="center" valign="middle" width="50" bgcolor="0000ff">0</td>
<td align="center" valign="middle" width="50" bgcolor="808080">N.D.</td>
<td align="center" valign="middle">&nbsp;(Values = STRING's binding scores)</td>
</tr></table>
<br>
<div class="lineWidth"><b>Usage: </b><a target="_blank" title="How to" href=http://www.yahoo.co.jp>here</a></div>
<div class="lineWidth"><b>Documents: </b><a target="_blank" title="Documents for Colocalization analysis in ChIP-Atlas" href="$urlDoc">here</a></div>
<div class="lineWidth"><b>Download: </b><a target="_blank" title="Download in TSV format" href="$urlTSV">$qProt.$ctl.tsv</a></div>



<table class="tableMargin" id="mainTable" border=0 width="$wid" style="table-layout: fixed;">
DDD


# 入力: 各 SRX でソートした TSV ファイル
proteinList="$projectDir/lib/string/protein.aliases.v10.$Genome.txt"

head -n 1001 "$inFn"| awk -F '\t' -v inFn="$inFn" -v Size=$Size -v SIZE=$SIZE -v URL1="$url1" -v URL2="$url2" -v HLM="$HLM" -v ctL="$ctL" -v proteinList="$proteinList" -v fnHead=$fnHead '
BEGIN {
  while ((getline < proteinList) > 0) {
    if (!proteinID[$2]) {   # ID の重複を避ける
      sub(SUBSEP, ".", $1)
      proteinID[$2] = $1    # proteinID["POU5F1"] = 9606.ENSP00000259915
    }
  }
  gsub(" ", "_", ctL)
  split(HLM, max, " ")
  
} {
  print "<tr>"
  for (i=1; i<=NF; i++) {
    if (NR == 1) { # 1 行目
      # 1-3 列目
      split($4, qProt, "|")
      if (i == 2) print "<td align=\"right\" width=" SIZE*2 " height=" Size ">Cell types</td>"
      if (i == 3) print "<td width=" SIZE*1 " height=" Size ">&nbsp;Exp. IDs</td>"
      if (i == 3) print "<td width=" SIZE*1 " height=" Size "><b>" qProt[1] "</b>\047s Colocalization partners</td>"
      if (i == 3) print "<td width=" Size*1 " height=" Size "><p id=\"rotate\">" "</p></td>"
      
      # 4 列目 以降
      if (i > 3) {
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
        if (i == 4)       Url = URL1 tag[1] "." ctL ".html"
        else if (i == NF) Url = URL1 "STRING_" qProt[1] "." ctL ".html"
        else              Url = URL1 tag[1] ".html"
        
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
          
        if (i > 4) printf "target=\"_blank\" title=\"%s\" style=\"text-decoration: none;\" href=\"%s\"", Comment, srxUrl
        gsub("-", "", First) # ハイフンがあると改行されてしまう
        print ">" First "</a><nobr>:&nbsp;" Second "</nobr></p>" boldB "</td>"
        if (i == NF-1 || i == 4) printf "<td width=%s height=%s></td>", Size, Size  # Average と STRING は一列あける
      }
    } else { # 2 行目以降
      pUrl = URL1 $1 ".html"
      srxUrl = URL2 $1
      if (i == 2) gsub("_", "\\&nbsp;", $2)
      if (i == 2) print "<td align=\"right\" width=" SIZE*2 " height=" Size "><div class=\"nowrap\">" $i "</div></td>"
      if (i == 3) print "<td title=\"Open this Info...\" width=" SIZE*1 " height=" Size "><a target=\"_blank\" style=\"text-decoration: none\" href=\" " srxUrl "\">&nbsp;" $1 "</a></td>"
      if (i == 3) print "<td width=" SIZE*1 " height=" Size "><div class=\"nowrap\">" $i "</div></td>"
      if (i == 3) print "<td title=\"Serach this partner...\" width=" SIZE*1 " height=" Size "><b><a style=\"text-decoration: none\" href=\"" pUrl "\">&#x21BB</a></b></td>"
      if (i > 3) {
        if (i == NF) {  # STRING の場合
          $i = $i + 10000
          comment = "Serach " qProt[1] " and " $3 " in STRING."
          stringURL = "http://string-db.org/newstring_cgi/show_network_section.pl?identifiers=" proteinID[qProt[1]] "%250D" proteinID[$3]
          Symbol = "<a target=\"_blank\" title=\"" comment "\" style=\"text-decoration: none;\" href=\"" stringURL "\">&#8811;</a>"
        } else {
          Symbol = ""
        }
        print "<td align=\"center\" bgcolor=\"#" color($i) "\" width=" Size " height=" Size ">" Symbol "</td>"
      }
      if (i == NF-1 || i == 4) printf "<td width=%s height=%s></td>\n", Size, Size  # Average と STRING は一列あける
    }
  }
  print "</tr>"
}
function color(x) {
  MAX=max[1]*max[1]
  if (x >= 10000) {  # STRING の場合
    x = x - 10000
    MAX = 1000
  }
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
    if (x == MAX+1) R=0
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
    for (var j = 5; j < Tbl.rows[i].cells.length; j++) {
      var Cells = Tbl.rows[i].cells[j];
      var Row = Tbl.rows[i].cells[2].innerHTML.replace("<div class=\"nowrap\">", "").replace("</div>", "");
      var Col = Tbl.rows[0].cells[j].innerHTML.replace(/</g, ">").split(">");
      var srx = String(Col[8]);
      var cellType = String(Col[12]).replace(":&nbsp;", "").replace(/&nbsp;/g, " ");
      if (Col[8]) Cells.title = cellType + "\n(" + srx +")\n\n" + Row;
    }
  }
})();
</script>

DDD


