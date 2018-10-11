import sys
args = sys.argv

dir='word_data/'
dir2='label_feature/'

true_false = args[1]

file=dir+'c10_cost1_antigen_curated_l2_2-4gram_'+true_false+'index'
with open(file) as f:
        l = f.readlines()
        l = [x.strip('\n') for x in l]
l = list(map(int, l))

f=open(dir2+'c10_unclassified_curated_antigen_intl2_feature.txt')
fout=open(dir+'c10_unclassified_curated_antigen_intl2_'+true_false+'samples','w')
i=1
for line in f:
        if i in l:
                fout.write("%s" % line)
        i+=1
fout.close()
