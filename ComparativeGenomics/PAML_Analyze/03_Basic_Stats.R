setwd("~/Dropbox/BirdImmuneGeneEvolution")
library(tidyverse)
library(cowplot)

#Load NCBI annotated dataset - output from script 02

load("02_output_annotated_data/all_res_zf_hs.Rdat")
load("02_output_annotated_data/all_res_ncbi.Rdat")


#######################################################################################################################
#Basic dataset characteristics
#######################################################################################################################

#How many genes in gene tree and species tree datasets?
all_res_gene_ncbi %>%
  summarize(n())
all_res_sp_ncbi %>%
  summarize(n())

#How many hogs could be assigned a chicken gene ID?
all_res_gene_ncbi %>%
  filter(!is.na(entrezgene)) %>%
  summarize(n())

#How many hogs could be assigned a zebra finch gene ID?
all_res_gene_ncbi %>%
  filter(!is.na(entrezgene_zf)) %>%
  summarize(n())

#How many hogs could be assigned to both a chicken and zebra finch gene ID?
all_res_gene_ncbi %>%
  filter(!is.na(entrezgene), !is.na(entrezgene_zf)) %>%
  summarize(n())

#How many hogs could not be assigned to a gene ID?
all_res_gene_ncbi %>%
  distinct(hog,.keep_all = TRUE) %>%
  filter(is.na(entrezgene), is.na(entrezgene_zf)) %>%
  summarize(n())

#How many hogs could be assigned to a human gene ID?
all_res_gene_zf_hs %>%
  distinct(hog,.keep_all = TRUE) %>%
  filter(!is.na(entrezgene_hs)) %>%
  summarize(n())


#######################################################################################################################
#Model significance characteristics
#######################################################################################################################

#Remove hogs that do not have results from all models
all_res_gene_ncbi <- all_res_gene_ncbi %>%
  filter(!is.na(pval_busted) & !is.na(PVal_m1m2) & !is.na(PVal_m2m2a) & !is.na(PVal_m7m8) & !is.na(PVal_m8m8a) & !is.na(total_sel.n)) %>%
  mutate(dataset="gene")

all_res_sp_ncbi <- all_res_sp_ncbi %>%
  filter(!is.na(pval_busted) & !is.na(PVal_m1m2) & !is.na(PVal_m2m2a) & !is.na(PVal_m7m8) & !is.na(PVal_m8m8a) & !is.na(total_sel.n)) %>%
  mutate(dataset="species")

#How many genes had results for all tests?
all_res_gene_ncbi %>%
  summarize(n())
all_res_sp_ncbi %>%
  summarize(n())

#Combine for easy computation
all_res <- bind_rows(all_res_gene_ncbi,all_res_sp_ncbi)

#Create table with numbers of signficant results for gene trees and species trees
model_res <- matrix(nrow=2,ncol=9) %>% as.tibble

model_res[,1] <- c("gene tree","species tree")

#How many genes in gene tree and species tree datasets (all results)?
model_res[,2] <- all_res %>%
  group_by(dataset) %>%
  summarize(n()) %>%
  pull

#How many hogs are selected according to each test?
model_res[,3] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m1m2 < 0.05) %>%
  summarize(n()) %>%
  pull
model_res[,4] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m2m2a < 0.05) %>%
  summarize(n()) %>%
  pull
model_res[,5] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m7m8 < 0.05) %>%
  summarize(n()) %>%
  pull
model_res[,6] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m8m8a < 0.05) %>%
  summarize(n()) %>%
  pull

#How many genes are signficant in all PAML tests?
model_res[,7] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m1m2 < 0.05, FDRPval_m2m2a < 0.05, FDRPval_m7m8 < 0.05, FDRPval_m8m8a < 0.05) %>%
  summarize(n()) %>%
  pull

#How many genes are signficant with BUSTED?
model_res[,8] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_busted < 0.05) %>%
  summarize(n()) %>%
  pull

#How many genes are signficant with BUSTED and all PAML tests?
model_res[,9] <- all_res %>%
  group_by(dataset) %>%
  filter(FDRPval_m1m2 < 0.05, FDRPval_m2m2a < 0.05, FDRPval_m7m8 < 0.05, FDRPval_m8m8a < 0.05, FDRPval_busted < 0.05) %>%
  summarize(n()) %>%
  pull

#Clean up table calculate percentages
model_res <- model_res %>%
  mutate_at(vars(V3:V9),funs( perc = . / V2)) %>%
  mutate_at(paste0("V",3:9,"_perc"), funs(sprintf("%0.2f", .))) %>%
  unite(V3,V3_perc,col = V3,sep = "/") %>%
  unite(V4,V4_perc,col = V4,sep = "/") %>%
  unite(V5,V5_perc,col = V5,sep = "/") %>%
  unite(V6,V6_perc,col = V6,sep = "/") %>%
  unite(V7,V7_perc,col = V7,sep = "/") %>%
  unite(V8,V8_perc,col = V8,sep = "/") %>%
  unite(V9,V9_perc,col = V9,sep = "/")

colnames(model_res) <- c("dataset", "# genes", "m1a vs m2a", "m2a vs m2a_fixed", "m7 vs m8", "m8 vs m8a", "all PAML", "BUSTED", "all PAML + BUSTED")

write_csv(model_res,"03_output_general_stats/n_sig_hogs_table.csv")


#######################################################################################################################
#Model parameter distribution characteristics
#######################################################################################################################

mean_parameters <- all_res %>%
  group_by(dataset) %>%
  summarize(mean_omega_m0 = mean(Omega_m0),
            mean_kappa_m0 = mean(Kappa_m0),
            mean_omega_m2 = mean(Omega_m2),
            mean_prop_sites_m2 = mean(Prop_m2),
            mean_omega_m8 = mean(Omega_m8),
            mean_prop_sites_m8 = mean(Prop_m8),
            mean_omega_BUSTED = mean(omega_busted),
            mean_prop_sites_BUSTED = mean(weight_busted))

#Test whether or not the two distributions are the same, 
sink("03_output_general_stats/m0_dataset_comparison_ks_test_results.txt")
all_res %>%
  dplyr::select(hog,dataset, Omega_m0) %>%
  spread(dataset,Omega_m0) %>%
  do(w=ks.test(.$gene,.$species,data=.)) %>%
  unlist
all_res %>%
  group_by(dataset) %>%
  filter(!is.na(Omega_m0)) %>%
  summarize(ngenes=n(),mean_omega_m0=mean(Omega_m0), median_omega_m0=median(Omega_m0), sd_omega_m0=sd(Omega_m0))
sink()

#Plot distribution of m0 model
ggplot(all_res,aes(Omega_m0)) +
  geom_histogram(bins=40, fill = "#44AA99") +
  facet_grid(~dataset) +
  theme_bw()
ggsave("03_output_general_stats/m0_Omega_distribution.pdf",width=10, height=6)



all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="yes",false="no")) %>%
ggplot(aes(sig_all,Omega_m0)) +
  geom_violin(fill = "#44AA99") +
  facet_grid(~dataset) +
  theme_bw() +
  xlab("under selection with all tests") +
  ylab(expression("m0 model "*omega))
ggsave("03_output_general_stats/m0_Omega_distribution_by_sigall.pdf",width=10,height=6)

sink("03_output_general_stats/m0_sig_dataset_comparison_mann_whit_test_results.txt")
all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="1",false="0")) %>%
  dplyr::select(hog,dataset,sig_all, Omega_m0) %>%
  group_by(dataset) %>%
  do(w=wilcox.test(Omega_m0~sig_all,data=.,paired=FALSE)) %>%
  unlist
all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="1",false="0")) %>%
  group_by(dataset,sig_all) %>%
  filter(!is.na(Omega_m0)) %>%
  summarize(ngenes=n(),mean_omega_m0=mean(Omega_m0), median_omega_m0=median(Omega_m0), sd_omega_m0=sd(Omega_m0))
sink()
  

#Compare the number of significant branches with signficant vs. not significant under BUSTED with Mann-Whitney U test
sink("03_output_general_stats/busted_sig_branches_wilcox_test_results.txt")
all_res %>%  
  mutate(sig_busted = FDRPval_busted < 0.05) %>%
  dplyr::group_by(dataset) %>%
  do(w=wilcox.test(prop_sel.n~sig_busted,data=., paired=FALSE)) %>%
  unlist

all_res %>%
  mutate(sig_busted = FDRPval_busted < 0.05) %>%
  dplyr::group_by(dataset, sig_busted) %>%
  filter(!is.na(prop_sel.n)) %>%
  summarize(ngenes=n(),mean_prop_sig_lineages=mean(prop_sel.n), median_prop_sig_lineages=median(prop_sel.n), sd_prop_sig_lineages=sd(prop_sel.n))
sink()
  
all_res_gene_ncbi <- all_res_gene_ncbi %>%  
  mutate(sig_busted = FDRPval_busted < 0.05)

unlist(wilcox.test(all_res_gene_ncbi$prop_sel.n~all_res_gene_ncbi$sig_busted, paired=FALSE))

#Make a figure
ggplot(all_res_gene_ncbi,aes(sig_busted,prop_sel.n)) +
  geom_violin(fill="#44AA99") +
  xlab("significant with busted (FDR q<0.05)") +
  ylab("prop significant lineages") +
  theme_bw()
ggsave("03_output_general_stats/busted_bsrel_genetree_sign_prop.pdf",height=5,width=5)


#Compare the alingment lengths - correlation with log(pvalue)?
#Conduct logistic regression for the chance of a gene being significant in all tests by its alignment length
all_res_gene_sigcat <- all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),1,0)) %>%
  filter(dataset=="gene")

all_res_sp_sigcat <- all_res  %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),1,0)) %>%
  filter(dataset=="species")

length_logreg_gene <- glm("sig_all~length",family="binomial",data=all_res_gene_sigcat)
length_logreg_sp <- glm("sig_all~length",family="binomial",data=all_res_sp_sigcat)

save(length_logreg_gene,length_logreg_sp,file="03_output_general_stats/alignment_length_logistic_regression_models.Rdat")

sink("03_output_general_stats/alignment_length_logistic_regression_summaries.txt")
print("Gene Tree Results")
summary(length_logreg_gene)
all_res_gene_sigcat %>%
  group_by(sig_all) %>%
  summarize(median_length = median(length)) %>%
  print()
print("Species Tree Results")
summary(length_logreg_sp)
all_res_sp_sigcat %>%
  group_by(sig_all) %>%
  summarize(median_length = median(length)) %>%
  print()
sink()

#Create violin plots
all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="1",false="0")) %>%
  ggplot(aes(sig_all,length)) +
  geom_violin(fill = "#44AA99") +
  facet_wrap(~dataset) +
  xlab("significant all tests") +
  ylab("alignment length")
ggsave("03_output_general_stats/alignment_length_by_signficance.pdf")


#Create overall summary stat plot:
selection_omega <- all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="yes",false="no")) %>%
  mutate(dataset=if_else(dataset=="gene","gene tree","species tree")) %>%
  ggplot(aes(sig_all,Omega_m0,fill=dataset)) +
  facet_wrap(~dataset) +
  geom_violin(show.legend = F) +
  theme_bw() +
  xlab("under selection\nwith all tests") +
  ylab(expression("m0 model "*omega)) +
  scale_fill_manual(values = c("gene tree"="#44AA99","species tree"="#332288")) +
  theme(panel.grid = element_blank())

overall_omega <- all_res %>%
  mutate(dataset=if_else(dataset=="gene","gene tree","species tree")) %>%
  ggplot(aes(y=Omega_m0,x=dataset,fill=dataset)) +
  geom_violin(show.legend=F) +
  theme_bw() +
  scale_fill_manual(values = c("gene tree"="#44AA99","species tree"="#332288")) +
  theme(panel.grid = element_blank()) +
  ylab(expression("m0 model "*omega))

align_length <- all_res %>%
  mutate(sig_all=if_else(condition=(FDRPval_m1m2<0.05 & FDRPval_m2m2a<0.05 & FDRPval_m7m8<0.05 & FDRPval_m8m8a<0.05 & FDRPval_busted<0.05),true="yes",false="no")) %>%
  mutate(dataset=if_else(dataset=="gene","gene tree","species tree")) %>%
  ggplot(aes(sig_all,length,fill=dataset)) +
  geom_violin(show.legend=F) +
  scale_fill_manual(values = c("gene tree"="#44AA99","species tree"="#332288")) +
  facet_wrap(~dataset) +
  xlab("under selection\nwith all tests") +
  ylab("alignment length") +
  theme_bw() +  
  theme(panel.grid = element_blank())

prop_sig_busted <- ggplot(all_res_gene_ncbi,aes(sig_busted,prop_sel.n)) +
  geom_violin(fill="#44AA99") +
  scale_x_discrete(labels=c("TRUE"="yes","FALSE"="no"))+
  xlab("significant with busted\n(FDR q<0.05)") +
  ylab("prop significant\nlineages") +
  theme_bw() +
  theme(panel.grid = element_blank())

tree_legend <- all_res %>%
  ggplot(aes(x=dataset,fill=dataset)) +
  geom_bar(position="fill") +
  scale_fill_manual(values = c("gene"="#44AA99","species"="#332288"),labels=c("gene" = "gene tree", "species" = "species tree")) +
  guides(fill=guide_legend(override.aes = list(fill= c("gene tree"="#44AA99","species tree"="#332288")))) +
  ylim(1,2)+
  theme_minimal()+
  theme(line = element_blank(),
        axis.text = element_blank(),
        title = element_blank())

plot_grid(selection_omega,overall_omega,tree_legend,align_length,prop_sig_busted,ncol=3,rel_widths=c(1.5,1,1),labels=c("A","B","","C","D"),label_size=12,label_fontface="plain")
ggsave("03_output_general_stats/all_summary_stat_plot_with_legend.pdf",width=8,height=5)

plot_grid(selection_omega,overall_omega,align_length,prop_sig_busted,ncol=2,rel_widths=c(1.5,1),labels=c("A","B","C","D"),label_size=12,label_fontface="plain")
ggsave("03_output_general_stats/all_summary_stat_plot.pdf",width=6,height=5)
#Is there a difference tree length variance between species trees and gene trees?

all_res %>%
  group_by(dataset) %>%
  summarize(SD_tree_length= sd(treelen_m0),median_tree_len = median(treelen_m0))

all_res %>%
  ggplot(aes(treelen_m0)) +
  geom_density() +
  facet_wrap(~dataset)
ggsave("03_output_general_stats/tree_length_gene_vs_species_density.pdf")

all_res %>%
  filter(treelen_m0<30) %>%
  ggplot(aes(treelen_m0)) +
  geom_histogram() +
  facet_wrap(~dataset)
ggsave("03_output_general_stats/tree_length_gene_vs_species_histogram_zoomed.pdf")
