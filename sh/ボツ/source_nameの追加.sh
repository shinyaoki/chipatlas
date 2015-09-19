
# 抗体名に source_name も追加
for Genome in `ls chipatlas/results`; do
  new=chipatlas/classification/ag_Statistics.$Genome.tab
  old=chipatlas/classification_old/ag_Statistics.$Genome.tab
  cat $new| awk -F '\t' -v old=$old '
  BEGIN {
    while ((getline < old) > 0) {
      Old[$4] = $5
      n[$4]++
    }
  } {
    if (n[$4] > 0) print
    else {
      N = split($4, s, "|")
      for (i=1; i<N; i++) Str = Str "|" s[i]
      sub("\\|", "", Str)
      if (n[Str] > 0) {
        if (Old[Str] ~ "@") printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, Old[Str]
        else                printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $4
      }
      else printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $4
      Str = ""
    }
  }' > aaaaaaa
  mv aaaaaaa $new
done

