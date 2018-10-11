library("ggplot2")
library(grid)

# 日付
Sys.setlocale("LC_TIME","C")
today <- Sys.Date()
today <- format(today, format="%B %Y")
png("chipatlas/lib/assembled_list/allDataNumber.png", width=4800, height=4800, res=720)

# 新しい画面
grid.newpage()
pushViewport(viewport(layout=grid.layout(2, 2)))

# ChIP-seq データの集計
data <- read.csv("tmpFile4ggplot_chipatlas3.txt")
data <- transform(data, Project= factor(Project, labels = c("ENCODE","Roadmap","Others")))
p1 <- ggplot(
  data, 
  aes(x=Organism, y=Numbers)
)
p1 <- p1 + geom_bar(
  stat="identity",
  aes(fill=Project)
) 
p1 <- p1 + scale_fill_manual(values = c("#558ED5", "#9BBB59", "#F79646"))
p1 <- p1 + scale_x_discrete(limits=c("S. cerevisiae", "C. elegans", "D. melanogaster", "R. norvegicus", "M. musculus", "H. sapiens"))
p1 <- p1 + coord_flip()
p1 <- p1 + theme(legend.position="none", plot.margin=unit(x=c(10,10,0,0), units="mm"))
p1 <- p1 + labs(x="Organism\n", y=paste("\n# of ChIP-seq data in ChIP-Atlas\n"))
p1 = p1 + theme(axis.text.x = element_text(size=12, color="#555555"),axis.text.y = element_text(size=12, color="#555555")) 


# DNase-seq データの集計
data <- read.csv("tmpFile4ggplot_chipatlas4.txt")
data <- transform(data, Project= factor(Project, labels = c("ENCODE","Roadmap","Others")))
p2 <- ggplot(
  data, 
  aes(x=Organism, y=Numbers)
)
p2 <- p2 + geom_bar(
  stat="identity",
  aes(fill=Project)
) 
p2 <- p2 + scale_fill_manual(values = c("#558ED5", "#9BBB59", "#F79646"))
p2 <- p2 + scale_x_discrete(limits=c("S. cerevisiae", "C. elegans", "D. melanogaster", "R. norvegicus", "M. musculus", "H. sapiens"))
p2 <- p2 + coord_flip()
p2 <- p2 + theme(legend.position = c(0.85, 0.3), plot.margin=unit(x=c(10,10,0,0), units="mm"))
p2 <- p2 + labs(x="Organism\n", y=paste("\n# of DNase-seq data in ChIP-Atlas\n(", today, ")"))
p2 = p2 + theme(axis.text.x = element_text(size=12, color="#555555"),axis.text.y = element_text(size=12, color="#555555")) 

# 描画
print(p1, vp = viewport(layout.pos.row=1))
print(p2, vp = viewport(layout.pos.row=2))

dev.off()



# 抗原、細胞クラスによる集計

# 新しい画面
png("chipatlas/lib/assembled_list/cellTypeNumber.png", width=2400, height=9600, res=360)
grid.newpage()
pushViewport(viewport(layout=grid.layout(2, 2)))

# 細胞タイプの集計
data <- read.csv("tmpFile4ggplot_chipatlas2.txt")
data <- transform(data, celltype= factor(celltype, labels = c("No description","Unclassified","Others","Yeast strain","Uterus","Spleen","Pupae","Prostate","Pluripotent stem cell","Placenta","Pancreas","Neural","Muscle","Lung","Liver","Larvae","Kidney","Gonad","Epidermis","Embryonic fibroblast","Embryo","Digestive tract","Cell line","Cardiovascular","Breast","Bone","Blood","Adult","Adipocyte")))
data <- transform(data, antigen= factor(antigen, labels = c("No description","Unclassified","Input control","TFs and others","RNA polymerase","Histone","DNase-seq")))
data <- transform(data, Organism= factor(Organism, labels = c("H. sapiens", "M. musculus", "R. norvegicus", "D. melanogaster", "C. elegans", "S. cerevisiae")))
ggplot(data, aes(celltype, fill=Organism)) +
geom_bar() + facet_wrap(~ Organism, ncol=1) + coord_flip() +
labs(title = paste("# of Cell Type Classes in ChIP-Atlas\n(", today, ")\n"), x="Cell type class\n", y="\nCounts")

dev.off()


# 新しい画面
png("chipatlas/lib/assembled_list/antigenNumber.png", width=2400, height=3600, res=360)
grid.newpage()
pushViewport(viewport(layout=grid.layout(2, 2)))

# 抗原クラスの集計
ggplot(data, aes(antigen, fill=Organism)) +
geom_bar() + facet_wrap(~ Organism, ncol=1) + coord_flip() +
labs(title = paste("# of Antigen Classes in ChIP-Atlas\n(", today, ")\n"), x="Antigen class\n", y="\nCounts")


dev.off()
