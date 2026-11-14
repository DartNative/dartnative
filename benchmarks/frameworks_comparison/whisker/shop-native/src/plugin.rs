//! Generation plugin: Info.plist keys the app needs on iOS.

use serde::{Deserialize, Serialize};
use whisker_plugin::{GenerateContext, Operation, PlistValue, Plugin, PluginConfig, Target};

#[derive(Default, Serialize, Deserialize)]
pub struct ShopNativePluginConfig {}

impl PluginConfig for ShopNativePluginConfig {
    const NAME: &'static str = "shop-native";
}

pub struct ShopNativePlugin;

impl Plugin for ShopNativePlugin {
    type Config = ShopNativePluginConfig;

    fn apply(&self, ctx: &mut GenerateContext, _cfg: &Self::Config) -> anyhow::Result<()> {
        let Some(ios) = ctx.ios.as_mut() else {
            return Ok(());
        };
        // Plain HTTP to the benchmark's LAN replay server.
        ios.info_plist.insert(
            "NSAppTransportSecurity".into(),
            PlistValue::Dict(
                [
                    (
                        "NSAllowsArbitraryLoads".to_string(),
                        PlistValue::Boolean(true),
                    ),
                    (
                        "NSAllowsLocalNetworking".to_string(),
                        PlistValue::Boolean(true),
                    ),
                ]
                .into(),
            ),
        );
        // Lets ProMotion devices render at 120 Hz.
        ios.info_plist.insert(
            "CADisableMinimumFrameDurationOnPhone".into(),
            PlistValue::Boolean(true),
        );
        for key in [
            "NSAppTransportSecurity",
            "CADisableMinimumFrameDurationOnPhone",
        ] {
            ctx.journal.record(
                ShopNativePluginConfig::NAME,
                Target::Ios,
                &format!("info_plist.{key}"),
                Operation::Set,
            );
        }
        Ok(())
    }
}
