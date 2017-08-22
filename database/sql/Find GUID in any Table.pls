    SET SERVEROUTPUT ON SIZE 100000

    DECLARE
      match_count INTEGER;
    BEGIN
      FOR t IN (SELECT owner, table_name, column_name
                  FROM all_tab_columns
                  WHERE owner = 'KCOEUS' and data_type LIKE '%CHAR%') LOOP

        EXECUTE IMMEDIATE
          'SELECT COUNT(*) FROM ' || t.owner || '.' || t.table_name ||
          ' WHERE '||t.column_name||' = :1'
          INTO match_count
          USING 'F58756B2-5D40-2C9C-E37E-A076DA92B695';

        IF match_count > 0 THEN
          dbms_output.put_line( t.table_name ||' '||t.column_name||' '||match_count );
        END IF;

      END LOOP;

    END;
    /