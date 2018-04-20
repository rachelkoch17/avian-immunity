setwd("~/Dropbox/BirdImmuneGeneEvolution")
library(tidyverse)

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

#How many hogs could be assigned to both a chicken or zebra finch gene ID?
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
model_res %>%
  mutate_at(paste0("V",3:9,"_perc"),funs(round(. / V2),2), V3:V9)

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

#Plot distribution of m0 model
ggplot(all_res,aes(Omega_m0)) +
  geom_histogram(bins=40, fill = "lightblue") +
  facet_grid(~dataset)
ggsave("03_output_general_stats/m0_Omega_distribution.pdf",width=10, height=6)

#Compare the number of significant branches with signficant vs. not significant under BUSTED with Mann-Whitney U test
all_res %>%  
  mutate(sig_busted = FDRPval_busted < 0.05) %>%
  group_by(dataset) %>%
  do(w=wilcox.test(prop_sel.n~sig_busted), data=., paired=FALSE)
  
all_res_gene_ncbi <- all_res_gene_ncbi %>%  
  mutate(sig_busted = FDRPval_busted < 0.05)

wilcox.test(all_res_gene_ncbi$prop_sel.n~all_res_gene_ncbi$sig_busted, paired=FALSE)

#Make a figure
ggplot(all_res_gene_ncbi,aes(sig_busted,prop_sel.n)) +
  geom_violin(fill="lightblue") +
  xlab("significant with busted (FDR q<0.05)") +
  ylab("prop significant lineages")
ggsave("03_output_general_stats/busted_bsrel_genetree_sign_prop.pdf",height=5,width=5)