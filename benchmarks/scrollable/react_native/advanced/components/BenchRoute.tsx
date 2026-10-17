// The example's own screen for one of its routes, unchanged, under a bar
// title that says which framework and which list are running, so a screen
// recording names what it shows. setup.sh copies this file into the
// example's components/ folder.
import { Stack } from "expo-router";

import { getRouteBySlug } from "~/screens/routes";

export function BenchRoute({ slug, title }: { slug: string; title: string }) {
    const route = getRouteBySlug(slug);
    if (!route) {
        return null;
    }
    const ScreenComponent = route.component;
    return (
        <>
            <Stack.Screen options={{ headerTitle: title, headerTransparent: false }} />
            <ScreenComponent />
        </>
    );
}
