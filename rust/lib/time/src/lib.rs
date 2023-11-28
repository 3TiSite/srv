use coarsetime::Clock;

pub fn nanos() -> u64 {
  Clock::now_since_epoch().as_nanos()
}

pub fn hours() -> u64 {
  Clock::now_since_epoch().as_hours()
}

pub fn sec() -> u64 {
  Clock::now_since_epoch().as_secs()
}

pub fn mins() -> u64 {
  Clock::now_since_epoch().as_mins()
}
