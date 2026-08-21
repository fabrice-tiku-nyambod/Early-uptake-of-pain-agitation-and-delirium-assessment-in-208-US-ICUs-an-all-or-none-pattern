-- ---------------------------------------------------------------------------
-- Audit of what the delirium match in 01_build_cohort.sql actually captures.
--
-- LIKE '%delirium%' catches two distinct fields, and they are not equivalent:
--   'Delirium Scale/Score'         -- holds CAM-ICU and ICDSC, validated tools
--   'Symptoms of Delirium Present' -- a Yes/No nursing impression, NOT a
--                                     validated instrument
--
-- PADIS requires screening with a VALIDATED tool, so a hospital charting only
-- the second is arguably not screening in the guideline sense. This counts, per
-- hospital and over the same cohort as the main extraction, how many stays each
-- field covers, so a strict-definition sensitivity analysis can be run.
-- ---------------------------------------------------------------------------
WITH coh AS (
  SELECT patientunitstayid, hospitalid
  FROM `physionet-data.eicu_crd.patient`
  WHERE unitvisitnumber = 1
    AND unitdischargeoffset >= 1440
    AND (SAFE_CAST(age AS INT64) >= 18 OR age = '> 89')
),
nc AS (
  SELECT patientunitstayid,
    MAX(CASE WHEN nursingchartcelltypevallabel = 'Delirium Scale/Score'
             THEN 1 ELSE 0 END) AS validated_tool,
    MAX(CASE WHEN nursingchartcelltypevallabel = 'Symptoms of Delirium Present'
             THEN 1 ELSE 0 END) AS impression_only
  FROM `physionet-data.eicu_crd.nursecharting`
  WHERE nursingchartoffset BETWEEN 0 AND 10080
    AND nursingchartcelltypevallabel IN ('Delirium Scale/Score',
                                         'Symptoms of Delirium Present')
  GROUP BY 1
)
SELECT c.hospitalid,
       COUNT(*)                                          AS n_stays,
       SUM(COALESCE(nc.validated_tool, 0))               AS n_validated,
       SUM(COALESCE(nc.impression_only, 0))              AS n_impression,
       SUM(CASE WHEN COALESCE(nc.validated_tool,0) = 0
                 AND COALESCE(nc.impression_only,0) = 1
                THEN 1 ELSE 0 END)                       AS n_impression_only
FROM coh c
LEFT JOIN nc USING (patientunitstayid)
GROUP BY 1
ORDER BY n_stays DESC
