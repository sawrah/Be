import CoreGraphics

struct RowLayout {
    let count: Int
    let x: CGFloat
}

let rowY: [CGFloat] = [0, 61.38, 106.55, 170.70, 215.52, 279.15, 324.29]

let layout28: [RowLayout] = [
    RowLayout(count: 2, x: 85.71),
    RowLayout(count: 4, x: 56.75),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 6, x: 0),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 4, x: 56.02),
    RowLayout(count: 2, x: 84.55 + 56.754),
]

let layout29: [RowLayout] = [
    RowLayout(count: 3, x: 85.71),
    RowLayout(count: 4, x: 56.75),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 6, x: 0),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 4, x: 56.02),
    RowLayout(count: 2, x: 84.55),
]

let layout30: [RowLayout] = [
    RowLayout(count: 3, x: 85.71),
    RowLayout(count: 4, x: 56.75),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 6, x: 0),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 4, x: 56.02),
    RowLayout(count: 3, x: 84.55),
]

let layout31: [RowLayout] = [
    RowLayout(count: 3, x: 85.71),
    RowLayout(count: 4, x: 56.75),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 6, x: 0),
    RowLayout(count: 5, x: 27.80),
    RowLayout(count: 4, x: 56.02),
    RowLayout(count: 4, x: 84.55),
]

func gardenLayout(for daysInMonth: Int) -> [RowLayout] {
    switch daysInMonth {
    case 28: return layout28
    case 29: return layout29
    case 31: return layout31
    default: return layout30
    }
}
