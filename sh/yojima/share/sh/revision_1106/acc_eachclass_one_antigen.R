library(ggplot2) 
library(ggrepel)

dir<-"word_data/"
type<-"antigen" #celltype or antigen
label<-"2" # "1" or "2"
num<-"2-4" # "1" to "10"
filt<-"10" # "1" to "5"

acc_mat<-c()
class_num=128  #283 #748 #76

######ここがべたうちになっている######
test_num=9958
true_class_total<-array(0, dim=class_num)
false_class_total<-array(0, dim=class_num)
result_file=paste(dir,"output_c",filt,"_cost1_unclassified_curated_",type,"_intl",label,"f",num,"gram.txt", sep="")
test_label_file=paste("label_feature/c",filt,"_unclassified_curated_",type,"_intl",label,".txt",sep = "")
train_label_file=paste("label_feature/c",filt,"_unclassified_training_",type,"_intl",label,".txt",sep = "")

test_result=read.table(file = result_file)
test_true_label=read.table(file = test_label_file)
train_true_label=read.table(file = train_label_file)
test_result.df <- data.frame(test_result)

predict_label=data.frame(test_result.df[2:(test_num+1),1])
true_predict_label<-cbind(test_true_label,predict_label)
colnames(true_predict_label)<-c("true","predicted")

#write index of false sample to file
predict_file =  paste(dir,"c",filt,"_cost1_unclassified_curated_",type,"_",num,"gram","_labelcheck",sep = "")
write.table(true_predict_label, file = predict_file,col.names = F, row.names = F, quote = F)

false_index<-c() # record the index of false predicted samples
true_index<-c()

index_unclassified<-sort(table(train_true_label),decreasing=TRUE)[1] #index that most frequently appears
index_unclassified<-as.integer(names(index_unclassified))

for (row in 2:dim(test_result.df)[1]) {
    row_value<-test_result.df[row,2:dim(test_result.df)[2]]
    sort_value<-sort(row_value,decreasing = T)
    top<-sort_value[1:1]  #top1=sort_value[1:1], top3=sort_value[1:3]
    col_ind_top<-which(colnames(row_value) %in% colnames(top))
    class_ind_top<-test_result.df[1,col_ind_top+1]
    label_ind_top<-true_predict_label[row-1,1]
    
    if((index_unclassified %in% class_ind_top)&&!(true_predict_label[row-1,1] %in% train_true_label[,1])){ 
      #predicted as unclassified and the true label of it is not contained in training labels, considered as correctly predicted
      true_class_total[label_ind_top+1]=true_class_total[label_ind_top+1]+1
      true_index<-c(true_index,row-1)
    }else{
        if(true_predict_label[row-1,1] %in% class_ind_top) {
          true_class_total[label_ind_top+1]=true_class_total[label_ind_top+1]+1
          true_index<-c(true_index,row-1)
        }
        else{
          false_class_total[label_ind_top+1]=false_class_total[label_ind_top+1]+1
          false_index<-c(false_index,row-1)
        }
    }
}

false_file = paste(dir,"c",filt,"_cost1_",type,"_curated_l",label,"_",num,"gram","_falseindex",sep = "")
write.table(false_index, file = false_file,col.names = F, row.names = F, quote = F, sep = "\n")
true_file = paste(dir,"c",filt,"_cost1_",type,"_curated_l",label,"_",num,"gram","_trueindex",sep = "")
write.table(true_index, file = true_file,col.names = F, row.names = F, quote = F, sep = "\n")
  
  
#write accuracy of each class to file
filename = paste(dir,"c",filt,"_cost1_",type,"_curated_l",label,"_",num,"gram","_accuracy",sep = "")