use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
  #[error("host not bind")]
  HostNoBind,
}

pub fn host_is_bind<T>(id: Option<T>) -> t3::Result<T> {
  if id.is_none() {
    t3::err(
      t3::StatusCode::UNPROCESSABLE_ENTITY,
      Error::HostNoBind.to_string(),
    )?;
  }
  Ok(id.unwrap())
}
