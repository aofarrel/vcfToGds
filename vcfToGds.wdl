version 1.0

# Cromwell has a bug where it cannot properly recognize certain comments as, well, comments
# Lines marked with "##goto X" are how I have to keep track of the location of certain
# commented-out things; basically putting the problematic comment in a place Cromwell does
# not parse.

task runGds {
	input {
		File vcf
		Int disk
		Int memory
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
	}
	
	command {
		set -eux -o pipefail

		echo "Calling R script vcfToGds.R"

		R --vanilla --args ~{vcf} < /vcfToGds/vcfToGds.R
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}

	output {
		File out = output_file_name
	}
}

task runLdPrune{
	input {

		# Array version
		##goto A

		# File version
		File gds

		# ld prune stuff
		Boolean autosome_only
		Boolean exclude_pca_corr
		String genome_build
		Float ld_r_threshold
		Int ld_win_size
		Float maf_threshold
		Float missing_threshold

		# runtime attributes
		Int disk
		Int memory

		# R script -- will eventually be hardcoded
		File debugScript
	}

	command {
		set -eux -o pipefail

		echo "Calling R script ld_pruning.R"

		# File version
		R --vanilla --args ~{gds} ~{autosome_only} ~{exclude_pca_corr} ~{genome_build} ~{ld_r_threshold} ~{ld_win_size} ~{maf_threshold} ~{missing_threshold} < ~{debugScript}

		# Array version
		##goto B
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}

	output {
		File out = "pruned_variants.RData"
	}

}
##goto A
		#File gds
##goto B
		#R --vanilla --args ~{sep="," gds} ~{autosome_only} ~{exclude_pca_corr} ~{genome_build} ~{ld_r_threshold} ~{ld_win_size} ~{maf_threshold} ~{missing_threshold} < ~{debugScript}

task runSubsetGds {
	input {
		File gds
		String output_name

		# R script
		File debugScript
	}
	command {
		set -eux -o pipefail

		WOW=$(echo $RANDOM)
		COOL=$("$WOW~{output_name}")

		echo "Calling R script runSubsetGds.R"

		R --vanilla --args ~{gds} $(COOL) < ~{debugScript}
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
	}

	output {
		File out = "subsetted.gds"
	}

}

task runMergeGds {
	input {
		Array[File] gds_array
		String merged_name

		# R script, will eventually be hardcoded
		File debugScript
	}

	command {
		set -eux -o pipefail

		echo "Calling R script runMergeGds.R"

		R --vanilla --args ~{sep="," gds_array} ~{merged_name} < ~{debugScript}
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
	}

	output {
		File out = "merged.gds"
	}
}

workflow vcfToGds_wf {
	input {
		Array[File] vcf_files
		Int vcfgds_disk
		Int vcfgds_memory

		# ld prune stuff
		Int ldprune_disk
		Int ldprune_memory
		
		Boolean? ldprune_autosome_only
		Boolean? ldprune_exclude_pca_corr
		String? ldprune_genome_build
		Float? ldprune_ld_r_threshold
		Int? ldprune_ld_win_size
		Float? ldprune_maf_threshold
		Float? ldprune_missing_threshold

		# R scripts -- will eventually be hardcoded in the Docker container
		# Inputting them like this makes testing a bazillion times faster
		File debugLDprunescript1
		File debugLDprunescript2
		File debugLDprunescript3
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = vcfgds_disk,
				memory = vcfgds_memory
		}
	}

	scatter(gds_file in runGds.out) { # Comment out for array version
		call runLdPrune {
			input:
				gds = gds_file, # File version
				#gds = runGds.out, # Array version
				disk = ldprune_disk,
				memory = ldprune_memory,
				autosome_only = select_first([ldprune_autosome_only, false]),
				exclude_pca_corr = select_first([ldprune_exclude_pca_corr, true]),
				genome_build = select_first([ldprune_genome_build, "hg38"]),
				ld_r_threshold = select_first([ldprune_ld_r_threshold, 0.32]),
				ld_win_size = select_first([ldprune_ld_win_size, 10]),
				maf_threshold = select_first([ldprune_maf_threshold, 0.01]),
				missing_threshold = select_first([ldprune_missing_threshold, 0.01]),
				debugScript = debugLDprunescript1
		}
	}
	scatter(gds_file in runGds.out) {
		call runSubsetGds {
			input:
				gds = gds_file,
				output_name = "subsetted.gds",
				debugScript = debugLDprunescript2
		}

	}
	call runMergeGds {
		input:
			gds_array = runSubsetGds.out,
			merged_name = "merged.gds",
			debugScript = debugLDprunescript3
	}

	meta {
		author: "Tim Majarian"
		email: "tmajaria@broadinstitute.org"
	}
}