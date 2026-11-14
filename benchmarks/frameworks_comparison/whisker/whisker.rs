use whisker_cng::Orientation;

fn main() {
    whisker_cng::run(|app| {
        app.name("Everbloom")
            .bundle_id("dev.whiskerrs.shopbench.whisker")
            .background("#FFFFFF")
            .version("1.0.0")
            .build_number(1);

        app.android(|a| {
            a.package("dev.whiskerrs.shopbench.whisker")
                .application_id("dev.whiskerrs.shopbench.whisker")
                .launcher_activity(".MainActivity")
                .min_sdk(24)
                .target_sdk(34);
        });

        app.ios(|i| {
            i.bundle_id("dev.whiskerrs.shopbench.whisker")
                .scheme("Everbloom")
                .deployment_target("15.0")
                .orientations([Orientation::Portrait]);
        });
    });
}
