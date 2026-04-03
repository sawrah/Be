import SwiftUI

enum TileStyle {
    case zigzag, wave
}

struct TileTheme {
    let top: Color
    let divider: Color
    let topLeft: Color
    let topRight: Color
    let bottomLeft: Color
    let bottomRight: Color
    let style: TileStyle
}

extension TileTheme {
    static let spring = TileTheme(
        top:         Color(hex: "C8E8C0"),
        divider:     Color(hex: "E2FFDB"),
        topLeft:     Color(hex: "7BA888"),
        topRight:    Color(hex: "5C8A6A"),
        bottomLeft:  Color(hex: "C0A882"),
        bottomRight: Color(hex: "A08A68"),
        style:       .zigzag
    )
    static let summer = TileTheme(
        top:         Color(hex: "8DC490"),
        divider:     Color(hex: "E2FFDB"),
        topLeft:     Color(hex: "4A7A58"),
        topRight:    Color(hex: "345840"),
        bottomLeft:  Color(hex: "8B6848"),
        bottomRight: Color(hex: "6A5038"),
        style:       .zigzag
    )
    static let autumn = TileTheme(
        top:         Color(hex: "E59178"),
        divider:     Color(hex: "FFDDD3"),
        topLeft:     Color(hex: "CC785E"),
        topRight:    Color(hex: "B25F45"),
        bottomLeft:  Color(hex: "7A5838"),
        bottomRight: Color(hex: "5C4028"),
        style:       .zigzag
    )
    static let winter = TileTheme(
        top:         Color(hex: "F4F4F8"),
        divider:     Color(hex: "F5FDFF"),
        topLeft:     Color(hex: "D8D8E0"),
        topRight:    Color(hex: "B8B8C4"),
        bottomLeft:  Color(hex: "909098"),
        bottomRight: Color(hex: "6C6C78"),
        style:       .wave
    )

    static func forMonth(_ month: Int) -> TileTheme {
        switch month {
        case 3, 4, 5:   return .spring
        case 6, 7, 8:   return .summer
        case 9, 10, 11: return .autumn
        default:         return .winter
        }
    }
}
