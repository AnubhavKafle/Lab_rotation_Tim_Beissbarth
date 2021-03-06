###### This is to format the file suitable for Surivival analysis########
###   Done in BASH SHELL   ####
for i in $(ls *.txt) ; do awk -F'\t' '{print ($1,$9,tolower($16)) }' $i | grep -v -E "Silent|RNA" | sed 's/ /\t/g'  >> "Filtered_"$i; done 
for i in $(ls Filtered*) ; do  cut -d"-" -f1,2,3 $i >> "filtered_"$i; done
rm Filtered*
mv filtered* ./Mu
rename 's/filtered_Filtered_/Filtered_/' filtered*
for i in $(ls *.txt) ; do  sed 's/Tumor_Sample_Barcode/Patience_ID/g' $i >> "tested_"$i; done
rm Filtered*
for i in $(ls *.txt) ; do  sed 's/-/./g' $i >> "point_"$i; done
rm tested*
rename 's/point_//g' point_*

###########################################################
#### R code for survival analysis  for the mutation data###
###########################################################
library(survival)

TCGA_Samples = c("BRCA","GBM","OV","LUAD","UCEC","KIRC","HNSC","LGG","THCA","LUSC","PRAD","STAD","SKCM","COAD","BLCA","CESC","KIRP","SARC","LAML","ESCA","PAAD","PCPG","READ","TGCT","THYM","ACC","UVM","DLBC","UCS","CHOL") #All TCGA Samples without MESO

TCGA_Samples = TCGA_Samples[order(TCGA_Samples)]

Mutation_survival = function(ACC, clinical_data)
  {
  #ACC = read.table("ACC-Mutations-AllSamples.txt", head =T, sep="\t")
  unique_genes = as.character(unique(ACC$Hugo_Symbol))
  unique_genes = unique_genes[order(unique_genes)]
  genes_acc = list()
   #unique(as.character(ACC[rownames(ACC[which(ACC$Hugo_Symbol=="NOL9"),]),3]))

  for(i in unique_genes)
    {
      genes_acc[[i]] = unique(as.character(ACC[rownames(ACC[which(ACC$Hugo_Symbol==i),]),3]))
     }

  #mutation_matrix = list()
  #for ( i in names(genes_acc))
   # {
     #mutation_matrix[[i]] = cbind(rep(1,length(genes_acc[[i]])))
     #rownames(mutation_matrix[[i]]) = as.character(genes_acc[[i]])
     #colnames(mutation_matrix[[i]])= "Status"
   # }

#clinical_data = t(read.table(list.files("~/Desktop/labRotation1_AnubhavK/Clinical_Firehose/",pattern="ACC",full.names = T),header=T,sep="\t",row.names = 1))[,-1]

  clinical_match = as.data.frame(clinical_data)

  event = c() #To have all the events coded in 0 or 1

  days_to_death = c() #days to death, if not, then follow-up data

##Preparing clinical survival data###
  for ( i in 1:length(as.character(clinical_match$days_to_death))) #Take follow-day where death days are not available
    {
      days_to_death[i] = ifelse(is.na(as.character(clinical_match$days_to_death)[i]),as.numeric(as.character(clinical_match$days_to_last_followup))[i],as.numeric(as.character(clinical_match$days_to_death))[i])
  
      event[i] = as.numeric(as.character(clinical_match$vital_status))[i]
    }

   clinical_survival = as.data.frame(cbind(days_to_death,event))

  rownames(clinical_survival)= rownames(clinical_match)

####################
  survival_mutation_matrix = list()

  #status = c()

  for(j in names(genes_acc))
    {
      status = c()
  
  for(i in rownames(clinical_survival))
    {
      status = c(status, ifelse( i %in% genes_acc[[j]][], 1, 0)) 
    }
  
    survival_mutation_matrix[[j]] = cbind(status)
    rownames(survival_mutation_matrix[[j]]) = rownames(clinical_survival)
    }
  
  results_coxph = list() #Creating a result list

 for (genes in names(survival_mutation_matrix))
  {
    if ( sum(survival_mutation_matrix[[genes]][]) > 0 )
      
    {  
      model_analysis = summary(coxph(Surv(clinical_survival$days_to_death,clinical_survival$event) ~ as.factor(survival_mutation_matrix[[genes]][]))) #P-value is 5th in the index of coefficient. Coxph model is used because of the continous event of gene expression
      
      results_coxph[[genes]] = c(model_analysis$coefficients[5], model_analysis$coefficients[2])
    }
    
  }

  coxph_results = t(as.data.frame(results_coxph))

  colnames(coxph_results) = c("P_values", "Hazard_ratio")

  #write.table(coxph_results, file = "ACC_Mutation.txt", sep = '\t', row.names = T)
  #write.table(coxph_results, file = paste(,".txt"), sep = "\t")
  
  return(coxph_results)

  }

for ( i in TCGA_Samples)
  {
  
    Cancer_Mutation = read.table(list.files("~/Desktop/labRotation1_Anubhav",pattern=i,full.names = T),header=T,sep="\t")
  
    clinical_data = t(read.table(list.files("~/Desktop/labRotation1_AnubhavK/Clinical/",pattern=i,full.names = T),header=T,sep="\t",row.names = 1))[,-1]
  
    survival_results = Mutation_survival(Cancer_Mutation,clinical_data)
  
    write.table(survival_results, file = paste(i,"_Mutation_Survival.txt"), sep = "\t", row.names = T)
  }


  










