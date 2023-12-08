#!/usr/bin/env coffee

> ./conf.coffee > ROOT
  @3-/walk
  @3-/dbq > $e
  @3-/nt/load
  fs > existsSync
  path > dirname join

BASE = dirname(ROOT)
MOD = join BASE, 'mod'

load_nt = (dir, nt)=>
  pli = []
  vli = []

  for [sh, minute_timeout] from Object.entries nt
    minute_timeout = minute_timeout.split(' ').map (i)=>Number.parseInt(i)
    console.log dir,sh,minute_timeout
    pli.push '(?,?,?,?)'
    vli.push dir, sh, ...minute_timeout

  if not vli.length
    return
  $e(
    "INSERT IGNORE INTO cron (dir,sh,minute,timeout) VALUES #{pli.join(',')}"
    ...vli
  )

for mod from load MOD+'.nt'
  dir = join MOD,mod
  cron_nt = join dir,'cron/cron.nt'
  if existsSync cron_nt
    nt = load cron_nt
    await load_nt mod, nt

process.exit()
