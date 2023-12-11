use sk::sk;
use xhash::hash64;

/// 对 BASE 求余, 为了防止数字过大,
pub const BASE: u64 = 1024;

pub fn day10() -> u64 {
  (sts::sec() / (86400 * 10)) % BASE
}

pub fn cookie_set(host: &str, client_id: u64) -> [String; 1] {
  let t = &vb::e([day10(), client_id])[..];
  let token = [&hash64(&[sk(), t].concat()).to_le_bytes()[..], t].concat();
  let i = cookiestr::e(token);
  let age = format!(";max-age=99999999;domain={host};path=/;Partitioned;Secure;SameSite=None");
  [format!("I={i}{age};HttpOnly")]
}
