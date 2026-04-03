import SwiftUI

struct GardenView: View {
    let month: Int
    let year: Int
    @Binding var isPlantingMode: Bool
    var onTilePlanted: ((Int) -> Void)?

    @State private var tiles: [GardenTile] = []
    @State private var plantedIds: Set<Int> = []

    private var theme: TileTheme { TileTheme.forMonth(month) }

    private var daysInMonth: Int {
        let comps = DateComponents(year: year, month: month)
        let cal = Calendar.current
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    // Total garden size for the Canvas
    private var gardenWidth: CGFloat {
        // max row width = 6 tiles at x=0
        6 * tileWidth
    }

    private var gardenHeight: CGFloat {
        rowY.last! + tileHeight * tileScale + 10
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Draw tiles row by row (painter's order)
            ForEach(tiles) { tile in
                IsometricTileView(theme: theme, origin: tile.origin)
            }

            // Flowers
            ForEach(tiles.filter { plantedIds.contains($0.id) }) { tile in
                FlowerView()
                    .position(tile.topCenter)
                    .transition(.scale)
            }

            // Tap overlay when planting
            if isPlantingMode {
                Color.white.opacity(0.001) // invisible tap target
                    .frame(width: gardenWidth, height: gardenHeight)
                    .onTapGesture { location in
                        handleTap(at: location)
                    }
            }
        }
        .frame(width: gardenWidth, height: gardenHeight)
        .overlay {
            if isPlantingMode {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color("BrandGreen").opacity(0.6), lineWidth: 2)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPlantingMode)
            }
        }
        .onAppear { reload() }
        .onChange(of: month) { _ in reload() }
        .onChange(of: year) { _ in reload() }
    }

    private func reload() {
        let layout = gardenLayout(for: daysInMonth)
        tiles = buildTiles(layout: layout)
        plantedIds = GardenPersistence.plantedTileIds(month: month, year: year)
    }

    private func handleTap(at point: CGPoint) {
        // Build a temporary version of tiles with current planted state
        var currentTiles = tiles
        for i in currentTiles.indices {
            currentTiles[i].hasFlower = plantedIds.contains(currentTiles[i].id)
        }

        guard let target = tileForTap(at: point, in: currentTiles) else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            plantedIds.insert(target.id)
        }
        GardenPersistence.save(tileId: target.id, month: month, year: year)
        onTilePlanted?(target.id)
        isPlantingMode = false
    }
}

// MARK: - Flower drawn in SwiftUI

struct FlowerView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Stem
            Capsule()
                .fill(Color(hex: "5C8A6A"))
                .frame(width: 2, height: 14)
                .offset(y: 8)

            // Petals
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(Color("BrandPurple"))
                    .frame(width: 8, height: 12)
                    .offset(y: -6)
                    .rotationEffect(.degrees(Double(i) * 72))
            }

            // Center
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: 6, height: 6)
        }
        .scaleEffect(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}
