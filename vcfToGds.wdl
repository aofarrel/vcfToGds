version 1.0

task runGds {
	input {
		File vcf
		Int disk
		Float memory
	}
	
	command {
		set -eux -o pipefail

		echo "Calling R script"
		<&2 echo $(ls)

		R --vanilla --args ~{vcf} < /vcfToGds/vcfToGds.R
	}

	runtime {
		docker: "manninglab/vcftogds:latest"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}

	output {
		# there should be a way to avoid using globs...
		Array[File] out_raw_gds = glob("*.gds")
	}
}

task runUniqueVarIDs {
	input {
		File gds
	}

	command {
		set -eux -o pipefail

		echo "Calling R script"
		<&2 echo $(ls)
		<&2 echo $(tree)

		R --vanilla --args ~{gds} < /vcfToGds/uniqueVariantIDs.R
	}

	runtime {
		docker: "manninglab/vcftogds:latest"
	}

	output {
		Array[File] out_gds_unique = glob("*.gds")
	}
}

workflow vcfToGds_wf {
	input {
		Array[File] vcf_files
		Int this_disk
		Float this_memory
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = this_disk,
				memory = this_memory
		}
		scatter(one_gds in runGds.out_raw_gds) { # crappy workaround to runGds outputting a blob
			call runUniqueVarIDs {
				input:
					gds = one_gds
			}
		}
	}

	meta {
		author: "Tim Majarian"
		email: "tmajaria@broadinstitute.org"
	}
}