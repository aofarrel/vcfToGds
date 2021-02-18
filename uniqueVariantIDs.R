# Adapted from TOPMed analysis pipeline

library(SeqArray)
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
gdsfile <- unname(config["gds_file"])
chr <- strsplit(chrtype, " ", fixed=TRUE)[[1]]
gds.files <- sapply(chr, function(c) insertChromString(gdsfile, c, "gds_file"))
gds.list <- lapply(gds.files, seqOpen, readonly=FALSE)

## exit gracefully if we only have one file
## this might be a bad idea; 1000 genomes files can throw issues with plink
if (length(gds.list) == 1) {
    message("Only one GDS file; no changes needed. Exiting gracefully.")
    q(save="no", status=0)
}

## get total number of variants
var.length <- sapply(gds.list, function(x) {
    objdesp.gdsn(index.gdsn(x, "variant.id"))$dim
})
seqClose(gds.list[[1]])

id.new <- list(1:var.length[1])
for (c in 2:length(chr)) {
    id.prev <- id.new[[c-1]]
    last.id <- id.prev[length(id.prev)]
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