use std::{ops::Deref, sync::Arc};

use axum::{
  extract::Request,
  http::{
    header::{COOKIE, ORIGIN, SET_COOKIE},
    StatusCode,
  },
  middleware::Next,
  response::{IntoResponse, Response},
  Extension,
};
use t3::middleware;
use user::{client_by_token, client_user_cookie, cookie_set, ClientUser};
use xtld::url_tld;

#[derive(Debug, Clone)]
pub struct _Client(pub Arc<ClientUser>);

pub type Client = Extension<_Client>;

fn header_get<B>(req: &Request<B>, key: impl AsRef<str>) -> Option<&str> {
  req
    .headers()
    .get(key.as_ref())
    .and_then(|header| header.to_str().ok())
}

pub async fn client(mut req: Request, next: Next) -> Response {
  middleware!(async move {
    if let Some(i) = header_get(&req, "I") {
      // api 请求
      let client_user = client_by_token(i).await?;
      req.extensions_mut().insert(_Client(client_user.into()));
      return Ok(next.run(req).await);
    }
    if let Some(origin) = header_get(&req, ORIGIN) {
      let origin = origin.to_owned();
      let client_user = Arc::new(client_user_cookie(header_get(&req, COOKIE)).await?);
      req.extensions_mut().insert(_Client(client_user.clone()));

      let mut r = next.run(req).await;

      if client_user.do_set() {
        let host = url_tld(origin);
        let cookie_li = cookie_set(&host, client_user.id, client_user.ver());
        for i in cookie_li.into_iter() {
          r.headers_mut().append(SET_COOKIE, i.parse()?);
        }
      }

      Ok(r)
    } else {
      Err(t3::origin::Error::HeaderMissOrigin.into())
    }
  })
}

#[macro_export]
macro_rules! unauthorized {
  () => {
    t3::err(StatusCode::UNAUTHORIZED, "need login".to_owned())
  };
}

impl _Client {
  pub async fn uid_logined(&self, uid: u64) -> Result<(), t3::Err> {
    if uid > user::UID_STATE_UNSET && self.is_login(uid).await? {
      return Ok(());
    }
    unauthorized!()
  }

  pub async fn logined(&self) -> Result<u64, t3::Err> {
    if let Some(id) = self.uid().await? {
      return Ok(id);
    }
    unauthorized!()
  }
}

impl Deref for _Client {
  type Target = ClientUser;
  fn deref(&self) -> &<Self as Deref>::Target {
    &self.0
  }
}
