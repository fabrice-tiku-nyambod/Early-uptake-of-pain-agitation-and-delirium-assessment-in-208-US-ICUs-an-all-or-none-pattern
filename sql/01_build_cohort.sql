-- ---------------------------------------------------------------------------
-- Delirium and sedation assessment in US ICUs: analytic cohort
--
-- One row per ICU stay. The question is not "who was delirious" but
-- "who was ever ASSESSED", which is what the PADIS guideline requires and
-- what an EHR can answer without ascertainment bias.
--
-- Denominator: first ICU stays with LOS >= 24 h. A patient in and out inside
-- a day has no guideline obligation for routine screening.
-- ---------------------------------------------------------------------------
WITH assess AS (
  SELECT patientunitstayid,
    MAX(CASE WHEN cat='delirium' THEN 1 ELSE 0 END)          AS any_delirium_assess,
    MAX(CASE WHEN cat='sedation' THEN 1 ELSE 0 END)          AS any_sedation_assess,
    MAX(CASE WHEN cat='pain'     THEN 1 ELSE 0 END)          AS any_pain_assess,
    SUM(CASE WHEN cat='delirium' THEN 1 ELSE 0 END)          AS n_delirium_obs,
    SUM(CASE WHEN cat='sedation' THEN 1 ELSE 0 END)          AS n_sedation_obs,
    MIN(CASE WHEN cat='delirium' THEN off END)               AS first_delirium_offset
  FROM (
    SELECT patientunitstayid, nursingchartoffset AS off,
      CASE
        WHEN LOWER(nursingchartcelltypevallabel) LIKE '%delirium%' THEN 'delirium'
        WHEN LOWER(nursingchartcelltypevallabel) LIKE '%sedation%'
          OR nursingchartcelltypevallabel = 'RASS'                 THEN 'sedation'
        WHEN LOWER(nursingchartcelltypevallabel) LIKE '%pain%'     THEN 'pain'
      END AS cat
    FROM `physionet-data.eicu_crd.nursecharting`
    WHERE nursingchartoffset BETWEEN 0 AND 10080)      -- first 7 days
  WHERE cat IS NOT NULL
  GROUP BY 1),

apache AS (
  SELECT patientunitstayid,
         MAX(CASE WHEN apacheversion='IVa' THEN apachescore END)                AS apache_iva,
         MAX(CASE WHEN apacheversion='IVa' THEN predictedhospitalmortality END) AS pred_mort
  FROM `physionet-data.eicu_crd.apachepatientresult` GROUP BY 1),

vent AS (
  SELECT DISTINCT patientunitstayid, 1 AS ventilated
  FROM `physionet-data.eicu_crd.respiratorycharting`
  WHERE respchartvaluelabel = 'Tidal Volume (set)' AND respchartoffset BETWEEN 0 AND 10080)

SELECT p.patientunitstayid, p.hospitalid, p.unittype,
       SAFE_CAST(p.age AS INT64) AS age, p.gender, p.ethnicity,
       p.unitadmitsource, p.apacheadmissiondx,
       p.unitdischargeoffset, p.unitdischargestatus, p.hospitaldischargestatus,
       COALESCE(a.any_delirium_assess,0) AS any_delirium_assess,
       COALESCE(a.any_sedation_assess,0) AS any_sedation_assess,
       COALESCE(a.any_pain_assess,0)     AS any_pain_assess,
       COALESCE(a.n_delirium_obs,0)      AS n_delirium_obs,
       COALESCE(a.n_sedation_obs,0)      AS n_sedation_obs,
       a.first_delirium_offset,
       COALESCE(v.ventilated,0)          AS ventilated,
       ap.apache_iva, ap.pred_mort,
       h.numbedscategory, h.teachingstatus, h.region
FROM `physionet-data.eicu_crd.patient` p
LEFT JOIN assess a  USING (patientunitstayid)
LEFT JOIN vent   v  USING (patientunitstayid)
LEFT JOIN apache ap USING (patientunitstayid)
LEFT JOIN `physionet-data.eicu_crd.hospital` h USING (hospitalid)
WHERE p.unitvisitnumber = 1
  AND p.unitdischargeoffset >= 1440
  AND (SAFE_CAST(p.age AS INT64) >= 18 OR p.age = '> 89')
