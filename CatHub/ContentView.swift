//  ContentView.swift
//  CatHub
//
//  Created by Zero on 2026-01-29.
//

import SwiftUI
import UIKit

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
    case purple
    case blue
    case pink
    case green
    case orange
    case graphite

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

// MARK: - ContentView Root (NO TabView)

struct ContentView: View {
    @State private var tab: CatHubTab = .browse

    @AppStorage("CatHub.tint") private var tintRaw: String = CatHubTintChoice.purple.rawValue
    private var tint: CatHubTintChoice { CatHubTintChoice(rawValue: tintRaw) ?? .purple }

    var body: some View {
        ZStack {
            // Manual screen switching (no native tab bar exists anymore)
            switch tab {
            case .browse:
                BrowseView(accent: tint.color)
            case .saved:
                SavedView(accent: tint.color)
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

// MARK: - Bottom Button -> iOS Native Menu

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
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
// MARK: - Glass Controls (neutral material + tinted glyph)

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
                                    onSelect: { images, idx in
                                        viewerImages = images
                                        viewerStartIndex = idx
                                        showViewer = true
                                    },
                                    onRefresh: {
                                        Task { await vm.refreshImages(for: breed) }
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 80)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 16)
                }

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showSearch.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
            .task { await vm.load() }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CatHub")
                .font(.system(size: 44, weight: .bold))
                .padding(.top, 4)

            Text("Just… cats. Right now. 🐾")
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
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
    let onSelect: (_ images: [CatImage], _ startIndex: Int) -> Void
    let onRefresh: () -> Void

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

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .tint(.clear)
                .accessibilityLabel("Refresh photos for \(breed.name)")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { (idx, img) in
                        CatThumb(url: img.url)
                            .onTapGesture { onSelect(images, idx) }
                            .accessibilityLabel("Open photo \(idx + 1) for \(breed.name)")
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

struct CatThumb: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
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
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Saved

struct SavedView: View {
    let accent: Color
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var vm = SavedViewModel()

    @State private var viewerImages: [CatImage] = []
    @State private var viewerStartIndex: Int = 0
    @State private var showViewer = false

    var body: some View {
        NavigationStack {
            ZStack {
                if favorites.ids.isEmpty {
                    VStack(spacing: 10) {
                        Text("Saved")
                            .font(.system(size: 44, weight: .bold))
                        Text("You haven’t favorited any cats yet.\nGo tap hearts like a menace. 😼")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 22)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, 60)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Saved")
                                .font(.system(size: 44, weight: .bold))
                                .padding(.top, 8)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(vm.savedImages, id: \.id) { img in
                                    AsyncImage(url: img.url) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .frame(height: 170)
                                                .overlay(ProgressView())
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 170)
                                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .frame(height: 170)
                                                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .onTapGesture {
                                        viewerImages = vm.savedImages
                                        if let idx = vm.savedImages.firstIndex(where: { $0.id == img.id }) {
                                            viewerStartIndex = idx
                                        } else {
                                            viewerStartIndex = 0
                                        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await vm.loadSaved(from: favorites.ids) }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                    .tint(.clear)
                }
            }
            .task { await vm.loadSaved(from: favorites.ids) }
            .onChange(of: favorites.ids) { newValue in
                Task { await vm.loadSaved(from: newValue) }
            }
            .fullScreenCover(isPresented: $showViewer) {
                CatViewer(images: viewerImages, startIndex: viewerStartIndex, accent: accent)
            }
        }
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
                    Text("CatHub is a tiny, cozy SwiftUI cat browser.\n\nComing later: ‘Catorithm’ personalization, vibe descriptions, and more chaos.")
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

    @State private var index: Int
    @State private var showShare = false
    @State private var isFlipped = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var favorites = FavoritesStore()

    init(images: [CatImage], startIndex: Int, accent: Color) {
        self.images = images
        self.startIndex = startIndex
        self.accent = accent
        _index = State(initialValue: startIndex)
    }

    private var current: CatImage? {
        guard !images.isEmpty else { return nil }
        return images[max(0, min(index, images.count - 1))]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(images.indices, id: \.self) { i in
                    FlippableCatCard(
                        image: images[i],
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
                        if current != nil { showShare = true }
                    }
                    .disabled(current == nil)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        if let c = current { favorites.toggle(c.id) }
                    } label: {
                        Image(systemName: (current != nil && favorites.isFavorite(current!.id)) ? "heart.fill" : "heart")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle((current != nil && favorites.isFavorite(current!.id)) ? Color.red : Color.primary)
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
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
        .sheet(isPresented: $showShare) {
            if let url = current?.url {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium])
            }
        }
    }
}

struct FlippableCatCard: View {
    let image: CatImage
    @Binding var isFlipped: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isFlipped {
                CatInfoBackCard(image: image)
                    .transition(.opacity)
            } else {
                CatZoomFrontCard(image: image, scale: $scale, lastScale: $lastScale)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isFlipped)
    }
}

struct CatZoomFrontCard: View {
    let image: CatImage
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            ZStack(alignment: .topTrailing) {
                AsyncImage(url: image.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = (scale * delta).clamped(to: 1.0...4.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    scale = (scale > 1.01) ? 1.0 : 2.0
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                }
                            }
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                if scale <= 1.01 {
                    Text("Pinch to zoom")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
                        .padding(.top, 64)
                        .padding(.trailing, 20)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

struct CatInfoBackCard: View {
    let image: CatImage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(image.breedName ?? "Unknown Breed")
                    .font(.system(size: 28, weight: .bold))

                if let origin = image.origin, !origin.isEmpty {
                    Text("Origin: \(origin)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                if let temperament = image.temperament, !temperament.isEmpty {
                    Text(temperament)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Divider().opacity(0.2)

                Text(image.description ?? "No description yet.")
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .padding(.top, 6)

                Text("✨ (Future) Apple Intelligence vibe description goes here.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.top, 14)

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

// MARK: - Networking + Models

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

final class CatAPIClient {
    private let base = URL(string: "https://api.thecatapi.com/v1")!
    private let session = URLSession.shared

    func fetchBreeds() async throws -> [CatBreed] {
        let url = base.appendingPathComponent("breeds")
        var req = URLRequest(url: url)
        req.timeoutInterval = 25

        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode([CatBreed].self, from: data)
    }

    func fetchImages(breedId: String, limit: Int = 5) async throws -> [CatImage] {
        var comps = URLComponents(url: base.appendingPathComponent("images/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "breed_ids", value: breedId),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "size", value: "small")
        ]
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 25

        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode([CatImage].self, from: data)
    }

    func fetchImagesByIds(_ ids: [String]) async throws -> [CatImage] {
        var results: [CatImage] = []
        for id in ids {
            if let img = try await fetchImageById(id) {
                results.append(img)
            }
        }
        return results
    }

    func fetchImageById(_ id: String) async throws -> CatImage? {
        let url = base.appendingPathComponent("images/\(id)")
        var req = URLRequest(url: url)
        req.timeoutInterval = 25
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(CatImage.self, from: data)
    }
}

// MARK: - Browse VM

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var imagesByBreed: [String: [CatImage]] = [:]

    private let api = CatAPIClient()

    func load() async {
        do {
            let b = try await api.fetchBreeds()
            breeds = b

            for breed in b.prefix(12) {
                let imgs = try await api.fetchImages(breedId: breed.id, limit: 5)
                imagesByBreed[breed.id] = imgs
            }
        } catch {
            print("Browse load error:", error)
        }
    }

    func refreshImages(for breed: CatBreed) async {
        do {
            let imgs = try await api.fetchImages(breedId: breed.id, limit: 5)
            imagesByBreed[breed.id] = imgs
        } catch {
            print("Refresh error:", error)
        }
    }
}

// MARK: - Favorites Store

final class FavoritesStore: ObservableObject {
    @Published var ids: [String] = []

    private let key = "CatHub.favorites"

    init() {
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            ids = data
        }
    }

    func isFavorite(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        if let idx = ids.firstIndex(of: id) {
            ids.remove(at: idx)
        } else {
            ids.append(id)
        }
        UserDefaults.standard.set(ids, forKey: key)
        objectWillChange.send()
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
            let images = try await api.fetchImagesByIds(ids)
            savedImages = images
        } catch {
            print("Saved load error:", error)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Helpers

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
