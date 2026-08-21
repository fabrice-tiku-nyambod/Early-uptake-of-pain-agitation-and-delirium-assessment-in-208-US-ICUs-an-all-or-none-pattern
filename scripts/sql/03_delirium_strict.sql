-- ---------------------------------------------------------------------------
-- Strict delirium-assessment flag, per ICU stay
--
-- The label audit (02_delirium_label_audit.sql) established that the two
-- delirium-labeled nursecharting fields are NOT equivalent and are perfectly
-- disjoint:
--
--   'Delirium Scale/Score'          CAM-ICU and ICDSC -- validated instruments,
--                                   which is what PADIS actually requires
--   'Symptoms of Delirium Present'  a Yes/No nursing impression, not a tool
--
-- 01_build_cohort.sql matches LOWER(label) LIKE '%delirium%', so it counts both
-- and cannot distinguish them after the fact. This pulls the split per stay so
-- it can be joined onto the existing cohort without a full re-extraction.
--
-- Window matches the cohort exactly: first 7 days (0-10080 min).
-- ---------------------------------------------------------------------------
SELECT
  patientunitstayid,

  -- validated instrument only -- the strict definition
  MAX(CASE WHEN nursingchartcelltypevallabel = 'Delirium Scale/Score'
           THEN 1 ELSE 0 END)                        AS any_delirium_strict,
  SUM(CASE WHEN nursingchartcelltypevallabel = 'Delirium Scale/Score'
           THEN 1 ELSE 0 END)                        AS n_delirium_strict_obs,
  MIN(CASE WHEN nursingchartcelltypevallabel = 'Delirium Scale/Score'
           THEN nursingchartoffset END)              AS first_delirium_strict_offset,

  -- non-validated nursing impression, kept separately so the 12-hospital
  -- impression-only group can be identified rather than silently dropped
  MAX(CASE WHEN nursingchartcelltypevallabel = 'Symptoms of Delirium Present'
           THEN 1 ELSE 0 END)                        AS any_delirium_impression,
  SUM(CASE WHEN nursingchartcelltypevallabel = 'Symptoms of Delirium Present'
           THEN 1 ELSE 0 END)                        AS n_delirium_impression_obs

FROM `physionet-data.eicu_crd.nursecharting`
WHERE nursingchartoffset BETWEEN 0 AND 10080
  AND nursingchartcelltypevallabel IN ('Delirium Scale/Score',
                                       'Symptoms of Delirium Present')
GROUP BY patientunitstayid
