# vcfToGds - Convert vcf files to gds format

## Description 

This workflow converts files in Variant Call Format (VCF) to Genomic Data Structure format (GDS). It attempts to implement the first step of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline), itself a five-part process.

### Authors

Although this workflow is forked from one produced by the [Manning Lab](https://manning-lab.github.io/), this fork is maintained by UCSC.

Contributing authors include:
* Tim Majarian (tmajaria@broadinstitute.org)
* Ash O'Farrell (aofarrel@ucsc.edu)

It is based on the University of Washington pipeline which has its own edit and contribution history.

## Dependencies

### Workflow execution

* [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart)
* [Cromwell](http://cromwell.readthedocs.io/en/develop/)

### R packages

* [SeqArray](https://www.bioconductor.org/packages/release/bioc/html/SeqArray.html)

## Workflow Inputs
All workflow inputs go into one JSON file. With that being said, because this is a big pipeline, this README breaks them down in catagory per R script they apply to.

### VCF to GDS Conversion
#### Required
* vcf : an *array of vcf files* in vcf, .vcf.bgz, or .vcf.gz format
* vcfgds_disk : *int* of disk space to allot for vcfToGds.R
* vcfgds_memory : *int* of memory to allot for vcfToGds.R

### LD Prune
This stage automatically takes in the GDS output of the previous step.
#### Optional
* autosome_only : *bool* of whether or not to only ld prune on autosomes (default is false, which is the **opposite** of the default of [the pipeline this is based on](https://github.com/UW-GAC/analysis_pipeline) as it expected users will be inputing one VCF per chr therefore if they wanted to exclude not-autosomes then they'd excluded them from the inputs)
* ld_r_threshold : *float*
* ld_win_size : *int* of window size (default: 10)
* maf_threshold : *float* of minor allele frequency threshold (default: 0.01)



### vcfToGds.R
This script is the main function for converting vcf to gds. It uses the SeqArray package in R.

Inputs:
* vcf : a file in vcf, .vcf.bgz, or .vcf.gz format
* disk : amount of disk space to allot for each job
* memory : amount of memory to allot for each job

Outputs :
* out_file : GDS file matching the name of the input vds with ".gds" appeneded to the end


## Limitations
The U of W version of this pipeline can accept BCF files as valid input. Currently this pipeline does not use bcftools and therefore cannot handle bcf files.

