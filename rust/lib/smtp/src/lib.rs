use lazy_static::lazy_static;
use mail_builder::{headers::address::Address, MessageBuilder};
use mail_send::SmtpClientBuilder;

lazy_static! {
  pub static ref FROM: String = std::env::var("SMTP_FROM").unwrap();
  pub static ref SMTP: SmtpClientBuilder<String> = {
    let smtp_port: u16 = std::env::var("SMTP_PORT").unwrap().parse().unwrap();

    let smtp_host = std::env::var("SMTP_HOST").unwrap();
    let smtp_user = std::env::var("SMTP_USER").unwrap();
    let smtp_password = std::env::var("SMTP_PASSWORD").unwrap();

    SmtpClientBuilder::new(smtp_host, smtp_port)
      .implicit_tls(false)
      .credentials((smtp_user, smtp_password))
  };
}

pub fn send(
  from_name: impl Into<String>,
  to: impl Into<Address<'static>>,
  subject: impl Into<String>,
  txt: impl Into<String>,
  htm: impl Into<String>,
) {
  let subject = subject.into();
  let txt = txt.into();
  let htm = htm.into();
  let from_name = from_name.into();
  let to = to.into();
  trt::spawn!(async move {
    let email = MessageBuilder::new()
      .from((from_name.as_str(), FROM.as_str()))
      .to(to)
      .subject(subject)
      .text_body(txt)
      .html_body(htm);
    let mut smtp = SMTP.connect().await?;
    smtp.send(email).await
  });
}
