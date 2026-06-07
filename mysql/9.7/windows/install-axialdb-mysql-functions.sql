-- Register AxialDB helper UDFs (run after INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll').
-- MySQL 9.7: DROP FUNCTION first if re-installing after DLL upgrade.

DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;

CREATE FUNCTION axialdb_init RETURNS STRING
  SONAME 'ha_axialdb.dll';

CREATE FUNCTION axialdb_drop_view RETURNS STRING
  SONAME 'ha_axialdb.dll';
