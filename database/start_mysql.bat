# Start mysql and double some of the default resource values.
C:\whennemuth\downloads\mysql-5.7.11-winx64\bin\mysqld -u root ^
 --console ^
 --join_buffer_size=524288 ^
 --key_buffer_size=16777216 ^
 --read_buffer_size=262144 ^
 --read_rnd_buffer_size=524288 ^
 --sort_buffer_size=524288 ^
 --table_definition_cache=2800 ^
 --table_open_cache=4000 ^
 --innodb_buffer_pool_size=268435456 ^
 --query_cache_size=2097152