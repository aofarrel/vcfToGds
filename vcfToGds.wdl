version 1.0


task runGds {
	input {
		File vcf
		Int disk
		Float memory
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
	}
	
	command <<<
		set -eux -o pipefail

		echo "Calling R script"
		R --vanilla --args ~{vcf} < /vcfToGds/vcfToGds.R
	>>>

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

task runUniqueVarIDs {
	input {
		File gds
		File DEBUGscript2
		String output_file_name = basename(gds)
	}

	command {
		set -eux -o pipefail

		echo "Calling R script"
		# To debug faster we are passing in the script directly 
		# rather than hardcoding it into the docker container
		#R --vanilla --args ~{gds} 0 < /vcfToGds/uniqueVariantIDs.R

		R --vanilla --args ~{gds} 0 < ~{DEBUGscript2}
	}

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
	}

	output {
		File out = output_file_name
	}
}

task runcheckGds {
	input {
		File gds
		Array[File] vcfs
		File DEBUGscript3
		String vcfname_bgz = basename(sub(gds, "\\.gds$", ".vcf.bgz"))
		String vcfname_gz = basename(sub(gds, "\\.gds$", ".vcf.gz"))
		String vcfname_vcf = basename(sub(gds, "\\.gds$", ".vcf"))
	}

	command <<<
		set -eux -o pipefail

		# Attempt 1
		echo "'~{vcfname_gz}'"

		if [ -e ~{vcfname_bgz} ]; then
			echo "gz vcf found"
			R --vanilla --args ~{gds} ~{vcfname_bgz} < ~{DEBUGscript3}
		else
			echo "matching VCF file not found"
		fi

		# Attempt 2
		BASH_VCFNAME=$(echo ~{gds} | sed 's/\.[^.]*$//')
		BASH_BASE_VCFNAME=$(basename ${BASH_VCFNAME} )

		echo "'${BASH_BASE_VCFNAME}'"

		if [[ -e ${BASH_BASE_VCFNAME}.vcf.gz ]]; then
			echo "gz vcf found"
			R --vanilla --args ~{gds} ~{vcfname_bgz} < ~{DEBUGscript3}
		else
			echo "matching VCF file not found"
		fi

	>>>

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
	}
}

task everything {
	input {
		File vcf
		File DEBUGscript2
		File DEBUGscript3
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
	}

	command <<<
		set -eux -o pipefail

		#######################################
		# Step 1: Convert to GDS
		#######################################
		R --vanilla --args ~{vcf} < /vcfToGds/vcfToGds.R


		#######################################
		# Step 2: Unique IDs
		#######################################
		#R --vanilla --args ~{output_file_name} 0 < ~{DEBUGscript2}

		#######################################
		# Step 3: Check VCF and GDS
		#######################################

		R --vanilla --args ~{output_file_name} ~{vcf} < ~{DEBUGscript3}

	>>>

	runtime {
		docker: "quay.io/aofarrel/vcf2gds:circleci-push"
	}
}

workflow vcfToGds_wf {
	input {
		Array[File] vcf_files
		Int this_disk
		Float this_memory
		File DEBUGscript2
		File DEBUGscript3
	}

	scatter(vcf_file in vcf_files) {
		call everything {
			input:
				vcf = vcf_file,
				DEBUGscript2 = DEBUGscript2,
				DEBUGscript3 = DEBUGscript3
		}
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = this_disk,
				memory = this_memory
		}
	}

	# this seems to keep erroring out and is of questionable utility
	#scatter (gds_file in runGds.out) {
		#call runUniqueVarIDs {
			#input:
				#gds = gds_file,
				#DEBUGscript2 = DEBUGscript2
		#}
	#}

	scatter (gds_file in runGds.out) {
	#scatter (gds_file in runUniqueVarIDs.out) {
		call runcheckGds {
			input:
				gds = gds_file,
				vcfs = vcf_files,
				DEBUGscript3 = DEBUGscript3
		}
	}

	meta {
		author: "Tim Majarian"
		email: "tmajaria@broadinstitute.org"
	}
}