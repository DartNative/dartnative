fn main() -> anyhow::Result<()> {
    whisker_plugin::run_as_subprocess(shop_native::plugin::ShopNativePlugin)
}
