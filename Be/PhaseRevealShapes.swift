import SwiftUI

struct InhaleRevealShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let reach = rect.width / 2 * progress
        // left side sweeping right
        p.addRect(CGRect(x: 0, y: 0, width: reach, height: rect.height))
        // right side sweeping left
        p.addRect(CGRect(x: rect.width - reach, y: 0, width: reach, height: rect.height))
        return p
    }
}

struct ExhaleRevealShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let reach = rect.width / 2 * progress
        p.addRect(CGRect(x: rect.midX - reach, y: 0, width: reach * 2, height: rect.height))
        return p
    }
}
