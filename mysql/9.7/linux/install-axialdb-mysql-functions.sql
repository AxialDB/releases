-- Register AxialDB helper UDFs (run after INSTALL PLUGIN axialdb SONAME 'ha_axialdb.so').
-- MySQL 9.7 Linux: DROP FUNCTION first if re-installing after .so upgrade.

DROP FUNCTION IF EXISTS analytics_init;
DROP FUNCTION IF EXISTS analytics_drop_view;
DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;

CREATE FUNCTION axialdb_init RETURNS STRING
  SONAME 'ha_axialdb.so';

CREATE FUNCTION axialdb_drop_view RETURNS STRING
  SONAME 'ha_axialdb.so';
