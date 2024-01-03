#!/usr/bin/env coffee

> path > join resolve basename dirname
  chalk
  fs > existsSync readdirSync statSync
  @3-/uridir
  zx/globals:
  @3-/dbq > $e
  @3-/read
  @3-/walk
  @3-/nt/load.js

{greenBright, gray} = chalk

ROOT = resolve(
  uridir import.meta
  '../../..'
)

{
  MYSQL_NAME
  MYSQL_HOST
  MYSQL_PASSWORD
  MYSQL_PORT
  MYSQL_USER
} = process.env

scan = (dir)=>
  if not existsSync dir
    return
  dirli = readdirSync dir
  table = 'table'
  p = dirli.indexOf(table)
  if p > 0
    dirli.splice(p, 1)
    dirli.unshift table
  for subdir from dirli
    ndir = join(dir,subdir)
    if statSync(ndir).isFile()
      continue
    for await i from walk ndir
      if i.endsWith '.sql'
        rfp = i.slice(ROOT.length+1)
        console.log greenBright rfp
        sql = read i
        kind = basename dirname(rfp)
        len = ('CREATE '+kind).length
        sql = sql.slice(0,len)+' IF NOT EXISTS'+sql.slice(len)
        if ['function','procedure','trigger'].includes(kind)
          li = [sql]
        else
          li = sql.split(';\n').filter((i)=>i.length).map((i)=>i+';')
        for i from li
          console.log gray(i)
          await $e(i)
  init_sql = join dir,'init.sql'
  if existsSync init_sql
     await $"MYSQL_PWD=#{MYSQL_PASSWORD} mysql -h #{MYSQL_HOST} -P#{MYSQL_PORT} -u #{MYSQL_USER} #{MYSQL_NAME} < #{init_sql}"
  return

await scan join ROOT,'db'
for i from load join ROOT, 'mod.nt'
  await scan join ROOT,'mod',i,'db'

process.exit()
