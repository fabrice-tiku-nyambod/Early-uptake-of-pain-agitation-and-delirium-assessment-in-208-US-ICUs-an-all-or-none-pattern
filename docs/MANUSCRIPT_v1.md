# Early uptake of guideline-recommended pain, agitation, and delirium assessment in 208 US intensive care units: an all-or-none pattern

**Running head:** Early uptake of PAD assessment in US ICUs

**Authors:** Fabrice T. Nyambod, January G. Msemakweli, Aja Claris, Murishi Onesphore, Victor Okpanachi

**Corresponding author:** Fabrice T. Nyambod, Department of International Health, Johns Hopkins Bloomberg School of Public Health, 615 N. Wolfe St, Baltimore, MD 21205, USA. Email: ntiku2@jh.edu. ORCID: 0009-0006-6592-2673

*(Full author list with affiliations on the separate title page.)*

**Word count:** abstract 249; main text 4,225 (Introduction through Conclusions)

**Conflicts of interest:** none declared

**Funding:** none

---

## Highlights

- Documented delirium assessment nearly doubled in US ICUs from 2014 to 2015.
- The rise came from a few ICUs starting abruptly, not from gradual spread.
- 123 of 173 ICUs did not change their delirium screening over the period.
- Which ICU a patient entered explained 94% of variation in being assessed.
- Ventilated patients seemed less screened until hospital was accounted for.

---

## Abstract

**Purpose:** The 2013 American College of Critical Care Medicine guideline recommended routine assessment of pain, agitation, and delirium in adult intensive care unit (ICU) patients. We characterized early uptake across US ICUs in the two years after publication.

**Materials and methods:** Retrospective cohort study of 110,257 first ICU admissions lasting at least 24 hours among adults at 208 US hospitals in the eICU Collaborative Research Database, 2014-2015. The outcome was documented assessment in structured nursing charting within seven ICU days; delirium assessment required a validated instrument. We compared years nationally and within hospitals, quantified between-hospital variation with random-intercept logistic models, and tested for a structural non-adopter class.

**Results:** Documented delirium assessment rose from 11.2% of stays in 2014 to 21.3% in 2015 (16.5% overall); sedation assessment rose from 29.0% to 37.8% and pain assessment was unchanged. Of 173 hospitals present in both years, 123 showed no change, and 12 of 14 new adopters had documented no assessment in 2014. Of 190 hospitals, 138 (72.6%) documented no validated delirium assessment. The intraclass correlation was 0.936, unchanged by case-mix adjustment, and the structural non-adopter fraction 0.71 (95% CI 0.54-0.80). Overall, 67,545 stays (61.3%) occurred at hospitals with no screening program, rising to 67.5% among ventilated patients staying at least 48 hours.

**Conclusions:** Early uptake was real but discontinuous, arising from abrupt adoption in a minority of ICUs rather than diffusion. Assessment behaved as an all-or-none institutional property.

**Keywords:** delirium; guideline adherence; critical care; intensive care units; implementation science; practice variation; documentation

---

## 1. Introduction

The 2013 clinical practice guideline of the American College of Critical Care Medicine recommended that adult ICU patients be routinely monitored for pain, agitation, and delirium using validated instruments [1]. Delirium can be detected reliably at the bedside with the Confusion Assessment Method for the ICU (CAM-ICU) [2] or the Intensive Care Delirium Screening Checklist (ICDSC) [3], and is associated with long-term cognitive impairment among survivors [4,5]. It is also partly modifiable, since sedative choice influences its occurrence [6], and among mechanically ventilated patients its incidence and consequences are substantial [7]. The guideline was extended in 2018 [8–10], an update whose methodological quality has since been formally appraised [11], and monitoring now sits at the center of the ABCDEF bundle [12,13].

What happened in ordinary ICUs immediately after 2013 is far less clear. Existing evidence comes from surveys of clinician knowledge and reported barriers [14–16], from single-center or small multicenter implementation projects [17–19], or from voluntary collaboratives whose participating units had already chosen to change [12,20]. None answers the question of baseline uptake: across hospitals that did not volunteer for anything, how many adopted routine assessment, and how quickly?

Electronic records can answer this only if the question is framed carefully. A database establishes whether an assessment was documented; it cannot establish how many patients were delirious, because ascertainment depends on the screening behavior under study. We therefore treat documentation as the object of study, an organizational behavior rather than a proxy for a clinical state.

Using a database covering 2014 and 2015, the one-to-two-year window immediately following the guideline, we asked how far assessment had been adopted, whether change occurred through gradual diffusion or discrete adoption events, and how much of a patient's chance of being assessed was determined by which ICU they entered.

## 2. Materials and methods

### 2.1 Design, data source, and ethics

This retrospective cohort study of routinely collected electronic health record data follows the STROBE statement [21]. The unit of observation was the ICU admission; the unit of inference was the hospital and, where clustering required it, the contributing health system. All outcomes are documentation outcomes; no estimate of delirium incidence is offered.

The eICU Collaborative Research Database contains deidentified records from 208 US hospitals participating in a critical care telehealth program during 2014 and 2015 [22]. It is a convenience sample. Its structure and known data-quality characteristics have been described previously [23], and the limitations of secondary use of such records are recognized [24]. The database is available to credentialed users under a data use agreement; individual consent is waived and this analysis was exempt from institutional review board review.

### 2.2 Cohort

We included first ICU admissions of adults with a length of stay of at least 24 hours, on the grounds that no obligation for routine daily screening attaches to a patient admitted and discharged within a day. Age was recorded in aggregated form above 89 years; those admissions were retained with age set to 91. Repeat ICU admissions within the same hospitalization were excluded so that each patient contributed one observation.

### 2.3 Outcome definitions

The outcome was documentation of an assessment in structured nursing charting within the first seven ICU days. We enumerated all 65 distinct nursing chart labels recorded in that window and inspected the values held in each candidate field.

Delirium assessment appeared in two fields, mutually exclusive at the level of the individual stay. *Delirium Scale/Score* holds validated instrument results, predominantly CAM-ICU and less often ICDSC; both instruments have been validated across languages and care settings [25]. *Symptoms of Delirium Present* holds a yes/no nursing impression. Because the guideline specifies a validated tool [1], our primary definition required the former; a permissive definition combining both is reported alongside throughout.

Sedation assessment was captured by the *Sedation Scale/Score/Goal*, *SEDATION SCORE*, and *RASS* fields, and pain assessment by four pain-scoring fields, including behavioral scales for patients unable to self-report [26]. *Mental Status Assessment* and *Neurological Assessment* held checkbox entries rather than instrument results and were excluded.

Among stays with any documented assessment we characterized intensity by the interval to the first assessment, the number of assessments per stay, and the number per ICU day, the last computed as the count divided by length of stay in days with a floor of one day.

### 2.4 Covariates

Sex was recorded in the database as a binary administrative field and is reported here as sex rather than gender; no information on gender identity was available, and we did not undertake a sex- or gender-based analysis beyond adjustment. Patient covariates were age, sex, race and ethnicity as recorded, ICU type, length of stay, mechanical ventilation during the first seven days, and the Acute Physiology and Chronic Health Evaluation (APACHE) IVa score with its predicted hospital mortality; admissions carrying the unscorable sentinel of minus one were treated as missing. Hospital characteristics were teaching status, bed-size category, and census region. Bed size and region were missing for entire hospitals rather than individual patients, so models using them were fitted on complete cases and the excluded hospitals compared with those retained.

### 2.5 Hospital-level definitions

Hospitals contributing at least 25 qualifying stays were characterized individually (n = 190 of 208). Year-specific rates required at least 15 stays in that year, restricting paired year-on-year analysis to the 173 hospitals present in both. A hospital was termed an adopter of an assessment if it documented that assessment in at least 10% of its stays. Both thresholds are arbitrary and were varied in sensitivity analysis.

### 2.6 Statistical analysis

Continuous variables are summarized as medians with interquartile ranges and compared with the Wilcoxon rank-sum test; categorical variables as counts with percentages and compared with the chi-squared test or the test of proportions. Not-recorded categories are shown explicitly so that percentages sum to 100.

**Uptake.** We compared years nationally and within hospitals, the latter with the Wilcoxon signed-rank test on paired hospital rates, and tabulated hospitals increasing, decreasing, and unchanged, since a mean change can conceal a distribution in which most units do not move. For hospitals that became adopters we recorded which other bundle elements they already had.

**Between-hospital variation.** Random-intercept logistic models yielded the intraclass correlation coefficient [27], before and after adjustment for ventilation, age, sex, length of stay, and ICU type. We do not report the median odds ratio: with a large proportion of hospitals at exactly zero the model approaches quasi-separation and the statistic becomes unstable.

**Structural non-adoption.** Hartigan's dip test searches for a valley between modes, which a point mass at zero does not present; we report it only for completeness. The question that matters is whether the mass at zero exceeds what a single continuous distribution of hospital rates could produce by sampling alone, since a hospital with few stays and a low underlying rate will sometimes record none. We therefore compared a beta-binomial model, which permits no structural zeros, against a zero-inflated beta-binomial model by likelihood ratio test, with a boundary correction because the null value of the inflation parameter lies on the edge of the parameter space.

**Non-independence.** Hospital identifiers partly encode the contributing health system, and hospitals with adjacent identifiers share charting templates. We tested this by permuting adoption signatures over 10,000 shuffles, defined blocks as maximal runs of consecutive identifiers sharing a signature, and computed the resulting design effect. Confidence intervals for the non-adopter fraction come from a block bootstrap over 2,000 replicates resampling these blocks; the naive hospital-level bootstrap is reported alongside to show the understatement.

**Internal validity.** The principal threat is that absent documentation reflects absent charting rather than absent screening. Two internal comparisons address it: assessment types within the same hospital, since an ICU documenting pain routinely and delirium never possesses the charting infrastructure without applying it; and the association with mechanical ventilation within hospitals against the same association pooled across them.

**Population burden.** We report admissions occurring at hospitals with no documented validated assessment, and patients personally assessed, overall and in the ventilated subgroup.

**Outcome associations.** Screening status is constant within hospital, so a random intercept absorbs it and the model is not identified. We fitted fixed-effects models with standard errors clustered at the contributing system, adjusting for APACHE-predicted mortality on the logit scale, age, sex, ventilation, and ICU type. These compare institutions, not screened against unscreened patients.

**Sensitivity analyses.** We varied the minimum stays per hospital from 10 to 200, the adopter threshold from 1% to 50%, the minimum length of stay from 1 to 5 days, and the minimum stays per hospital-year from 10 to 40; repeated the analysis within each calendar year and among ventilated patients staying at least 48 hours; and refitted the intraclass correlation excluding each of the ten largest hospitals in turn.

Two-sided *P* values below 0.05 were considered significant. No adjustment was made for multiple comparisons; the analysis is descriptive and the intervals should be read accordingly.

### 2.7 Software

Analyses used R 4.6.0: *lme4* for mixed-effects models, *sandwich* and *lmtest* for cluster-robust variance, *diptest*, *cobalt* for covariate balance, *ggplot2* for figures, and *data.table*.

## 3. Results

### 3.1 Cohort

Cohort characteristics are shown in Table 1. The cohort comprised 110,257 first ICU admissions at 208 hospitals; 190 hospitals contributed at least 25 stays and 173 were present in both years. Median age was 65 years, 54.2% were male, and 26,131 stays (23.7%) involved mechanical ventilation.

### 3.2 National uptake, 2014 to 2015

Under the primary definition, requiring documentation of a validated instrument, delirium assessment appeared in 16.5% of stays. Under the permissive definition, which also counts the non-validated nursing impression field, the figure was 21.8% (95% CI 21.5–22.0); the 5.3-percentage-point difference corresponds to 5,844 stays. Sedation assessment was documented in 33.6% of stays and pain assessment in 41.5%.

Between 2014 and 2015, documented delirium assessment by validated instrument rose from 11.2% to 21.3% of stays (Table 2), a relative increase of 90%; under the permissive definition it rose from 16.7% to 26.5%. Sedation assessment rose from 29.0% to 37.8% (relative increase 31%). Pain assessment did not change (41.2% to 41.7%). All subsequent analyses use the validated-instrument definition unless stated otherwise.

### 3.3 The rise came from few hospitals

Among the 173 hospitals present in both years, the median hospital changed very little. Delirium screening rose from 11.0% to 16.8% of stays (+5.8 percentage points, *P* = 0.001) and sedation screening from 22.6% to 27.9% (+5.3 points, *P* = 0.002); pain screening was unchanged (-1.1 points, *P* = 0.658).

The distribution of change matters more than its average. For delirium, 32 hospitals increased, 18 decreased, and 123 did not move at all. Considering the three assessments together, 20 hospitals gained at least one element, 13 lost at least one, and 140 were unchanged (Figure 1). Of the 93 hospitals documenting none of the three assessments in 2014, 78 remained at none in 2015; only 15 gained any element.

Fourteen hospitals became delirium adopters during the period. Twelve of these began from a cold start, having documented neither pain nor sedation assessment in 2014; only one already had both. Several moved from essentially zero to near-universal screening within a single year — from 8.2% to 99.4%, from 7.6% to 97.4%, from 0% to 73.8%. This is the signature of a protocol being switched on, not of practice drifting upward.

### 3.4 Assessment is an all-or-none institutional property

Of 190 hospitals, 138 (72.6%) documented no validated delirium assessment at all; 41 (21.6%) reached the 10% adopter threshold (Figure 2, Table 3). Ninety hospitals (47.4%) documented none of the three assessments and 28 (14.7%) documented all three. Of 83 hospitals that screened for pain, only 35% also screened for delirium with a validated instrument. Adoption was piecemeal rather than sequential: 30 hospitals (15.8%) violated the nesting pain ≥ sedation ≥ delirium, so we make no claim about a fixed order of adoption.

The intraclass correlation for delirium assessment was 0.936, and for sedation and pain assessment 0.937 and 0.942. Case-mix adjustment left the between-hospital variance unchanged (100.7% of the unadjusted variance); no patient characteristic approached the size of the hospital effect.

Patients at adopter and non-adopter hospitals were closely comparable in severity of illness: standardized differences were -0.04 for APACHE IVa score, 0.01 for predicted hospital mortality, and -0.07 for age. Two case-mix differences did exceed the conventional 0.1 threshold — adopter hospitals cared for proportionally fewer mechanically ventilated patients (standardized difference -0.23) and fewer medical-surgical ICU patients (-0.24). These imbalances are the compositional mechanism behind the ventilation reversal described below, and they did not explain the between-hospital variation: adjusting for them changed the intraclass correlation not at all.

Hartigan's dip test did not reject unimodality for delirium (D = 0.029, *P* = 0.34); with a large point mass at zero there is no valley between modes for the test to find. The appropriate test is for excess zeros. A zero-inflated beta-binomial model fit better than a beta-binomial (*P* < 0.001), with a structural non-adopter fraction of 0.71 (block bootstrap 95% CI 0.54–0.80; the naive hospital-level bootstrap gives 0.61–0.77, an interval 1.6 times too narrow). The corresponding fractions were 0.52 for sedation (*P* < 0.001) and 0.30 for pain (*P* = 0.094, not significant). Structural non-adoption therefore strengthens across the bundle, being clearest for delirium and absent for pain.

Pooling two calendar years could in principle manufacture a partial rate at a hospital that adopted mid-period, or a zero at one that adopted late. It did not: computed within a single year the pattern was more extreme, not less. In 2014, 135 of 168 hospitals (80.4%) documented no validated delirium assessment and only 11.3% fell in the 10–90% band; in 2015 the figures were 72.5% and 13.5%.

Where screening occurred, it was thorough (Figure 3A). Among the 18,174 stays with a validated assessment, the first was documented a median of 4.5 hours after ICU admission (IQR 0.7–12.9), 84.2% within 24 hours; the median stay had 12 assessments (IQR 6–24), or 4.3 per ICU day. No screened stay contained a single isolated assessment (0.0%), and 82.4% met a twice-daily frequency. Partial compliance was therefore almost absent: 16.5% of all stays had any validated delirium assessment and 13.6% met twice-daily frequency.

### 3.5 Documentation reflects behavior, not charting capacity

Of the 138 hospitals documenting no validated delirium assessment, 86 documented none of the three assessment types and cannot be distinguished from hospitals that do not chart to structured fields. The remaining 52 documented sedation or pain while never documenting delirium. Restricting to the clearest cases, 45 hospitals documented pain or sedation assessment in at least 75% of stays and a validated delirium assessment in exactly 0%, across 29,035 stays, with median pain documentation of 92.1%: the same nurses and structured fields, applied to one assessment and not another. These hospitals fall into 20 distinct identifier blocks, so the pattern is not one system's artifact.

Separately, one contributing health system, comprising 12 hospitals with adjacent identifiers and covering 7,253 stays, documented only the non-validated impression field — a median of 77.3% of stays under the permissive definition and 0% under the validated-instrument definition. Because these hospitals share a charting template, this represents one organizational decision rather than twelve, but it illustrates how a permissive outcome definition can convert an entire system from non-adopter to adopter.

### 3.6 Ventilated patients and the hazard of pooled rates

Pooled across hospitals, ventilated patients appeared *less* likely to receive a validated delirium assessment than other patients (crude odds ratio [OR] 0.67, 95% CI 0.65–0.70). This is an artifact of where ventilated patients are cared for. Within hospitals the association reverses: ventilated patients were more likely to be assessed (OR 1.32, 95% CI 1.22–1.43, *P* < 0.001). The reversal arises because ventilated stays are over-represented at hospitals with little or no screening. A national rate computed across institutions with this much between-hospital variance can therefore invert the direction of a within-hospital association, and should be interpreted accordingly.

### 3.7 Population burden

Expressed at the level of the population rather than the institution (Figure 3B), 67,545 of 110,257 stays (61.3%) occurred at hospitals where no validated delirium assessment was documented for any patient, and 79,326 (71.9%) at hospitals screening fewer than 10% of their patients. Overall, 18,174 patients (16.5%) personally received a validated assessment.

The burden was concentrated where the recommendation is strongest. Among the 20,398 stays involving mechanical ventilation and lasting at least 48 hours, only 2,735 (13.4%) included a validated delirium assessment, and 13,772 (67.5%) occurred at hospitals with no screening program at all.

### 3.8 Predictors of adoption and sensitivity analyses

Teaching hospitals were more likely to be adopters (OR 6.48, 95% CI 1.43–39.20, *P* = 0.024), although only 18 teaching hospitals contributed. Bed size and annual volume showed no association. A regional association was observed (South versus Midwest OR 5.05, 95% CI 1.88–14.86), but its direction and magnitude changed substantially between the permissive and validated-instrument definitions, and given the clustering of hospitals within contributing systems we regard region here as a proxy for data contributor rather than geography and place no weight on it. Jointly, hospital characteristics were significant (*P* < 0.001; area under the curve 0.817) but explained only 24.7% of the between-hospital variance, moving the intraclass correlation from 0.936 to 0.917.

Findings were insensitive to analytic choices. Restricting to hospitals with at least 200 stays, 67.2% still documented no validated delirium assessment. Moving the adopter threshold from 1% to 50% changed the adopter count only from 48 to 26, because few hospitals occupy the middle. Screening did not increase with length of stay (16.5% at ≥1 day, 17.3% at ≥5 days). Among ventilated patients staying at least 48 hours — the population for which the recommendation is strongest — only 13.4% of stays had a validated assessment and 72.1% of hospitals documented none. The proportion of new adopters starting from a cold start was identical (12 of 14) at every hospital-year threshold from 10 to 40 stays.

Adoption signatures clustered strongly among adjacent hospital identifiers (128 adjacent matching pairs observed versus 48.3 expected under permutation, *P* = 0.0001). Grouping hospitals into 68 signature blocks implies a design effect of 2.79, so the effective number of independent units is closer to 68 than to 190.

The 17 hospitals excluded from the paired within-hospital analysis were smaller (median 49 versus 403 stays) and more often documented no screening at all (94.1% versus 70.5%). This exclusion therefore biases the paired analysis toward more screening, making our estimates conservative with respect to the paper's central claim.

## 4. Discussion

In the one to two years after the 2013 guideline, documented delirium assessment across a broad set of US ICUs approximately doubled. That headline is accurate and, taken alone, misleading. The increase did not come from many ICUs each screening somewhat more. It came from a small number of ICUs that began screening abruptly and comprehensively, most of them from a standing start, while the large majority did not change at all. Averaged across hospitals this looks like diffusion; disaggregated it is a set of discrete adoption events.

Three observations support reading assessment as an all-or-none institutional property rather than a gradient of quality. Which ICU a patient entered explained 94% of the variation in whether they were assessed, and case-mix adjustment did not reduce that at all. A structural non-adopter class was statistically supported, comprising roughly seven in ten hospitals. And where screening did occur it was dense and immediate — a median of 4.3 assessments per ICU day beginning about four hours after admission, with not one screened stay containing a single isolated assessment. ICUs ran a protocol or they ran nothing.

This has a direct consequence for how such data should be read. Our ventilated-patient result is the clearest example: pooled nationally, ventilated patients appeared *less* likely to be screened (OR 0.67), which would be a troubling finding since the recommendation is strongest for them. Within hospitals the association reversed (OR 1.32). The pooled figure was driven by where ventilated patients receive care, not by how clinicians treat them. Any national assessment rate computed across institutions with such extreme between-hospital variance should be interpreted with corresponding caution.

Our estimates are lower than those from implementation collaboratives, and the difference is instructive rather than contradictory. The ICU Liberation Collaborative reported substantially higher bundle performance across more than 15,000 adults [12], and multifaceted implementation programs have improved adherence and reduced brain dysfunction [17]; a recent systematic review confirms that active implementation strategies work [28]. But those units volunteered. Our hospitals did not, and the gap between them is a reasonable estimate of what implementation effort buys. Incomplete bundle utilization is not peculiar to adult practice, the same piecemeal pattern having been described in pediatric intensive care [20,29]. Sustained adherence years after implementation has been documented in single centers [18], and clinical decision support may help [30]; the barriers literature consistently identifies workload, knowledge, and perceived utility as obstacles [14,15,19,31].

The distinction between instruments deserves attention. One contributing health system, comprising twelve hospitals, documented delirium using a yes/no nursing impression rather than CAM-ICU or ICDSC. Under a permissive definition that system counts as an adopter; under the guideline's own standard it does not. Studies that count any delirium documentation will overstate guideline-concordant practice, and our own national figure falls from 21.8% to 16.5% when the standard is applied — a single organizational charting choice moving a national estimate by more than five percentage points.

That adoption was largely unpredictable from hospital characteristics is, we think, the most actionable finding. Teaching status was associated with adoption, but observable characteristics together explained only a quarter of the between-hospital variance. There is no identifiable class of hospital that adopts and another that does not, which argues against targeting implementation effort at a recognizable subgroup and in favor of treating non-adoption as a general condition. Whether a patient is assessed is not only a process metric: delirium is distressing to families, whose experience of it is imperfectly recognized by clinicians [33].

Hospital screening-program status was not associated with patient outcomes: adjusted hospital mortality did not differ between adopter and non-adopter hospitals (OR 0.99, 95% CI 0.87–1.13), nor did ICU length of stay. We report this and draw no inference from it. With an intraclass correlation of 0.936, screening status functions almost as a label for the institution, so the comparison is between institutions, and unmeasured differences in staffing, protocols, and case mix are not separable from screening. This design establishes who was assessed. It cannot establish what assessment achieves, and the null should not be read as evidence that screening does not help patients.

### 4.1 Limitations

Documentation is not practice. An assessment may be performed and not charted, and retrospective review of electronic records can diverge from prospective observation [32]; the reliability of secondary use of such data is itself an active question [24]. The internal comparison is our strongest defense: in the 45 hospitals described above, the charting infrastructure demonstrably existed and was not applied to delirium. For the 86 hospitals documenting nothing at all we cannot make this distinction, and we do not claim to.

The database is a convenience sample of hospitals contributing to a telemedicine program, containing only 18 teaching hospitals, and is not representative of US ICUs generally. The clustering of adoption signatures among adjacent hospital identifiers means the effective number of independent units is smaller than 190. With a design effect of 2.79 the effective count is nearer 68, the unit of inference is closer to the contributing health system than to the individual hospital, and we therefore report block-bootstrap intervals throughout; the naive hospital-level interval on the non-adopter fraction is 1.6 times too narrow. With only a discharge year available there are exactly two time points, which supports a before-and-after comparison but not a trend. Finally, the data predate the 2018 guideline [8]; our findings describe early uptake of the 2013 recommendation and should not be read as current practice.

## 5. Conclusions

Across 208 US ICUs in the two years after the 2013 pain, agitation, and delirium guideline, documented delirium assessment approximately doubled, but the increase came from a small number of ICUs adopting abruptly rather than from broad diffusion. Assessment behaved as an all-or-none institutional property: roughly seven in ten ICUs documented no validated assessment at all, and those that did screened thoroughly and without exception. Because adoption was largely unpredictable from hospital characteristics, efforts to improve delirium monitoring may be better directed at establishing programs where none exist than at improving performance where they already do.

---

## Declarations

**Ethics approval:** The eICU Collaborative Research Database is deidentified and publicly available under a data use agreement; this analysis was exempt from institutional review board review and the requirement for informed consent was waived.

**Data availability:** The database is available to credentialed users at https://eicu-crd.mit.edu. Analysis code is available from the corresponding author on reasonable request.

**Funding:** This research received no specific grant from any funding agency.

**Authors' contributions:** FTN conceived the study, developed the methodology and analysis code, and wrote the original draft. JGM contributed to methodology, curated data, and validated results. AC contributed to methodology and reviewed and edited the manuscript. MO reviewed and edited the manuscript and contributed to formal analysis. VO contributed software and formal analysis and supervised the work. All authors read and approved the final manuscript.

**Declaration of competing interest:** The authors declare no competing interests.

---

## Tables and figures

**Table 1.** Cohort characteristics, overall and by year.

**Table 2.** Documented assessment by element and year, nationally and within hospitals present in both years.

**Table 3.** Hospital-level adoption, between-hospital variation, and predictors of adoption.

**Figure 1. Change in documented delirium assessment, 2014 to 2015.**
Each line is one of the 173 hospitals contributing at least 15 qualifying stays in both calendar years. Hospitals that crossed the 10% adopter threshold between years are drawn in dark blue; all others are grey. Delirium is the validated-instrument definition. The fan rising out of zero, against a grey majority that does not move, is the paper's central observation: the aggregate increase came from a small number of hospitals switching on abruptly rather than from the field drifting upward together.
*(figures/Figure1_uptake.tiff; 4.6 x 4.2 in, 1200 dpi, LZW)*

**Figure 2. Documentation of pain and of validated delirium assessment within the same hospital.**
Each vertical line is one of the 190 hospitals contributing at least 25 qualifying stays, ordered by pain documentation. The upper point is the proportion of that hospital's stays with a pain assessment documented; the lower point is the proportion with a validated delirium assessment. The gap between them is the shortfall within a single institution, holding the nursing staff, the chart and the patient population constant. The long floor of points at zero beneath a high pain curve is the study's internal control: the charting infrastructure demonstrably exists and is not applied to delirium.
*(figures/Figure2_shortfall.tiff; 6.6 x 3.6 in, 1200 dpi, LZW)*

**Figure 3. Intensity of assessment where it occurred (A) and population burden (B).**
(A) Distribution of validated delirium assessments per ICU day among the 18,174 stays in which any such assessment was documented; the dashed line marks the twice-daily frequency the guideline implies, and the rightmost bar collects stays at 12 or more per day. Where screening happened it was dense rather than occasional. (B) All 110,257 qualifying stays classified by the screening rate of the hospital that treated them. The majority were cared for at hospitals documenting no validated delirium assessment for any patient.
*(figures/Figure3_intensity_burden.tiff; 6.8 x 5.2 in, 1200 dpi, LZW)*

---

## Acknowledgements

[Complete or delete before submission.]

## Declaration of generative AI and AI-assisted technologies in the manuscript preparation process

During the preparation of this work the authors used Grammarly in order to assist with grammar checking, language editing, and reference formatting. After using this tool, the authors reviewed and edited the content as needed and take full responsibility for the content of the published article. No AI tool is listed as an author.

## References

*(Full AMA-formatted list in `docs/REFERENCES_ama.md`; every entry retrieved from a live Crossref API response.)*
