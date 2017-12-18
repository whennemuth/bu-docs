create or replace PROCEDURE drop_all_sequences IS
CURSOR fke_cur IS
SELECT sequence_name
FROM user_sequences;
ExStr VARCHAR2(4000);
BEGIN
  dbms_output.put_line('DROPPING ALL SEQUENCES');
  FOR fke_rec IN fke_cur
  LOOP
    dbms_output.put_line('Dropping ' || fke_rec.sequence_name);
    ExStr := 'DROP SEQUENCE "' || fke_rec.sequence_name || '"';
    BEGIN
      EXECUTE IMMEDIATE ExStr;
    EXCEPTION
      WHEN OTHERS THEN
               dbms_output.put_line('Dynamic SQL Failure: ' || SQLERRM);
               dbms_output.put_line('On statement: ' || ExStr);    END;
  END LOOP;
END drop_all_sequences;
