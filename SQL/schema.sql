CREATE TABLE IF NOT EXISTS `mouse_gene` (
	`gene_accession_id` VARCHAR(32) NOT NULL,
	`gene_symbol` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`gene_accession_id`)
);


CREATE TABLE IF NOT EXISTS `human_gene` (
	`human_gene_id` BIGINT NOT NULL AUTO_INCREMENT,
	`human_gene_symbol` VARCHAR(64) NOT NULL,
	`human_gene_name` VARCHAR(255) NOT NULL,
	`human_entrez_gene_id` VARCHAR(32) NOT NULL,
	`hgnc_id` VARCHAR(32) NOT NULL,
	PRIMARY KEY(`human_gene_id`)
);


CREATE TABLE IF NOT EXISTS `IMPC_parameter_description` (
	`parameter_id` VARCHAR(64) NOT NULL,
	`impcParameterOrigId` VARCHAR(64) NOT NULL,
	`parameter_name` VARCHAR(255) NOT NULL,
	`description` TEXT NOT NULL,
	PRIMARY KEY(`parameter_id`)
);


CREATE TABLE IF NOT EXISTS `IMPC_procedure` (
	`procedure_id` BIGINT NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	`description` TEXT NOT NULL,
	`isMandatory` BOOLEAN NOT NULL,
	`impcParameterOrigId` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`procedure_id`)
);


CREATE TABLE IF NOT EXISTS `IMPC_procedure_parameter` (
	`procedure_id` BIGINT NOT NULL,
	`parameter_id` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`procedure_id`, `parameter_id`)
);


CREATE TABLE IF NOT EXISTS `parameter_group` (
	`group_id` INTEGER NOT NULL,
	`group_name` VARCHAR(128) NOT NULL UNIQUE,
	PRIMARY KEY(`group_id`)
);


CREATE TABLE IF NOT EXISTS `parameter_group_member` (
	`group_id` INTEGER NOT NULL,
	`parameter_id` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`group_id`, `parameter_id`)
);


CREATE TABLE IF NOT EXISTS `clean_wide_data` (
	`result_id` BIGINT NOT NULL AUTO_INCREMENT,
	`source_file` VARCHAR(255) NOT NULL,
	`analysis_id` VARCHAR(128) NOT NULL,
	`gene_accession_id` VARCHAR(32) NOT NULL,
	`gene_symbol` VARCHAR(64) NOT NULL,
	`allele_symbol` VARCHAR(128) NOT NULL,
	`strain_name` VARCHAR(128) NOT NULL,
	`mouse_life_stage` VARCHAR(64) NOT NULL,
	`parameter_id` VARCHAR(64) NOT NULL,
	`parameter_name` VARCHAR(255) NOT NULL,
	`pvalue` DOUBLE NOT NULL,
	PRIMARY KEY(`result_id`)
);


CREATE TABLE IF NOT EXISTS `lacz_expression` (
	`result_id` BIGINT NOT NULL,
	`lacz_blood` VARCHAR(64) NOT NULL,
	`lacz_brain` VARCHAR(64) NOT NULL,
	`lacz_colon` VARCHAR(64) NOT NULL,
	`lacz_eye` VARCHAR(64) NOT NULL,
	`lacz_heart` VARCHAR(64) NOT NULL,
	`lacz_kidney` VARCHAR(64) NOT NULL,
	`lacz_liver` VARCHAR(64) NOT NULL,
	`lacz_lung` VARCHAR(64) NOT NULL,
	`lacz_skeletal_muscle` VARCHAR(64) NOT NULL,
	`lacz_skin` VARCHAR(64) NOT NULL,
	`lacz_vascular_system` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`result_id`)
);


CREATE TABLE IF NOT EXISTS `bespokeTask` (
	`bespoke_task_id` BIGINT NOT NULL AUTO_INCREMENT,
	`human_gene_symbol` VARCHAR(64) NOT NULL,
	`human_entrez_gene_id` VARCHAR(32) NOT NULL,
	`gene_symbol` VARCHAR(64) NOT NULL,
	`gene_accession_id` VARCHAR(32) NOT NULL,
	`high_level_mp_ids` TEXT NOT NULL,
	`human_gene_id` BIGINT NOT NULL,
	PRIMARY KEY(`bespoke_task_id`)
);


CREATE TABLE IF NOT EXISTS `mp_terms` (
	`mp_term_id` VARCHAR(32) NOT NULL,
	`mp_term_name` VARCHAR(255) NOT NULL,
	PRIMARY KEY(`mp_term_id`)
);


CREATE TABLE IF NOT EXISTS `bespokeTask_mp` (
	`bespoke_task_id` BIGINT NOT NULL,
	`mp_term_id` VARCHAR(32) NOT NULL,
	PRIMARY KEY(`bespoke_task_id`, `mp_term_id`)
);


CREATE TABLE IF NOT EXISTS `human_diseases` (
	`do_term_id` VARCHAR(32) NOT NULL,
	`do_term_name` VARCHAR(255) NOT NULL,
	PRIMARY KEY(`do_term_id`)
);


CREATE TABLE IF NOT EXISTS `Disease_information` (
	`disease_information_id` BIGINT NOT NULL AUTO_INCREMENT,
	`human_gene_symbol` VARCHAR(64) NOT NULL,
	`human_gene_name` VARCHAR(255) NOT NULL,
	`hgnc_id` VARCHAR(32) NOT NULL,
	`do_term_name` VARCHAR(255) NOT NULL,
	`do_term_id` VARCHAR(32) NOT NULL,
	`mouse_genotype_ids` TEXT NOT NULL,
	`gene_symbol` VARCHAR(64) NOT NULL,
	`gene_accession_id` VARCHAR(32) NOT NULL,
	`human_gene_id` BIGINT NOT NULL,
	PRIMARY KEY(`disease_information_id`)
);


CREATE TABLE IF NOT EXISTS `Disease_information_genotype` (
	`disease_information_id` BIGINT NOT NULL,
	`mouse_genotype_id` VARCHAR(255) NOT NULL,
	PRIMARY KEY(`disease_information_id`, `mouse_genotype_id`)
);


CREATE TABLE IF NOT EXISTS `chrom2_transcript` (
	`transcript_stable_id` VARCHAR(64) NOT NULL,
	`gene_stable_id` VARCHAR(64) NOT NULL,
	`gene_symbol` VARCHAR(64) NOT NULL,
	PRIMARY KEY(`transcript_stable_id`)
);


CREATE TABLE IF NOT EXISTS `chrom2` (
	`chrom2_row_id` BIGINT NOT NULL AUTO_INCREMENT,
	`transcript_stable_id` VARCHAR(64) NOT NULL,
	`exon_stable_id` VARCHAR(64) NOT NULL,
	`exon_start_bp` BIGINT NOT NULL,
	`exon_end_bp` BIGINT NOT NULL,
	`exon_rank` INTEGER NOT NULL,
	PRIMARY KEY(`chrom2_row_id`)
);


CREATE TABLE IF NOT EXISTS `parameter_group_external_data` (
	`external_record_id` BIGINT NOT NULL AUTO_INCREMENT,
	`group_id` INTEGER NOT NULL,
	`resource_name` VARCHAR(128) NOT NULL,
	`external_id` VARCHAR(64) NOT NULL,
	`term_or_label` VARCHAR(255) NOT NULL,
	`notes` TEXT NOT NULL,
	`gene_accession_id` VARCHAR(32) NOT NULL,
	PRIMARY KEY(`external_record_id`)
);


ALTER TABLE `IMPC_procedure_parameter`
ADD FOREIGN KEY(`procedure_id`) REFERENCES `IMPC_procedure`(`procedure_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `IMPC_procedure_parameter`
ADD FOREIGN KEY(`parameter_id`) REFERENCES `IMPC_parameter_description`(`parameter_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `parameter_group_member`
ADD FOREIGN KEY(`group_id`) REFERENCES `parameter_group`(`group_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `parameter_group_member`
ADD FOREIGN KEY(`parameter_id`) REFERENCES `IMPC_parameter_description`(`parameter_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `clean_wide_data`
ADD FOREIGN KEY(`gene_accession_id`) REFERENCES `mouse_gene`(`gene_accession_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `clean_wide_data`
ADD FOREIGN KEY(`parameter_id`) REFERENCES `IMPC_parameter_description`(`parameter_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `lacz_expression`
ADD FOREIGN KEY(`result_id`) REFERENCES `clean_wide_data`(`result_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `bespokeTask`
ADD FOREIGN KEY(`gene_accession_id`) REFERENCES `mouse_gene`(`gene_accession_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `bespokeTask`
ADD FOREIGN KEY(`human_gene_id`) REFERENCES `human_gene`(`human_gene_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `bespokeTask_mp`
ADD FOREIGN KEY(`bespoke_task_id`) REFERENCES `bespokeTask`(`bespoke_task_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `bespokeTask_mp`
ADD FOREIGN KEY(`mp_term_id`) REFERENCES `mp_terms`(`mp_term_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `Disease_information`
ADD FOREIGN KEY(`gene_accession_id`) REFERENCES `mouse_gene`(`gene_accession_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `Disease_information`
ADD FOREIGN KEY(`human_gene_id`) REFERENCES `human_gene`(`human_gene_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `Disease_information`
ADD FOREIGN KEY(`do_term_id`) REFERENCES `human_diseases`(`do_term_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `Disease_information_genotype`
ADD FOREIGN KEY(`disease_information_id`) REFERENCES `Disease_information`(`disease_information_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `chrom2`
ADD FOREIGN KEY(`transcript_stable_id`) REFERENCES `chrom2_transcript`(`transcript_stable_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `parameter_group_external_data`
ADD FOREIGN KEY(`group_id`) REFERENCES `parameter_group`(`group_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE `parameter_group_external_data`
ADD FOREIGN KEY(`gene_accession_id`) REFERENCES `mouse_gene`(`gene_accession_id`)
ON UPDATE NO ACTION ON DELETE NO ACTION;