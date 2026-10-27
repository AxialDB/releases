-- Register AxialDB helper UDFs (run after INSTALL PLUGIN axialdb SONAME 'ha_axialdb.so').
-- MySQL 9.7 Linux: DROP FUNCTION first if re-installing after .so upgrade.

-- A replica does not carry the AxialDB plugin. CREATE FUNCTION ... SONAME is
-- written to the binary log, and a replica that cannot load the library would
-- stop on it. Keep these statements out of the binary log.
SET sql_log_bin = 0;

DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
-- From earlier releases; no longer installed.
DROP FUNCTION IF EXISTS axialdb_cdc_publish;
DROP FUNCTION IF EXISTS axialdb_cdc_status;

CREATE FUNCTION axialdb_init RETURNS STRING
  SONAME 'ha_axialdb.so';

CREATE FUNCTION axialdb_drop_view RETURNS STRING
  SONAME 'ha_axialdb.so';

CREATE FUNCTION axialdb_cdc_status RETURNS STRING
  SONAME 'ha_axialdb.so';

SET sql_log_bin = 1;
