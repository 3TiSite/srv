#!/usr/bin/env coffee

> @3-/write
  path > join
  ./conf > ROOT

{
  DB_PASSWORD
  DB_NAME
  DB_USER
  DB_TENANT
} = process.env

sql = """
ALTER USER root@'%' IDENTIFIED BY '#{DB_PASSWORD}';
CREATE DATABASE IF NOT EXISTS #{DB_NAME};
"""

if DB_USER != "root"
  sql += """
CREATE USER '#{DB_USER}'@'%' IDENTIFIED BY '#{DB_PASSWORD}';
GRANT ALL PRIVILEGES ON #{DB_NAME}.* TO '#{DB_USER}'@'%';
"""

write(
  join ROOT, "conf/init/oceanbase/init.sql"
  sql
)
