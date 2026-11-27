DROP DATABASE IF EXISTS Data_base_merged;

CREATE DATABASE Data_base_merged
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE Data_base_merged;

-- 1. Core Mouse Gene Hub Table
CREATE TABLE IF NOT EXISTS mouse_gene (
    gene_accession_id VARCHAR(32) NOT NULL,
    gene_symbol VARCHAR(64),
    PRIMARY KEY (gene_accession_id),
    INDEX idx_mouse_gene_symbol (gene_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Procedures (matches Procedures.csv)
CREATE TABLE IF NOT EXISTS procedures (
    procedure_code VARCHAR(64) NOT NULL,
    procedure_name VARCHAR(255),
    procedure_description TEXT,
    is_mandatory BOOLEAN,
    PRIMARY KEY (procedure_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Parameters (matches Parameters.csv)
CREATE TABLE IF NOT EXISTS parameters (
    parameter_id VARCHAR(64) NOT NULL,
    parameter_name VARCHAR(255),
    parameter_description TEXT,
    procedure_code VARCHAR(64),
    impc_parameter_orig_id VARCHAR(64),
    PRIMARY KEY (parameter_id),
    CONSTRAINT fk_param_procedure_code
        FOREIGN KEY (procedure_code)
        REFERENCES procedures (procedure_code),
    INDEX idx_param_proc_code (procedure_code),
    INDEX idx_param_orig_id (impc_parameter_orig_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Parameter Groups (matches parameter_group.csv)
CREATE TABLE IF NOT EXISTS parameter_group (
    group_id INT NOT NULL,
    group_name VARCHAR(128) NOT NULL,
    PRIMARY KEY (group_id),
    UNIQUE KEY uq_parameter_group_name (group_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Parameter Group Members (matches parameter_group_member.csv)
CREATE TABLE IF NOT EXISTS parameter_group_member (
    group_id INT NOT NULL,
    parameter_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (group_id, parameter_id),
    CONSTRAINT fk_pgm_group
        FOREIGN KEY (group_id)
        REFERENCES parameter_group (group_id),
    CONSTRAINT fk_pgm_parameter
        FOREIGN KEY (parameter_id)
        REFERENCES parameters (parameter_id),
    INDEX idx_pgm_parameter (parameter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Parameter Group External Scientific Resource Data
CREATE TABLE IF NOT EXISTS parameter_group_external_data (
    external_record_id BIGINT NOT NULL AUTO_INCREMENT,
    group_id INT NOT NULL,
    resource_name VARCHAR(128) NOT NULL,
    external_id VARCHAR(64) NOT NULL,
    term_or_label VARCHAR(255),
    notes TEXT,
    gene_accession_id VARCHAR(32),
    PRIMARY KEY (external_record_id),
    CONSTRAINT fk_pged_group
        FOREIGN KEY (group_id)
        REFERENCES parameter_group (group_id),
    CONSTRAINT fk_pged_mouse_gene
        FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene (gene_accession_id),
    INDEX idx_pged_group (group_id),
    INDEX idx_pged_external (resource_name, external_id),
    INDEX idx_pged_gene (gene_accession_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Main Phenotyping Dataset (analysis_id as PRIMARY KEY)
CREATE TABLE IF NOT EXISTS group14_cleaned_imputed (
    analysis_id VARCHAR(128) NOT NULL,
    gene_accession_id VARCHAR(32),
    gene_symbol VARCHAR(64),
    allele_symbol VARCHAR(128),
    strain_name VARCHAR(128),
    parameter_id VARCHAR(64),
    parameter_name VARCHAR(255),
    p_value DOUBLE,
    mouse_life_stage VARCHAR(64),
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
    source_file VARCHAR(255),
    PRIMARY KEY (analysis_id),
    CONSTRAINT fk_g14_mouse_gene
        FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene (gene_accession_id),
    CONSTRAINT fk_g14_parameter
        FOREIGN KEY (parameter_id)
        REFERENCES parameters (parameter_id),
    CONSTRAINT chk_g14_pvalue
        CHECK (p_value IS NULL OR (p_value >= 0 AND p_value <= 1)),
    INDEX idx_g14_gene (gene_accession_id),
    INDEX idx_g14_param (parameter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Bespoke Task Standardised
CREATE TABLE IF NOT EXISTS bespoke_task_standardised (
    bespoke_row_id BIGINT NOT NULL,
    human_gene_symbol VARCHAR(64),
    human_entrez_gene_id VARCHAR(32),
    gene_symbol VARCHAR(64),
    gene_accession_id VARCHAR(32),
    in_impc_dataset VARCHAR(32),
    PRIMARY KEY (bespoke_row_id),
    CONSTRAINT fk_bts_mouse_gene
        FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene (gene_accession_id),
    INDEX idx_bts_gene (gene_accession_id),
    INDEX idx_bts_human_symbol (human_gene_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Bespoke Task MP Bridge
CREATE TABLE IF NOT EXISTS bespoke_task_mp_bridge (
    bespoke_row_id BIGINT NOT NULL,
    high_level_mp_ids VARCHAR(64) NOT NULL,
    PRIMARY KEY (bespoke_row_id, high_level_mp_ids),
    CONSTRAINT fk_btmp_bespoke_row
        FOREIGN KEY (bespoke_row_id)
        REFERENCES bespoke_task_standardised (bespoke_row_id),
    INDEX idx_btmp_mp_id (high_level_mp_ids)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Disease Information Standardised
CREATE TABLE IF NOT EXISTS disease_information_standardised (
    disease_row_id BIGINT NOT NULL,
    human_gene_symbol VARCHAR(64),
    human_gene_name VARCHAR(255),
    hgnc_id VARCHAR(32),
    do_term_name VARCHAR(255),
    do_term_id VARCHAR(32),
    gene_symbol VARCHAR(64),
    gene_accession_id VARCHAR(32),
    PRIMARY KEY (disease_row_id),
    CONSTRAINT fk_dis_mouse_gene
        FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene (gene_accession_id),
    INDEX idx_dis_gene (gene_accession_id),
    INDEX idx_dis_do_term (do_term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. Mouse Genotype Bridge
CREATE TABLE IF NOT EXISTS mouse_genotype_bridge (
    disease_row_id BIGINT NOT NULL,
    mouse_genotype_ids VARCHAR(255) NOT NULL,
    PRIMARY KEY (disease_row_id, mouse_genotype_ids),
    CONSTRAINT fk_mgb_disease_row
        FOREIGN KEY (disease_row_id)
        REFERENCES disease_information_standardised (disease_row_id),
    INDEX idx_mgb_genotype (mouse_genotype_ids)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Chromosome 2 Annotations
CREATE TABLE IF NOT EXISTS chrom2 (
    ensembl_gene_id VARCHAR(64),
    ensembl_transcript_id VARCHAR(64),
    gene_name VARCHAR(255),
    ensembl_exon_id VARCHAR(64),
    exon_start BIGINT,
    exon_end BIGINT,
    exon_rank INT,
    gene_accession_id VARCHAR(32),
    gene_symbol VARCHAR(64),
    CONSTRAINT fk_chrom2_mouse_gene
        FOREIGN KEY (gene_accession_id)
        REFERENCES mouse_gene (gene_accession_id),
    INDEX idx_chrom2_ensembl_gene (ensembl_gene_id),
    INDEX idx_chrom2_ensembl_tx (ensembl_transcript_id),
    INDEX idx_chrom2_gene_acc (gene_accession_id),
    INDEX idx_chrom2_symbol (gene_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;