SET SERVEROUTPUT ON;
execute drop_all_constraints;
PURGE RECYCLEBIN;
execute drop_all_indexes;
PURGE RECYCLEBIN;
execute drop_all_tables;
PURGE RECYCLEBIN;
SET SERVEROUTPUT OFF;