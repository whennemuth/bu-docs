CREATE OR REPLACE PROCEDURE drop_all_tables IS
CURSOR fke_cur IS
SELECT table_name
FROM user_tables;
ExStr VARCHAR2(4000);
BEGIN
  dbms_output.put_line('DROPPING ALL TABLES');
  FOR fke_rec IN fke_cur
  LOOP
    dbms_output.put_line('Dropping ' || fke_rec.table_name);
    ExStr := 'DROP TABLE "' || fke_rec.table_name || '"';
    BEGIN
      EXECUTE IMMEDIATE ExStr;
    EXCEPTION
      WHEN OTHERS THEN
               dbms_output.put_line('Dynamic SQL Failure: ' || SQLERRM);
               dbms_output.put_line('On statement: ' || ExStr);    END;
  END LOOP;
END drop_all_tables;
/