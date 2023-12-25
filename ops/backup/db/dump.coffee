#!/usr/bin/env coffee

> path > join resolve
  fs > existsSync rmSync
  @3-/uridir
  @3-/read
  @3-/write
  @3-/nt/load.js

firstUpperCase = (str) =>
  for ch, i in str
    if ch == ch.toUpperCase()
      return i
  return -1

GEN = []

gen = (kind, name, sql)=>
  console.log kind,name
  if kind != 'function'
    return
  sql = sql.replace(/\sBEGIN\s/,'\nBEGIN\n').replace('\nRETURNS',' RETURNS')
  p = sql.indexOf '('
  end = sql.indexOf('\nBEGIN\n',++p)
  args = sql.slice(p, end)
  body = sql.slice(end)
  p = args.lastIndexOf ' RETURNS '
  if p<0
    return
  _return = args.slice(p+9)
  args = args.slice(0,p)
  args = args.slice(0,args.lastIndexOf(')')).split(',').map(
    (i)=>i.replaceAll('`','').trim()
  )
  _return_type = new Set()
  for i from body.split('\n')
    i = i.trim()
    if i.startsWith('RETURN ') and i.endsWith(';')
      _return_type.add i.slice(7,-1)

  option = 0
  if _return_type.has 'NULL'
    if _return_type.size == 1
      _return = ''
    else
      option = 1

  GEN.push [
    name
    args
    _return
    option
  ]
  return

{
  DB_NAME
} = process.env

PWD = uridir(import.meta)
ROOT = resolve PWD,'../../..'
MOD = join ROOT, 'mod'
DUMP_SQL = join PWD, DB_NAME+'.sql'

li = []
sql = read(DUMP_SQL).replaceAll(
  ' unsigned',' UNSIGNED'
).replaceAll(
  ' return '
  ' RETURN '
).replaceAll(
  ' returns '
  ' RETURNS '
)
for t from [
  [/ varbinary\b/gi, ' VARBINARY']
  [/ varchar\b/gi, ' VARCHAR']
  [/ binary\b/gi, ' BINARY']

  [/ tinyint\b/gi, ' TINYINT']
  [/ smallint\b/gi, ' SMALLINT']
  [/ int\b/gi, ' INT']
  [/ mediumint\b/gi, ' MEDIUMINT']
  [/ bigint\b/gi,' BIGINT']

  [/ tinyint\(\d+\)/gi, ' TINYINT']
  [/ smallint\(\d+\)/gi, ' SMALLINT']
  [/ int\(\d+\)/gi, ' INT']
  [/ mediumint\(\d+\)/gi, ' MEDIUMINT']
  [/ bigint\(\d+\)/gi,' BIGINT']
  [/ null\b/gi,' NULL']
  [/ text\b/gi, ' TEXT']
  [/ blob\b/gi, ' BLOB']
  [/ longblob\b/gi, ' LONGBLOB']
  [/ longtext\b/gi, ' LONGTEXT']
  [/ mediumblob\b/gi, ' MEDIUMBLOB']
  [/ mediumtext\b/gi, ' MEDIUMTEXT']
  [/\s*,\s*/g,',']
]
  sql = sql.replace(...t)

for i from sql.split('\n')
  i = i.trimEnd()
  len = i.length
  i = i.trimStart()
  indent = ''.padEnd(len-i.length)
  if not i
    continue

  if i.startsWith('/*!50003 CREATE*/')
    i = 'CREATE'+i.slice(i.lastIndexOf('/*!50003')+8).replace(' IF NOT EXISTS','')
    li.push i
    continue

  if i.startsWith('--')
    continue
  else if i.startsWith('/*')
    continue
  else if i.startsWith(') ENGINE=')
    i = ');'
  else if i.startsWith 'CREATE DEFINER='
    p = i.indexOf('` ')
    if ~p
      i = 'CREATE'+i.slice(p+1)


  if i.endsWith ('*/;;')
    i = i.slice(0,-4)+';;'
  li.push indent+i

create = /^CREATE (\w+) `?(\w+)`?/
r = []
t = []

+ kind, name

push = =>
  if t.length
    r.push [ kind, name, t.join('\n') ]
    t = []

for i from li
  if i == 'DELIMITER ;;'
    continue

  m = i.match(create)
  if m
    push()
    kind = m[1].toLowerCase()
    name = m[2]

  if i == 'DELIMITER ;'
    push()
    continue
  t.push i

push()

nt = load MOD+'.nt'

rm = (fp)=>
  rmSync(fp, { force: true, recursive: true })
  return

rmpre = (dir)=>
  for p from ['function','table','trigger','procedure']
    rm join dir,p
  return


if r.length
  mod = new Map
  for i from nt
    p = i.lastIndexOf '/'
    if p
      k = i.slice(p+1)
    else
      k = i
    mdir = join i,'db'
    mod.set k, mdir
    rmpre join MOD,mdir

  DUMP_DIR = join ROOT, 'db'

  rmpre DUMP_DIR

  for [kind,name,sql] from r
    p = firstUpperCase(name)
    if ~p
      prefix = name.slice(0,p)
      dump_name = name.slice(p)
    else
      prefix = dump_name = name

    m = mod.get(prefix)
    if m
      gen kind,name,sql
      write(
        join MOD, m, kind, dump_name+'.sql'
        sql
      )
      continue
    gen kind,name,sql
    write(
      join(DUMP_DIR, kind, name+'.sql')
      sql
    )

rm DUMP_SQL

INT_TYPE = {
  BIGINT: 64
  INT: 32
  MEDIUMINT: 32
  SMALLINT: 16
  TINYINT: 8
}
F_TYPE = {
  FLOAT: 'f32'
  DOUBLE: 'f64'
}
S_TYPE = {
  VARBINARY: 'String'
  VARCHAR: 'String'
  TEXT: 'String'
  MIDDLETEXT: 'String'
  LONGTEXT: 'String'
  BLOB: 'Vec<u8>'
  MEDIUMBLOB: 'Vec<u8>'
  LONGBLOB: 'Vec<u8>'
}

RT_TYPE = {
  ...F_TYPE
  ...S_TYPE
}

main = =>
  rust = [
    'pub use mysql_macro::*;\n'
  ]
# used = new Set ['Result']

  for [fn, args, _return, option] from GEN
    if _return
      t = _return.split ' '
      rtype = INT_TYPE[t[0]]
      if rtype
        if t[1] == 'UNSIGNED'
          rtype = 'u'+rtype
        else
          rtype = 'i'+rtype
      else
        [rtype]=t
        p = rtype.indexOf('(')
        if ~p
          rtype = rtype.slice(0,p)
        rtype = RT_TYPE[rtype] or rtype
      func = 'q1'
      if option
        rtype = 'Option<'+rtype+'>'
    else
      rtype = '()'
      func = 'exe'

    # used.add func
    format = 0
    qli = []
    mli = []
    ali = []
    fli = []
    for i from args
      [name,type] = i = i.split(' ')
      ty = INT_TYPE[type]
      qpush = (i)=>
        format = 1
        qli.push i
        return
      if ty
        if i[2] == 'UNSIGNED'
          ty = 'u'+ty
        else
          ty = 'i'+ty
        qpush("{#{name}}")
      else
        ty = F_TYPE[type]
        if ty
          qpush("{#{name}}")
        else
          p = type.indexOf '('
          if ~p
            num = +type.slice(p+1,-1)
            type = type.slice(0,p)
          ty = S_TYPE[type]
          qli.push('?')
          if ty
            if num != 255 and type.includes 'BINARY'
              ty = '&[u8]'
              fli.push name
            else
              ty = 'impl AsRef<str>'
              fli.push "#{name}.as_ref()"
          else if type == 'BINARY'
            ty = "[u8;#{num}]"
            fli.push name
          else
            console.log "⚠️ UNDEFINED",type, num
      ali.push("#{name}:#{ty}")
      mli.push name

    if fli.length
      fli = ','+fli.join(',')
    sql = JSON.stringify "SELECT #{fn}(#{qli.join(',')})"

    rust.push """
  pub async fn #{fn}(#{ali.join(',')})->Result<#{rtype}>{"""
    if format
      rust.push "let sql = format!(#{sql});"
      sql = 'sql'

    rust.push """
    Ok(#{func}!(#{sql}#{fli}))
  }

#[macro_export]
macro_rules! #{fn} {
(#{mli.map((i)=>"$#{i}:expr").join(',')}) => {
$crate::#{fn}(#{mli.map((i)=>'$'+i).join(',')}).await?
};
}\n"""

  rust = rust.join('\n')
  write(
    join ROOT, 'rust/lib/m/src/lib.rs'
    """
#[allow(non_snake_case,clippy::too_many_arguments)]
mod r#fn {
  #{rust}
}

pub use r#fn::*;
    """
  )
await main()
