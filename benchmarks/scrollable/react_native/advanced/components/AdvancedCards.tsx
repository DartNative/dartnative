// The scrolling benchmark's advanced mode of Legend List's "Cards" screen,
// derived from the example's own card (screens/fixtures/shared/cardsRenderItem.tsx,
// MIT, Legend List's authors): the same card, with one to forty sentences, a
// horizontal list of ten images inside every card, and the example's own
// PERF_TEST work done in every card's render (its prime check, Fibonacci
// number, string and array work, copied unchanged), on the same three
// libraries. The bar's Scroll button goes to the next card of
// SCROLL_TARGETS with each library's own animated scrollToIndex, as the
// example's accurate-scrollto fixtures do. setup.sh copies this file into
// the example's components/ folder; nothing of the example's own code is
// edited.
import { MaterialIcons } from "@expo/vector-icons";
import { Stack } from "expo-router";
import { type MutableRefObject, memo, useRef, useState } from "react";
import { FlatList, Image, Pressable, StyleSheet, Text, View } from "react-native";
import Swipeable from "react-native-gesture-handler/Swipeable";

import {
    LegendList,
    type LegendListRef,
    type LegendListRenderItemProps,
    useRecyclingState,
} from "@legendapp/list/react-native";
import { FlashList, type FlashListRef, useRecyclingState as useFlashRecyclingState } from "@shopify/flash-list";
import { DRAW_DISTANCE, ESTIMATED_ITEM_LENGTH } from "~/constants/constants";
import CardsFixture from "~/screens/fixtures/cards";
import CardsFlashListFixture from "~/screens/fixtures/cards-flashlist";
import CardsFlatListFixture from "~/screens/fixtures/cards-flatlist";
import { type Item, loremSentences, randomNames } from "~/screens/fixtures/shared/cardsRenderItem";

export type Library = "legendlist" | "flashlist" | "flatlist";

// The example's dark palette (cardsRenderItem.tsx, DARK_MODE).
const palette = {
    border: "#323232",
    cardBackground: "#141414",
    divider: "#1f1f1f",
    outerBackground: "#050505",
    shadowColor: "#000000",
    success: "#22c55e",
    textMuted: "#9ca3af",
    textPrimary: "#f4f4f5",
    textSecondary: "#d4d4d8",
};

const RAIL_LENGTH = 10;
const RAIL_IMAGES = 70;
const RAIL_SIDE = 80;
const RAIL_GAP = 8;

/**
 * The cards the Scroll button goes to, in turn, the same in every app. Each
 * press scrolls, animated, until that card's top is at the top of the list.
 * The list opens at its first card and every scroll goes down it,
 * away from there. Two are short: the first, to card 1, lands among cards
 * every list has measured, so it shows where a card's title sits when the
 * card is at the top, and the one to card 402 moves two cards. The others
 * go far, hundreds of cards, past cards no list has measured.
 */
export const SCROLL_TARGETS = [1, 400, 402, 700, 950];

type ScrollTo = MutableRefObject<((index: number) => void) | null>;

const randomAvatars = Array.from({ length: 20 }, (_, i) => `https://i.pravatar.cc/150?img=${i + 1}`);

/**
 * How many sentences an advanced card holds, the same in every app: card n
 * takes entry (n × 7) mod 13, so neighbouring cards alternate between short
 * and long and a list cannot guess a card's height from its neighbours'.
 * From two lines of text to more than a screen.
 */
const ADVANCED_SENTENCES = [1, 2, 3, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40];

/** The same data every app generates for a card index. */
function cardData(index: number) {
    const numSentences = ADVANCED_SENTENCES[(index * 7) % ADVANCED_SENTENCES.length];
    return {
        authorName: randomNames[index % randomNames.length],
        avatarUrl: randomAvatars[index % randomAvatars.length],
        longBody: Array.from({ length: numSentences }, (_, i) => loremSentences[i % loremSentences.length]).join(" "),
        railUrls: Array.from(
            { length: RAIL_LENGTH },
            (_, k) => `https://i.pravatar.cc/150?img=${((index * 7 + k) % RAIL_IMAGES) + 1}`,
        ),
        timestamp: `${Math.max(1, index % 24)}h ago`,
    };
}

/**
 * The example's PERF_TEST work for one card (cardsRenderItem.tsx, the block
 * under "EXPENSIVE COMPUTATIONS"), unchanged: what a render that does real
 * work costs. Its two shown results go on the card, so nothing can skip it.
 */
function perfTest(indexForData: number, id: string) {
    // COMPUTATION 1: Prime number calculation
    const isPrime = (n: number): boolean => {
        if (n <= 1) return false;
        if (n <= 3) return true;
        if (n % 2 === 0 || n % 3 === 0) return false;
        for (let i = 5; i * i <= n; i += 6) {
            if (n % i === 0 || n % (i + 2) === 0) return false;
        }
        return true;
    };
    const primeCheck = isPrime(indexForData + 1000);

    // COMPUTATION 2: Fibonacci calculation (intentionally inefficient)
    const fibonacci = (n: number): number => {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    };
    const fibResult = fibonacci(Math.min((indexForData % 20) + 15, 25)); // Cap at 25 to avoid extreme slowness

    // COMPUTATION 3: Complex string manipulation
    const expensiveStringOp = (str: string): string => {
        let result = str;
        for (let i = 0; i < 50; i++) {
            result = result.split("").reverse().join("").toLowerCase().toUpperCase();
        }
        return result.slice(0, 10);
    };
    const processedString = expensiveStringOp(id.repeat(10));

    // COMPUTATION 4: Array sorting and filtering
    const largeArray = Array.from({ length: 1000 }, (_, _i) => Math.random() * indexForData);
    const sortedFiltered = largeArray
        .filter((x) => x > indexForData / 2)
        .sort((a, b) => b - a)
        .slice(0, 10);

    return { fibResult, primeCheck, processedString, sortedFiltered };
}

type RailItem = { id: string; url: string };

/** The rail: ten images in a horizontal list of the card's own library. */
function Rail({ library, urls }: { library: Library; urls: string[] }) {
    const data: RailItem[] = urls.map((url, i) => ({ id: i.toString(), url }));
    const renderRailItem = ({ item, index }: { item: RailItem; index: number }) => (
        <Image
            source={{ uri: item.url }}
            style={[styles.railImage, index === data.length - 1 && styles.railImageLast]}
        />
    );
    const keyExtractor = (item: RailItem) => item.id;
    if (library === "legendlist") {
        return (
            <View style={styles.rail}>
                <LegendList
                    data={data}
                    estimatedItemSize={RAIL_SIDE + RAIL_GAP}
                    horizontal
                    keyExtractor={keyExtractor}
                    recycleItems
                    renderItem={renderRailItem}
                    showsHorizontalScrollIndicator={false}
                />
            </View>
        );
    }
    if (library === "flashlist") {
        return (
            <View style={styles.rail}>
                <FlashList
                    data={data}
                    horizontal
                    keyExtractor={keyExtractor}
                    renderItem={renderRailItem}
                    showsHorizontalScrollIndicator={false}
                />
            </View>
        );
    }
    return (
        <View style={styles.rail}>
            <FlatList
                data={data}
                horizontal
                keyExtractor={keyExtractor}
                renderItem={renderRailItem}
                showsHorizontalScrollIndicator={false}
            />
        </View>
    );
}

const renderRightActions = () => (
    <Pressable style={styles.action}>
        <MaterialIcons color="white" name="check-circle" size={24} />
        <Text style={styles.actionText}>Complete</Text>
    </Pressable>
);

type CardProps = { index: number; item: Item; library: Library };

function AdvancedCardContent({
    index,
    item,
    library,
    isExpanded,
    setIsExpanded,
}: CardProps & { isExpanded: boolean; setIsExpanded: (value: boolean) => void }) {
    const d = cardData(Math.abs(+item.id));
    const perf = perfTest(Math.abs(+item.id), item.id);
    return (
        <View style={styles.itemOuterContainer}>
            <Swipeable containerStyle={styles.swipeableContainer} overshootRight renderRightActions={renderRightActions}>
                <Pressable
                    onPress={(e) => {
                        e.stopPropagation();
                        setIsExpanded(!isExpanded);
                    }}
                >
                    <View style={styles.itemContainer}>
                        <View style={styles.headerContainer}>
                            <Image source={{ uri: d.avatarUrl }} style={styles.avatar} />
                            <View style={styles.headerText}>
                                <Text style={styles.authorName}>
                                    {d.authorName} {item.id}
                                </Text>
                                <Text style={styles.timestamp}>{d.timestamp}</Text>
                            </View>
                        </View>
                        <Text style={styles.itemTitle}>Item #{item.id}</Text>
                        <Text style={styles.itemBody}>
                            {d.longBody}
                            {isExpanded ? d.longBody : null}
                        </Text>
                        <Rail library={library} urls={d.railUrls} />
                        <View style={styles.itemFooter}>
                            <Text style={styles.footerText}>❤️ 42</Text>
                            <Text style={styles.footerText}>💬 12</Text>
                            <Text style={styles.footerText}>🔄 8</Text>
                        </View>
                        <Text style={styles.perfText}>
                            🧮 Prime: {perf.primeCheck ? "✓" : "✗"} | Fib: {perf.fibResult}
                        </Text>
                    </View>
                </Pressable>
            </Swipeable>
        </View>
    );
}

// The expanded state lives with the item, as in the example: Legend List's
// and FlashList's recycling hooks reset it when the cell shows another item.
const LegendCard = memo(function LegendCard(props: CardProps) {
    const [isExpanded = false, setIsExpanded] = useRecyclingState<boolean>(() => false);
    return <AdvancedCardContent {...props} isExpanded={isExpanded} setIsExpanded={setIsExpanded} />;
});
const FlashCard = memo(function FlashCard(props: CardProps) {
    const [isExpanded, setIsExpanded] = useFlashRecyclingState(false, [props.item.id]);
    return <AdvancedCardContent {...props} isExpanded={isExpanded} setIsExpanded={setIsExpanded} />;
});
const PlainCard = memo(function PlainCard(props: CardProps) {
    const [isExpanded, setIsExpanded] = useState(false);
    return <AdvancedCardContent {...props} isExpanded={isExpanded} setIsExpanded={setIsExpanded} />;
});

/**
 * The advanced list: the example's Cards list configuration, with the
 * advanced card. [scrollTo] receives the library's own animated scrollToIndex.
 */
function AdvancedList({ scrollTo, library }: { scrollTo: ScrollTo; library: Library }) {
    const [data] = useState<Item[]>(() => Array.from({ length: 1000 }, (_, i) => ({ id: i.toString() })));
    const legendRef = useRef<LegendListRef>(null);
    const flashRef = useRef<FlashListRef<Item>>(null);
    const flatRef = useRef<FlatList<Item>>(null);
    scrollTo.current = (index: number) => {
        if (library === "legendlist") void legendRef.current?.scrollToIndex({ animated: true, index });
        else if (library === "flashlist") void flashRef.current?.scrollToIndex({ animated: true, index });
        else flatRef.current?.scrollToIndex({ animated: true, index });
    };
    const keyExtractor = (item: Item) => item.id;
    if (library === "legendlist") {
        return (
            <View key="legendlist" style={[StyleSheet.absoluteFill, styles.outerContainer]}>
                <LegendList
                    data={data}
                    drawDistance={DRAW_DISTANCE}
                    estimatedItemSize={ESTIMATED_ITEM_LENGTH}
                    keyExtractor={keyExtractor}
                    ListHeaderComponent={<View />}
                    ListHeaderComponentStyle={styles.listHeader}
                    recycleItems={true}
                    ref={legendRef}
                    renderItem={({ item, index }: LegendListRenderItemProps<Item>) => (
                        <LegendCard index={index} item={item} library={library} />
                    )}
                />
            </View>
        );
    }
    if (library === "flashlist") {
        return (
            <View key="flashlist" style={[StyleSheet.absoluteFill, styles.outerContainer]}>
                <FlashList
                    data={data}
                    drawDistance={DRAW_DISTANCE}
                    keyExtractor={keyExtractor}
                    ListHeaderComponent={<View />}
                    ListHeaderComponentStyle={styles.listHeader}
                    ref={flashRef}
                    renderItem={({ item, index }) => <FlashCard index={index} item={item} library={library} />}
                />
            </View>
        );
    }
    return (
        <View key="flatlist" style={[StyleSheet.absoluteFill, styles.outerContainer]}>
            <FlatList
                data={data}
                keyExtractor={keyExtractor}
                ListHeaderComponent={<View />}
                ListHeaderComponentStyle={styles.listHeader}
                // FlatList cannot scroll to a row it has not laid out; React
                // Native's documented answer: scroll to the estimate from
                // the rows measured so far, then ask again.
                onScrollToIndexFailed={(info) => {
                    flatRef.current?.scrollToOffset({ animated: true, offset: info.averageItemLength * info.index });
                    setTimeout(() => flatRef.current?.scrollToIndex({ animated: true, index: info.index }), 500);
                }}
                ref={flatRef}
                renderItem={({ item, index }) => <PlainCard index={index} item={item} library={library} />}
            />
        </View>
    );
}

/**
 * The Cards screen of one library in the benchmark's advanced mode, with the
 * Scroll bar button. With ADVANCED false it is the example's own Cards
 * screen, which the benchmark does not show.
 */
const ADVANCED = true;
/** What the bar title names, so a screen recording says what is running. */
const TITLE_TAG: Record<Library, string> = {
    flashlist: "RN - FlashList",
    flatlist: "RN - FlatList",
    legendlist: "RN - Legend List",
};

export function AdvancedCardsScreen({ library }: { library: Library }) {
    const scrollTo: ScrollTo = useRef(null);
    const nextTarget = useRef(0);
    const scroll = () => {
        scrollTo.current?.(SCROLL_TARGETS[nextTarget.current % SCROLL_TARGETS.length]);
        nextTarget.current++;
    };
    const Normal = library === "legendlist" ? CardsFixture : library === "flashlist" ? CardsFlashListFixture : CardsFlatListFixture;
    return (
        <>
            <Stack.Screen
                options={{
                    headerRight: ({ tintColor }) => (
                        <View style={styles.barButtons}>
                            <Pressable
                                accessibilityLabel="Scroll"
                                accessibilityRole="button"
                                hitSlop={8}
                                onPress={scroll}
                                style={styles.toggle}
                            >
                                <MaterialIcons color={tintColor} name="arrow-downward" size={24} />
                            </Pressable>
                        </View>
                    ),
                    headerTitle: `Cards (${TITLE_TAG[library]})`,
                    headerTransparent: false,
                }}
            />
            {ADVANCED ? <AdvancedList key="advanced" library={library} scrollTo={scrollTo} /> : <Normal key="normal" />}
        </>
    );
}

const styles = StyleSheet.create({
    action: {
        alignItems: "center",
        backgroundColor: palette.success,
        borderBottomRightRadius: 12,
        borderTopRightRadius: 12,
        height: "100%",
        justifyContent: "center",
        width: 80,
    },
    actionText: { color: "white", fontSize: 12, fontWeight: "600", marginTop: 4 },
    authorName: { color: palette.textPrimary, fontSize: 16, fontWeight: "600" },
    avatar: { borderRadius: 20, height: 40, marginRight: 12, width: 40 },
    barButtons: { alignItems: "center", flexDirection: "row" },
    footerText: { color: palette.textMuted, fontSize: 14 },
    headerContainer: { alignItems: "center", flexDirection: "row", marginBottom: 12 },
    headerText: { flex: 1 },
    itemBody: { color: palette.textSecondary, fontSize: 14, lineHeight: 20 },
    itemContainer: {
        backgroundColor: palette.cardBackground,
        borderColor: palette.border,
        borderRadius: 12,
        borderWidth: StyleSheet.hairlineWidth * 2,
        elevation: 4,
        overflow: "hidden",
        padding: 16,
        shadowColor: palette.shadowColor,
        shadowOffset: { height: 6, width: 0 },
        shadowOpacity: 0.45,
        shadowRadius: 12,
    },
    itemFooter: {
        borderTopColor: palette.divider,
        borderTopWidth: 1,
        flexDirection: "row",
        gap: 16,
        justifyContent: "flex-start",
        marginTop: 12,
        paddingTop: 12,
    },
    itemOuterContainer: { backgroundColor: palette.outerBackground, paddingHorizontal: 12, paddingVertical: 12 },
    itemTitle: { color: palette.textPrimary, fontSize: 18, fontWeight: "bold", marginBottom: 8 },
    listHeader: {
        alignSelf: "center",
        backgroundColor: "#456AAA",
        borderRadius: 12,
        height: 100,
        marginHorizontal: 8,
        marginVertical: 8,
        width: 100,
    },
    outerContainer: { backgroundColor: "#456" },
    perfText: { color: palette.textMuted, fontSize: 14, marginTop: 8 },
    rail: { height: RAIL_SIDE, marginTop: 12 },
    railImage: { backgroundColor: palette.divider, borderRadius: 8, height: RAIL_SIDE, marginRight: RAIL_GAP, width: RAIL_SIDE },
    railImageLast: { marginRight: 0 },
    swipeableContainer: { backgroundColor: palette.success, borderRadius: 12 },
    timestamp: { color: palette.textMuted, fontSize: 12, marginTop: 2 },
    // Square, so iOS 26 draws the bar's glass behind it as a circle, as it
    // does for a system bar button.
    toggle: { padding: 6 },
});
