//
//  ContentView.swift
//  CatHub
//
//  Created by Zero on 2026-01-29.
//  Updated by ChatGPT on 2026-02-03.
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

// MARK: - App Secrets (Integrated Keys)

enum AppSecrets {
    /// Put this in Info.plist:
    /// THE_CAT_API_KEY : String = "..."
    static var theCatAPIKey: String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "THE_CAT_API_KEY") as? String) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - App State

enum CatHubTab: String, CaseIterable, Identifiable {
    case browse
    case more
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browse: return "Browse"
        case .more: return "More Cats (New!)"
        case .saved: return "Saved"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .browse: return "pawprint.fill"
        case .more: return "cat.fill"
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

        case .rainbow:
            // Placeholder: you’ll need to handle this specially in UI
            // (gradient / animated hue shift, not a single Color)
            return .purple
        }
    }

    var symbol: String {
        switch self {

        // Purples
        case .purple: return "sparkles"
        case .lavender: return "wand.and.stars"

        // Blues
        case .blue: return "drop.fill"
        case .indigo: return "wave.3.right"

        // Cool tones
        case .cyan: return "bubbles.and.sparkles"
        case .teal: return "wind"
        case .mint: return "leaf.circle.fill"

        // Nature / warm
        case .green: return "leaf.fill"
        case .yellow: return "sun.max.fill"
        case .orange: return "sun.haze.fill"
        case .red: return "flame.fill"

        // Pinks
        case .pink: return "heart.fill"
        case .hotPink: return "heart.circle.fill"

        // Neutrals
        case .brown: return "cup.and.saucer.fill"

        case .graphite: return "circle.lefthalf.filled"
        case .midnight: return "moon.stars.fill"
        case .black: return "circle.fill"
        case .white: return "circle"

        // Special
        case .rainbow: return "paintpalette.fill"
        }
    }
}
// MARK: - ContentView Root

struct ContentView: View {
    @State private var tab: CatHubTab = .browse

    @AppStorage("CatHub.tint") private var tintRaw: String = CatHubTintChoice.purple.rawValue
    private var tint: CatHubTintChoice { CatHubTintChoice(rawValue: tintRaw) ?? .purple }

    // ✅ single source of truth for favorites
    @StateObject private var favorites = FavoritesStore()

    var body: some View {
        ZStack {
            switch tab {
            case .browse:
                BrowseView(accent: tint.color, favorites: favorites)

            case .more:
                MoreCatsView(accent: tint.color, favorites: favorites)

            case .saved:
                SavedView(accent: tint.color, favorites: favorites)

            case .settings:
                SettingsView(tintRaw: $tintRaw)
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomNativeMenu(selection: $tab, accent: tint.color)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .preferredColorScheme(nil)
    }
}

// MARK: - Bottom Button -> Native Menu

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

// MARK: - Browse

struct BrowseView: View {
    let accent: Color
    @ObservedObject var favorites: FavoritesStore

    @StateObject private var vm = BrowseViewModel()

    @State private var showSearch = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false

    private enum BrowseScrollAnchor: Hashable {
        case searchField
    }

    private var filteredBreeds: [CatBreed] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return vm.breeds }

        let lower = q.lowercased()
        return vm.breeds.filter { b in
            b.name.lowercased().contains(lower) ||
            (b.origin ?? "").lowercased().contains(lower) ||
            (b.temperament ?? "").lowercased().contains(lower)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            header

                            // ✅ Multi-API “More Cats” section (teaser row)
                            MoreCatsSectionCard(
                                accent: accent,
                                images: vm.globalImages,
                                isLoading: vm.isLoadingGlobal,
                                onSelect: { imgs, idx in
                                    viewerImages = imgs
                                    viewerStartIndex = idx
                                    showViewer = true
                                },
                                onNeedMore: { Task { await vm.loadMoreGlobal(batchSize: 18) } },
                                onFirstAppear: { Task { await vm.ensureGlobalLoadedOnce() } }
                            )

                            if showSearch {
                                searchField
                                    .id(BrowseScrollAnchor.searchField)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            LazyVStack(spacing: 14) {
                                ForEach(filteredBreeds) { breed in
                                    BreedSectionCard(
                                        breed: breed,
                                        images: vm.imagesByBreed[breed.id] ?? [],
                                        isLoading: vm.loadingBreeds.contains(breed.id),
                                        onSelect: { images, idx in
                                            viewerImages = images
                                            viewerStartIndex = idx
                                            showViewer = true
                                        },
                                        onNeedMore: {
                                            Task { await vm.loadMoreImages(for: breed, batchSize: 20) }
                                        },
                                        onFirstAppear: {
                                            Task { await vm.ensureInitialImages(for: breed) }
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 80)
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                    }
                    .refreshable {
                        await vm.softRefreshVisible(prefixCount: 14)
                        await vm.softRefreshGlobal()
                    }

                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                revealSearch(using: proxy)
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(accent)
                                    .frame(width: 46, height: 46)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .tint(.clear)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        Spacer()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.loadOnce()
                await vm.performLaunchWarmup()
            }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent, favorites: favorites)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CatHub")
                .font(.system(size: 44, weight: .bold))
                .padding(.top, 4)

            Text("Got Cat? We do.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search breeds, origin, temperament", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    softHaptic()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .tint(.clear)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private func revealSearch(using proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showSearch = true
        }
        softHaptic()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(BrowseScrollAnchor.searchField, anchor: .top)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
    }
}

// MARK: - More Cats Tab (Photos-ish Grid)

struct MoreCatsView: View {
    let accent: Color
    @ObservedObject var favorites: FavoritesStore

    @StateObject private var vm = BrowseViewModel()

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false

    // ✅ gate so infinite scroll can’t spam
    @State private var lastLoadTriggerCount: Int = 0

    // Photos “Recents” vibe: tighter spacing than Saved
    private let spacing: CGFloat = 8

    private var columns: [GridItem] {
        // 3-ish columns on iPhone, feels like Photos
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    Text("More Cats")
                        .font(.system(size: 44, weight: .bold))
                        .padding(.top, 8)

                    Text("So.. many... cats.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(Array(vm.globalImages.enumerated()), id: \.element.id) { (idx, img) in
                            CompactGridTile(url: img.url)
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onTapGesture {
                                    viewerImages = vm.globalImages
                                    viewerStartIndex = idx
                                    showViewer = true
                                }
                                .onAppear {
                                    maybeLoadMoreIfNeeded(currentIndex: idx)
                                }
                        }

                        if vm.isLoadingGlobal {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            .refreshable {
                await vm.softRefreshGlobal()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Only needs global feed, but reusing VM is fine.
                await vm.ensureGlobalLoadedOnce()
            }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent, favorites: favorites)
            }
        }
    }

    private func maybeLoadMoreIfNeeded(currentIndex idx: Int) {
        guard !vm.isLoadingGlobal else { return }
        guard !vm.globalImages.isEmpty else { return }

        let triggerIndex = max(vm.globalImages.count - 10, 0)
        guard idx == triggerIndex else { return }

        // ✅ only once per milestone
        guard vm.globalImages.count != lastLoadTriggerCount else { return }
        lastLoadTriggerCount = vm.globalImages.count

        Task { await vm.loadMoreGlobal(batchSize: 24) }
    }
}

private struct CompactGridTile: View {
    let url: URL?

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                CachedRemoteImage(
                    url: url,
                    targetPixelSize: CGSize(width: 800, height: 800)
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
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Multi-API “More Cats” Section (Browse teaser row)

struct MoreCatsSectionCard: View {
    let accent: Color
    let images: [CatImage]
    let isLoading: Bool
    let onSelect: (_ images: [CatImage], _ startIndex: Int) -> Void
    let onNeedMore: () -> Void
    let onFirstAppear: () -> Void

    // ✅ gate so onAppear spam can’t summon infinite cats
    @State private var lastLoadTriggerCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Randomizer")
                        .font(.system(size: 22, weight: .bold))
                    Text("Just Added!")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "camera.aperture")
                    .foregroundStyle(accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if images.isEmpty && isLoading {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 124, height: 92)
                                .overlay(ProgressView().scaleEffect(0.85))
                        }
                    } else {
                        ForEach(Array(images.enumerated()), id: \.element.id) { (idx, img) in
                            CatThumb(url: img.url)
                                .onTapGesture { onSelect(images, idx) }
                                .accessibilityLabel("Open photo \(idx + 1)")
                                .onAppear { maybeTriggerLoadMore(currentIndex: idx) }
                        }

                        if isLoading {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 124, height: 92)
                                .overlay(ProgressView().scaleEffect(0.85))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
        .onAppear { onFirstAppear() }
    }

    private func maybeTriggerLoadMore(currentIndex idx: Int) {
        guard !isLoading else { return }
        guard !images.isEmpty else { return }

        let triggerIndex = max(images.count - 4, 0)
        guard idx == triggerIndex else { return }

        // ✅ only once per milestone
        guard images.count != lastLoadTriggerCount else { return }
        lastLoadTriggerCount = images.count

        onNeedMore()
    }
}

// MARK: - Breed Section Card

struct BreedSectionCard: View {
    let breed: CatBreed
    let images: [CatImage]
    let isLoading: Bool
    let onSelect: (_ images: [CatImage], _ startIndex: Int) -> Void
    let onNeedMore: () -> Void
    let onFirstAppear: () -> Void

    // ✅ gate load-more spam
    @State private var lastLoadTriggerCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(breed.name)
                        .font(.system(size: 22, weight: .bold))
                    if let origin = breed.origin, !origin.isEmpty {
                        Text(origin)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if images.isEmpty && isLoading {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 124, height: 92)
                                .overlay(ProgressView().scaleEffect(0.85))
                        }
                    } else {
                        ForEach(Array(images.enumerated()), id: \.element.id) { (idx, img) in
                            CatThumb(url: img.url)
                                .onTapGesture { onSelect(images, idx) }
                                .accessibilityLabel("Open photo \(idx + 1) for \(breed.name)")
                                .onAppear { maybeTriggerLoadMore(currentIndex: idx) }
                        }

                        if isLoading {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .frame(width: 124, height: 92)
                                .overlay(ProgressView().scaleEffect(0.85))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
        .onAppear { onFirstAppear() }
    }

    private func maybeTriggerLoadMore(currentIndex idx: Int) {
        guard !isLoading else { return }
        guard !images.isEmpty else { return }

        let triggerIndex = max(images.count - 4, 0)
        guard idx == triggerIndex else { return }

        // ✅ only once per milestone
        guard images.count != lastLoadTriggerCount else { return }
        lastLoadTriggerCount = images.count

        onNeedMore()
    }
}

struct CatThumb: View {
    let url: URL?

    var body: some View {
        CachedRemoteImage(url: url, targetPixelSize: CGSize(width: 320, height: 240)) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 124, height: 92)
                    .overlay(ProgressView().scaleEffect(0.85))
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 124, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            case .failure:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 124, height: 92)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    )
            }
        }
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

    private let spacing: CGFloat = 14
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
                                        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                await vm.loadSaved(from: favorites.ids)
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
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)

                CachedRemoteImage(
                    url: url,
                    targetPixelSize: CGSize(width: 900, height: 900)
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
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
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
                    Text("CatHub is a tiny, cozy app designed to bring immediate joy.\n\nThis version of the beta adds a 'More Cats' tab, new colors, and enhanced performance. Enjoy!")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                
                Section("Version") {
                    Text("0.0.4B - Colorful CATastrophies.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Section("Known Issues") {
                    Text("Refreshing the 'More Cats' tab may sometimes not update the images as expected. \n\nSometimes when tapping on a cat image, the image viewer will still display black. \n\nThe Accent 'Rainbow' displays as Purple. \n\nNot all cats have a description.")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Viewer (Image + Flip Info + Zoom)

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
                        if let id = current?.id {
                            favorites.toggle(id)
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
            if let current {
                await loadDetailsIfNeeded(for: current)
            }
        }
        .onChange(of: index) { _ in
            if let current {
                Task { await loadDetailsIfNeeded(for: current) }
            }
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

// MARK: - Flip Card (Front/Back)

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
        .onChange(of: isFlipped) { flipped in
            if flipped { zoomScale = 1.0 }
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

        // ✅ If JSON doesn't include "source" (TheCatAPI doesn't), default to .theCatAPI
        source = (try? c.decode(CatSource.self, forKey: .source)) ?? .theCatAPI
    }
}

// MARK: - Networking (TheCatAPI + CATAAS)

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

    // MARK: Breeds

    func fetchBreeds() async throws -> [CatBreed] {
        let url = base.appendingPathComponent("breeds")
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        applyTheCatAPIKey(&req)

        let data = try await validatedData(for: req)
        return try JSONDecoder().decode([CatBreed].self, from: data)
    }

    // MARK: Breed Images (pagination)

    func fetchImages(
        breedId: String,
        limit: Int = 20,
        page: Int = 0,
        order: String = "DESC"
    ) async throws -> [CatImage] {
        var comps = URLComponents(url: base.appendingPathComponent("images/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "breed_ids", value: breedId),
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

    // MARK: Global Images (no breed filter)

    func fetchGlobalImages(limit: Int = 20, page: Int = 0, order: String = "DESC") async throws -> [CatImage] {
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

    // MARK: Image Details (TheCatAPI)

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

    // MARK: CATAAS (random cats)

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
        guard let imageURL = URL(string: decoded.url) else { return nil }

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

// MARK: - Browse VM

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var imagesByBreed: [String: [CatImage]] = [:]
    @Published var loadingBreeds: Set<String> = []

    // ✅ multi-source global feed
    @Published var globalImages: [CatImage] = []
    @Published var isLoadingGlobal: Bool = false

    private let api = CatAPIClient()
    private var didLoad = false
    private var loadedBreedIds: Set<String> = []
    private var isLoadingMore: Set<String> = []
    private var didPerformLaunchWarmup = false

    // ✅ pagination state per breed
    private var nextPageByBreed: [String: Int] = [:]
    private let maxImagesKeptPerBreed = 70

    // ✅ global pagination state
    private var globalPage: Int = 0
    private let maxGlobalKept = 180
    private var didLoadGlobalOnce = false

    func loadOnce() async {
        guard !didLoad else { return }
        didLoad = true
        do {
            breeds = try await api.fetchBreeds()
        } catch {
            print("Browse load error:", error)
        }
    }

    func performLaunchWarmup() async {
        guard !didPerformLaunchWarmup else { return }
        didPerformLaunchWarmup = true
        guard !breeds.isEmpty else { return }

        let initialBreeds = Array(breeds.prefix(18))
        for breed in initialBreeds {
            await ensureInitialImages(for: breed)
        }

        await ensureGlobalLoadedOnce()

        let delays: [UInt64] = [500_000_000, 1_000_000_000]
        for delay in delays {
            try? await Task.sleep(nanoseconds: delay)
            for breed in initialBreeds {
                if (imagesByBreed[breed.id]?.isEmpty ?? true) {
                    await loadMoreImages(for: breed, batchSize: 20)
                } else {
                    await refreshImages(for: breed)
                }
            }
        }
    }

    func ensureInitialImages(for breed: CatBreed) async {
        guard !loadedBreedIds.contains(breed.id) else { return }
        loadedBreedIds.insert(breed.id)

        nextPageByBreed[breed.id] = 0
        await loadMoreImages(for: breed, batchSize: 20)
    }

    func refreshImages(for breed: CatBreed) async {
        loadingBreeds.insert(breed.id)
        defer { loadingBreeds.remove(breed.id) }

        do {
            nextPageByBreed[breed.id] = 0

            let imgs = try await api.fetchImages(
                breedId: breed.id,
                limit: 20,
                page: 0,
                order: "DESC"
            )

            imagesByBreed[breed.id] = imgs.uniquedById()
        } catch {
            print("Refresh error:", error)
        }
    }

    func loadMoreImages(for breed: CatBreed, batchSize: Int = 20) async {
        guard !isLoadingMore.contains(breed.id) else { return }
        isLoadingMore.insert(breed.id)
        loadingBreeds.insert(breed.id)
        defer {
            isLoadingMore.remove(breed.id)
            loadingBreeds.remove(breed.id)
        }

        let page = nextPageByBreed[breed.id, default: 0]

        do {
            let newOnes = try await api.fetchImages(
                breedId: breed.id,
                limit: batchSize,
                page: page,
                order: "DESC"
            )

            if !newOnes.isEmpty {
                nextPageByBreed[breed.id] = page + 1
            }

            var existing = imagesByBreed[breed.id] ?? []
            existing.append(contentsOf: newOnes)
            existing = existing.uniquedById()

            if existing.count > maxImagesKeptPerBreed {
                existing = Array(existing.suffix(maxImagesKeptPerBreed))
            }

            imagesByBreed[breed.id] = existing
        } catch {
            print("Load more error:", error)
        }
    }

    func softRefreshVisible(prefixCount: Int) async {
        let slice = Array(breeds.prefix(prefixCount))
        for b in slice {
            if (imagesByBreed[b.id]?.isEmpty ?? true) == false {
                await refreshImages(for: b)
            }
        }
    }

    // MARK: Global (multi-source)

    func ensureGlobalLoadedOnce() async {
        guard !didLoadGlobalOnce else { return }
        didLoadGlobalOnce = true
        await loadMoreGlobal(batchSize: 24)
    }

    func softRefreshGlobal() async {
        globalPage = 0
        globalImages = []
        await loadMoreGlobal(batchSize: 24)
    }

    func loadMoreGlobal(batchSize: Int = 24) async {
        guard !isLoadingGlobal else { return }
        isLoadingGlobal = true
        defer { isLoadingGlobal = false }

        do {
            let catApiCount = max(batchSize - 6, 12)
            let cataasCount = max(batchSize - catApiCount, 4)

            async let a = api.fetchGlobalImages(limit: catApiCount, page: globalPage, order: "DESC")
            async let b = api.fetchCataasRandomBatch(cataasCount)

            var combined = try await (a + b)
            combined = combined.uniquedById()

            if !combined.isEmpty {
                globalPage += 1
            }

            globalImages.append(contentsOf: combined)
            globalImages = globalImages.uniquedById()

            if globalImages.count > maxGlobalKept {
                globalImages = Array(globalImages.suffix(maxGlobalKept))
            }
        } catch {
            print("Global load error:", error)
        }
    }
}

// MARK: - Favorites Store

final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: [String] = []
    private let key = "CatHub.favorites"

    init() {
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            ids = data
        }
    }

    func isFavorite(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if let idx = ids.firstIndex(of: id) {
            ids.remove(at: idx)
        } else {
            if !ids.contains(id) { ids.append(id) }
        }
        UserDefaults.standard.set(ids, forKey: key)
    }
}

// MARK: - Saved VM

@MainActor
final class SavedViewModel: ObservableObject {
    @Published var savedImages: [CatImage] = []
    private let api = CatAPIClient()

    func loadSaved(from ids: [String]) async {
        if ids.isEmpty {
            savedImages = []
            return
        }

        let theCatAPIIds = ids.filter { !$0.hasPrefix("cataas_") }

        do {
            let hydrated = try await api.fetchImagesByIdsConcurrent(theCatAPIIds)

            let stubs: [CatImage] = ids
                .filter { $0.hasPrefix("cataas_") }
                .map { CatImage(id: $0, url: nil, breeds: nil, source: .cataas) }

            savedImages = (hydrated + stubs)
        } catch {
            print("Saved load error:", error)
        }
    }
}

// MARK: - Share Sheet (cross-platform)

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

// MARK: - Cached Image System (cross-platform, off-main)

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
        if currentURL == url, case .success = phase {
            return
        }

        task?.cancel()
        Task { @MainActor in phase = .empty }

        guard let url else {
            Task { @MainActor in phase = .failure }
            return
        }

        currentURL = url
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
            .onAppear { loader.load(url: url, targetPixelSize: targetPixelSize) }
            .onChange(of: url) { loader.load(url: url, targetPixelSize: targetPixelSize) }
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
