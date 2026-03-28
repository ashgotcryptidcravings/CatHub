//
//  ContentView.swift
//  CatHub
//
//  Created by Zero on 2026-01-29.
//

import SwiftUI
import CryptoKit
import ImageIO
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Helpers

@inline(__always)
func softHaptic() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    #endif
}

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

// MARK: - App Secrets

enum AppSecrets {
    static var theCatAPIKey: String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "THE_CAT_API_KEY") as? String) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - App State

enum CatHubTab: String, CaseIterable, Identifiable {
    case randomizer
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .randomizer: return "Randomizer"
        case .saved: return "Saved"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .randomizer: return "cat.fill"
        case .saved: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum CatHubTintChoice: String, CaseIterable, Identifiable {
    case purple, lavender
    case blue, indigo
    case cyan, teal, mint, green
    case yellow, orange, red
    case pink, hotPink
    case brown
    case graphite, midnight, black, white
    case rainbow

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hotPink: return "Hot Pink"
        default: return rawValue.capitalized
        }
    }

    var color: Color {
        switch self {
        case .purple: return .purple
        case .lavender: return Color(red: 0.74, green: 0.63, blue: 0.98)
        case .blue: return .blue
        case .indigo: return .indigo
        case .cyan: return .cyan
        case .teal: return .teal
        case .mint: return .mint
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .hotPink: return Color(red: 1.00, green: 0.18, blue: 0.55)
        case .brown: return .brown
        case .graphite: return Color(white: 0.65)
        case .midnight: return Color(red: 0.05, green: 0.08, blue: 0.14)
        case .black: return .black
        case .white: return .white
        case .rainbow: return .purple
        }
    }

    var symbol: String {
        switch self {
        case .purple: return "sparkles"
        case .lavender: return "wand.and.stars"
        case .blue: return "drop.fill"
        case .indigo: return "wave.3.right"
        case .cyan: return "bubbles.and.sparkles"
        case .teal: return "wind"
        case .mint: return "leaf.circle.fill"
        case .green: return "leaf.fill"
        case .yellow: return "sun.max.fill"
        case .orange: return "sun.haze.fill"
        case .red: return "flame.fill"
        case .pink: return "heart.fill"
        case .hotPink: return "heart.circle.fill"
        case .brown: return "cup.and.saucer.fill"
        case .graphite: return "circle.lefthalf.filled"
        case .midnight: return "moon.stars.fill"
        case .black: return "circle.fill"
        case .white: return "circle"
        case .rainbow: return "paintpalette.fill"
        }
    }
}

// MARK: - ContentView Root

struct ContentView: View {
    @State private var tab: CatHubTab = .randomizer

    @AppStorage("CatHub.tint") private var tintRaw: String = CatHubTintChoice.purple.rawValue
    private var tint: CatHubTintChoice { CatHubTintChoice(rawValue: tintRaw) ?? .purple }

    @StateObject private var favorites = FavoritesStore()
    @StateObject private var randomizerVM = RandomizerViewModel()

    @State private var rainbowHue: Double = 0

    private var accentColor: Color {
        if tint == .rainbow {
            return Color(hue: rainbowHue, saturation: 0.7, brightness: 0.95)
        }
        return tint.color
    }

    var body: some View {
        ZStack {
            switch tab {
            case .randomizer:
                RandomizerView(accent: accentColor, favorites: favorites, vm: randomizerVM)
            case .saved:
                SavedView(accent: accentColor, favorites: favorites)
            case .settings:
                SettingsView(tintRaw: $tintRaw)
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomNativeMenu(selection: $tab, accent: accentColor)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .preferredColorScheme(nil)
        .onAppear { startRainbowIfNeeded() }
        .onChange(of: tintRaw) { _, _ in startRainbowIfNeeded() }
    }

    private func startRainbowIfNeeded() {
        guard tint == .rainbow else { return }
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            rainbowHue = 1.0
        }
    }
}

// MARK: - Bottom Menu

struct BottomNativeMenu: View {
    @Binding var selection: CatHubTab
    let accent: Color

    var body: some View {
        HStack {
            Spacer()
            Menu {
                ForEach(CatHubTab.allCases) { tab in
                    Button {
                        selection = tab
                        softHaptic()
                    } label: {
                        Label(tab.title, systemImage: tab.symbol)
                    }
                }
            } label: {
                Image(systemName: selection.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 54, height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
            }
            .menuStyle(.automatic)
            Spacer()
        }
    }
}

// MARK: - Glass Controls

struct GlassIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var accent: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .tint(.clear)
        .accessibilityAddTraits(.isButton)
    }
}

struct GlassPillButton<Content: View>: View {
    var height: CGFloat = 44
    var content: () -> Content
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            content()
                .frame(height: height)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .tint(.clear)
    }
}

// MARK: - Randomizer

struct RandomizerView: View {
    let accent: Color
    @ObservedObject var favorites: FavoritesStore
    @ObservedObject var vm: RandomizerViewModel

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false
    @State private var lastLoadTriggerCount: Int = 0

    private let spacing: CGFloat = 2
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CatHub")
                        .font(.system(size: 44, weight: .bold))
                        .padding(.top, 8)

                    Text("Got Cat? We do.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(Array(vm.images.enumerated()), id: \.element.id) { (idx, img) in
                            CompactGridTile(url: img.url)
                                .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .onTapGesture {
                                    viewerImages = vm.images
                                    viewerStartIndex = idx
                                    showViewer = true
                                }
                                .onAppear { maybeLoadMore(at: idx) }
                        }

                        if vm.isLoading {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(ProgressView().scaleEffect(0.9))
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
                .padding(.horizontal, 14)
            }
            .refreshable { await vm.refresh() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadOnce() }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent, favorites: favorites)
            }
        }
    }

    private func maybeLoadMore(at idx: Int) {
        guard !vm.isLoading, !vm.images.isEmpty else { return }
        let triggerIndex = max(vm.images.count - 10, 0)
        guard idx >= triggerIndex else { return }
        guard vm.images.count != lastLoadTriggerCount else { return }
        lastLoadTriggerCount = vm.images.count
        Task { await vm.loadMore() }
    }
}

private struct CompactGridTile: View {
    let url: URL?

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width

            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.ultraThinMaterial)

                CachedRemoteImage(
                    url: url,
                    targetPixelSize: CGSize(width: 400, height: 400)
                ) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: side, height: side)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: side, height: side)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Saved

struct SavedView: View {
    let accent: Color
    @ObservedObject var favorites: FavoritesStore

    @StateObject private var vm = SavedViewModel()

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false

    private let spacing: CGFloat = 4
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if favorites.ids.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: spacing) {
                            Text("Saved")
                                .font(.system(size: 44, weight: .bold))
                                .padding(.top, 8)

                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(vm.savedImages, id: \.id) { img in
                                    SavedTile(url: img.url)
                                        .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .onTapGesture {
                                            viewerImages = vm.savedImages
                                            viewerStartIndex = vm.savedImages.firstIndex(where: { $0.id == img.id }) ?? 0
                                            showViewer = true
                                        }
                                }
                            }
                            .padding(.bottom, 80)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: favorites.ids) {
                await vm.loadSaved(from: favorites)
            }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent, favorites: favorites)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Saved")
                .font(.system(size: 44, weight: .bold))
            Text("You haven't favorited any cats yet.\nGo collect some kitties!")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

private struct SavedTile: View {
    let url: URL?

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width

            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.ultraThinMaterial)

                CachedRemoteImage(
                    url: url,
                    targetPixelSize: CGSize(width: 600, height: 600)
                ) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: side, height: side)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: side, height: side)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Binding var tintRaw: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Tint") {
                    Picker("Accent", selection: $tintRaw) {
                        ForEach(CatHubTintChoice.allCases) { t in
                            Label(t.name, systemImage: t.symbol)
                                .tag(t.rawValue)
                        }
                    }
                }

                Section("About CatHub") {
                    Text("CatHub is a tiny, cozy app designed to bring immediate joy.\n\nJust cats. Randomized. Saveable. Customizable. That's it.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                Section("Version") {
                    Text("0.1.0B - The Simplicity Update.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Viewer

struct CatViewer: View {
    let images: [CatImage]
    let startIndex: Int
    let accent: Color
    @ObservedObject var favorites: FavoritesStore

    @State private var index: Int
    @State private var sharePayload: SharePayload?
    @State private var isPreparingShare = false
    @State private var isFlipped = false
    @State private var detailOverrides: [String: CatImage] = [:]
    @State private var loadingDetails: Set<String> = []

    @Environment(\.dismiss) private var dismiss
    private let api = CatAPIClient()

    init(images: [CatImage], startIndex: Int, accent: Color, favorites: FavoritesStore) {
        self.images = images
        self.startIndex = startIndex
        self.accent = accent
        self.favorites = favorites
        _index = State(initialValue: startIndex)
    }

    private var current: CatImage? {
        guard !images.isEmpty else { return nil }
        let image = images[max(0, min(index, images.count - 1))]
        return detailOverrides[image.id] ?? image
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(images.indices, id: \.self) { i in
                    FlippableCatCard(
                        image: detailOverrides[images[i].id] ?? images[i],
                        isFlipped: Binding(
                            get: { isFlipped && i == index },
                            set: { newValue in
                                if i == index { isFlipped = newValue }
                            }
                        )
                    )
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    GlassIconButton(systemName: "xmark", accent: accent) { dismiss() }
                    Spacer()
                    GlassIconButton(systemName: "square.and.arrow.up", accent: accent) {
                        Task { await prepareShare() }
                    }
                    .disabled(current == nil || isPreparingShare)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if let img = current {
                            favorites.toggle(img.id, url: img.url)
                            softHaptic()
                        }
                    } label: {
                        let isFav = (current?.id).map { favorites.isFavorite($0) } ?? false
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isFav ? Color.red : Color.primary)
                            .frame(width: 54, height: 44)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .tint(.clear)
                    .disabled(current == nil)

                    GlassPillButton(height: 44, content: {
                        Label("Info", systemImage: "rectangle.3.group.bubble.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }, action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isFlipped.toggle()
                        }
                        softHaptic()
                    })
                    .disabled(current == nil)

                    Spacer()

                    Text("\(min(index + 1, max(images.count, 1)))/\(max(images.count, 1))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .task {
            if let current { await loadDetailsIfNeeded(for: current) }
        }
        .onChange(of: index) { _, _ in
            if let current { Task { await loadDetailsIfNeeded(for: current) } }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
            #if canImport(UIKit)
                .presentationDetents([.medium])
            #endif
        }
    }

    private func needsDetails(_ image: CatImage) -> Bool {
        guard image.source == .theCatAPI else { return false }
        guard let breed = image.breeds?.first else { return true }
        return breed.name.isEmpty ||
        (breed.origin?.isEmpty ?? true) ||
        (breed.temperament?.isEmpty ?? true) ||
        (breed.description?.isEmpty ?? true)
    }

    private func loadDetailsIfNeeded(for image: CatImage) async {
        guard needsDetails(image) else { return }
        let shouldLoad = await MainActor.run { !loadingDetails.contains(image.id) }
        guard shouldLoad else { return }

        await MainActor.run { loadingDetails.insert(image.id) }
        defer { Task { @MainActor in loadingDetails.remove(image.id) } }

        do {
            if let enriched = try await api.fetchImageById(image.id) {
                await MainActor.run { detailOverrides[image.id] = enriched }
            }
        } catch {
            print("Detail load error:", error)
        }
    }

    @MainActor
    private func prepareShare() async {
        guard let image = current, let url = image.url else { return }
        guard !isPreparingShare else { return }
        isPreparingShare = true
        defer { isPreparingShare = false }

        if let platformImage = await CatImageCache.shared.imageForShare(url: url) {
            sharePayload = SharePayload(items: [platformImage])
        }
    }
}

// MARK: - Flip Card

struct FlippableCatCard: View {
    let image: CatImage
    @Binding var isFlipped: Bool

    @State private var zoomScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            ZoomableScrollView(zoomScale: $zoomScale) {
                CatImageCard(image: image)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(isFlipped ? 0.0 : 1.0)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .allowsHitTesting(!isFlipped)
            .accessibilityHidden(isFlipped)

            CatInfoBackCard(image: image)
                .opacity(isFlipped ? 1.0 : 0.0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .allowsHitTesting(isFlipped)
                .accessibilityHidden(!isFlipped)
        }
        .ignoresSafeArea()
        .onChange(of: isFlipped) { _, newValue in
            if newValue { zoomScale = 1.0 }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: isFlipped)
    }
}

// MARK: - Image Card

struct CatImageCard: View {
    let image: CatImage

    var body: some View {
        CachedRemoteImage(
            url: image.url,
            targetPixelSize: CGSize(width: 1800, height: 1800)
        ) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView().scaleEffect(1.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                ZStack {
                    Color.black.opacity(0.4)
                    Image(systemName: "photo")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Zoomable Scroll View

#if canImport(UIKit)
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @Binding var zoomScale: CGFloat
    var minZoom: CGFloat = 1.0
    var maxZoom: CGFloat = 4.0
    var doubleTapZoom: CGFloat = 2.5
    var content: Content

    init(
        zoomScale: Binding<CGFloat>,
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 4.0,
        doubleTapZoom: CGFloat = 2.5,
        @ViewBuilder content: () -> Content
    ) {
        self._zoomScale = zoomScale
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.doubleTapZoom = doubleTapZoom
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = minZoom
        scroll.maximumZoomScale = maxZoom
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.bouncesZoom = true
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.decelerationRate = .fast

        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),
        ])

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.hostingController = host

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        scroll.setZoomScale(zoomScale, animated: false)
        context.coordinator.centerContent(scroll)

        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        if !scroll.isDragging, !scroll.isZooming, !scroll.isDecelerating {
            context.coordinator.hostingController?.rootView = content

            let current = scroll.zoomScale
            let desired = zoomScale
            if abs(current - desired) > 0.01 {
                scroll.setZoomScale(desired, animated: false)
            }
        }
        context.coordinator.centerContent(scroll)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale, doubleTapZoom: doubleTapZoom)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        private var zoomScaleBinding: Binding<CGFloat>
        private let doubleTapZoom: CGFloat

        init(zoomScale: Binding<CGFloat>, doubleTapZoom: CGFloat) {
            self.zoomScaleBinding = zoomScale
            self.doubleTapZoom = doubleTapZoom
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScaleBinding.wrappedValue = scrollView.zoomScale
            centerContent(scrollView)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            centerContent(scrollView)
        }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = gr.view as? UIScrollView,
                  let zoomView = hostingController?.view else { return }

            let isZoomedIn = scroll.zoomScale > (scroll.minimumZoomScale + 0.01)
            let targetScale: CGFloat = isZoomedIn
            ? scroll.minimumZoomScale
            : min(doubleTapZoom, scroll.maximumZoomScale)

            let tapPointInZoomView = gr.location(in: zoomView)
            let rect = zoomRect(for: targetScale, center: tapPointInZoomView, in: scroll)
            scroll.zoom(to: rect, animated: true)
            softHaptic()
        }

        private func zoomRect(for scale: CGFloat, center: CGPoint, in scroll: UIScrollView) -> CGRect {
            let size = scroll.bounds.size
            let w = size.width / scale
            let h = size.height / scale
            return CGRect(x: center.x - w/2, y: center.y - h/2, width: w, height: h)
        }

        func centerContent(_ scrollView: UIScrollView) {
            guard let v = hostingController?.view else { return }
            let boundsSize = scrollView.bounds.size
            let contentSize = v.frame.size

            let insetX = max(0, (boundsSize.width - contentSize.width) / 2)
            let insetY = max(0, (boundsSize.height - contentSize.height) / 2)

            scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        }
    }
}
#elseif canImport(AppKit)
struct ZoomableScrollView<Content: View>: View {
    @Binding var zoomScale: CGFloat
    var content: Content

    init(
        zoomScale: Binding<CGFloat>,
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 4.0,
        doubleTapZoom: CGFloat = 2.5,
        @ViewBuilder content: () -> Content
    ) {
        self._zoomScale = zoomScale
        self.content = content()
    }

    var body: some View {
        content
    }
}
#endif

// MARK: - Back Card (Info)

struct CatInfoBackCard: View {
    let image: CatImage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(image.breedName ?? fallbackTitle)
                    .font(.system(size: 28, weight: .bold))

                Group {
                    if let origin = image.origin, !origin.isEmpty {
                        Text("Origin: \(origin)")
                    }
                    if let temperament = image.temperament, !temperament.isEmpty {
                        Text(temperament)
                            .padding(.top, 2)
                    }
                    if image.source != .theCatAPI {
                        Text("Source: \(image.source.displayName)")
                            .padding(.top, 6)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

                Divider().opacity(0.2)

                if let description = image.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .padding(.top, 6)
                } else {
                    Text(fallbackDescription)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .padding(.top, 6)

                    Text("Don't worry if nothing appears here yet! Our doughmakers are still baking this section :3")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                }

                Spacer(minLength: 60)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 18)
            .padding(.top, 90)
            .padding(.bottom, 90)
        }
    }

    private var fallbackTitle: String {
        switch image.source {
        case .cataas:
            return "Mystery Internet Cat (CATAAS)"
        case .theCatAPI:
            return "Cat did not feel comfortable with sharing breed info."
        }
    }

    private var fallbackDescription: String {
        switch image.source {
        case .cataas:
            return "This cat came from CATAAS — it's pure chaos-energy, no breed metadata. Just vibes."
        case .theCatAPI:
            return "Description was pushed off the table."
        }
    }
}

// MARK: - Models

struct CatBreed: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let origin: String?
    let temperament: String?
    let description: String?
}

enum CatSource: String, Codable, Hashable {
    case theCatAPI
    case cataas

    var displayName: String {
        switch self {
        case .theCatAPI: return "TheCatAPI"
        case .cataas: return "CATAAS"
        }
    }
}

struct CatImage: Identifiable, Codable, Hashable {
    let id: String
    let url: URL?
    let breeds: [CatBreed]?
    let source: CatSource

    var breedName: String? { breeds?.first?.name }
    var origin: String? { breeds?.first?.origin }
    var temperament: String? { breeds?.first?.temperament }
    var description: String? { breeds?.first?.description }

    enum CodingKeys: String, CodingKey {
        case id, url, breeds, source
    }

    init(id: String, url: URL?, breeds: [CatBreed]?, source: CatSource) {
        self.id = id
        self.url = url
        self.breeds = breeds
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        url = try? c.decode(URL.self, forKey: .url)
        breeds = try? c.decode([CatBreed].self, forKey: .breeds)
        source = (try? c.decode(CatSource.self, forKey: .source)) ?? .theCatAPI
    }
}

// MARK: - Networking

final class CatAPIClient {
    private let base = URL(string: "https://api.thecatapi.com/v1")!
    private let session: URLSession
    private let theCatAPIKey: String

    init(theCatAPIKey: String = AppSecrets.theCatAPIKey) {
        self.theCatAPIKey = theCatAPIKey

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.urlCache = URLCache(
            memoryCapacity: 40 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "CatHubURLCache"
        )
        self.session = URLSession(configuration: cfg)
    }

    private func applyTheCatAPIKey(_ req: inout URLRequest) {
        let key = theCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        req.setValue(key, forHTTPHeaderField: "x-api-key")
    }

    private func validatedData(for req: URLRequest) async throws -> Data {
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: Global Images

    func fetchGlobalImages(limit: Int = 20, page: Int = 0, order: String = "RAND") async throws -> [CatImage] {
        var comps = URLComponents(url: base.appendingPathComponent("images/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "size", value: "med"),
            URLQueryItem(name: "include_breeds", value: "1")
        ]

        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 25
        applyTheCatAPIKey(&req)

        let data = try await validatedData(for: req)
        let decoded = try JSONDecoder().decode([CatImage].self, from: data)
        return decoded.map { CatImage(id: $0.id, url: $0.url, breeds: $0.breeds, source: .theCatAPI) }
    }

    // MARK: Image Details

    func fetchImageById(_ id: String) async throws -> CatImage? {
        var comps = URLComponents(url: base.appendingPathComponent("images/\(id)"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "include_breeds", value: "1")
        ]

        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 25
        applyTheCatAPIKey(&req)

        let data = try await validatedData(for: req)
        let decoded = try JSONDecoder().decode(CatImage.self, from: data)
        return CatImage(id: decoded.id, url: decoded.url, breeds: decoded.breeds, source: .theCatAPI)
    }

    func fetchImagesByIdsConcurrent(_ ids: [String]) async throws -> [CatImage] {
        if ids.isEmpty { return [] }

        return try await withThrowingTaskGroup(of: CatImage?.self) { group in
            for id in ids {
                group.addTask { try await self.fetchImageById(id) }
            }

            var results: [CatImage] = []
            for try await item in group {
                if let item { results.append(item) }
            }

            let order = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
            return results.sorted { (order[$0.id] ?? 999_999) < (order[$1.id] ?? 999_999) }
        }
    }

    // MARK: CATAAS

    struct CataasRandomResponse: Codable {
        let id: String
        let url: String
        let mimetype: String?
    }

    func fetchCataasRandom() async throws -> CatImage? {
        let url = URL(string: "https://cataas.com/cat?json=true")!
        var req = URLRequest(url: url)
        req.timeoutInterval = 20

        let data = try await validatedData(for: req)
        let decoded = try JSONDecoder().decode(CataasRandomResponse.self, from: data)

        let imageURL: URL?
        if decoded.url.hasPrefix("http") {
            imageURL = URL(string: decoded.url)
        } else {
            imageURL = URL(string: "https://cataas.com\(decoded.url)")
        }
        guard let imageURL else { return nil }

        return CatImage(id: "cataas_\(decoded.id)", url: imageURL, breeds: nil, source: .cataas)
    }

    func fetchCataasRandomBatch(_ count: Int) async throws -> [CatImage] {
        if count <= 0 { return [] }
        return try await withThrowingTaskGroup(of: CatImage?.self) { group in
            for _ in 0..<count {
                group.addTask { try await self.fetchCataasRandom() }
            }
            var out: [CatImage] = []
            for try await item in group {
                if let item { out.append(item) }
            }
            return out
        }
    }
}

// MARK: - Randomizer VM

@MainActor
final class RandomizerViewModel: ObservableObject {
    @Published var images: [CatImage] = []
    @Published var isLoading = false

    private let api = CatAPIClient()
    private let maxKept = 200
    private var didLoadOnce = false

    func loadOnce() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await loadMore()
    }

    func refresh() async {
        await loadMore()
    }

    func loadMore(batchSize: Int = 24) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let catApiCount = max(batchSize - 6, 12)
            let cataasCount = max(batchSize - catApiCount, 4)

            async let a = api.fetchGlobalImages(limit: catApiCount, page: 0, order: "RAND")
            async let b = api.fetchCataasRandomBatch(cataasCount)

            var combined = try await (a + b)
            combined = combined.uniquedById()

            images.append(contentsOf: combined)
            images = images.uniquedById()

            if images.count > maxKept {
                images = Array(images.suffix(maxKept))
            }
        } catch {
            print("Load error:", error)
        }
    }
}

// MARK: - Favorites Store

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: [String] = []
    private var urlMap: [String: String] = [:]
    private let idsKey = "CatHub.favorites"
    private let urlsKey = "CatHub.favoriteURLs"

    init() {
        if let data = UserDefaults.standard.array(forKey: idsKey) as? [String] {
            ids = data
        }
        if let data = UserDefaults.standard.dictionary(forKey: urlsKey) as? [String: String] {
            urlMap = data
        }
    }

    func isFavorite(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String, url: URL? = nil) {
        if let idx = ids.firstIndex(of: id) {
            ids.remove(at: idx)
            urlMap.removeValue(forKey: id)
        } else {
            ids.append(id)
            if let url { urlMap[id] = url.absoluteString }
        }
        save()
        softHaptic()
    }

    func url(for id: String) -> URL? {
        guard let str = urlMap[id] else { return nil }
        return URL(string: str)
    }

    func cacheURL(_ url: URL, for id: String) {
        urlMap[id] = url.absoluteString
        UserDefaults.standard.set(urlMap, forKey: urlsKey)
    }

    private func save() {
        UserDefaults.standard.set(ids, forKey: idsKey)
        UserDefaults.standard.set(urlMap, forKey: urlsKey)
    }
}

// MARK: - Saved VM

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedImages: [CatImage] = []
    private let api = CatAPIClient()

    func loadSaved(from favorites: FavoritesStore) async {
        let ids = favorites.ids
        if ids.isEmpty {
            savedImages = []
            return
        }

        var resolved: [CatImage] = []
        var needsLookup: [String] = []

        for id in ids {
            if id.hasPrefix("cataas_") {
                let cataasId = String(id.dropFirst("cataas_".count))
                let url = URL(string: "https://cataas.com/cat/\(cataasId)")
                resolved.append(CatImage(id: id, url: url, breeds: nil, source: .cataas))
            } else if let url = favorites.url(for: id) {
                resolved.append(CatImage(id: id, url: url, breeds: nil, source: .theCatAPI))
            } else {
                needsLookup.append(id)
            }
        }

        if !needsLookup.isEmpty {
            do {
                let hydrated = try await api.fetchImagesByIdsConcurrent(needsLookup)
                for img in hydrated {
                    if let url = img.url {
                        favorites.cacheURL(url, for: img.id)
                    }
                }
                resolved.append(contentsOf: hydrated)
            } catch {
                print("Saved load error:", error)
            }
        }

        let lookup = Dictionary(uniqueKeysWithValues: resolved.map { ($0.id, $0) })
        savedImages = ids.compactMap { lookup[$0] }
    }
}

// MARK: - Share Sheet

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif canImport(AppKit)
struct ShareSheet: NSViewRepresentable {
    let activityItems: [Any]
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: activityItems)
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

// MARK: - Cached Image System

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure
}

private struct ImageCacheKey: Hashable {
    let url: URL
    let pixelWidth: Int
    let pixelHeight: Int

    init(url: URL, targetPixelSize: CGSize) {
        self.url = url
        self.pixelWidth = max(Int(targetPixelSize.width.rounded(.up)), 1)
        self.pixelHeight = max(Int(targetPixelSize.height.rounded(.up)), 1)
    }

    var cacheKey: NSString {
        "\(url.absoluteString)|\(pixelWidth)x\(pixelHeight)" as NSString
    }
}

actor ImagePipeline {
    static let shared = ImagePipeline()

    private let memoryCache = NSCache<NSString, PlatformImage>()
    private var inFlight: [ImageCacheKey: Task<PlatformImage?, Never>] = [:]

    init() {
        memoryCache.countLimit = 400
    }

    fileprivate func image(for key: ImageCacheKey, loader: @Sendable @escaping () async -> PlatformImage?) async -> PlatformImage? {
        if let cached = memoryCache.object(forKey: key.cacheKey) {
            return cached
        }

        if let task = inFlight[key] {
            return await task.value
        }

        let task = Task { await loader() }
        inFlight[key] = task

        let result = await task.value
        inFlight[key] = nil

        if let result {
            memoryCache.setObject(result, forKey: key.cacheKey)
        }

        return result
    }
}

final class CatImageCache {
    static let shared = CatImageCache()

    private let mem = NSCache<NSURL, PlatformImage>()
    private let fm = FileManager.default
    private let dirURL: URL

    private init() {
        mem.countLimit = 300
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        dirURL = caches.appendingPathComponent("CatHubImageCache", isDirectory: true)
        if !fm.fileExists(atPath: dirURL.path) {
            try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }
    }

    func image(for url: URL) -> PlatformImage? {
        if let img = mem.object(forKey: url as NSURL) { return img }
        let f = fileURL(for: url)
        if let data = try? Data(contentsOf: f),
           let img = Self.decode(data: data) {
            mem.setObject(img, forKey: url as NSURL)
            return img
        }
        return nil
    }

    func store(_ image: PlatformImage, for url: URL) {
        mem.setObject(image, forKey: url as NSURL)
        let f = fileURL(for: url)
        if let data = Self.encodeJPEG(image: image, quality: 0.9) {
            try? data.write(to: f, options: [.atomic])
        }
    }

    func imageForShare(url: URL) async -> PlatformImage? {
        if let cached = image(for: url) {
            return cached
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = Self.decode(data: data) {
                store(image, for: url)
                return image
            }
        } catch {
            print("Share image error:", error)
        }

        return nil
    }

    private func fileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = hash.compactMap { String(format: "%02x", $0) }.joined()
        return dirURL.appendingPathComponent(name).appendingPathExtension("jpg")
    }

    static func decode(data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #else
        return NSImage(data: data)
        #endif
    }

    static func encodeJPEG(image: PlatformImage, quality: CGFloat) -> Data? {
        #if canImport(UIKit)
        return image.jpegData(compressionQuality: quality)
        #else
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #endif
    }
}

final class CachedImageLoader: ObservableObject {
    @MainActor @Published var phase: CachedImagePhase = .empty

    private var task: Task<Void, Never>?
    private let cache = CatImageCache.shared
    private let pipeline = ImagePipeline.shared
    private var currentURL: URL?

    @MainActor func load(url: URL?, targetPixelSize: CGSize) {
        if currentURL == url, case .success = phase { return }
        task?.cancel()

        guard let url else {
            phase = .failure
            return
        }

        currentURL = url

        // Check disk/memory cache synchronously — cached images appear instantly
        if let cached = cache.image(for: url) {
            phase = .success(Self.toSwiftUIImage(cached))
            return
        }

        phase = .empty
        let key = ImageCacheKey(url: url, targetPixelSize: targetPixelSize)

        task = Task.detached(priority: .utility) { [cache, pipeline] in
            if Task.isCancelled { return }

            let image = await pipeline.image(for: key) {
                if Task.isCancelled { return nil }

                if let cached = cache.image(for: url) {
                    return cached
                }

                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if Task.isCancelled { return nil }

                    if let img = Self.downsample(data: data, to: targetPixelSize) ?? CatImageCache.decode(data: data) {
                        cache.store(img, for: url)
                        return img
                    }
                } catch {
                    if Task.isCancelled { return nil }
                }

                return nil
            }

            if Task.isCancelled { return }

            if let image {
                let swiftUIImage = Self.toSwiftUIImage(image)
                await MainActor.run { self.phase = .success(swiftUIImage) }
            } else {
                await MainActor.run { self.phase = .failure }
            }
        }
    }

    func cancel() { task?.cancel() }

    static func downsample(data: Data, to targetPixelSize: CGSize) -> PlatformImage? {
        let maxDimension = max(targetPixelSize.width, targetPixelSize.height)
        guard maxDimension > 0 else { return CatImageCache.decode(data: data) }

        let options: [CFString: Any] = [ kCGImageSourceShouldCache: false ]
        guard let src = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, downsampleOptions as CFDictionary) else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: cg)
        #else
        return NSImage(cgImage: cg, size: .zero)
        #endif
    }

    static func toSwiftUIImage(_ img: PlatformImage) -> Image {
        #if canImport(UIKit)
        return Image(uiImage: img)
        #else
        return Image(nsImage: img)
        #endif
    }
}

struct CachedRemoteImage<Content: View>: View {
    let url: URL?
    let targetPixelSize: CGSize
    let content: (CachedImagePhase) -> Content

    @StateObject private var loader = CachedImageLoader()

    init(url: URL?, targetPixelSize: CGSize, @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        self.url = url
        self.targetPixelSize = targetPixelSize
        self.content = content
    }

    var body: some View {
        content(loader.phase)
            .task(id: url) {
                loader.load(url: url, targetPixelSize: targetPixelSize)
            }
            .onDisappear { loader.cancel() }
    }
}

// MARK: - Helpers

extension Array where Element == CatImage {
    func uniquedById() -> [CatImage] {
        var seen = Set<String>()
        var out: [CatImage] = []
        out.reserveCapacity(self.count)
        for item in self {
            if seen.insert(item.id).inserted {
                out.append(item)
            }
        }
        return out
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
