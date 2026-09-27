-- Register AxialDB helper UDFs (run after INSTALL PLUGIN axialdb SONAME 'ha_axialdb.dll').
-- MySQL 9.7: DROP FUNCTION first if re-installing after DLL upgrade.

DROP FUNCTION IF EXISTS axialdb_init;
DROP FUNCTION IF EXISTS axialdb_drop_view;
DROP FUNCTION IF EXISTS axialdb_cdc_publish;
DROP FUNCTION IF EXISTS axialdb_cdc_status;

CREATE FUNCTION axialdb_init RETURNS STRING
  SONAME 'ha_axialdb.dll';

CREATE FUNCTION axialdb_drop_view RETURNS STRING
  SONAME 'ha_axialdb.dll';

CREATE FUNCTION axialdb_cdc_publish RETURNS STRING
  SONAME 'ha_axialdb.dll';

CREATE FUNCTION axialdb_cdc_status RETURNS STRING
  SONAME 'ha_axialdb.dll';
