use kc;

SELECT DISTINCT n.entity_id,
  concat(n.FIRST_NM, ' ', n.LAST_NM) AS fullname,
  g.grp_nm,
  r.role_nm
FROM krim_entity_t e,
  krim_entity_nm_t n,
  krim_grp_t g,
  krim_grp_mbr_t gm,
  krim_role_t r,
  krim_role_mbr_t rm
WHERE e.entity_id = n.entity_id
AND g.grp_id = gm.grp_id
AND ((gm.mbr_id = e.entity_id and gm.mbr_typ_cd = 'P')
  OR (rm.mbr_id = n.entity_id and rm.mbr_typ_cd = 'P')
)
AND r.role_id = rm.role_id
ORDER BY n.entity_id,
  g.grp_nm,
  r.role_nm;


SELECT 
-- DISTINCT 
  n.entity_id,
  concat(n.FIRST_NM, ' ', n.LAST_NM) AS fullname,
  r.*
--  r.role_nm -- ,
--  p.NM, p.NMSPC_CD, p.DESC_TXT
FROM 
  krim_entity_nm_t n,
  krim_role_t r,
  krim_role_mbr_t rm -- ,
--  krim_perm_t p,
--  krim_role_perm_t rp
WHERE rm.mbr_id = n.entity_id 
and rm.mbr_typ_cd = 'P'
AND r.role_id = rm.role_id
-- and p.perm_id = rp.perm_id
-- and rp.role_id = r.role_id
ORDER BY n.entity_id,
  r.role_nm -- , p.NM;
  
SELECT 
-- DISTINCT 
  n.entity_id,
  concat(n.FIRST_NM, ' ', n.LAST_NM) AS fullname,
  g.grp_nm
FROM 
  krim_entity_nm_t n,
  krim_grp_t g,
  krim_grp_mbr_t gm
WHERE gm.mbr_id = n.entity_id 
and gm.mbr_typ_cd = 'P'
AND g.grp_id = gm.grp_id
ORDER BY n.entity_id,
  g.grp_nm;
  
