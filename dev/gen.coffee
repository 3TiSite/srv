#!/usr/bin/env coffee

> ./conf > ROOT
  @3-/write
  fs > existsSync
  @3-/nt/load.js
  path > join


yml = """version: '3'
services:"""

use = load join ROOT, 'use.nt'

for [name, file] from Object.entries use
  init = join ROOT, file+'.coffee'
  if existsSync init
    await import(init)
  yml += """
\n  #{name}:
    container_name: 3ti-#{name}
    extends:
      file: #{file}.yml
      service: #{name}
"""

write(
  join ROOT, 'docker-compose.yml'
  yml
)
