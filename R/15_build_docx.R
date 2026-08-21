# ---------------------------------------------------------------------------
# 15_build_docx.R
#
# Builds the Word submission package into Journal-of-Critical-Care/. Standing requirement:
# every deliverable in Journal-of-Critical-Care/ is .docx, because that is what Elsevier
# takes. The markdown files in docs/ remain the editable source; this script is
# a converter and should never be edited to fix content.
#
#   docs/MANUSCRIPT_v1.md      ->  Journal-of-Critical-Care/Manuscript.docx
#   docs/TABLES.md             ->  Journal-of-Critical-Care/Tables.docx
#   docs/REFERENCES_ama.md     ->  appended to Manuscript.docx
#   Journal-of-Critical-Care/Title_Page.md   ->  Journal-of-Critical-Care/Title_Page.docx
#   Journal-of-Critical-Care/highlights.md   ->  Journal-of-Critical-Care/Highlights.docx
#   figures/*.tiff             ->  Journal-of-Critical-Care/Figures.docx  (PNG for Word)
#
# pandoc is not installed on this machine, so the conversion is done with
# officer/flextable directly. Serif throughout, per standing preference.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(officer); library(flextable); library(data.table)
})
HAVE_MAGICK <- requireNamespace("magick", quietly = TRUE)

# --- locate the project root, wherever this is run from --------------------
# Walks up from the working directory looking for the .projectroot sentinel,
# so the pipeline runs identically from the repository root, from R/, or from
# an IDE with a different working directory. No absolute paths anywhere.
.find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = FALSE)
  for (i in 1:8) {
    if (file.exists(file.path(p, ".projectroot"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) break
    p <- parent
  }
  stop("Could not find the project root. Run from the repository, which must ",
       "contain a .projectroot file.", call. = FALSE)
}
PROJ <- .find_root()
SUB  <- file.path(PROJ, "Journal-of-Critical-Care")
FONT <- "Times New Roman"
dir.create(SUB, showWarnings = FALSE)

# --- text and paragraph properties -----------------------------------------
body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
ital_fp <- fp_text(font.family = FONT, font.size = 12, italic = TRUE)
ttl_fp  <- fp_text(font.family = FONT, font.size = 15, bold = TRUE)
h1_fp   <- fp_text(font.family = FONT, font.size = 13, bold = TRUE)
h2_fp   <- fp_text(font.family = FONT, font.size = 12, bold = TRUE, italic = TRUE)
note_fp <- fp_text(font.family = FONT, font.size = 9)

par_body <- fp_par(line_spacing = 2, text.align = "justify",
                   padding.top = 0, padding.bottom = 6)   # double-spaced for review
par_head <- fp_par(line_spacing = 1.5, padding.top = 12, padding.bottom = 4)
par_ttl  <- fp_par(line_spacing = 1.5, padding.bottom = 10)
par_note <- fp_par(line_spacing = 1, padding.top = 2, padding.bottom = 2)
par_bul  <- fp_par(line_spacing = 1.5, padding.left = 18, padding.bottom = 4)

# --- inline markdown: **bold**, *italic*, and <sup>superscript</sup> -------
# Superscripts matter here: affiliation markers on the title page must be real
# Word superscripts, not literal "<sup>1</sup>" text.
sup_of <- function(fp) update(fp, vertical.align = "superscript")

.emph <- function(txt, base, b, i) {
  runs <- list()
  parts <- strsplit(txt, "(\\*\\*)", perl = TRUE)[[1]]
  for (k in seq_along(parts)) {
    seg <- parts[k]
    if (!nchar(seg)) next
    if (k %% 2 == 0) {
      runs[[length(runs) + 1]] <- ftext(seg, prop = b)
    } else {
      sub2 <- strsplit(seg, "(\\*)", perl = TRUE)[[1]]
      for (m in seq_along(sub2)) {
        s2 <- sub2[m]
        if (!nchar(s2)) next
        runs[[length(runs) + 1]] <- ftext(s2, prop = if (m %% 2 == 0) i else base)
      }
    }
  }
  runs
}

rich <- function(txt, fp_p = par_body, base = body_fp,
                 b = bold_fp, i = ital_fp) {
  txt <- gsub("`", "", txt)
  txt <- gsub("&nbsp;", " ", txt, fixed = TRUE)
  pieces <- strsplit(txt, "<sup>|</sup>", perl = TRUE)[[1]]
  is_sup <- rep(FALSE, length(pieces))
  if (grepl("<sup>", txt)) is_sup <- seq_along(pieces) %% 2 == 0
  runs <- list()
  for (k in seq_along(pieces)) {
    seg <- pieces[k]
    if (!nchar(seg)) next
    if (is_sup[k]) {
      runs[[length(runs) + 1]] <- ftext(trimws(seg), prop = sup_of(base))
    } else {
      runs <- c(runs, .emph(seg, base, b, i))
    }
  }
  if (!length(runs)) runs <- list(ftext("", prop = base))
  do.call(fpar, c(runs, list(fp_p = fp_p)))
}

# --- markdown table block -> flextable -------------------------------------
md_table <- function(lines) {
  cells <- lapply(lines, function(l) {
    x <- strsplit(sub("^\\|", "", sub("\\|$", "", l)), "\\|")[[1]]
    trimws(gsub("&nbsp;", " ", gsub("\\*\\*", "", x), fixed = FALSE))
  })
  hdr <- cells[[1]]
  body <- cells[-c(1, 2)]                      # drop the |---| separator row
  nc <- length(hdr)
  body <- lapply(body, function(r) { length(r) <- nc; ifelse(is.na(r), "", r) })
  df <- as.data.frame(do.call(rbind, body), stringsAsFactors = FALSE)
  names(df) <- make.unique(ifelse(nzchar(hdr), hdr, paste0("V", seq_len(nc))))
  ft <- flextable(df) |>
    font(fontname = FONT, part = "all") |>
    fontsize(size = 9, part = "all") |>
    bold(part = "header") |>
    padding(padding.top = 2, padding.bottom = 2, part = "all") |>
    align(j = 1, align = "left", part = "all") |>
    border_remove() |>
    hline_top(part = "header", border = fp_border(width = 1)) |>
    hline_bottom(part = "header", border = fp_border(width = .5)) |>
    hline_bottom(part = "body", border = fp_border(width = 1)) |>
    set_table_properties(layout = "autofit", width = 1)
  if (nc > 1) ft <- align(ft, j = 2:nc, align = "center", part = "all")
  ft
}

# --- markdown document -> officer docx -------------------------------------
md_to_docx <- function(md_file, out_file, title_size_first = TRUE,
                       break_on_section = TRUE) {
  ln <- readLines(md_file, warn = FALSE, encoding = "UTF-8")
  doc <- read_docx()
  i <- 1
  wrote_any <- FALSE   # so the first section does not open with a blank page
  while (i <= length(ln)) {
    l <- ln[i]
    if (grepl("^\\s*$", l)) { i <- i + 1; next }
    if (grepl("^---+\\s*$", l)) { i <- i + 1; next }

    # table block
    if (grepl("^\\|", l)) {
      j <- i
      while (j <= length(ln) && grepl("^\\|", ln[j])) j <- j + 1
      blk <- ln[i:(j - 1)]
      if (length(blk) >= 2) doc <- body_add_flextable(doc, md_table(blk))
      wrote_any <- TRUE
      doc <- body_add_fpar(doc, fpar(ftext("", prop = note_fp), fp_p = par_note))
      i <- j; next
    }
    # headings
    if (grepl("^# ", l)) {
      doc <- body_add_fpar(doc, rich(sub("^# ", "", l),
                                     if (title_size_first) par_ttl else par_head,
                                     base = ttl_fp, b = ttl_fp, i = ttl_fp))
      wrote_any <- TRUE
      i <- i + 1; next
    }
    if (grepl("^## ", l)) {
      # each major section opens on its own page
      if (break_on_section && wrote_any) doc <- body_add_break(doc)
      doc <- body_add_fpar(doc, rich(sub("^## ", "", l), par_head,
                                     base = h1_fp, b = h1_fp, i = h1_fp))
      wrote_any <- TRUE
      i <- i + 1; next
    }
    if (grepl("^### ", l)) {
      doc <- body_add_fpar(doc, rich(sub("^### ", "", l), par_head,
                                     base = h2_fp, b = h2_fp, i = h2_fp))
      i <- i + 1; next
    }
    # bullets
    if (grepl("^[-*] ", l)) {
      doc <- body_add_fpar(doc, rich(paste0("\u2022  ", sub("^[-*] ", "", l)), par_bul))
      i <- i + 1; next
    }
    # plain paragraph
    doc <- body_add_fpar(doc, rich(l, par_body))
    wrote_any <- TRUE
    i <- i + 1
  }
  print(doc, target = out_file)
  invisible(out_file)
}

built <- character(0)

# --- 1. manuscript, with the reference list appended -----------------------
man_md  <- file.path(PROJ, "docs", "MANUSCRIPT_v1.md")
refs_md <- file.path(PROJ, "docs", "REFERENCES_ama.md")
tmp <- file.path(tempdir(), "manuscript_with_refs.md")
mm <- readLines(man_md, warn = FALSE, encoding = "UTF-8")
# replace the placeholder reference pointer with the real numbered list
k <- grep("^\\*\\(Full AMA-formatted list", mm)
if (length(k)) mm <- mm[-k]
writeLines(c(mm, "", readLines(refs_md, warn = FALSE, encoding = "UTF-8")), tmp, useBytes = TRUE)
built <- c(built, md_to_docx(tmp, file.path(SUB, "Manuscript.docx")))

# --- 2. tables, 3. title page, 4. highlights -------------------------------
built <- c(built, md_to_docx(file.path(PROJ, "docs", "TABLES.md"),
                             file.path(SUB, "Tables.docx")))
# the title page is a single front-matter page: its subheadings must not each
# open a new page
built <- c(built, md_to_docx(file.path(SUB, "Title_Page.md"),
                             file.path(SUB, "Title_Page.docx"),
                             break_on_section = FALSE))
# cover letter: continuous prose, no page breaks between its headings
built <- c(built, md_to_docx(file.path(SUB, "Cover_Letter.md"),
                             file.path(SUB, "Cover_Letter.docx"),
                             break_on_section = FALSE))
built <- c(built, md_to_docx(file.path(SUB, "highlights.md"),
                             file.path(SUB, "Highlights.docx"),
                             break_on_section = FALSE))

# --- 5. figures -------------------------------------------------------------
figs <- list.files(file.path(PROJ, "figures"), pattern = "\\.tiff$", full.names = TRUE)
if (length(figs)) {
  doc <- read_docx()
  doc <- body_add_fpar(doc, rich("Figures", par_ttl, base = ttl_fp, b = ttl_fp, i = ttl_fp))
  png_dir <- file.path(SUB, "figures_png"); dir.create(png_dir, showWarnings = FALSE)
  for (f in sort(figs)) {
    nm <- tools::file_path_sans_ext(basename(f))
    doc <- body_add_fpar(doc, rich(gsub("_", " ", nm), par_head, base = h1_fp, b = h1_fp, i = h1_fp))
    if (HAVE_MAGICK) {
      png <- file.path(png_dir, paste0(nm, ".png"))
      if (!file.exists(png) || file.mtime(f) > file.mtime(png))
        magick::image_write(magick::image_read(f), png, format = "png")
      doc <- body_add_img(doc, png, width = 6.3,
                          height = 6.3 * (magick::image_info(magick::image_read(png))$height /
                                          magick::image_info(magick::image_read(png))$width))
    } else {
      doc <- body_add_fpar(doc, rich(
        paste0("[", basename(f), " - submit the TIFF separately; magick not installed",
               " so the image could not be embedded]"), par_note, base = note_fp))
    }
    doc <- body_add_break(doc)
  }
  print(doc, target = file.path(SUB, "Figures.docx"))
  built <- c(built, file.path(SUB, "Figures.docx"))
}

cat("\nBuilt into Journal-of-Critical-Care/:\n")
for (f in built) cat(sprintf("  %-22s %6.0f KB\n", basename(f), file.size(f) / 1024))
if (!HAVE_MAGICK) cat("\n  NOTE: magick not installed; figures not embedded. Submit the TIFFs.\n")
cat("\nSource of truth remains the markdown in docs/. Re-run this script after any edit.\n")
