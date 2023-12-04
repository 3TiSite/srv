#!/usr/bin/env coffee

> @3-/walk > walkRel
  @3-/extract > extract
  @3-/read
  @3-/write
  @3-/nt/dumps.js
  @3-/camel/Camel.js
  zx/globals:
  path > join basename dirname
  fs > readdirSync
  ./rm_target_if_rustc_ver_change.coffee:rmTarget

removeEnd = (s)=>
  s = s.trim()
  if s.endsWith ','
    return s.slice(0,-1)
  s

json_args = (code)=>
  args = []
  begin = code.indexOf('from_str(')
  if ~begin
    t = code.slice(0, begin)
    begin = t.lastIndexOf('let ')
    if ~begin
      begin += 5
      end = t.lastIndexOf(')')
      if ~end
        t = t.slice(begin,end)
        [name, type] = t.split(':')
        name = name.trim().replace(/\s*\)$/,'')
        name = removeEnd(name).split(',').map((i)=>i.trim())

        type = removeEnd(type.trim().replace(/\(/,'')).split(',').map((i)=>i.trim())
        for i, p in name
          args.push [i,type[p]]
      else
        end = t.lastIndexOf('=')
        if ~end
          [name, type] = t.slice(begin,end).split(':')
          args.push [name.trim(), type.trim()]

  # post_args = []
  return args

return_type = (code)=>
  p = code.lastIndexOf('api::')
  if ~p
    p += 5
    code = code.slice(p)
    for i, end in code
      if '>{ \n,='.includes i
        return code.slice(0,end).trim()
  '()'

hasCaptcha = (code)=>
  return !! ~ code.indexOf' captcha::verify('

async_export = (def)=>
  'pub async fn '+ def + '('

args_body = (def, code)=>
  def = async_export def
  begin = code.indexOf def
  if ~begin
    begin += def.length
    end = code.indexOf '\n}', begin
    if ~end
      code = code.slice(begin,end)
      for s from [
        't3::Result<'
      ]
        s = '-> '+s
        p = code.indexOf(s)
        if ~p
          args = code.slice(0,p)
          args = args.slice(0,args.lastIndexOf(')'))
          body = code.slice(p+s.length)
          body = body.slice(body.indexOf('{')+1)
          return [args, body]
  return

api = (url, code)=>
  + post_args, get
  r = args_body('post', code)
  if r
    [args, body] = r
    args = args.replaceAll('\n',' ').replace(/\s+/g,' ').trim().replace(/,$/,'')
    rt = return_type(body)
    has_captcha = hasCaptcha(body)
    tip = "#{url}(#{args}) -> #{rt}"
    if has_captcha
      tip = '🚧 '+tip
    console.log '\n'+tip
    post_args = []
    if /: String\b/.test(args)
      a =  json_args(body)
      json = a.map(
        ([name,type])=>
          post_args.push "#{name}:#{type}"
          "  #{name} : #{type}"
      ).join('\n')
      console.log json
    post_args = post_args.join(';')
    post_args += ('→' + rt)
    if has_captcha
      post_args = '🚧 '+post_args

  r = args_body('get', code)
  if r
    [args] = r
    p = args.indexOf 'Path('
    if ~ p
      p+=5
      args = args.slice(p, args.indexOf(')',p+1)).replaceAll('(','').split(',').map (i)=>i.trim()
      get = args
    else
      get = 0
  if (post_args != undefined) or get != undefined
    return [post_args, get]
  return

mod_rs = (dir)=>
  src = join dir, 'src'
  mod_li = []
  for i from readdirSync src
    if i.endsWith('.rs') and not i.startsWith('_')
      if i == 'lib.rs'
        continue
      code = read join src, i
      has_export = 0
      for method from ['get','post']
        if ~ code.indexOf(async_export(method))
          has_export = 1
          break
      if has_export
        mod_li.push i.slice(0,-3)
  urlmod = mod_li.map (m)=>"    pub mod #{m};"
  write(
    join src, '_mod.rs'
    """// GEN BY api.coffee ; DON'T EDIT
#[macro_export]
macro_rules! urlmod {
  () => {
#{urlmod.join('\n')}
  };
}"""
  )
  return

out_mod_li = (out)=>
  r = []
  t = []
  mod = ''
  for i from out.split('\n')
    t.push i
    if i == '}'
      r.push [mod, t]
      t = []
      mod = ''
    else if i.startsWith('mod ') or i.startsWith('pub mod ')
      if i.endsWith('}')
        t.pop()
        continue
      i = i.slice(0,i.lastIndexOf('{')-1).trimEnd()
      mod = i.slice(i.lastIndexOf(' ')+1)

  return r

export default main = (dir)=>
  await rmTarget(dir)
  mod_rs(dir)
  cd dir
  base = basename dir
  $.verbose = false
  out = await $"cargo expand --theme=none"
  $.verbose = true

  import_li = []
  api_nt = {}
  get_map = {}
  map_li = [
    (url, i)=>
      api_nt[url] = i
      return
    (url, i)=>
      get_map[url] = i
      return
  ]

  merge = (url, code)=>
    r = api(url, code)
    if r
      for i, p in r
        if i != undefined
          map_li[p](url, i)
    return !!r

  for [mod, li] from out_mod_li out.stdout
    realm = mod
    if mod == base
      mod = ''
    else
      mod = Camel mod
    url = base + mod
    end = '\n}'
    li =  li.join('\n').split(end)
    if merge(url,  li.shift()+end)
      if realm
        import_li.push realm+' as '+url
      else
        import_li.push 'self as '+base

    for i from li
      i = i.trim()
      if i
        if merge(base, i+end)
          import_li.push 'self as '+base

  write(
    join dir, 'api.nt'
    '# GEN BY url.coffee . DON\'T EDIT !\n'+dumps(
      api_nt
    ).trim()+'\n'
  )
  mod = "#{basename(dirname dir)}_#{base}"
  return [
    mod
    "pub use #{mod}::{#{import_li.join(', ')}};"
    Object.keys(api_nt)
    get_map
  ]


if process.argv[1] == decodeURI (new URL(import.meta.url)).pathname
  {existsSync} = await import('fs')
  {ROOT} = await import('./conf.coffee')
  root = join(dirname(ROOT),'mod')
  for dir from readdirSync root
    if dir.startsWith '.'
      continue
    dir = join root, dir
    for i from readdirSync dir
      if i.startsWith '.'
        continue
      if existsSync join dir,i,'Cargo.toml'
        await main join(dir,i)
  process.exit()
