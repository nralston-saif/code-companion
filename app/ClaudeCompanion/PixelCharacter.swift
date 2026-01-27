import SwiftUI

struct PixelCharacter: View {
    let state: CompanionState
    let frame: Int
    let isHovering: Bool

    private let bodyColor = Color(red: 0.92, green: 0.75, blue: 0.70)
    private let eyeColor = Color.black
    private let feetColor = Color(red: 0.88, green: 0.68, blue: 0.63)
    private let pixelSize: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let bounceOffset = calculateBounce()
            let squishX = calculateSquishX()
            let squishY = calculateSquishY()

            drawBody(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY)
            drawFeet(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX)
            drawEyes(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY)
        }
        .frame(width: 60, height: 60)
    }

    private func calculateBounce() -> CGFloat {
        switch state {
        case .attention: return sin(Double(frame) * 0.5) * 3
        case .success: return -abs(sin(Double(frame) * 0.4) * 4)
        case .hovering, .curious: return sin(Double(frame) * 0.2) * 1
        default: return 0
        }
    }

    private func calculateSquishX() -> CGFloat {
        state == .clicked ? 1.1 : 1.0
    }

    private func calculateSquishY() -> CGFloat {
        state == .clicked ? 0.9 : 1.0
    }

    private func drawBody(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat, squishY: CGFloat) {
        let bodyWidth: CGFloat = 10 * pixelSize * squishX
        let bodyHeight: CGFloat = 7 * pixelSize * squishY
        let startX = centerX - bodyWidth / 2
        let startY = centerY - bodyHeight / 2 - 2

        let bodyPixels: [(Int, Int)] = [
            (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0),
            (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1),
            (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2),
            (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3),
            (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4),
            (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5),
            (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6),
        ]

        for (px, py) in bodyPixels {
            let x = startX + CGFloat(px) * pixelSize * squishX
            let y = startY + CGFloat(py) * pixelSize * squishY
            let rect = CGRect(x: x, y: y, width: pixelSize * squishX, height: pixelSize * squishY)
            context.fill(Path(rect), with: .color(bodyColor))
        }
    }

    private func drawFeet(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat) {
        let feetY = centerY + 12
        let footSize = CGSize(width: pixelSize * 1.5, height: pixelSize * 2)

        context.fill(
            Path(CGRect(origin: CGPoint(x: centerX - 10 * squishX, y: feetY), size: footSize)),
            with: .color(feetColor)
        )
        context.fill(
            Path(CGRect(origin: CGPoint(x: centerX + 6 * squishX, y: feetY), size: footSize)),
            with: .color(feetColor)
        )
    }

    private func drawEyes(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat, squishY: CGFloat) {
        let eyeY = centerY - 2 * squishY
        let leftEyeX = centerX - 8 * squishX
        let rightEyeX = centerX + 4 * squishX

        let drawBothEyes: (EyeStyle, CGFloat, CGFloat) -> Void = { style, leftX, rightX in
            self.drawEye(context: context, style: style, x: leftX, y: eyeY)
            self.drawEye(context: context, style: style, x: rightX, y: eyeY)
        }

        switch state {
        case .sleeping:
            drawBothEyes(.closed, leftEyeX, rightEyeX)

        case .idle:
            let style: EyeStyle = (frame % 120) < 5 ? .closed : .normal
            drawBothEyes(style, leftEyeX, rightEyeX)

        case .thinking:
            drawBothEyes(.thinking, leftEyeX, rightEyeX)

        case .working:
            drawBothEyes(.focused, leftEyeX, rightEyeX)

        case .attention:
            drawBothEyes(.wide, leftEyeX, rightEyeX)

        case .success, .clicked, .waving:
            drawBothEyes(.happy, leftEyeX, rightEyeX)

        case .error:
            drawBothEyes(.worried, leftEyeX, rightEyeX)

        case .hovering, .curious:
            let lookOffset: CGFloat = isHovering ? 1 : 0
            drawBothEyes(.curious, leftEyeX + lookOffset, rightEyeX + lookOffset)

        case .listening:
            drawBothEyes(.attentive, leftEyeX, rightEyeX)
        }
    }

    private enum EyeStyle {
        case normal, closed, thinking, focused, wide, happy, worried, curious, attentive
    }

    private func drawEye(context: GraphicsContext, style: EyeStyle, x: CGFloat, y: CGFloat) {
        switch style {
        case .normal:
            let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
            context.fill(Path(rect), with: .color(eyeColor))

        case .closed:
            let rect = CGRect(x: x, y: y + pixelSize * 0.5, width: pixelSize * 2, height: pixelSize * 0.8)
            context.fill(Path(rect), with: .color(eyeColor))

        case .thinking:
            let rect = CGRect(x: x + pixelSize * 0.3, y: y - pixelSize * 0.5 - 1, width: pixelSize * 1.5, height: pixelSize * 1.5)
            context.fill(Path(rect), with: .color(eyeColor))

        case .focused:
            let rect = CGRect(x: x, y: y + pixelSize * 0.3, width: pixelSize * 2, height: pixelSize * 1.5)
            context.fill(Path(rect), with: .color(eyeColor))

        case .wide:
            let rect = CGRect(x: x - pixelSize * 0.25, y: y - pixelSize * 0.25, width: pixelSize * 2.5, height: pixelSize * 2.5)
            context.fill(Path(rect), with: .color(eyeColor))

        case .happy:
            var path = Path()
            path.move(to: CGPoint(x: x, y: y + pixelSize * 1.5))
            path.addLine(to: CGPoint(x: x + pixelSize, y: y))
            path.addLine(to: CGPoint(x: x + pixelSize * 2, y: y + pixelSize * 1.5))
            context.stroke(path, with: .color(eyeColor), lineWidth: pixelSize * 0.8)

        case .worried:
            let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
            context.fill(Path(rect), with: .color(eyeColor))
            let worryLine = CGRect(x: x, y: y - pixelSize, width: pixelSize * 2, height: pixelSize * 0.5)
            context.fill(Path(worryLine), with: .color(eyeColor.opacity(0.5)))

        case .curious:
            let rect = CGRect(x: x, y: y, width: pixelSize * 2.2, height: pixelSize * 2.2)
            context.fill(Path(roundedRect: rect, cornerRadius: pixelSize * 0.3), with: .color(eyeColor))

        case .attentive:
            let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
            context.fill(Path(rect), with: .color(eyeColor))
            let highlight = CGRect(x: x + pixelSize * 0.3, y: y + pixelSize * 0.3, width: pixelSize * 0.5, height: pixelSize * 0.5)
            context.fill(Path(highlight), with: .color(.white.opacity(0.7)))
        }
    }
}
