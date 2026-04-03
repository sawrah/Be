import Foundation
import CoreGraphics

struct GardenTile: Identifiable {
    let id: Int
    let row: Int
    let col: Int
    let origin: CGPoint
    let topCenter: CGPoint
    var hasFlower: Bool
    var flowerPlantedDate: Date?
}

let tileWidth: CGFloat = 56.754
let tileHeight: CGFloat = 77.709
let topFaceHeight: CGFloat = 48.75
let svgSourceWidth: CGFloat = 65
let tileScale: CGFloat = 56.754 / 65

func buildTiles(layout: [RowLayout]) -> [GardenTile] {
    var tiles: [GardenTile] = []
    var index = 0
    let topFaceH = topFaceHeight * tileScale

    for (rowIndex, row) in layout.enumerated() {
        for col in 0..<row.count {
            let origin = CGPoint(
                x: row.x + CGFloat(col) * tileWidth,
                y: rowY[rowIndex]
            )
            let topCenter = CGPoint(
                x: origin.x + tileWidth / 2,
                y: origin.y + topFaceH / 2
            )
            tiles.append(GardenTile(
                id: index, row: rowIndex, col: col,
                origin: origin, topCenter: topCenter,
                hasFlower: false
            ))
            index += 1
        }
    }
    return tiles
}

func tileForTap(at point: CGPoint, in tiles: [GardenTile]) -> GardenTile? {
    let maxRadius = tileWidth / 2
    return tiles
        .filter { !$0.hasFlower }
        .filter { hypot($0.topCenter.x - point.x, $0.topCenter.y - point.y) < maxRadius }
        .min(by: {
            hypot($0.topCenter.x - point.x, $0.topCenter.y - point.y) <
            hypot($1.topCenter.x - point.x, $1.topCenter.y - point.y)
        })
}
