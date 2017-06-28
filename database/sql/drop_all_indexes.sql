CREATE OR REPLACE PROCEDURE drop_all_indexes IS
CURSOR fke_cur IS
SELECT table_name, index_name
FROM user_indexes;
ExStr VARCHAR2(4000);
BEGIN
  dbms_output.put_line('DROPPING ALL INDEXES');
  FOR fke_rec IN fke_cur
  LOOP
    dbms_output.put_line('Dropping ' || fke_rec.table_name || '.' || fke_rec.index_name);
    ExStr := 'DROP INDEX "' || fke_rec.index_name || '"';
    BEGIN
      EXECUTE IMMEDIATE ExStr;
    EXCEPTION
      WHEN OTHERS THEN
               dbms_output.put_line('Dynamic SQL Failure: ' || SQLERRM);
               dbms_output.put_line('On statement: ' || ExStr);    END;
  END LOOP;
END drop_all_indexes;
/