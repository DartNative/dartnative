// The scrolling benchmark's route for the example's "cards-flatlist" screen,
// unchanged, under the title "Cards (RN - FlatList)". setup.sh copies this
// file into the example's app/ folder; a static route there takes precedence
// over the example's [slug].
import { BenchRoute } from "~/components/BenchRoute";

export default function CardsFlatListRoute() {
    return <BenchRoute slug="cards-flatlist" title="Cards (RN - FlatList)" />;
}
