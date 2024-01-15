use sk::sk;
use xhash::hash64;

/// 对 BASE 求余, 为了防止数字过大,
pub const BASE: u64 = 1024;

pub fn cookie_set(host: &str, client_id: u64) -> [String; 1] {
  let now = sts::sec();
  let day = (now / (86400 * 10)) % BASE;
  let t = &vb::e([day, client_id])[..];
  let token = [&hash64(&[sk(), t].concat()).to_le_bytes()[..], t].concat();
  let i = cookiestr::e(token);
  let max_age = 34560000;
  let expire = now + max_age;

  let age = format!(";max-age={max_age};domain={host};path=/;Partitioned;Secure;SameSite=None");
  [format!("I={i}{age};HttpOnly")]
}
