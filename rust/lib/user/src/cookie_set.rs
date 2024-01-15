use chrono::{DateTime, NaiveDateTime, Utc};
use sk::sk;
use xhash::hash64;

/// 对 BASE 求余, 为了防止数字过大,
pub const BASE: u64 = 1024;

fn ts2gmt(ts: u64) -> String {
  let datetime: DateTime<Utc> = DateTime::from_utc(NaiveDateTime::from_ts(ts as _, 0), Utc);
  datetime.to_rfc2822()
}

pub fn cookie_set(host: &str, client_id: u64) -> [String; 1] {
  let now = sts::sec();
  let day = (now / (86400 * 10)) % BASE;
  let t = &vb::e([day, client_id])[..];
  let token = [&hash64(&[sk(), t].concat()).to_le_bytes()[..], t].concat();
  let i = cookiestr::e(token);
  let max_age = 34560000;
  let expire = ts2gmt(now + max_age);

  let age = format!(
    ";expires={expire};max-age={max_age};domain={host};path=/;Partitioned;Secure;SameSite=None"
  );
  [format!("I={i}{age};HttpOnly")]
}
