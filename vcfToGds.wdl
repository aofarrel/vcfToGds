version 1.0

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
		File gds

		# ld prune stuff
		Boolean? autosome_only
		Float? ld_r_threshold
		Int? ld_win_size
		Float? maf_threshold
		Float? missing_threshold

		# runtime attributes
		Int? disk
		Float? memory

		# R script -- will eventually be hardcoded
		File debugScript
	}

	command {
		set -eux -o pipefail

		# set defaults
		autosome_only = autosome_only

		echo "Calling R script ld_pruning.R"

		R --vanilla --args ~{gds} < ~{debugScript}
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
		#disks: "local-disk ${disk} SSD"
		#bootDiskSizeGb: 6
		#memory: "${memory} GB"
	}
}

workflow vcfToGds_wf {
	input {
		Array[File] vcf_files
		Int vcfgds_disk
		Int vcfgds_memory

		# R scripts -- will eventually be hardcoded in the Docker container
		# Inputting them like this makes testing a bazillion times faster
		File debugLDprunescript1
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = vcfgds_disk,
				memory = vcfgds_memory
		}
	}

	scatter(gds_file in runGds.out) {
		call runLdPrune {
			input:
				gds = gds_file,
				debugScript = debugLDprunescript1
		}
	}

	meta {
		author: "Tim Majarian"
		email: "tmajaria@broadinstitute.org"
	}
}