#![feature(macro_metavar_expr)]
use std::env::var;

use lazy_static::lazy_static;
pub use mysql_async::{
  self,
  prelude::{Query, Queryable, WithParams},
  Error, Params, Result,
};
use mysql_async::{OptsBuilder, Pool};
pub use trt::spawn;

pub const MYSQL_DEFAULT_PORT: u16 = 3306;

lazy_static! {
  pub static ref POOL: Pool = Pool::new({
    let opt = OptsBuilder::default()
      .compression(mysql_async::Compression::fast())
      .ip_or_hostname(var("DB_HOST").unwrap_or("127.0.0.1".into()))
      .tcp_port(
        var("DB_PORT")
          .map(|i| i.parse().unwrap_or(MYSQL_DEFAULT_PORT))
          .unwrap_or(MYSQL_DEFAULT_PORT),
      );

    macro_rules! opt {
            ($opt:ident : $($str:ident $fn:ident);*) => {{
                $(let $opt = opt!($opt, $str, $fn);)+
                    $opt
            }};
            ($opt:ident, $str:ident, $fn:ident) => {
                if let Ok(o) = var(stringify!($str)) {
                    $opt.$fn(Some(o))
                } else {
                    $opt
                }
            };
        }

    opt!(
        opt:
        DB_USER user;
        DB_DB db_name;
        DB_PASSWORD pass
    )
  });
}

#[macro_export]
macro_rules! conn {
    ()=>{
        $crate::POOL.get_conn().await?
    };
    ($conn:expr;$func:ident $sql:expr, $($arg:expr),+) => {{
        use $crate::{Query, WithParams};
        $sql.with(
            $crate::Params::Positional(vec![$($arg.into()),+])
        ).$func($conn).await?
    }};
    ($conn:expr; $func:ident $sql:expr) => {{
        use $crate::{Query};
        $sql.$func($conn).await?
    }};
    ($func:ident $sql:expr $(,$arg:expr)* $(,)?) => {{
#[allow(unused_mut)]
        let mut conn = $crate::conn!();
        $crate::conn!(&mut conn; $func $sql $(,$arg)*)
    }};
}

macro_rules! def {
    ($($m:ident $func:ident;)+) => {
        $(def!($m $func);)+
    };
    ($m:ident $func:ident) => {
#[macro_export]
        macro_rules! $m {
            ($conn:expr; $sql:expr $$(,$arg:expr)* $$(,)?) => {
                $$crate::conn!($$conn; $func $$sql $$(,$$arg)*)
            };
            ($sql:expr $$(,$arg:expr)* $$(,)?) => {
                $$crate::conn!($func $$sql $$(,$$arg)*)
            };
        }
    };
}

def!(
    exe ignore;
    q fetch;
    q01 first;
);

#[macro_export]
macro_rules! bg {
    ($sql:expr $(,$arg:expr)* $(,)?) => {{
        $crate::spawn!(async move {
            $crate::exe!($sql $(,$arg)*);
            Ok::<_,$crate::Error>(())
        });
    }};
}

#[macro_export]
macro_rules! q1 {
    ($conn:expr; $sql:expr $(,$arg:expr)* $(,)?) => {
        $crate::q01!($conn;$sql $(,$arg)*).unwrap()
    };
    ($sql:expr $(,$arg:expr)* $(,)?) => {
        $crate::q01!($sql $(,$arg)*).unwrap()
    };
}
