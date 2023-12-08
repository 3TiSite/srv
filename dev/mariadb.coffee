#!/usr/bin/env coffee

> @3-/write
  path > join
  ./conf > ROOT

{
  DB_PASSWORD
  DB_NAME
  DB_USER
} = process.env

sql = """
CREATE DATABASE `#{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"""

if DB_USER != "root"
  sql += """
CREATE USER '#{DB_USER}'@'%' IDENTIFIED BY '#{DB_PASSWORD}';
GRANT ALL PRIVILEGES ON #{DB_NAME}.* TO '#{DB_USER}'@'%';
"""

write(
  join ROOT, "conf/init/mariadb/init.sql"
  sql
)
