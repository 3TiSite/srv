#!/usr/bin/env coffee

> @3-/write
  path > join
  ./conf > ROOT

{
  MYSQL_PWD
  MYSQL_NAME
  MYSQL_USER
} = process.env

sql = """
CREATE DATABASE `#{MYSQL_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"""

if MYSQL_USER != "root"
  sql += """
CREATE USER '#{MYSQL_USER}'@'%' IDENTIFIED BY '#{MYSQL_PWD}';
GRANT ALL PRIVILEGES ON #{MYSQL_NAME}.* TO '#{MYSQL_USER}'@'%';
"""

write(
  join ROOT, "conf/init/mariadb/init.sql"
  sql
)
