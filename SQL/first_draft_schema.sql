-- THIS IS THE FIRST DRAFT
  
-- Group 14 IMPC: revised 18-table CREATE TABLE definitions.
-- Group 14 IMPC database: revised 18-table schema for the accepted eight CSV inputs.
-- MySQL 8.0 / InnoDB / utf8mb4.
-- IMPORTANT: Run against an EMPTY data_base_merged_revised schema (or migrate existing tables
-- separately). CREATE TABLE does not modify pre-existing table structures.
-- Do NOT disable foreign-key checks to force incompatible data into the database.

CREATE DATABASE IF NOT EXISTS data_base_merged
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE data_base_merged;

-- 1. Mouse MGI reference, union of four mouse-gene sources.
CREATE TABLE mouse_gene (
    gene_accession_id VARCHAR(32) NOT NULL,
    gene_symbol VARCHAR(128),
    PRIMARY KEY (gene_accession_id),
    INDEX idx_mouse_gene_symbol (gene_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Human identifiers. Entrez and HGNC records remain distinct until verified.
CREATE TABLE human_gene (
    human_gene_id BIGINT NOT NULL,
    human_gene_symbol VARCHAR(128),
    human_gene_name VARCHAR(255),
    human_entrez_gene_id VARCHAR(64),
    hgnc_id VARCHAR(64),
    PRIMARY KEY (human_gene_id),
    UNIQUE KEY uq_human_entrez (human_entrez_gene_id),
    UNIQUE KEY uq_human_hgnc (hgnc_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Procedure is identified by the supplied procedure_code.
CREATE TABLE IMPC_procedure (
    procedure_code VARCHAR(16) NOT NULL,
    procedure_name VARCHAR(255),
    procedure_description TEXT,
    is_mandatory TINYINT(1),
    PRIMARY KEY (procedure_code),
    CONSTRAINT chk_proc_mandatory CHECK (is_mandatory IS NULL OR is_mandatory IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Each parameter belongs to at most one procedure in the supplied catalogue.
-- The obsolete IMPC_procedure_parameter table is intentionally omitted;
-- the direct procedure_code foreign key avoids storing the same association twice.
CREATE TABLE IMPC_parameter_description (
    parameter_id VARCHAR(64) NOT NULL,
    parameter_name VARCHAR(255) NOT NULL,
    parameter_description TEXT,
    procedure_code VARCHAR(16),
    impc_parameter_orig_id BIGINT,
    PRIMARY KEY (parameter_id),
    INDEX idx_param_procedure_code (procedure_code),
    INDEX idx_param_original_id (impc_parameter_orig_id),
    CONSTRAINT fk_parameter_procedure FOREIGN KEY (procedure_code)
        REFERENCES IMPC_procedure(procedure_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Six phenotype parameter groups.
CREATE TABLE parameter_group (
    group_id INT NOT NULL,
    group_name VARCHAR(128) NOT NULL,
    PRIMARY KEY (group_id),
    UNIQUE KEY uq_group_name (group_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Many-to-many parameter/group membership.
CREATE TABLE parameter_group_member (
    group_id INT NOT NULL,
    parameter_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (group_id, parameter_id),
    INDEX idx_groupmember_parameter (parameter_id),
    CONSTRAINT fk_groupmember_group FOREIGN KEY (group_id)
        REFERENCES parameter_group(group_id),
    CONSTRAINT fk_groupmember_parameter FOREIGN KEY (parameter_id)
        REFERENCES IMPC_parameter_description(parameter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. One row per phenotype analysis; lacZ and parameter descriptions are separate.
CREATE TABLE clean_data (
    result_id BIGINT NOT NULL,
    analysis_id VARCHAR(128) NOT NULL,
    source_file VARCHAR(512),
    gene_accession_id VARCHAR(32),
    gene_symbol VARCHAR(128),
    allele_symbol VARCHAR(255),
    strain_name VARCHAR(255),
    parameter_id VARCHAR(64),
    pvalue DOUBLE,
    mouse_life_stage VARCHAR(64),
    PRIMARY KEY (result_id),
    INDEX idx_analysis_id (analysis_id),
    INDEX idx_results_gene (gene_accession_id),
    INDEX idx_results_param (parameter_id),
    INDEX idx_results_gene_symbol (gene_symbol),
    CONSTRAINT fk_result_mouse FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene(gene_accession_id),
    CONSTRAINT fk_result_param FOREIGN KEY (parameter_id)
        REFERENCES IMPC_parameter_description(parameter_id),
    CONSTRAINT chk_result_pvalue CHECK
        (pvalue IS NULL OR (pvalue >= 0 AND pvalue <= 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. One lacZ record per phenotype analysis (11 tissue columns).
CREATE TABLE lacz_expression (
    result_id BIGINT NOT NULL,
    lacz_blood VARCHAR(64),
    lacz_brain VARCHAR(64),
    lacz_colon VARCHAR(64),
    lacz_eye VARCHAR(64),
    lacz_heart VARCHAR(64),
    lacz_kidney VARCHAR(64),
    lacz_liver VARCHAR(64),
    lacz_lung VARCHAR(64),
    lacz_skeletal_muscle VARCHAR(64),
    lacz_skin VARCHAR(64),
    lacz_vascular_system VARCHAR(64),
    PRIMARY KEY (result_id),
    CONSTRAINT fk_lacz_result FOREIGN KEY (result_id)
        REFERENCES clean_data(result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Original human-mouse orthology / bespoke task records.
CREATE TABLE bespokeTask (
    bespoke_task_id BIGINT NOT NULL,
    human_gene_symbol VARCHAR(128),
    human_entrez_gene_id VARCHAR(64),
    gene_symbol VARCHAR(128),
    gene_accession_id VARCHAR(32),
    high_level_mp_ids TEXT,
    in_impc_dataset TINYINT(1),
    human_gene_id BIGINT,
    PRIMARY KEY (bespoke_task_id),
    INDEX idx_bespoke_gene_pair (human_entrez_gene_id, gene_accession_id),
    INDEX idx_bespoke_mouse (gene_accession_id),
    INDEX idx_bespoke_human (human_gene_id),
    CONSTRAINT fk_bespoke_mouse FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene(gene_accession_id),
    CONSTRAINT fk_bespoke_human FOREIGN KEY (human_gene_id)
        REFERENCES human_gene(human_gene_id),
    CONSTRAINT chk_bespoke_in_impc CHECK
        (in_impc_dataset IS NULL OR in_impc_dataset IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Distinct Mammalian Phenotype ontology IDs.
CREATE TABLE mp_terms (
    mp_term_id VARCHAR(32) NOT NULL,
    mp_term_name VARCHAR(255),
    PRIMARY KEY (mp_term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. One bespoke-to-MP link per MP ID.
CREATE TABLE bespokeTask_mp (
    bespoke_task_id BIGINT NOT NULL,
    mp_term_id VARCHAR(32) NOT NULL,
    PRIMARY KEY (bespoke_task_id, mp_term_id),
    INDEX idx_bespoke_mp_term (mp_term_id),
    CONSTRAINT fk_bespokemp_bespoke FOREIGN KEY (bespoke_task_id)
        REFERENCES bespokeTask(bespoke_task_id),
    CONSTRAINT fk_bespokemp_term FOREIGN KEY (mp_term_id)
        REFERENCES mp_terms(mp_term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Distinct Disease Ontology IDs.
CREATE TABLE human_diseases (
    do_term_id VARCHAR(32) NOT NULL,
    do_term_name VARCHAR(255),
    PRIMARY KEY (do_term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. Original human-gene/disease associations, with mouse ortholog information.
CREATE TABLE Disease_information (
    disease_information_id BIGINT NOT NULL,
    human_gene_symbol VARCHAR(128),
    human_gene_name VARCHAR(255),
    hgnc_id VARCHAR(64),
    do_term_name VARCHAR(255),
    do_term_id VARCHAR(32),
    mouse_genotype_ids TEXT,
    gene_symbol VARCHAR(128),
    gene_accession_id VARCHAR(32),
    human_gene_id BIGINT,
    PRIMARY KEY (disease_information_id),
    INDEX idx_disease_hgnc_do (hgnc_id, do_term_id),
    INDEX idx_disease_mouse (gene_accession_id),
    INDEX idx_disease_term (do_term_id),
    INDEX idx_disease_human (human_gene_id),
    CONSTRAINT fk_disease_mouse FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene(gene_accession_id),
    CONSTRAINT fk_disease_human FOREIGN KEY (human_gene_id)
        REFERENCES human_gene(human_gene_id),
    CONSTRAINT fk_disease_do FOREIGN KEY (do_term_id)
        REFERENCES human_diseases(do_term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. Pipe-delimited genotype lists expanded to atomic associations.
CREATE TABLE Disease_information_genotype (
    disease_information_id BIGINT NOT NULL,
    mouse_genotype_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (disease_information_id, mouse_genotype_id),
    INDEX idx_disease_genotype_id (mouse_genotype_id),
    CONSTRAINT fk_diseasegenotype_record FOREIGN KEY (disease_information_id)
        REFERENCES Disease_information(disease_information_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 15. NEW: Ensembl gene -> nullable MGI ID mapping from cleaned chrom2.csv.
-- Replaces the obsolete IMPC_procedure_parameter table, keeping 18 tables total.
CREATE TABLE chrom2_gene (
    ensembl_gene_id VARCHAR(32) NOT NULL,
    gene_name VARCHAR(255),
    gene_accession_id VARCHAR(32),
    gene_symbol VARCHAR(128),
    PRIMARY KEY (ensembl_gene_id),
    INDEX idx_chromgene_mgi (gene_accession_id),
    CONSTRAINT fk_chromgene_mgi FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene(gene_accession_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 16. One record per Ensembl transcript.
CREATE TABLE chrom2_transcript (
    ensembl_transcript_id VARCHAR(32) NOT NULL,
    ensembl_gene_id VARCHAR(32) NOT NULL,
    PRIMARY KEY (ensembl_transcript_id),
    INDEX idx_chromtranscript_gene (ensembl_gene_id),
    CONSTRAINT fk_chromtranscript_gene FOREIGN KEY (ensembl_gene_id)
        REFERENCES chrom2_gene(ensembl_gene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 17. Original exon-level records (an exon can belong to several transcripts).
CREATE TABLE chrom2 (
    chrom2_row_id BIGINT NOT NULL,
    ensembl_transcript_id VARCHAR(32) NOT NULL,
    ensembl_exon_id VARCHAR(32) NOT NULL,
    exon_start BIGINT,
    exon_end BIGINT,
    exon_rank INT,
    PRIMARY KEY (chrom2_row_id),
    UNIQUE KEY uq_chrom_transcript_exon (ensembl_transcript_id, ensembl_exon_id),
    INDEX idx_chrom_exon_id (ensembl_exon_id),
    CONSTRAINT fk_chrom2_transcript FOREIGN KEY (ensembl_transcript_id)
        REFERENCES chrom2_transcript(ensembl_transcript_id),
    CONSTRAINT chk_chrom_coordinates CHECK
        (exon_start IS NULL OR exon_end IS NULL OR exon_start <= exon_end),
    CONSTRAINT chk_chrom_rank CHECK (exon_rank IS NULL OR exon_rank >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 18. Optional group-specific scientific-resource annotations.
CREATE TABLE parameter_group_external_data (
    external_record_id BIGINT NOT NULL,
    group_id INT NOT NULL,
    resource_name VARCHAR(128) NOT NULL,
    external_id VARCHAR(64) NOT NULL,
    term_or_label VARCHAR(255),
    notes TEXT,
    gene_accession_id VARCHAR(32),
    PRIMARY KEY (external_record_id),
    INDEX idx_external_group_resource (group_id, resource_name),
    INDEX idx_external_external_id (external_id),
    INDEX idx_external_gene (gene_accession_id),
    CONSTRAINT fk_external_group FOREIGN KEY (group_id)
        REFERENCES parameter_group(group_id),
    CONSTRAINT fk_external_mouse FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene(gene_accession_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;




SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'data_base_merged'
  AND table_type = 'BASE TABLE';

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = ON;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

SELECT
    COUNT(*) AS total_rows,
    COUNT(hgnc_id) AS hgnc_rows,
    COUNT(human_entrez_gene_id) AS entrez_rows
FROM data_base_merged.human_gene;
