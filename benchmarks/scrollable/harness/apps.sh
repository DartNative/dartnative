# The installed app for one framework or list and one screen, on either
# phone. Each screen of each app is an app of its own, which opens straight
# on that screen (the app "ChatList (RN - FlatList)" is
# com.legendapp.listtest.chat.flatlist), so the harness launches it by its
# id, with no link or route to open in it.
#
#   . apps.sh
#   app_id <app> <screen>     the bundle id or Android package
#   app_activity <app>        the Android activity to start
#
#   app     dartnative | kotlin | uikit | legendlist | flashlist | flatlist
#   screen  cards | chat | empty

app_id() {
  local app=$1 screen=$2 s
  case "$screen" in
    cards) s=cards ;;
    chat) s=chat ;;
    empty) s=empty ;;
    *) echo "unknown screen: $screen" >&2; return 1 ;;
  esac
  case "$app:$s" in
    dartnative:*) echo "com.dartnative.benchmarks.scrollable.$s" ;;
    kotlin:*) echo "com.dartnative.benchmarks.scrollable.kotlin.$s" ;;
    uikit:*) echo "com.dartnative.benchmarks.scrollable.uikit.$s" ;;
    legendlist:empty) echo "there is no empty screen in Legend List's example" >&2; return 1 ;;
    legendlist:*) echo "com.legendapp.listtest.$s.legend" ;;
    flashlist:cards|flashlist:chat) echo "com.legendapp.listtest.$s.flashlist" ;;
    flatlist:cards|flatlist:chat) echo "com.legendapp.listtest.$s.flatlist" ;;
    *) echo "there is no $app app for the $screen screen" >&2; return 1 ;;
  esac
}

app_activity() {
  case "$1" in
    dartnative) echo "com.dartnative.benchmarks.scrollable.MainActivity" ;;
    kotlin) echo "com.dartnative.benchmarks.cards.MainActivity" ;;
    *) echo "com.legendapp.listtest.MainActivity" ;;
  esac
}
