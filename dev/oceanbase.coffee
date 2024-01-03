#!/usr/bin/env coffee

> @3-/write
  path > join
  ./conf > ROOT

{
  MYSQL_PWD
  MYSQL_NAME
  MYSQL_USER
  MYSQL_TENANT
} = process.env

sql = """
ALTER USER root@'%' IDENTIFIED BY '#{MYSQL_PWD}';
CREATE DATABASE IF NOT EXISTS #{MYSQL_NAME};
"""

if MYSQL_USER != "root"
  sql += """
CREATE USER '#{MYSQL_USER}'@'%' IDENTIFIED BY '#{MYSQL_PWD}';
GRANT ALL PRIVILEGES ON #{MYSQL_NAME}.* TO '#{MYSQL_USER}'@'%';
"""

write(
  join ROOT, "conf/init/oceanbase/init.sql"
  sql
)
