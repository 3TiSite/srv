use sk::sk;
use time::sec;
use xhash::hash64;

/// 对 BASE 求余, 为了防止数字过大,
pub const BASE: u64 = 1024;

pub fn day10() -> u64 {
  (sec() / (86400 * 10)) % BASE
}

pub fn cookie_set(host: &str, client_id: u64, client_ver: u64) -> [String; 2] {
  let t = &vb::e([day10(), client_id])[..];
  let v = intbin::u64_bin(client_ver);
  let token = [&hash64(&[sk(), t, &v].concat()).to_le_bytes()[..], t].concat();
  let i = cookiestr::e(token);
  let v = cookiestr::e(v);
  let age = format!(";max-age=99999999;domain={host};path=/");
  [
    format!("I={i}{age};HttpOnly;SameSite=Lax;Secure"),
    format!("V={v}{age}"),
  ]
}
