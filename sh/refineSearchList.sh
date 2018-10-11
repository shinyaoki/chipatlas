#!/bin/sh
#$ -S /bin/sh
# sh chipatlas/sh/refineSearchList.sh

# experimentList.tab を JSON 形式に変換
  # 簡易版
cat `ls -1 chipatlas/lib/metadata/NCBI_SRA_Metadata_Full_20*tab| tail -n1`| awk -F '\t' -v OFS='\t' '{
  x[$1] = $12
} END {
  while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
    $1 = $1 "\t" x[$1]
    if ($9 ~ /^GSM[0-9][0-9]/) {
      split($9, a, ":")
      $1 = $1 "\t" a[1]
    } else {
      $1 = $1 "\t-"
    }
    print
  }
}'| cut -f1-8| awk -F '\t' '
BEGIN {
  printf "{\"data\": ["
} {
  printf "["
  for (i=1; i<NF; i++) printf "\"%s\",", $i
  printf "\"%s\"],", $NF
}'| awk '{
  sub(/,$/, "", $0)
  print $0 "]}"
}' > chipatlas/lib/assembled_list/ExperimentList.json


  # Advanced 版
cat `ls -1 chipatlas/lib/metadata/NCBI_SRA_Metadata_Full_20*tab| tail -n1`| awk -F '\t' -v OFS='\t' '{
  x[$1] = $12
} END {
  while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
    $1 = $1 "\t" x[$1]
    if ($9 ~ /^GSM[0-9][0-9]/) {
      split($9, a, ":")
      $1 = $1 "\t" a[1]
      sub(": ", "\t", $9)
    } else {
      $1 = $1 "\t-"
      $9 = "-\t" $9
    }
    gsub("\\\\", "", $0)
    gsub("\"", "\\\"", $0)
    print
  }
}'| cut -f1-8,12-| awk '{
  gsub("\t", "__TAB__")
  for (i=1; i<=9; i++) sub("__TAB__", "\t", $0)
  print
}'| awk -F '\t' '{
  print (NF == 9) ? $0 "\t-" : $0
}'| awk -F '\t' '
BEGIN {
  printf "{\"data\": ["
} {
  printf "["
  for (i=1; i<NF; i++) printf "\"%s\",", $i
  printf "\"%s\"],", $NF
}'| awk '{
  sub(/,$/, "", $0)
  print $0 "]}"
}' > chipatlas/lib/assembled_list/ExperimentList_adv.json




# HTML ファイルを作成 (簡易版)
cat << 'DDD' > chipatlas/lib/assembled_list/refineSearchList.html
<!DOCTYPE HTML>
<html lang='en'>
<head>
<meta charset='utf-8'>
<FONT face="Helvetica Neue" color="333333">
<title>ChIP-Atlas / Keyword search</title>

<script type="text/javascript" language="javascript" src="https://www.datatables.net/release-datatables/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="https://code.jquery.com/jquery-1.12.4.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/dataTables.buttons.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.html5.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css" />
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/1.5.1/css/buttons.dataTables.min.css" />


<style type="text/css">
<!--
.bodyMargin {margin: 30px 30px 30px 30px ;}

.table1 {
	margin: 10px auto;
}
@media (max-width:767px) { .table1 {
    width: auto;
	margin: 0;
} }
-->
</style>
</head>
<body class="bodyMargin" onresize="location.reload()">
<h1>ChIP-Atlas / Keyword search</h1>
<p>Search for ChIP-seq data with keywords.</p>
<p class="radio-area">
  <input type="radio" name="lang" value="ruby" checked="checked"> Simple search<br>
  <input type="radio" name="lang" value="perl" onclick="location.href = 'http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/refineSearchList_advanced.html'"> Advanced search
</p>

<script>
jQuery.fn.dataTableExt.aTypes.unshift(
	function ( sData )
	{
		var sValidChars = "0123456789-,./";
		var Char;
		var bDecimal = false;
		for ( i=0 ; i<sData.length ; i++ )
		{
			Char = sData.charAt(i);
			if (sValidChars.indexOf(Char) == -1)
			{
				return null;
			}
			if ( Char == "," )
			{
				if ( bDecimal )
				{
					return null;
				}
				bDecimal = true;
			}
		}
		
		return 'numeric-comma';
	}
);

jQuery.fn.dataTableExt.oSort['numeric-comma-asc']  = function(a,b) {
	var x = (a == "-") ? 0 : a.replace( /,/, "" );
	var y = (b == "-") ? 0 : b.replace( /,/, "" );
	x = parseFloat( x );
	y = parseFloat( y );
    return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['numeric-comma-desc'] = function(a,b) {
	var x = (a == "-") ? 0 : a.replace( /,/, "" );
	var y = (b == "-") ? 0 : b.replace( /,/, "" );
	x = parseFloat( x );
	y = parseFloat( y );
	return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};

$(document).ready(function() {
    $('#example').DataTable( {
        deferRender: true,
        dom: '<"top"fliB>tpr<"bottom"><"clear">',
        aLengthMenu: [[10, 20, 50, 100, -1], [10, 20, 50, 100, "All"]],
        iDisplayLength: 10,
        buttons: [
            'copyHtml5',
            {
                text: 'TSV',
                extend: 'csvHtml5',
                fieldSeparator: '\t',
                extension: '.tsv'
            }
        ],
        ajax: "ExperimentList.json",
        columns: [
            { title: "<a title='Experimental ID.'>SRX ID</a>",
              render: function ( data, type, row ) {
                return "<a title='Open this Info...' target='_blank' style='text-decoration: none' href='http://chip-atlas.org/view?id=" + data +  "'>" + data + "</a>";
              }
            },
            { title: "<a title='Accession ID'>SRA ID</a>" },
            { title: "<a title='Experimental ID in GEO'>GEO ID",
              render: function ( data, type, row ) {
                if (data != "-") {
                  return "<a title='Open this Info...' target='_blank' style='text-decoration: none' href='https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=" + data +  "'>" + data + "</a>";
                } else {
                  return data;
                }
              }
            },
            { title: "<a title='Genome assembly (hg19, mm9, rn6, dm3, ce10, sacCer3)'>Genome</a>" },
            { title: "<a title='Curated antigen class'>Antigen class</a>" },
            { title: "<a title='Curated antigen name'>Antigen</a>" },
            { title: "<a title='Curated cell type class'>Cell type class</a>" },
            { title: "<a title='Curated cell type'>Cell type</a>" }
        ],
        order: [[ 6, "asc" ]]
    } );
} );


</script>

<div class="table1">
<table id="example" class="display" width="100%"></table>

DDD


# HTML ファイルを作成 (advanced 版)
cat << 'DDD' > chipatlas/lib/assembled_list/refineSearchList_advanced.html
<!DOCTYPE HTML>
<html lang='en'>
<head>
<meta charset='utf-8'>
<FONT face="Helvetica Neue" color="333333">
<title>ChIP-Atlas / Keyword search</title>

<script type="text/javascript" language="javascript" src="https://www.datatables.net/release-datatables/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="https://code.jquery.com/jquery-1.12.4.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/dataTables.buttons.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
<script type="text/javascript" language="javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.html5.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css" />
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/1.5.1/css/buttons.dataTables.min.css" />


<style type="text/css">
<!--
.bodyMargin {margin: 30px 30px 30px 30px ;}

.table1 {
	margin: 10px auto;
}
@media (max-width:767px) { .table1 {
    width: auto;
	margin: 0;
} }
-->
</style>
</head>
<body class="bodyMargin" onresize="location.reload()">
<h1>ChIP-Atlas / Advanced keyword search</h1>
<p>Search for ChIP-seq data with keywords.</p>
<p class="radio-area">
  <input type="radio" name="lang" value="ruby" onclick="location.href = 'http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/refineSearchList.html'"> Simple search<br>
  <input type="radio" name="lang" value="perl" checked="checked"> Advanced search
</p>

<script>
jQuery.fn.dataTableExt.aTypes.unshift(
	function ( sData )
	{
		var sValidChars = "0123456789-,./";
		var Char;
		var bDecimal = false;
		for ( i=0 ; i<sData.length ; i++ )
		{
			Char = sData.charAt(i);
			if (sValidChars.indexOf(Char) == -1)
			{
				return null;
			}
			if ( Char == "," )
			{
				if ( bDecimal )
				{
					return null;
				}
				bDecimal = true;
			}
		}
		
		return 'numeric-comma';
	}
);

jQuery.fn.dataTableExt.oSort['numeric-comma-asc']  = function(a,b) {
	var x = (a == "-") ? 0 : a.replace( /,/, "" );
	var y = (b == "-") ? 0 : b.replace( /,/, "" );
	x = parseFloat( x );
	y = parseFloat( y );
    return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['numeric-comma-desc'] = function(a,b) {
	var x = (a == "-") ? 0 : a.replace( /,/, "" );
	var y = (b == "-") ? 0 : b.replace( /,/, "" );
	x = parseFloat( x );
	y = parseFloat( y );
	return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};
 
$(document).ready(function() {
    $('#example').DataTable( {
        deferRender: true,
        dom: '<"top"fliB>tpr<"bottom"><"clear">',
        aLengthMenu: [[10, 20, 50, 100, -1], [10, 20, 50, 100, "All"]],
        iDisplayLength: 10,
        buttons: [
            'copyHtml5',
            {
                text: 'TSV',
                extend: 'csvHtml5',
                fieldSeparator: '\t',
                extension: '.tsv'
            }
        ],
        ajax: "ExperimentList_adv.json",
        columns: [
            { title: "<a title='Experimental ID.'>SRX ID</a>",
              render: function ( data, type, row ) {
                return "<a title='Open this Info...' target='_blank' style='text-decoration: none' href='http://chip-atlas.org/view?id=" + data +  "'>" + data + "</a>";
              }
            },
            { title: "<a title='Accession ID'>SRA ID</a>" },
            { title: "<a title='Experimental ID in GEO'>GEO ID",
              render: function ( data, type, row ) {
                if (data != "-") {
                  return "<a title='Open this Info...' target='_blank' style='text-decoration: none' href='https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=" + data +  "'>" + data + "</a>";
                } else {
                  return data;
                }
              }
            },
            { title: "<a title='Genome assembly (hg19, mm9, rn6, dm3, ce10, sacCer3)'>Genome</a>" },
            { title: "<a title='Curated antigen class'>Antigen class</a>" },
            { title: "<a title='Curated antigen name'>Antigen</a>" },
            { title: "<a title='Curated cell type class'>Cell type class</a>" },
            { title: "<a title='Curated cell type'>Cell type</a>" },
            { title: "<a title='Title written by authors'>Title</a>" },
            { title: "<a title='Attributes written by authors'>Attributes</a>",
              render: function ( data, type, row ) {
                if (data != "-") {
                  data = '<b>' + data;
                  data = data.replace( /=/g, '</b>: ' );
                  data = data.replace( /__TAB__/g, '<br><b>' );
                  return data;
                } else {
                  return data;
                }
              }
            }
        ],
        order: [[ 6, "asc" ]]
    } );
} );
</script>

<div class="table1">
<table id="example" class="display" width="100%"></table>

DDD
