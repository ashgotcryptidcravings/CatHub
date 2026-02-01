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

// MARK: - App State

enum CatHubTab: String, CaseIterable, Identifiable {
    case browse
    case saved
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browse: return "Browse"
        case .saved: return "Saved"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .browse: return "pawprint.fill"
        case .saved: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum CatHubTintChoice: String, CaseIterable, Identifiable {
    case purple, blue, pink, green, orange, graphite

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .pink: return .pink
        case .green: return .green
        case .orange: return .orange
        case .graphite: return Color(white: 0.65)
        }
    }

    var symbol: String {
        switch self {
        case .purple: return "sparkle"
        case .blue: return "drop.fill"
        case .pink: return "heart.fill"
        case .green: return "leaf.fill"
        case .orange: return "sun.max.fill"
        case .graphite: return "circle.lefthalf.filled"
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

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false

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
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header

                        if showSearch {
                            searchField
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
                                        Task { await vm.loadMoreImages(for: breed) }
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
                    await vm.softRefreshVisible(prefixCount: 8)
                }

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showSearch.toggle()
                            }
                            softHaptic()
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadOnce() }
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

            Text("Got Cat? 🐾")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search breeds, origin, temperament…", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

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
}

// MARK: - Breed Section Card

struct BreedSectionCard: View {
    let breed: CatBreed
    let images: [CatImage]
    let isLoading: Bool
    let onSelect: (_ images: [CatImage], _ startIndex: Int) -> Void
    let onNeedMore: () -> Void
    let onFirstAppear: () -> Void

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
                        ForEach(0..<5, id: \.self) { _ in
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
                                .onAppear {
                                    // ✅ trigger exactly at threshold to avoid spam
                                    let triggerIndex = max(images.count - 3, 0)
                                    if idx == triggerIndex {
                                        onNeedMore()
                                    }
                                }
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
            GridItem(.flexible(minimum: 160), spacing: spacing),
            GridItem(.flexible(minimum: 160), spacing: spacing)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if favorites.ids.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        GeometryReader { proxy in
                            let availableWidth = proxy.size.width - spacing
                            let tileSize = max(140, availableWidth / 2)

                            VStack(alignment: .leading, spacing: spacing) {
                                Text("Saved")
                                    .font(.system(size: 44, weight: .bold))
                                    .padding(.top, 8)

                                LazyVGrid(columns: columns, spacing: spacing) {
                                    ForEach(vm.savedImages, id: \.id) { img in
                                        SavedTile(url: img.url, size: tileSize)
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
                            .frame(width: proxy.size.width, alignment: .topLeading)
                        }
                        .frame(minHeight: 0)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ runs on appear and whenever favorites.ids changes
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
            Text("You haven’t favorited any cats yet.\nGo collect some kitties!")
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
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)

            CachedRemoteImage(url: url, targetPixelSize: CGSize(width: 900, height: 900)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
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

                Section("About") {
                    Text("CatHub is a tiny, cozy app designed to bring immediate joy.\n\nThis version of the beta fixes issues like Zoom Function, Performance deficits, and some minor UI tweaks. Enjoy!")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
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
                        Label("Info", systemImage: "info.circle")
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

struct FlippableCatCard: View {
    let image: CatImage
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            if isFlipped {
                CatInfoBackCard(image: image)
                    .transition(.opacity)
            } else {
                CatZoomFrontCard(image: image)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isFlipped)
    }
}

struct CatZoomFrontCard: View {
    let image: CatImage
    @State private var zoomScale: CGFloat = 1.0

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            ZStack(alignment: .topTrailing) {
                CachedRemoteImage(
                    url: image.url,
                    targetPixelSize: CGSize(width: 1800, height: 1800)
                ) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                    case .success(let img):
                        #if canImport(UIKit)
                        ZoomableImageContainer(zoomScale: $zoomScale) {
                            img.resizable().scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        #else
                        // macOS: show image without UIScrollView zoom
                        img.resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                #if canImport(UIKit)
                if zoomScale <= 1.01 {
                    Text("Pinch to zoom")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
                        .padding(.top, 64)
                        .padding(.trailing, 20)
                        .transition(.opacity)
                }
                #endif
            }

            Spacer(minLength: 0)
        }
    }
}

#if canImport(UIKit)
private struct ZoomableImageContainer<Content: View>: UIViewRepresentable {
    @Binding var zoomScale: CGFloat
    let content: Content

    init(zoomScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._zoomScale = zoomScale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 4.0
        scroll.bouncesZoom = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        scroll.clipsToBounds = false

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),

            host.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            host.view.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])

        context.coordinator.hostingController = host

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        private var zoomScaleBinding: Binding<CGFloat>

        init(zoomScale: Binding<CGFloat>) {
            self.zoomScaleBinding = zoomScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScaleBinding.wrappedValue = scrollView.zoomScale
        }

        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = gr.view as? UIScrollView else { return }
            let target: CGFloat = (scroll.zoomScale > 1.01) ? 1.0 : 2.0
            scroll.setZoomScale(target, animated: true)
            softHaptic()
        }
    }
}
#endif

struct CatInfoBackCard: View {
    let image: CatImage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(image.breedName ?? "Cat did not feel comfortable with sharing breed info.")
                    .font(.system(size: 28, weight: .bold))

                Group {
                    if let origin = image.origin, !origin.isEmpty {
                        Text("Origin: \(origin)")
                    }

                    if let temperament = image.temperament, !temperament.isEmpty {
                        Text(temperament)
                            .padding(.top, 2)
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
                    Text("Description was pushed off the table.")
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
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 18)
            .padding(.top, 90)
            .padding(.bottom, 90)
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

struct CatImage: Identifiable, Codable, Hashable {
    let id: String
    let url: URL?
    let breeds: [CatBreed]?

    var breedName: String? { breeds?.first?.name }
    var origin: String? { breeds?.first?.origin }
    var temperament: String? { breeds?.first?.temperament }
    var description: String? { breeds?.first?.description }
}

// MARK: - Networking

final class CatAPIClient {
    private let base = URL(string: "https://api.thecatapi.com/v1")!
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.urlCache = URLCache(memoryCapacity: 40 * 1024 * 1024,
                                diskCapacity: 200 * 1024 * 1024,
                                diskPath: "CatHubURLCache")
        self.session = URLSession(configuration: cfg)
    }

    func fetchBreeds() async throws -> [CatBreed] {
        let url = base.appendingPathComponent("breeds")
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode([CatBreed].self, from: data)
    }

    func fetchImages(breedId: String, limit: Int = 10) async throws -> [CatImage] {
        var comps = URLComponents(url: base.appendingPathComponent("images/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "breed_ids", value: breedId),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "size", value: "small"),
            URLQueryItem(name: "include_breeds", value: "1")
        ]
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 25
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode([CatImage].self, from: data)
    }

    func fetchImageById(_ id: String) async throws -> CatImage? {
        var comps = URLComponents(url: base.appendingPathComponent("images/\(id)"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "include_breeds", value: "1")
        ]
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 25
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(CatImage.self, from: data)
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
}

// MARK: - Browse VM

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var imagesByBreed: [String: [CatImage]] = [:]
    @Published var loadingBreeds: Set<String> = []

    private let api = CatAPIClient()
    private var didLoad = false
    private var loadedBreedIds: Set<String> = []
    private var isLoadingMore: Set<String> = []

    func loadOnce() async {
        guard !didLoad else { return }
        didLoad = true
        do {
            breeds = try await api.fetchBreeds()
        } catch {
            print("Browse load error:", error)
        }
    }

    func ensureInitialImages(for breed: CatBreed) async {
        guard !loadedBreedIds.contains(breed.id) else { return }
        loadedBreedIds.insert(breed.id)
        await loadMoreImages(for: breed, batchSize: 8)
    }

    func refreshImages(for breed: CatBreed) async {
        loadingBreeds.insert(breed.id)
        defer { loadingBreeds.remove(breed.id) }
        do {
            let imgs = try await api.fetchImages(breedId: breed.id, limit: 10)
            imagesByBreed[breed.id] = imgs.uniquedById()
        } catch {
            print("Refresh error:", error)
        }
    }

    func loadMoreImages(for breed: CatBreed, batchSize: Int = 6) async {
        guard !isLoadingMore.contains(breed.id) else { return }
        isLoadingMore.insert(breed.id)
        loadingBreeds.insert(breed.id)
        defer {
            isLoadingMore.remove(breed.id)
            loadingBreeds.remove(breed.id)
        }

        do {
            let newOnes = try await api.fetchImages(breedId: breed.id, limit: batchSize)
            var existing = imagesByBreed[breed.id] ?? []
            existing.append(contentsOf: newOnes)
            imagesByBreed[breed.id] = existing.uniquedById()
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
        do {
            savedImages = try await api.fetchImagesByIdsConcurrent(ids)
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

    func load(url: URL?, targetPixelSize: CGSize) {
        task?.cancel()
        Task { @MainActor in phase = .empty }

        guard let url else {
            Task { @MainActor in phase = .failure }
            return
        }

        task = Task.detached(priority: .utility) { [cache] in
            if Task.isCancelled { return }

            if let cached = cache.image(for: url) {
                let swiftUIImage = Self.toSwiftUIImage(cached)
                await MainActor.run { self.phase = .success(swiftUIImage) }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if Task.isCancelled { return }

                if let img = Self.downsample(data: data, to: targetPixelSize) ?? CatImageCache.decode(data: data) {
                    cache.store(img, for: url)
                    let swiftUIImage = Self.toSwiftUIImage(img)
                    await MainActor.run { self.phase = .success(swiftUIImage) }
                } else {
                    await MainActor.run { self.phase = .failure }
                }
            } catch {
                if Task.isCancelled { return }
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
