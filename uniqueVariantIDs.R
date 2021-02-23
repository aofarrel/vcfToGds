# Adapted from TOPMed analysis pipeline

library(SeqArray)
library(TopmedPipeline)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gds_file <- args[1]
chr_kind <- args[2]

if (chr_kind == 0) {
    chrtype <- "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X"
}
if (chr_kind == 1) {
    chrtype <- "Y"
}

## gds file has two parts split by chromosome identifier

######################## debug zone ########################
#
#gdsfile <- unname(config["gds_file"])
#
# If we comment this out to avoid usage of the config (which
# doesn't exist in the WDL context), we also avoid using
# the unname function. however, it is (theorhetically) accounted
# for by the addition of unname() around the gds_file input
# on insertChromString. however, as noted below, we are
# getting a blank space error in that function...
############################################################


chr <- strsplit(chrtype, " ", fixed=TRUE)[[1]]

######################## debug zone ########################
# This always seems to throw the blank space error.
#
#gds.files <- sapply(chr, function(c) insertChromString(unname(gds_file), c, "gds_file"))
#
# The function, which is imported from TopmedPipeline, is as follows:
#
#' Format a string by inserting chromosome into a blank space
#'
#' @param x Character string
#' @param chr Chromosome number (or character) to instert
#' @param err If not \code{NULL}, print this string with an error message about requiring a blank space
#' @return String \code{x} with \code{chr} inserted into blank space
#'
#' @export
#insertChromString <- function(x, chr, err=NULL) {
    #if (!is.null(err) & !(grepl(" ", x, fixed=TRUE))) {
        #stop(paste(err, "must have a blank space to insert chromosome number"))
    #}
    #sub(" ", chr, x, fixed=TRUE)
#}
############################################################


gds.files <- gds_file
gds.list <- lapply(gds.files, seqOpen, readonly=FALSE)


######################## debug zone ########################
## exit gracefully if we only have one file
## this might be a bad idea; 1000 genomes files can throw issues with plink
#if (length(gds.list) == 1) {
    #message("Only one GDS file; no changes needed. Exiting gracefully.")
    #q(save="no", status=0)
#}

# due to how scattering in WDL works, the above will always
# exit gracefully if left uncommented. later on in we use
# PLINK, which throws a fit if variant IDs are not unique,
# so we probably cannot allow for this to be uncommented.
############################################################

## get total number of variants
var.length <- sapply(gds.list, function(x) {
    objdesp.gdsn(index.gdsn(x, "variant.id"))$dim
})
seqClose(gds.list[[1]])
message(var.length)

######################## debug zone ########################
# we crash somewhere in this upcoming block, likely line 97
#
# Error in (last.id + 1):(last.id + var.length[c]) : NA/NaN argument
######################## debug zone ########################

id.new <- list(1:var.length[1])
for (c in 2:length(chr)) {
    id.prev <- id.new[[c-1]]
    last.id <- id.prev[length(id.prev)]
    message(id.prev)
    message(last.id)
    message(var.length[c])
    id.new[[c]] <- (last.id + 1):(last.id + var.length[c])
    stopifnot(length(id.new[[c]]) == var.length[c])
}

for (c in 2:length(chr)) {
    node <- index.gdsn(gds.list[[c]], "variant.id")
    desc <- objdesp.gdsn(node)
    stopifnot(desc$dim == length(id.new[[c]]))
    compress <- desc$compress
    compression.gdsn(node, "")
    write.gdsn(node, id.new[[c]])
    compression.gdsn(node, compress)
    seqClose(gds.list[[c]])
}

# mem stats
ms <- gc()
cat(">>> Max memory: ", ms[1,6]+ms[2,6], " MB\n")