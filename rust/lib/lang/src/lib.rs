pub use const_str;
pub use http::HeaderMap;
pub use intbin::u8_bin;

pub const LANG: phf::OrderedSet<&str> = phf::phf_ordered_set! {"en","zh","es","fr","de","ja","it","ko","ru","pt","sq","ar","am","as","az","ee","ay","ga","et","or","om","eu","be","bm","bg","is","pl","bs","fa","bho","af","tt","da","dv","ti","doi","sa","fil","fi","fy","km","ka","gom","gu","gn","kk","ht","ha","nl","ky","gl","ca","cs","kn","co","hr","qu","ku","ckb","la","lv","lo","lt","ln","lg","lb","rw","ro","mg","mt","mr","ml","ms","mk","mai","mi","mni-Mtei","mn","bn","lus","my","hmn","xh","zu","ne","no","pa","ps","ny","ak","sv","sm","sr","nso","st","si","eo","sk","sl","sw","gd","ceb","so","tg","te","ta","th","tr","tk","cy","ug","ur","uk","uz","he","el","haw","sd","hu","sn","hy","ig","ilo","yi","hi","su","id","jv","yo","vi","zh-TW","ts"};

// pub const NOSPACE: phf::Set<&str> = phf::phf_set! {"zh", "zh-TW", "ja", "km", "th", "lo"};

pub const NOSPACE: [u8; 6] = [1, 5, 40, 61, 106, 130];

pub fn space(lang: u8) -> &'static str {
  if NOSPACE.contains(&lang) {
    ""
  } else {
    " "
  }
}

pub fn lang_bin(lang: &str) -> Box<[u8]> {
  u8_bin(lang_id(lang))
}

pub fn lang_id(lang: &str) -> u8 {
  if let Some(p) = LANG.get_index(lang) {
    return p as _;
  }
  0
}

#[macro_export]
macro_rules! gen {
  ($key:ident) => {
    pub const HSET_PREFIX: &[u8] = $crate::const_str::concat!(stringify!($key), "I18n:").as_bytes();

    pub async fn get_li<'a, const N: usize>(
      lang: u8,
      li: &'a [&[u8]; N],
    ) -> RedisResult<Vec<String>> {
      let hset = &[HSET_PREFIX, &$crate::u8_bin(lang)].concat()[..];
      KV.hmget(hset, li).await
    }

    pub async fn get<'a, const N: usize>(
      header: &$crate::HeaderMap,
      key: &'a [u8],
    ) -> RedisResult<Vec<String>> {
      let lang = $crate::header(header);
      let hset = &[HSET_PREFIX, &$crate::u8_bin(lang)].concat()[..];
      KV.hget(hset, key).await
    }

    pub async fn throw_li<'a, const N: usize>(
      header: &$crate::HeaderMap,
      key: impl AsRef<str>,
      li: &'a [&[u8]; N],
    ) -> anyhow::Result<()> {
      let lang = $crate::header(header);
      let li = get_li(lang, li).await?;
      let space = $crate::space(lang);
      Ok(t3::form::Error::throw(key.as_ref(), li.join(space))?)
    }

    pub async fn throw(
      header: &$crate::HeaderMap,
      key: impl AsRef<str>,
      val: &[u8],
    ) -> anyhow::Result<()> {
      let lang = $crate::header(header);
      let hset = &[HSET_PREFIX, &$crate::u8_bin(lang)].concat()[..];
      let val: String = KV.hget(hset, val).await?;
      Ok(t3::form::Error::throw(key.as_ref(), val)?)
    }
  };
}

pub fn header_bin(m: &HeaderMap) -> Box<[u8]> {
  u8_bin(header(m))
}

pub fn header(m: &HeaderMap) -> u8 {
  if let Some(i) = m.get("accept-language") {
    if let Ok(i) = i.to_str() {
      return lang_id(i);
    }
  }
  0
}
