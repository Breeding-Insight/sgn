 #SNOPSIS

 #runs phenotypic correlation analysis.
 #Correlation coeffiecients are stored in tabular and json formats 

 #AUTHOR
 # Isaak Y Tecle (iyt2@cornell.edu)


options(echo = FALSE)

library(gplots)
library(ltm)
library(plyr)
library(rjson)
library(lme4)
library(data.table)
library(phenoAnalysis)
#library(rbenchmark)


allargs<-commandArgs()

refererQtl <- grep("qtl",
                   allargs,
                   ignore.case=TRUE,
                   perl=TRUE,
                   value=TRUE
                   )

phenoDataFile <- grep("\\/phenotype_data",
                      allargs,
                      ignore.case=TRUE,
                      perl=TRUE,
                      value=TRUE
                      )

correCoefficientsFile <- grep("corre_coefficients_table",
                              allargs,
                              ignore.case=TRUE,
                              perl=TRUE,
                              value=TRUE
                              )

correCoefficientsJsonFile <- grep("corre_coefficients_json",
                                  allargs,
                                  ignore.case=TRUE,
                                  perl=TRUE,
                                  value=TRUE
                                  )

formattedPhenoFile <- grep("formatted_phenotype_data",
                           allargs,
                           ignore.case = TRUE,
                           fixed = FALSE,
                           value = TRUE
                           )


formattedPhenoData <- c()
phenoData          <- c()



if ( length(refererQtl) != 0 ) {
    
  phenoData <- as.data.frame(fread(phenoDataFile,
                                   sep=",",
                                   na.strings=c("NA", "-", " ", ".", "..")
                                   ))
 
} else {

  phenoData <- as.data.frame(fread(phenoDataFile,
                                   na.strings = c("NA", " ", "--", "-", ".", "..")
                                   ))
} 

allTraitNames <- c()
nonTraitNames <- c()

if (length(refererQtl) != 0) {

  allNames      <- names(phenoData)
  nonTraitNames <- c("ID")
  allTraitNames <- allNames[! allNames %in% nonTraitNames]

} else {

  allNames <- names(phenoData)

  nonTraitNames <- c('studyYear', 'studyDbId', 'studyName', 'studyDesign', 'locationDbId', 'locationName')
  nonTraitNames <- c(nonTraitNames, 'germplasmDbId', 'germplasmName', 'germplasmSynonyms', 'observationLevel')
  nonTraitNames <- c(nonTraitNames, 'observationUnitDbId', 'observationUnitName', 'replicate', 'blockNumber', 'plotNumber')
  
  allTraitNames <- allNames[! allNames %in% nonTraitNames]
 
}

if (!is.null(phenoData) && length(refererQtl) == 0) {
  
  for (i in allTraitNames) {

    if (class(phenoData[, i]) != 'numeric') {
      phenoData[, i] <- as.numeric(as.character(phenoData[, i]))
    }
    
    if (all(is.nan(phenoData$i))) {
      phenoData[, i] <- sapply(phenoData[, i], function(x) ifelse(is.numeric(x), x, NA))                     
    }
  }
}

#phenoData     <- phenoData[, colSums(is.na(phenoData)) < nrow(phenoData)]
#allTraitNames <- names(phenoData)[! names(phenoData) %in% nonTraitNames]

###############################
if (length(refererQtl) == 0  ) {
  cnt   <- 0
 
  for (trait in allTraitNames) {

    cnt   <- cnt + 1
    adjMeans <- getAdjMeans(phenoData, trait)

    if (cnt == 1 ) {
      formattedPhenoData <- adjMeans
    } else {
      formattedPhenoData <-  merge(formattedPhenoData, adjMeans,  all=TRUE)
    }
  }

} else {
  message("qtl stuff")
  formattedPhenoData <- ddply(phenoData,
                              "ID",
                              colwise(mean, na.rm=TRUE)
                              )

  row.names(formattedPhenoData) <- formattedPhenoData[, 1]
  formattedPhenoData[, 1] <- NULL

  formattedPhenoData <- round(formattedPhenoData, digits = 2)
}
 
formattedPhenoData <- data.frame(formattedPhenoData)

coefpvalues <- rcor.test(formattedPhenoData,
                         method="pearson",
                         use="pairwise"
                         )

coefficients <- coefpvalues$cor.mat
allcordata   <- coefpvalues$cor.mat

allcordata[lower.tri(allcordata)] <- coefpvalues$p.values[, 3]
diag(allcordata) <- 1.00

pvalues <- as.matrix(allcordata)

pvalues <- round(pvalues,
                 digits=2
                 )

coefficients <- round(coefficients,
                      digits=3
                      )
 
allcordata   <- round(allcordata,
                    digits=3
                    )

#remove rows and columns that are all "NA"
if ( apply(coefficients,
           1,
           function(x)any(is.na(x))
           )
    ||
    apply(coefficients,
          2,
          function(x)any(is.na(x))
          )
    )
  {
                                                            
    coefficients<-coefficients[-which(apply(coefficients,
                                            1,
                                            function(x)all(is.na(x)))
                                      ),
                               -which(apply(coefficients,
                                            2,
                                            function(x)all(is.na(x)))
                                      )
                               ]
  }


pvalues[upper.tri(pvalues)]           <- NA
coefficients[upper.tri(coefficients)] <- NA
coefficients <- data.frame(coefficients)

coefficients2json <- function(mat) {
  mat <- as.list(as.data.frame(t(mat)))
  names(mat) <- NULL
  toJSON(mat)
}

traits <- colnames(coefficients)

correlationList <- list(
                     "traits" = toJSON(traits),
                     "coefficients " =coefficients2json(coefficients)
                   )

correlationJson <- paste("{",paste("\"", names(correlationList), "\":", correlationList, collapse=","), "}")

correlationJson <- list(correlationJson)

fwrite(coefficients,
       file      = correCoefficientsFile,
       row.names = TRUE,
       sep       = "\t",
       quote     = FALSE,
       )

fwrite(correlationJson,
       file      = correCoefficientsJsonFile,
       col.names = FALSE,
       row.names = FALSE,
       qmethod   = "escape"
       )

if (file.info(formattedPhenoFile)$size == 0 && !is.null(formattedPhenoData) ) {
  fwrite(formattedPhenoData,
         file      = formattedPhenoFile,
         sep       = "\t",
         row.names = TRUE,
         quote     = FALSE,
         )
}


q(save = "no", runLast = FALSE)
