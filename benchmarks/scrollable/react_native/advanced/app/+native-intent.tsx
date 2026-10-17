// Each app that setup.sh builds opens straight on one screen, as the
// DartNative and platform apps do. Expo Router asks this file where to go
// for every path the system opens the app on; a launch from the home
// screen arrives as the app's root, and goes to the route setup.sh wrote
// into BenchStart.ts. A link to a route keeps its own path. setup.sh copies
// this file into the example's app/ folder, beside their routes.
import { START_ROUTE } from "~/components/BenchStart";

export function redirectSystemPath({ path, initial }: { path: string; initial: boolean }) {
    const route = path.replace(/^[a-z][a-z0-9+.-]*:\/\//i, "").replace(/^\/+/, "");
    if (initial && START_ROUTE && route === "") {
        return `/${START_ROUTE}`;
    }
    return path;
}
