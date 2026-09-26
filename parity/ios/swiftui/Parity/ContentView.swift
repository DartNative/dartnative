import SwiftUI

/// The platform's own controls with nothing set on them, in the order of the
/// DartNative parity screen, so the two can be held side by side. iOS has no
/// checkbox, radio button, card, floating action button or centre dialog, and
/// SwiftUI has no tinted or outlined button style; those rows are
/// DartNative's own and have no line here.
struct ContentView: View {
    @State private var isOn = true
    @State private var slider = 0.4
    @State private var segment = 0
    @State private var pick: String? = nil
    @State private var tab = 0
    @State private var hint = ""
    @State private var plain = ""
    @State private var showSheet = false
    @State private var showMediumSheet = false
    @State private var sheetHeight: CGFloat = 0
    @State private var showAlert = false

    /// nil follows the system; the bar's button cycles light and dark so the
    /// two themes are compared in one install.
    @State private var scheme: ColorScheme? = nil
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Plain Text, no style")
                        Text("Title, 22").font(.system(size: 22))
                        Text("Body, 16").font(.system(size: 16))
                        Spacer().frame(height: 12)
                        // Stacked buttons 8pt apart, the stack's own default between
                        // bordered buttons; an iOS button carries no air of its own.
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Filled") {}.buttonStyle(.borderedProminent)
                            Button("Gray") {}.buttonStyle(.bordered)
                            Button("Plain") {}.buttonStyle(.borderless)
                            Button("No variant") {}
                        }
                        Spacer().frame(height: 12)
                        HStack(spacing: 12) {
                            Toggle("", isOn: $isOn).labelsHidden()
                            Text("Switch")
                        }
                        Spacer().frame(height: 8)
                        Slider(value: $slider)
                        Spacer().frame(height: 12)
                        ProgressView()
                        Spacer().frame(height: 12)
                        ProgressView(value: 0.6)
                        Spacer().frame(height: 12)
                        TextField("Hint", text: $hint).textFieldStyle(.roundedBorder)
                        Spacer().frame(height: 12)
                        TextField("Plain EditText", text: $plain)
                        Spacer().frame(height: 12)
                        Picker("", selection: $segment) {
                            Text("One").tag(0)
                            Text("Two").tag(1)
                            Text("Three").tag(2)
                        }
                        .pickerStyle(.segmented)
                        Spacer().frame(height: 12)
                        Picker("Pick", selection: $pick) {
                            Text("Pick").tag(String?.none)
                            Text("One").tag(String?.some("One"))
                            Text("Two").tag(String?.some("Two"))
                            Text("Three").tag(String?.some("Three"))
                        }
                        .pickerStyle(.menu)
                        Spacer().frame(height: 12)
                        // A row of the platform's own list, at the row's own height,
                        // its separator replaced by the divider below it.
                        List {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("List item")
                                Text("Supporting text").font(.subheadline).foregroundStyle(.secondary)
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .frame(height: 70)
                        Divider()
                        Spacer().frame(height: 20)
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Bottom sheet") { showSheet = true }.buttonStyle(.borderedProminent)
                            Button("Modal sheet (medium)") { showMediumSheet = true }.buttonStyle(.borderedProminent)
                            Button("Alert") { showAlert = true }.buttonStyle(.borderedProminent)
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // A tap on the page outside a field puts the keyboard away.
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .navigationTitle("System parity (SwiftUI)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            scheme = scheme == .dark ? .light : .dark
                        } label: {
                            Image(systemName: scheme == .dark ? "sun.max" : "moon")
                        }
                    }
                }
                .preferredColorScheme(scheme)
        .sheet(isPresented: $showSheet) {
                    // A sheet sized to its content: the measured panel height
                    // as the one detent; the panel keeps its wrapped height
                    // whatever height the sheet proposes, so the measurement
                    // is the content's own.
                    panel("sheet")
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
                        .presentationDetents([.height(sheetHeight)])
                }
                .sheet(isPresented: $showMediumSheet) {
                    VStack(spacing: 0) { panel("sheet"); Spacer() }
                        .presentationDetents([.medium])
                }
                .alert("Native alert", isPresented: $showAlert) {
                    Button("OK") {}
                } message: {
                    Text("A native alert with a message and a button.")
                }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)
            Text("Search")
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .badge(3)
                .tag(1)
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(2)
        }
    }

    /// The same content as the other twins' panels, at the same spacing: 8
    /// between the texts, 16 before the button, 20 around.
    @ViewBuilder
    private func panel(_ what: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Native \(what)").font(.system(size: 22))
            Spacer().frame(height: 8)
            Text("Dismiss this \(what) by dragging the grabber down.")
            Spacer().frame(height: 8)
            Text("Body text with TextAppearance BodyLarge").font(.system(size: 16))
            Spacer().frame(height: 16)
            Button("Close") { showSheet = false; showMediumSheet = false }.buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
