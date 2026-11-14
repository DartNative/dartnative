//! `SHOP_API_URL` at build time is the endpoint of builds that cannot be
//! given one at launch (Android): rebuild when it changes.

fn main() {
    println!("cargo:rerun-if-env-changed=SHOP_API_URL");
}
