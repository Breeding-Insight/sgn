 #SNOPSIS

 #runs k-means or k-medoids cluster analysis

 #AUTHOR
 # Isaak Y Tecle (iyt2@cornell.edu)


options(echo = FALSE)

library(randomForest)
library(data.table)
library(genoDataFilter)
library(tibble)
library(dplyr)
library(fpc)
library(cluster)
library(ggfortify)
#library(factoextra)



allArgs <- commandArgs()

outputFile  <- grep("output_files", allArgs, value = TRUE)
outputFiles <- scan(outputFile, what = "character")

inputFile  <- grep("input_files", allArgs, value = TRUE)
inputFiles <- scan(inputFile, what = "character")

kResultFile <- grep("result", outputFiles, value = TRUE)
reportFile  <- grep("report", outputFiles, value = TRUE)
errorFile   <- grep("error", outputFiles, value = TRUE)

combinedDataFile <- grep("combined_cluster_data_file", outputFiles, value = TRUE)

plotPamFile      <- grep("plot_pam", outputFiles, value = TRUE)
plotKmeansFile   <- grep("plot_kmeans", outputFiles, value = TRUE)

message("k means result file: ", kResultFile)
message("k means plot file: ", plotKmeansFile)


if (is.null(kResultFile))
{
  stop("Scores output file is missing.")
  q("no", 1, FALSE) 
}

genoData <- c()
genoMetaData <- c()

filteredGenoFile <- c()

if (length(inputFiles) > 1 ) {   
    allGenoFiles <- inputFiles

    message('allGenoFiles: ', allGenoFiles)
    genoData <- combineGenoData(allGenoFiles)
    
    genoMetaData   <- genoData$trial
    genoData$trial <- NULL
 
} else {
    genoDataFile <- grep("genotype_data", inputFiles,  value = TRUE)
    genoData     <- fread(genoDataFile, na.strings = c("NA", " ", "--", "-", "."))
    genoData     <- unique(genoData, by='V1')
 
   filteredGenoFile <- grep("filtered_genotype_data_",  genoDataFile, value = TRUE)

    if (!is.null(genoData)) { 

        genoData <- data.frame(genoData)
        genoData <- column_to_rownames(genoData, 'V1')
    
    } else {
        genoData <- fread(filteredGenoFile)
    }
}

if (is.null(genoData)) {
  stop("There is no genotype dataset.")
  q("no", 1, FALSE)
}


genoDataMissing <- c()
if (is.null(filteredGenoFile) == TRUE) {
    ##genoDataFilter::filterGenoData
    
    genoData <- filterGenoData(genoData, maf=0.01)
    genoData <- column_to_rownames(genoData, 'rn')

    message("No. of geno missing values, ", sum(is.na(genoData)) )
    if (sum(is.na(genoData)) > 0) {
        genoDataMissing <- c('yes')
        genoData <- na.roughfix(genoData)
    }
}

genoData <- data.frame(genoData)

set.seed(235)


pca    <- prcomp(genoData, retx=TRUE)
pca    <- summary(pca)

variances <- data.frame(pca$importance)

varProp        <- variances[3, ]
varProp        <- data.frame(t(varProp))
names(varProp) <- c('cumVar')

selectPcs <- varProp %>% filter(cumVar <= 0.9) 
pcsCnt    <- nrow(selectPcs)

pcsNote <- paste0('Before clustering this dataset, principal component analysis (PCA) was done on it. ')
pcsNote <- paste0(pcsNote, 'Based on the PCA, ', pcsCnt, ' PCs are used to cluster this dataset. ')
pcsNote <- paste0(pcsNote, 'They explain 90% of the variance in the original dataset.')
cat(pcsNote, file=reportFile, sep="\n", append=TRUE)

scores   <- data.frame(pca$x)
scores   <- scores[, 1:pcsCnt]
scores   <- round(scores, 3)

variances <- variances[2, 1:pcsCnt]
variances <- round(variances, 4) * 100
variances <- data.frame(t(variances))

kMeansOut <- kmeansruns(scores, runs=10)
recK <- paste0('Recommended number of clusters (k) for this data set is: ', kMeansOut$bestk)
cat(recK, file=reportFile, sep="\n", append=TRUE)

kCenters         <- kMeansOut$bestk
kMeansOut        <- kmeans(scores, centers=kCenters, nstart=10)
kClusters        <- data.frame(kMeansOut$cluster)
kClusters        <- rownames_to_column(kClusters)
names(kClusters) <- c('Genotypes', 'Cluster')
kClusters        <- kClusters %>% arrange(Cluster)

png(plotKmeansFile)
autoplot(kMeansOut, data=scores, frame = TRUE,  x=1, y=2)
dev.off()

#png(plotPamFile)
#autoplot(pam(genoData, 3), frame = TRUE, frame.type = 'norm', x=1, y=2)
#dev.off()


if (length(inputFiles) > 1) {
    fwrite(genoData,
       file      = combinedDataFile,
       sep       = "\t",
       row.names = TRUE,
       quote     = FALSE,
       )

}

if (!is.null(kResultFile)) {
    fwrite(kClusters,
       file      = kResultFile,
       sep       = "\t",
       row.names = FALSE,
       quote     = FALSE,
       )

}

####
q(save = "no", runLast = FALSE)
####
