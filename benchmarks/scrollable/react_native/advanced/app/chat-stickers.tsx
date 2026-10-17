// The scrolling benchmark's route for the Chat screen, on LegendList. setup.sh
// copies this file into the example's app/ folder; a static route there
// takes precedence over the example's [slug].
import { ChatStickersScreen } from "~/components/ChatStickers";

export default function ChatLegendListRoute() {
    return <ChatStickersScreen library="legendlist" />;
}
