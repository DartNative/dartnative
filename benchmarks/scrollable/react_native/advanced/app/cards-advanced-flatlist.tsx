// The scrolling benchmark's route for the Cards screen with its advanced
// mode, on FlatList. setup.sh copies this file into the example's app/
// folder; a static route there takes precedence over the example's [slug].
import { AdvancedCardsScreen } from "~/components/AdvancedCards";

export default function CardsAdvancedFlatListRoute() {
    return <AdvancedCardsScreen library="flatlist" />;
}
