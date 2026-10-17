// The scrolling benchmark's route for the example's "cards" screen,
// unchanged, under the title "Cards (RN - Legend List)". setup.sh copies
// this file into the example's app/ folder; a static route there takes
// precedence over the example's [slug].
import { BenchRoute } from "~/components/BenchRoute";

export default function CardsRoute() {
    return <BenchRoute slug="cards" title="Cards (RN - Legend List)" />;
}
