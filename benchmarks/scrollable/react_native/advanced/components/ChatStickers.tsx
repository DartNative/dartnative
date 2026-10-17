// The scrolling benchmark's Chat screen: Legend List's own chat example
// (screens/examples/ChatExample.tsx, MIT, Legend List's authors), its
// messages (buildChatMessages), its bubbles and attachment cards and, on
// Legend List, its list configuration (getChatListProps), plus two kinds of
// message added. After every fourth message comes a photo with a bubble's
// rounded corners and no padding, at one of five aspect ratios; after every
// third, a sticker, a looping Lottie animation shown without a bubble, as
// messaging apps show them. Both sit on the sender's side. A message with
// an attachment card takes the bubble's whole width and the card fills it,
// as a link preview does in a messaging app; the example draws the card
// 220 points wide whatever the bubble's width. The stickers are
// lottie-react-native views, which play through lottie-android and
// lottie-ios; the photos are React Native's Image. The thread opens at its
// newest message, at the bottom, and the benchmark scrolls up through its
// history.
//
// The composer and the jump-to-latest button of the example are left out:
// the benchmark measures the list. The bar's Scroll button goes to the next
// message of CHAT_SCROLL_TARGETS with each library's own animated
// scrollToIndex, for the scroll-to test. FlashList and FlatList show the same
// thread with each library's documented way of opening at the newest
// message: FlashList's initialScrollIndex with maintainVisibleContentPosition
// starting from the bottom, FlatList's inverted list. setup.sh copies this
// file into the example's components/ folder; nothing of the example's own
// code is edited.
import { MaterialIcons } from "@expo/vector-icons";
import { Stack } from "expo-router";
import LottieView from "lottie-react-native";
import { useMemo, useRef } from "react";
import { FlatList, Image, Pressable, StyleSheet, Text, View } from "react-native";

import { LegendList, type LegendListRef } from "@legendapp/list/react-native";
import { FlashList, type FlashListRef } from "@shopify/flash-list";
import { getChatListProps } from "~/screens/examples/chatShared";
import { SafeAreaShell, styles as exampleStyles } from "~/screens/examples/shared";
import { buildChatMessages, type ChatMessage } from "../../examples-shared/chat";

export type Library = "legendlist" | "flashlist" | "flatlist";

/** How many messages the thread holds, before the stickers are added. */
export const MESSAGE_COUNT = 1000;

/** A sticker follows every this many messages. */
export const STICKER_EVERY = 3;

/** A sticker's side, in points, as a messaging app shows one. */
export const STICKER_SIDE = 160;

/** A photo follows every this many messages. */
export const PHOTO_EVERY = 4;

/** A photo's width, in points; its height follows its shape. */
export const PHOTO_WIDTH = 240;

/**
 * The photos' shapes, in turn: the pixel size asked of the image service
 * (720 wide, three pixels a point) and the height shown, in points.
 */
const PHOTO_SHAPES: { pixels: [number, number]; height: number }[] = [
    { height: 180, pixels: [720, 540] }, // 4:3
    { height: 320, pixels: [720, 960] }, // 3:4
    { height: 240, pixels: [720, 720] }, // 1:1
    { height: 135, pixels: [720, 405] }, // 16:9
    { height: 427, pixels: [720, 1280] }, // 9:16
];

/** The photos: 24 images from picsum.photos, by id, the same in every app. */
const PHOTO_IDS = Array.from({ length: 24 }, (_, i) => 10 + i);

/**
 * The sticker files: six from each of four packs of the DartNative
 * playground's sticker keyboard, the same in every app.
 */
const STICKERS = [
    require("../assets/stickers/duck_0.json"),
    require("../assets/stickers/duck_1.json"),
    require("../assets/stickers/duck_2.json"),
    require("../assets/stickers/duck_3.json"),
    require("../assets/stickers/duck_4.json"),
    require("../assets/stickers/duck_5.json"),
    require("../assets/stickers/mia_bunny_0.json"),
    require("../assets/stickers/mia_bunny_1.json"),
    require("../assets/stickers/mia_bunny_2.json"),
    require("../assets/stickers/mia_bunny_3.json"),
    require("../assets/stickers/mia_bunny_4.json"),
    require("../assets/stickers/mia_bunny_5.json"),
    require("../assets/stickers/hot_cherry_0.json"),
    require("../assets/stickers/hot_cherry_1.json"),
    require("../assets/stickers/hot_cherry_2.json"),
    require("../assets/stickers/hot_cherry_3.json"),
    require("../assets/stickers/hot_cherry_4.json"),
    require("../assets/stickers/hot_cherry_5.json"),
    require("../assets/stickers/baby_yoda_0.json"),
    require("../assets/stickers/baby_yoda_1.json"),
    require("../assets/stickers/baby_yoda_2.json"),
    require("../assets/stickers/baby_yoda_3.json"),
    require("../assets/stickers/baby_yoda_4.json"),
    require("../assets/stickers/baby_yoda_5.json"),
];

/**
 * The messages the bar's Scroll button goes to, in turn, the same in every
 * app, by number (0 is the oldest, 999 the newest). Each press scrolls,
 * animated, until that message's top is at the top of the list. The first,
 * to a message a few rows from the newest, lands among rows every list has
 * measured, so it shows where a message's top sits when it is at the top.
 * Every scroll goes up the history, away from where the thread opens: the
 * one to message 598 moves two messages, the others hundreds, past messages
 * no list has measured, the oldest last.
 */
export const CHAT_SCROLL_TARGETS = [996, 600, 598, 300, 0];

type StickerMessage = { id: string; sender: ChatMessage["sender"]; sticker: number };
type PhotoMessage = { id: string; sender: ChatMessage["sender"]; photo: string; height: number };
type ThreadItem = ChatMessage | StickerMessage | PhotoMessage;

const isSticker = (item: ThreadItem): item is StickerMessage => "sticker" in item;
const isPhoto = (item: ThreadItem): item is PhotoMessage => "photo" in item;

/**
 * The thread, oldest first: the example's messages, with a photo after the
 * second of every four and a sticker after the third of every three, each
 * from the sender of the message before it. The sticker is picked by a
 * small generator with a fixed seed, the same in every app, so a sticker
 * file never repeats at a fixed distance: a list reuses its views in turn,
 * and a file that came back to the view still holding it would be shown
 * without being built again.
 */
export function buildThread(): ThreadItem[] {
    const thread: ThreadItem[] = [];
    let stickerSeed = 2026;
    buildChatMessages(MESSAGE_COUNT).forEach((message, index) => {
        thread.push(message);
        if (index % PHOTO_EVERY === 1) {
            const n = Math.floor(index / PHOTO_EVERY);
            const shape = PHOTO_SHAPES[n % PHOTO_SHAPES.length];
            const [w, h] = shape.pixels;
            thread.push({
                height: shape.height,
                id: `photo-${index}`,
                photo: `https://picsum.photos/id/${PHOTO_IDS[n % PHOTO_IDS.length]}/${w}/${h}`,
                sender: message.sender,
            });
        }
        if (index % STICKER_EVERY === STICKER_EVERY - 1) {
            stickerSeed = (stickerSeed * 48271) % 2147483647;
            thread.push({ id: `sticker-${index}`, sender: message.sender, sticker: stickerSeed % STICKERS.length });
        }
    });
    return thread;
}

/**
 * The example's message bubble (getChatListProps' renderItem). A bubble
 * with an attachment card takes the most width a bubble may have, 84 %.
 */
function Bubble({ item }: { item: ChatMessage }) {
    return (
        <View
            style={[
                exampleStyles.bubble,
                item.sender === "self" ? exampleStyles.selfBubble : exampleStyles.otherBubble,
                item.attachment ? styles.fullBubble : null,
            ]}
        >
            <Text style={exampleStyles.sender}>{item.senderName}</Text>
            {item.attachment ? <AttachmentCard attachment={item.attachment} /> : null}
            <Text style={exampleStyles.body}>{item.text}</Text>
            <Text style={exampleStyles.timestamp}>{item.timestampLabel}</Text>
        </View>
    );
}

/** The example's attachment card (ChatAttachmentCard), filling its bubble. */
function AttachmentCard({ attachment }: { attachment: NonNullable<ChatMessage["attachment"]> }) {
    return (
        <View
            style={[
                exampleStyles.chatAttachment,
                styles.fullCard,
                { backgroundColor: attachment.accent, height: attachment.height },
            ]}
        >
            <View style={exampleStyles.chatAttachmentScrim} />
            <Text style={exampleStyles.chatAttachmentLabel}>{attachment.label}</Text>
            <Text style={exampleStyles.chatAttachmentSubtitle}>{attachment.subtitle}</Text>
        </View>
    );
}

function Sticker({ item }: { item: StickerMessage }) {
    return (
        <LottieView
            autoPlay
            loop
            source={STICKERS[item.sticker]}
            style={[styles.sticker, item.sender === "self" ? styles.self : styles.other]}
        />
    );
}

/** A photo with a bubble's rounded corners and no padding. */
function Photo({ item }: { item: PhotoMessage }) {
    return (
        <Image
            source={{ uri: item.photo }}
            style={[styles.photo, { height: item.height }, item.sender === "self" ? styles.self : styles.other]}
        />
    );
}

const renderItem = ({ item }: { item: ThreadItem }) =>
    isSticker(item) ? <Sticker item={item} /> : isPhoto(item) ? <Photo item={item} /> : <Bubble item={item} />;
const keyExtractor = (item: ThreadItem) => item.id;
const getItemType = (item: ThreadItem) => (isSticker(item) ? "sticker" : isPhoto(item) ? "photo" : "message");

/** What the bar title names, so a screen recording says what is running. */
const TITLE_TAG: Record<Library, string> = {
    flashlist: "RN - FlashList",
    flatlist: "RN - FlatList",
    legendlist: "RN - Legend List",
};

export function ChatStickersScreen({ library }: { library: Library }) {
    const thread = useMemo(buildThread, []);
    const newestFirst = useMemo(() => [...thread].reverse(), [thread]);
    // Each message's index in the thread, by its number.
    const messageRows = useMemo(
        () => thread.flatMap((item, row) => (isSticker(item) || isPhoto(item) ? [] : [row])),
        [thread],
    );
    const legendRef = useRef<LegendListRef>(null);
    const flashRef = useRef<FlashListRef<ThreadItem>>(null);
    const flatRef = useRef<FlatList<ThreadItem>>(null);
    const nextTarget = useRef(0);
    const scroll = () => {
        const row = messageRows[CHAT_SCROLL_TARGETS[nextTarget.current % CHAT_SCROLL_TARGETS.length]];
        nextTarget.current++;
        if (library === "legendlist") void legendRef.current?.scrollToIndex({ animated: true, index: row, viewPosition: 0 });
        else if (library === "flashlist") void flashRef.current?.scrollToIndex({ animated: true, index: row, viewPosition: 0 });
        // Inverted, newest first: the row counts from the newest, and the top
        // of the screen is the list's end.
        else flatRef.current?.scrollToIndex({ animated: true, index: thread.length - 1 - row, viewPosition: 1 });
    };
    let list: React.ReactNode;
    if (library === "legendlist") {
        // The example's chat configuration: aligned and opened at the end,
        // the end kept in place, recycled rows, its size estimate.
        const exampleProps = getChatListProps({ messages: [] });
        list = (
            <LegendList
                {...exampleProps}
                data={thread}
                ref={legendRef}
                getItemType={getItemType}
                keyExtractor={keyExtractor}
                renderItem={renderItem}
                style={styles.list}
            />
        );
    } else if (library === "flashlist") {
        list = (
            <FlashList
                contentContainerStyle={exampleStyles.list}
                data={thread}
                getItemType={getItemType}
                initialScrollIndex={thread.length - 1}
                keyExtractor={keyExtractor}
                ref={flashRef}
                maintainVisibleContentPosition={{ startRenderingFromBottom: true }}
                renderItem={renderItem}
                style={styles.list}
            />
        );
    } else {
        list = (
            <FlatList
                contentContainerStyle={exampleStyles.list}
                data={newestFirst}
                inverted
                keyExtractor={keyExtractor}
                // React Native's documented answer for a row not laid out
                // yet: scroll to its estimated offset, then ask again.
                onScrollToIndexFailed={(info) => {
                    flatRef.current?.scrollToOffset({ animated: true, offset: info.averageItemLength * info.index });
                    setTimeout(() => flatRef.current?.scrollToIndex({ animated: true, index: info.index, viewPosition: 1 }), 500);
                }}
                ref={flatRef}
                renderItem={renderItem}
                style={styles.list}
            />
        );
    }
    return (
        <>
            <Stack.Screen
                options={{
                    headerRight: ({ tintColor }) => (
                        <View style={styles.barButtons}>
                            <Pressable accessibilityLabel="Scroll" accessibilityRole="button" hitSlop={8} onPress={scroll} style={styles.scroll}>
                                <MaterialIcons color={tintColor} name="arrow-upward" size={24} />
                            </Pressable>
                        </View>
                    ),
                    headerTitle: `Chat (${TITLE_TAG[library]})`,
                    headerTransparent: false,
                }}
            />
            <SafeAreaShell>{list}</SafeAreaShell>
        </>
    );
}

const styles = StyleSheet.create({
    barButtons: { alignItems: "center", flexDirection: "row" },
    fullBubble: { width: "84%" },
    fullCard: { width: "100%" },
    // Square, so iOS 26 draws the bar's glass behind it as a circle, as it
    // does for a system bar button.
    scroll: { padding: 6 },
    list: { flex: 1 },
    other: { alignSelf: "flex-start" },
    // The example's bubble corners, and the light fill a chat shows while
    // a photo loads.
    photo: { backgroundColor: "#E5E7EB", borderRadius: 18, marginBottom: 12, width: PHOTO_WIDTH },
    self: { alignSelf: "flex-end" },
    sticker: { height: STICKER_SIDE, marginBottom: 12, width: STICKER_SIDE },
});
