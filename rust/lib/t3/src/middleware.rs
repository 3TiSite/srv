#[macro_export]
macro_rules! middleware {
  ($body:expr) => {{
    let r: anyhow::Result<Response> = $body.await;
    match r {
      Ok(r) => r,
      Err(err) => {
        $crate::tracing::error!("{:?}", err);
        (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()).into_response()
      }
    }
  }};
}
