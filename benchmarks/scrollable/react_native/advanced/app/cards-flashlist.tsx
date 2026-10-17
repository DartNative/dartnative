// The scrolling benchmark's route for the example's "cards-flashlist"
// screen, unchanged, under the title "Cards (RN - FlashList)". setup.sh
// copies this file into the example's app/ folder; a static route there
// takes precedence over the example's [slug].
import { BenchRoute } from "~/components/BenchRoute";

export default function CardsFlashListRoute() {
    return <BenchRoute slug="cards-flashlist" title="Cards (RN - FlashList)" />;
}
