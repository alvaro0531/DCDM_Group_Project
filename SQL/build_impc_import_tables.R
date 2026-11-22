# IMPC normalized import-table builder (R base only)
# Input: existing data.frames in .GlobalEnv OR CSVs in INPUT_DIR.
# Output: 18 *_import data.frames and 18 *_import.csv files.
# IMPORTANT: Run AFTER the original data-cleaning and parameter-grouping steps
# (or provide the nine source CSV files). Does not modify original data.frames.
# Does not execute SQL / import into MySQL.

INPUT_DIR <- "database_import"
OUTPUT_DIR <- "database_import_revised"
GENOTYPE_SPLIT_REGEX <- "[,;]"  # verify the actual delimiter in the source

fail <- function(...) stop(paste0(...), call. = FALSE)
report <- character()
note <- function(...) {
  message(...)
  report <<- c(report, paste0(...))
}

load_source <- function(nm, optional = FALSE) {
  if (exists(nm, envir = .GlobalEnv, inherits = FALSE)) {
    x <- get(nm, envir = .GlobalEnv, inherits = FALSE)
    if (!is.data.frame(x)) fail(nm, " exists but is not a data.frame")
    note("Using in-memory data frame: ", nm, " (", nrow(x), " rows)")
    return(as.data.frame(x, stringsAsFactors = FALSE))
  }
  file <- file.path(INPUT_DIR, paste0(nm, ".csv"))
  if (file.exists(file)) {
    # Preserve identifiers (including any leading zeros) as strings.
    x <- read.csv(file, stringsAsFactors = FALSE, check.names = FALSE,
                  colClasses = "character", na.strings = c("", "NA"),
                  fileEncoding = "UTF-8")
    note("Reading CSV: ", file, " (", nrow(x), " rows)")
    return(x)
  }
  if (optional) return(NULL)
  fail("Missing source ", nm, ": provide an R data frame or ", file)
}

required <- function(x, cols, table_name) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) fail(table_name, " is missing required columns: ",
                            paste(missing, collapse = ", "))
  invisible(TRUE)
}

rename_alias <- function(x, old, new, table_name) {
  if (!(old %in% names(x))) return(x)
  if (!(new %in% names(x))) {
    names(x)[names(x) == old] <- new
    return(x)
  }
  a <- as.character(x[[old]])
  b <- as.character(x[[new]])
  equivalent <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
  if (!all(equivalent)) fail(table_name, ": ", old,
                             " conflicts with existing ", new)
  x[[old]] <- NULL
  x
}

strclean <- function(x) {
  x <- trimws(as.character(x))
  x[!is.na(x) & x == ""] <- NA_character_
  x
}

ids <- function(x, col, table_name) {
  if (!(col %in% names(x))) return(seq_len(nrow(x)))
  v <- suppressWarnings(as.numeric(as.character(x[[col]])))
  if (any(is.na(v)) || any(!is.finite(v)) || any(v < 1) ||
      any(v != floor(v)) || anyDuplicated(v)) {
    fail(table_name, "$", col, " contains invalid/duplicate IDs")
  }
  v
}

pk_check <- function(x, fields, table_name) {
  required(x, fields, table_name)
  if (!nrow(x)) return(invisible(TRUE))
  key_cols <- lapply(x[fields], as.character)
  if (any(vapply(key_cols, function(v) any(is.na(strclean(v))), logical(1))))
    fail(table_name, " has missing primary-key values")
  key <- do.call(paste, c(key_cols, sep = "\r"))
  if (anyDuplicated(key)) fail(table_name, " contains duplicate primary keys")
  invisible(TRUE)
}

fk_check <- function(child, col, parent, parent_col, child_name) {
  required(child, col, child_name)
  required(parent, parent_col, "parent")
  values <- strclean(child[[col]])
  missing <- setdiff(unique(values[!is.na(values)]),
                     unique(strclean(parent[[parent_col]])))
  if (length(missing)) {
    fail(child_name, ".", col, " contains ", length(missing),
         " unknown foreign keys. First examples: ",
         paste(head(missing, 8), collapse = ", "))
  }
  invisible(TRUE)
}

int_numeric <- function(x, field) {
  v <- strclean(x)
  z <- suppressWarnings(as.numeric(v))
  invalid <- !is.na(v) & (is.na(z) | !is.finite(z) | z != floor(z))
  if (any(invalid)) fail("Non-integer values in ", field, ": ",
                         paste(head(unique(v[invalid]), 5), collapse = ", "))
  z
}

valid_pvalues <- function(x) {
  raw <- strclean(x)
  value <- suppressWarnings(as.numeric(raw))
  bad <- !is.na(raw) & (is.na(value) | !is.finite(value) |
                        value < 0 | value > 1)
  if (any(bad)) fail("Invalid pvalue values (first): ",
                      paste(head(unique(raw[bad]), 6), collapse = ", "))
  value
}

# Pick a single nonblank string per identifier; refuse contradictory values.
unique_detail <- function(v, identity, field) {
  w <- sort(unique(strclean(v)))
  w <- w[!is.na(w)]
  if (length(w) > 1) fail("Conflicting ", field, " for ID ", identity,
                          ": ", paste(head(w, 5), collapse = " / "))
  if (length(w) == 0) NA_character_ else w[1]
}

single_record_per_key <- function(x, key_col, detail_cols, table_name) {
  required(x, c(key_col, detail_cols), table_name)
  keys <- sort(unique(strclean(x[[key_col]])))
  keys <- keys[!is.na(keys)]
  out <- data.frame(key = keys, stringsAsFactors = FALSE)
  names(out)[1] <- key_col
  for (nm in detail_cols) {
    out[[nm]] <- vapply(keys, function(k) {
      ix <- !is.na(strclean(x[[key_col]])) & strclean(x[[key_col]]) == k
      unique_detail(x[[nm]][ix], k, nm)
    }, character(1))
  }
  out
}

# Convert delimiter-separated values to a two-column association table.
expand_ids <- function(row_id, strings, value_name, split_regex) {
  pieces <- strsplit(ifelse(is.na(strings), "", as.character(strings)),
                     split = split_regex, perl = TRUE)
  n <- lengths(pieces)
  if (!sum(n)) {
    out <- data.frame(row_id = numeric(), value = character(),
                      stringsAsFactors = FALSE)
  } else {
    out <- data.frame(row_id = rep(row_id, n),
                      value = trimws(unlist(pieces, use.names = FALSE)),
                      stringsAsFactors = FALSE)
  }
  out <- out[!is.na(out$value) & out$value != "", , drop = FALSE]
  out <- unique(out)
  names(out) <- c("row_id", value_name)
  rownames(out) <- NULL
  out
}

# -------- LOAD INPUTS --------
wide_src <- load_source("clean_wide_data")
param_src <- load_source("IMPC_parameter_description")
proc_src <- load_source("IMPC_procedure")
bespoke_src <- load_source("bespokeTask")
disease_src <- load_source("Disease_information")
chrom2_src <- load_source("chrom2")
group_src <- load_source("parameter_group")
member_src <- load_source("parameter_group_member")
mouse_src <- load_source("mouse_gene", optional = TRUE)
external_src <- load_source("external_raw", optional = TRUE)

# -------- STANDARDISE SOURCE COLUMNS --------
param_src <- rename_alias(param_src, "parameterId", "parameter_id", "IMPC_parameter_description")
param_src <- rename_alias(param_src, "name", "parameter_name", "IMPC_parameter_description")
param_src <- rename_alias(param_src, "parameter_description", "description", "IMPC_parameter_description")
for (j in seq_along(c("Gene stable ID", "Transcript stable ID", "Gene name",
                    "Exon stable ID", "Exon region start (bp)",
                    "Exon region end (bp)", "Exon rank in transcript"))) {
  old <- c("Gene stable ID", "Transcript stable ID", "Gene name",
           "Exon stable ID", "Exon region start (bp)",
           "Exon region end (bp)", "Exon rank in transcript")[j]
  new <- c("gene_stable_id", "transcript_stable_id", "gene_symbol",
           "exon_stable_id", "exon_start_bp", "exon_end_bp", "exon_rank")[j]
  chrom2_src <- rename_alias(chrom2_src, old, new, "chrom2")
}

required(wide_src, c("source_file", "analysis_id", "gene_accession_id",
  "gene_symbol", "allele_symbol", "strain_name", "parameter_id", "pvalue",
  "parameter_name", "mouse_life_stage"), "clean_wide_data")
lacz_columns <- paste0("lacz_", c("blood", "brain", "colon", "eye", "heart",
   "kidney", "liver", "lung", "skeletal_muscle", "skin", "vascular_system"))
required(wide_src, lacz_columns, "clean_wide_data")
required(param_src, c("parameter_id", "impcParameterOrigId", "parameter_name",
                      "description"), "IMPC_parameter_description")
required(proc_src, c("name", "description", "isMandatory", "impcParameterOrigId"),
         "IMPC_procedure")
required(bespoke_src, c("human_gene_symbol", "human_entrez_gene_id",
   "gene_symbol", "gene_accession_id", "high_level_mp_ids"), "bespokeTask")
required(disease_src, c("human_gene_symbol", "human_gene_name", "hgnc_id",
  "do_term_name", "do_term_id", "mouse_genotype_ids", "gene_symbol",
  "gene_accession_id"), "Disease_information")
required(chrom2_src, c("gene_stable_id", "transcript_stable_id", "gene_symbol",
  "exon_stable_id", "exon_start_bp", "exon_end_bp", "exon_rank"), "chrom2")
required(group_src, c("group_id", "group_name"), "parameter_group")
required(member_src, c("group_id", "parameter_id"), "parameter_group_member")

# -------- 1. MOUSE GENE --------
# Rebuild a complete MGI directory from the three sources, plus existing mouse_gene.
gene_sources <- list(wide_src[c("gene_accession_id", "gene_symbol")],
                     bespoke_src[c("gene_accession_id", "gene_symbol")],
                     disease_src[c("gene_accession_id", "gene_symbol")])
if (!is.null(mouse_src)) {
  required(mouse_src, c("gene_accession_id", "gene_symbol"), "mouse_gene")
  gene_sources <- c(gene_sources,
                    list(mouse_src[c("gene_accession_id", "gene_symbol")]))
}
gene_raw <- do.call(rbind, gene_sources)
gene_raw$gene_accession_id <- strclean(gene_raw$gene_accession_id)
gene_raw$gene_symbol <- strclean(gene_raw$gene_symbol)
mgis <- sort(unique(gene_raw$gene_accession_id[!is.na(gene_raw$gene_accession_id)]))
mouse_gene_import <- data.frame(gene_accession_id = mgis,
                                gene_symbol = NA_character_,
                                stringsAsFactors = FALSE)
mouse_gene_symbol_conflicts <- character()
for (i in seq_along(mgis)) {
  syms <- unique(gene_raw$gene_symbol[
    gene_raw$gene_accession_id %in% mgis[i] & !is.na(gene_raw$gene_symbol)])
  if (length(syms) == 1) mouse_gene_import$gene_symbol[i] <- syms
  if (length(syms) > 1) mouse_gene_symbol_conflicts <- c(mouse_gene_symbol_conflicts, mgis[i])
}
if (length(mouse_gene_symbol_conflicts))
  note("WARNING: ", length(mouse_gene_symbol_conflicts),
       " MGI IDs have conflicting symbols; symbol left blank for review")

# -------- 2. PARAMETER CATALOGUE --------
param_src$parameter_id <- strclean(param_src$parameter_id)
if (anyNA(param_src$parameter_id)) fail("IMPC_parameter_description has blank parameter IDs")
IMPC_parameter_description_import <- single_record_per_key(
  param_src, "parameter_id",
  c("impcParameterOrigId", "parameter_name", "description"),
  "IMPC_parameter_description")

# -------- 3. PARAMETER GROUPS (preserve original IDs) --------
parameter_group_import <- group_src[c("group_id", "group_name")]
parameter_group_import$group_id <- int_numeric(parameter_group_import$group_id, "group_id")
parameter_group_import$group_name <- strclean(parameter_group_import$group_name)
if (anyDuplicated(parameter_group_import$group_name) || anyNA(parameter_group_import$group_name))
  fail("parameter_group has missing or duplicate group_name values")
parameter_group_member_import <- unique(member_src[c("group_id", "parameter_id")])
parameter_group_member_import$group_id <- int_numeric(
  parameter_group_member_import$group_id, "parameter_group_member.group_id")
parameter_group_member_import$parameter_id <- strclean(parameter_group_member_import$parameter_id)

# -------- 4. PROCEDURE + JOIN TABLE --------
proc_src$procedure_id <- ids(proc_src, "procedure_id", "IMPC_procedure")
IMPC_procedure_import <- proc_src[c("procedure_id", "name", "description",
                                    "isMandatory", "impcParameterOrigId")]
IMPC_procedure_import$impcParameterOrigId <- strclean(IMPC_procedure_import$impcParameterOrigId)
# Convert boolean values to MySQL-compatible 1 / 0 / NULL.
mandatory_raw <- tolower(strclean(IMPC_procedure_import$isMandatory))
mandatory_raw[mandatory_raw %in% c("t", "yes", "y", "true")] <- "1"
mandatory_raw[mandatory_raw %in% c("f", "no", "n", "false")] <- "0"
if (any(!is.na(mandatory_raw) & !(mandatory_raw %in% c("0", "1"))))
  fail("IMPC_procedure$isMandatory has unrecognised boolean values")
IMPC_procedure_import$isMandatory <- as.integer(mandatory_raw)
# Only map an original ID if it uniquely resolves to one parameter_stable_id.
original_id <- strclean(IMPC_parameter_description_import$impcParameterOrigId)
original_id_to_parameter <- split(IMPC_parameter_description_import$parameter_id,
                                   original_id)
# Remove NA/empty split group if present.
original_id_to_parameter <- original_id_to_parameter[
  !is.na(names(original_id_to_parameter)) & names(original_id_to_parameter) != "NA"]
procedure_pairs <- lapply(seq_len(nrow(IMPC_procedure_import)), function(i) {
  oid <- IMPC_procedure_import$impcParameterOrigId[i]
  if (is.na(oid)) return(NULL)
  matches <- unique(original_id_to_parameter[[oid]])
  if (is.null(matches) || length(matches) != 1) return(NULL)
  data.frame(procedure_id = IMPC_procedure_import$procedure_id[i],
             parameter_id = matches, stringsAsFactors = FALSE)
})
procedure_pairs <- Filter(Negate(is.null), procedure_pairs)
IMPC_procedure_parameter_import <- if (length(procedure_pairs))
  unique(do.call(rbind, procedure_pairs)) else
  data.frame(procedure_id = numeric(), parameter_id = character())
proc_mapped <- unique(IMPC_procedure_parameter_import$procedure_id)
procedure_unmatched_report <- IMPC_procedure_import[
  !(IMPC_procedure_import$procedure_id %in% proc_mapped),
  c("procedure_id", "impcParameterOrigId", "name"), drop = FALSE]
if (nrow(procedure_unmatched_report))
  note("WARNING: ", nrow(procedure_unmatched_report),
       " procedures were not uniquely matched to parameters (see audit report)")

# -------- 5. PHENOTYPE DATA + LACZ --------
wide_src$result_id <- ids(wide_src, "result_id", "clean_wide_data")
clean_wide_data_import <- wide_src[c("result_id", "source_file", "analysis_id",
 "gene_accession_id", "gene_symbol", "allele_symbol", "strain_name",
 "parameter_id", "pvalue", "parameter_name", "mouse_life_stage")]
clean_wide_data_import$pvalue <- valid_pvalues(clean_wide_data_import$pvalue)
lacz_expression_import <- wide_src[c("result_id", lacz_columns)]
stopifnot(nrow(clean_wide_data_import) == nrow(lacz_expression_import),
          identical(clean_wide_data_import$result_id,
                    lacz_expression_import$result_id))

# -------- 6. HUMAN GENE LOOKUP (NO UNVERIFIED CROSS-SOURCE MERGES) --------
# Entrez from bespoke and HGNC from disease are treated as separate identities
# unless a verified crosswalk is supplied later. This avoids false gene matches.
bespoke_entrez <- data.frame(
  human_entrez_gene_id = strclean(bespoke_src$human_entrez_gene_id),
  human_gene_symbol = strclean(bespoke_src$human_gene_symbol),
  human_gene_name = NA_character_, stringsAsFactors = FALSE)
bespoke_entrez <- bespoke_entrez[!is.na(bespoke_entrez$human_entrez_gene_id), ]
if (nrow(bespoke_entrez)) {
  entrez_lookup <- single_record_per_key(bespoke_entrez, "human_entrez_gene_id",
                                        c("human_gene_symbol", "human_gene_name"),
                                        "bespoke human genes")
  entrez_lookup$hgnc_id <- NA_character_
} else {
  entrez_lookup <- data.frame(human_entrez_gene_id = character(),
    human_gene_symbol = character(), human_gene_name = character(),
    hgnc_id = character())
}
disease_hgnc <- data.frame(
  hgnc_id = strclean(disease_src$hgnc_id),
  human_gene_symbol = strclean(disease_src$human_gene_symbol),
  human_gene_name = strclean(disease_src$human_gene_name),
  stringsAsFactors = FALSE)
disease_hgnc <- disease_hgnc[!is.na(disease_hgnc$hgnc_id), ]
if (nrow(disease_hgnc)) {
  hgnc_lookup <- single_record_per_key(disease_hgnc, "hgnc_id",
    c("human_gene_symbol", "human_gene_name"), "disease human genes")
  hgnc_lookup$human_entrez_gene_id <- NA_character_
} else {
  hgnc_lookup <- data.frame(hgnc_id = character(), human_gene_symbol = character(),
     human_gene_name = character(), human_entrez_gene_id = character())
}
human_gene_import <- rbind(
  entrez_lookup[c("human_gene_symbol", "human_gene_name", "human_entrez_gene_id", "hgnc_id")],
  hgnc_lookup[c("human_gene_symbol", "human_gene_name", "human_entrez_gene_id", "hgnc_id")]
)
human_gene_import$human_gene_id <- seq_len(nrow(human_gene_import))
human_gene_import <- human_gene_import[c("human_gene_id", "human_gene_symbol",
 "human_gene_name", "human_entrez_gene_id", "hgnc_id")]

# -------- 7. BESPOKE + MP --------
bespoke_src$bespoke_task_id <- ids(bespoke_src, "bespoke_task_id", "bespokeTask")
bespokeTask_import <- bespoke_src[c("bespoke_task_id", "human_gene_symbol",
 "human_entrez_gene_id", "gene_symbol", "gene_accession_id", "high_level_mp_ids")]
# Match only on the source's explicitly supplied Entrez identifier.
bespokeTask_import$human_entrez_gene_id <- strclean(bespokeTask_import$human_entrez_gene_id)
bespokeTask_import$human_gene_id <- human_gene_import$human_gene_id[match(
  bespokeTask_import$human_entrez_gene_id,
  human_gene_import$human_entrez_gene_id)]
# match(NA, NA) could link to an unrelated record; explicitly reset null keys.
bespokeTask_import$human_gene_id[is.na(bespokeTask_import$human_entrez_gene_id)] <- NA_real_

bespokeTask_mp_import <- expand_ids(bespokeTask_import$bespoke_task_id,
  bespokeTask_import$high_level_mp_ids, "mp_term_id", ",")
names(bespokeTask_mp_import)[1] <- "bespoke_task_id"
if (nrow(bespokeTask_mp_import)) {
  invalid_mp <- !grepl("^MP:[0-9]+$", bespokeTask_mp_import$mp_term_id)
  if (any(invalid_mp)) fail("Malformed MP IDs: ",
     paste(head(unique(bespokeTask_mp_import$mp_term_id[invalid_mp]), 8),
           collapse = ", "))
}
mp_terms_import <- data.frame(
  mp_term_id = sort(unique(bespokeTask_mp_import$mp_term_id)),
  stringsAsFactors = FALSE)
mp_terms_import$mp_term_name <- NA_character_  # not given in source

# -------- 8. DISEASE DATA + GENOTYPES --------
disease_src$disease_information_id <- ids(disease_src,
   "disease_information_id", "Disease_information")
disease_list <- data.frame(do_term_id = strclean(disease_src$do_term_id),
  do_term_name = strclean(disease_src$do_term_name), stringsAsFactors = FALSE)
human_diseases_import <- single_record_per_key(disease_list, "do_term_id",
  "do_term_name", "Disease Ontology")
Disease_information_import <- disease_src[c("disease_information_id",
 "human_gene_symbol", "human_gene_name", "hgnc_id", "do_term_name",
 "do_term_id", "mouse_genotype_ids", "gene_symbol", "gene_accession_id")]
Disease_information_import$hgnc_id <- strclean(Disease_information_import$hgnc_id)
Disease_information_import$human_gene_id <- human_gene_import$human_gene_id[match(
  Disease_information_import$hgnc_id, human_gene_import$hgnc_id)]
Disease_information_import$human_gene_id[is.na(Disease_information_import$hgnc_id)] <- NA_real_
Disease_information_genotype_import <- expand_ids(
  Disease_information_import$disease_information_id,
  Disease_information_import$mouse_genotype_ids,
  "mouse_genotype_id", GENOTYPE_SPLIT_REGEX)
names(Disease_information_genotype_import)[1] <- "disease_information_id"
# Unexpected vertical bars may indicate unrecognised separators; do not guess.
if (any(grepl("[|]", Disease_information_genotype_import$mouse_genotype_id)))
  fail("The genotype ID field contains '|'; verify its delimiter before importing")

# -------- 9. CHROMOSOME 2: TRANSCRIPTS + EXONS --------
chrom2_src$transcript_stable_id <- strclean(chrom2_src$transcript_stable_id)
if (anyNA(chrom2_src$transcript_stable_id))
  fail("chrom2 has blank transcript_stable_id; cannot link exons")
chrom2_transcript_import <- single_record_per_key(chrom2_src,
  "transcript_stable_id", c("gene_stable_id", "gene_symbol"), "chrom2")
chrom2_src$chrom2_row_id <- ids(chrom2_src, "chrom2_row_id", "chrom2")
chrom2_import <- chrom2_src[c("chrom2_row_id", "transcript_stable_id",
 "exon_stable_id", "exon_start_bp", "exon_end_bp", "exon_rank")]
for (nm in c("exon_start_bp", "exon_end_bp", "exon_rank"))
  chrom2_import[[nm]] <- int_numeric(chrom2_import[[nm]], nm)
if (any(!is.na(chrom2_import$exon_start_bp) &
        !is.na(chrom2_import$exon_end_bp) &
        chrom2_import$exon_start_bp > chrom2_import$exon_end_bp))
  fail("chrom2 has exon start coordinates greater than end coordinates")
if (any(!is.na(chrom2_import$exon_rank) & chrom2_import$exon_rank < 1))
  fail("chrom2 contains exon_rank < 1")

# -------- 10. PARAMETER GROUP EXTERNAL SCIENTIFIC DATA --------
external_fields <- c("external_record_id", "group_id", "resource_name",
 "external_id", "term_or_label", "notes", "gene_accession_id")
if (is.null(external_src)) {
  parameter_group_external_data_import <- data.frame(
    external_record_id = numeric(), group_id = numeric(),
    resource_name = character(), external_id = character(),
    term_or_label = character(), notes = character(),
    gene_accession_id = character(), stringsAsFactors = FALSE)
  note("WARNING: external_raw was not supplied; external resource table will be empty")
} else {
  required(external_src, c("resource_name", "external_id"), "external_raw")
  if (!("group_id" %in% names(external_src))) {
    required(external_src, "group_name", "external_raw")
    group_index <- match(strclean(external_src$group_name),
                         strclean(parameter_group_import$group_name))
    if (anyNA(group_index)) fail("external_raw has group_names not in parameter_group")
    external_src$group_id <- parameter_group_import$group_id[group_index]
  }
  for (nm in c("term_or_label", "notes", "gene_accession_id"))
    if (!(nm %in% names(external_src))) external_src[[nm]] <- NA_character_
  external_src$external_record_id <- ids(external_src,
      "external_record_id", "external_raw")
  parameter_group_external_data_import <- external_src[external_fields]
}

# -------- 11. STRICT RELATIONAL VALIDATION --------
table_list <- list(
  mouse_gene_import = mouse_gene_import,
  human_gene_import = human_gene_import,
  IMPC_parameter_description_import = IMPC_parameter_description_import,
  IMPC_procedure_import = IMPC_procedure_import,
  IMPC_procedure_parameter_import = IMPC_procedure_parameter_import,
  parameter_group_import = parameter_group_import,
  parameter_group_member_import = parameter_group_member_import,
  clean_wide_data_import = clean_wide_data_import,
  lacz_expression_import = lacz_expression_import,
  bespokeTask_import = bespokeTask_import,
  mp_terms_import = mp_terms_import,
  bespokeTask_mp_import = bespokeTask_mp_import,
  human_diseases_import = human_diseases_import,
  Disease_information_import = Disease_information_import,
  Disease_information_genotype_import = Disease_information_genotype_import,
  chrom2_transcript_import = chrom2_transcript_import,
  chrom2_import = chrom2_import,
  parameter_group_external_data_import = parameter_group_external_data_import
)
key_specs <- list(
 mouse_gene_import = "gene_accession_id",
 human_gene_import = "human_gene_id",
 IMPC_parameter_description_import = "parameter_id",
 IMPC_procedure_import = "procedure_id",
 IMPC_procedure_parameter_import = c("procedure_id", "parameter_id"),
 parameter_group_import = "group_id",
 parameter_group_member_import = c("group_id", "parameter_id"),
 clean_wide_data_import = "result_id",
 lacz_expression_import = "result_id",
 bespokeTask_import = "bespoke_task_id",
 mp_terms_import = "mp_term_id",
 bespokeTask_mp_import = c("bespoke_task_id", "mp_term_id"),
 human_diseases_import = "do_term_id",
 Disease_information_import = "disease_information_id",
 Disease_information_genotype_import = c("disease_information_id", "mouse_genotype_id"),
 chrom2_transcript_import = "transcript_stable_id",
 chrom2_import = "chrom2_row_id",
 parameter_group_external_data_import = "external_record_id"
)
# Trim identifier values in exported data (not only during validation).
# Otherwise a value may pass a trimmed FK check but fail in MySQL.
string_keys <- c("gene_accession_id", "parameter_id", "impcParameterOrigId",
  "group_name", "human_entrez_gene_id", "hgnc_id", "mp_term_id",
  "do_term_id", "transcript_stable_id", "gene_stable_id", "exon_stable_id",
  "mouse_genotype_id", "external_id", "resource_name")
for (nm in names(table_list)) {
  x <- table_list[[nm]]
  for (field in intersect(string_keys, names(x))) x[[field]] <- strclean(x[[field]])
  table_list[[nm]] <- x
  assign(nm, x, envir = .GlobalEnv)
}

# Check string widths against the 18-table SQL schema before writing CSV.
max_lengths <- list(
 mouse_gene_import = c(gene_accession_id=32, gene_symbol=64),
 human_gene_import = c(human_gene_symbol=64, human_gene_name=255,
                       human_entrez_gene_id=32, hgnc_id=32),
 IMPC_parameter_description_import = c(parameter_id=64,
   impcParameterOrigId=64, parameter_name=255),
 IMPC_procedure_import = c(name=255, impcParameterOrigId=64),
 IMPC_procedure_parameter_import = c(parameter_id=64),
 parameter_group_import = c(group_name=128),
 parameter_group_member_import = c(parameter_id=64),
 clean_wide_data_import = c(source_file=255, analysis_id=128,
   gene_accession_id=32, gene_symbol=64, allele_symbol=128,
   strain_name=128, mouse_life_stage=64, parameter_id=64,
   parameter_name=255),
 lacz_expression_import = setNames(rep(64, length(lacz_columns)), lacz_columns),
 bespokeTask_import = c(human_gene_symbol=64, human_entrez_gene_id=32,
   gene_symbol=64, gene_accession_id=32),
 mp_terms_import = c(mp_term_id=32, mp_term_name=255),
 bespokeTask_mp_import = c(mp_term_id=32),
 human_diseases_import = c(do_term_id=32, do_term_name=255),
 Disease_information_import = c(human_gene_symbol=64, human_gene_name=255,
   hgnc_id=32, do_term_name=255, do_term_id=32, gene_symbol=64,
   gene_accession_id=32),
 Disease_information_genotype_import = c(mouse_genotype_id=255),
 chrom2_transcript_import = c(transcript_stable_id=64, gene_stable_id=64,
   gene_symbol=64),
 chrom2_import = c(transcript_stable_id=64, exon_stable_id=64),
 parameter_group_external_data_import = c(resource_name=128,
   external_id=64, term_or_label=255, gene_accession_id=32)
)
for (nm in names(max_lengths)) {
  x <- table_list[[nm]]
  for (field in names(max_lengths[[nm]])) {
    if (!(field %in% names(x))) fail(nm, " missing schema column ", field)
    vals <- as.character(x[[field]])
    too_long <- !is.na(vals) & nchar(vals, type="chars") > max_lengths[[nm]][[field]]
    if (any(too_long)) fail(nm, ".", field, " exceeds VARCHAR(",
      max_lengths[[nm]][[field]], ") (example: ", vals[which(too_long)[1]], ")")
  }
}

for (nm in names(table_list)) pk_check(table_list[[nm]], key_specs[[nm]], nm)

fk_check(parameter_group_member_import, "group_id", parameter_group_import,
 "group_id", "parameter_group_member_import")
fk_check(parameter_group_member_import, "parameter_id",
 IMPC_parameter_description_import, "parameter_id", "parameter_group_member_import")
fk_check(clean_wide_data_import, "gene_accession_id", mouse_gene_import,
 "gene_accession_id", "clean_wide_data_import")
fk_check(clean_wide_data_import, "parameter_id", IMPC_parameter_description_import,
 "parameter_id", "clean_wide_data_import")
fk_check(lacz_expression_import, "result_id", clean_wide_data_import,
 "result_id", "lacz_expression_import")
fk_check(IMPC_procedure_parameter_import, "procedure_id", IMPC_procedure_import,
 "procedure_id", "IMPC_procedure_parameter_import")
fk_check(IMPC_procedure_parameter_import, "parameter_id",
 IMPC_parameter_description_import, "parameter_id", "IMPC_procedure_parameter_import")
fk_check(bespokeTask_import, "gene_accession_id", mouse_gene_import,
 "gene_accession_id", "bespokeTask_import")
fk_check(bespokeTask_import, "human_gene_id", human_gene_import,
 "human_gene_id", "bespokeTask_import")
fk_check(bespokeTask_mp_import, "bespoke_task_id", bespokeTask_import,
 "bespoke_task_id", "bespokeTask_mp_import")
fk_check(bespokeTask_mp_import, "mp_term_id", mp_terms_import,
 "mp_term_id", "bespokeTask_mp_import")
fk_check(Disease_information_import, "gene_accession_id", mouse_gene_import,
 "gene_accession_id", "Disease_information_import")
fk_check(Disease_information_import, "human_gene_id", human_gene_import,
 "human_gene_id", "Disease_information_import")
fk_check(Disease_information_import, "do_term_id", human_diseases_import,
 "do_term_id", "Disease_information_import")
fk_check(Disease_information_genotype_import, "disease_information_id",
 Disease_information_import, "disease_information_id",
 "Disease_information_genotype_import")
fk_check(chrom2_import, "transcript_stable_id", chrom2_transcript_import,
 "transcript_stable_id", "chrom2_import")
fk_check(parameter_group_external_data_import, "group_id", parameter_group_import,
 "group_id", "parameter_group_external_data_import")
fk_check(parameter_group_external_data_import, "gene_accession_id", mouse_gene_import,
 "gene_accession_id", "parameter_group_external_data_import")

# No row loss from core result, bespoke, disease or chromosome exon sources.
stopifnot(nrow(clean_wide_data_import) == nrow(wide_src),
          nrow(lacz_expression_import) == nrow(wide_src),
          nrow(bespokeTask_import) == nrow(bespoke_src),
          nrow(Disease_information_import) == nrow(disease_src),
          nrow(chrom2_import) == nrow(chrom2_src))

# -------- 12. EXPORT AND EXPOSE THE 18 OBJECTS --------
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
for (nm in names(table_list)) {
  assign(nm, table_list[[nm]], envir = .GlobalEnv)
  write.csv(table_list[[nm]],
    file.path(OUTPUT_DIR, paste0(nm, ".csv")),
    row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
write.csv(procedure_unmatched_report,
  file.path(OUTPUT_DIR, "procedure_unmatched_report.csv"), row.names = FALSE)
write.csv(data.frame(gene_accession_id = mouse_gene_symbol_conflicts),
  file.path(OUTPUT_DIR, "mouse_gene_symbol_conflicts_report.csv"), row.names = FALSE)
import_summary <- data.frame(
  table = names(table_list), rows = vapply(table_list, nrow, numeric(1)),
  stringsAsFactors = FALSE)
write.csv(import_summary, file.path(OUTPUT_DIR, "import_summary.csv"),
          row.names = FALSE)
writeLines(c("IMPC conversion validation notes", report),
           file.path(OUTPUT_DIR, "validation_notes.txt"))
message("SUCCESS: ", length(table_list), " *_import tables prepared in ", OUTPUT_DIR)
print(import_summary, row.names = FALSE)
