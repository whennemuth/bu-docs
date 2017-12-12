create or replace PROCEDURE drop_all_triggers IS
CURSOR fke_cur IS
SELECT trigger_name FROM user_triggers;
ExStr VARCHAR2(4000);
BEGIN
  dbms_output.put_line('DROPPING ALL TRIGGERS');
  FOR fke_rec IN fke_cur
  LOOP
    dbms_output.put_line('Dropping COI.' || fke_rec.trigger_name);
    ExStr := 'DROP TRIGGER COI."' || fke_rec.trigger_name || '"';
    BEGIN
      EXECUTE IMMEDIATE ExStr;
    EXCEPTION
      WHEN OTHERS THEN
               dbms_output.put_line('Dynamic SQL Failure: ' || SQLERRM);
               dbms_output.put_line('On statement: ' || ExStr);    END;
  END LOOP;
END drop_all_triggers;
