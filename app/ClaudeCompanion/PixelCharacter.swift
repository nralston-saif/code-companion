import SwiftUI

struct PixelCharacter: View {
    let state: CompanionState
    let frame: Int
    let isHovering: Bool

    // Colors
    let bodyColor = Color(red: 0.92, green: 0.75, blue: 0.70)      // Warm pink/salmon
    let bodyDarkColor = Color(red: 0.85, green: 0.65, blue: 0.60)  // Darker for shading
    let eyeColor = Color.black
    let feetColor = Color(red: 0.88, green: 0.68, blue: 0.63)

    // Pixel size
    let pixelSize: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2

            // Calculate bounce offset for animations
            let bounceOffset = calculateBounce()
            let squishX = calculateSquishX()
            let squishY = calculateSquishY()

            // Draw the character
            drawBody(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY)
            drawFeet(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX)
            drawEyes(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY)
        }
        .frame(width: 60, height: 60)
    }

    func calculateBounce() -> CGFloat {
        switch state {
        case .attention:
            return sin(Double(frame) * 0.5) * 3
        case .success:
            return -abs(sin(Double(frame) * 0.4) * 4)
        case .clicked:
            return 0
        case .hovering, .curious:
            return sin(Double(frame) * 0.2) * 1
        default:
            return 0
        }
    }

    func calculateSquishX() -> CGFloat {
        switch state {
        case .clicked:
            return 1.1
        default:
            return 1.0
        }
    }

    func calculateSquishY() -> CGFloat {
        switch state {
        case .clicked:
            return 0.9
        default:
            return 1.0
        }
    }

    func drawBody(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat, squishY: CGFloat) {
        // Main body - rounded rectangle of pixels
        // Body is roughly 10 pixels wide, 7 pixels tall

        let bodyWidth: CGFloat = 10 * pixelSize * squishX
        let bodyHeight: CGFloat = 7 * pixelSize * squishY
        let startX = centerX - bodyWidth / 2
        let startY = centerY - bodyHeight / 2 - 2

        // Draw body pixels (simple rounded shape)
        let bodyPixels: [(Int, Int)] = [
            // Row 0 (top) - narrower
            (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0),
            // Row 1
            (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1),
            // Row 2
            (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2),
            // Row 3
            (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3),
            // Row 4
            (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4),
            // Row 5
            (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5),
            // Row 6 (bottom) - narrower
            (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6),
        ]

        for (px, py) in bodyPixels {
            let x = startX + CGFloat(px) * pixelSize * squishX
            let y = startY + CGFloat(py) * pixelSize * squishY
            let rect = CGRect(x: x, y: y, width: pixelSize * squishX, height: pixelSize * squishY)
            context.fill(Path(rect), with: .color(bodyColor))
        }
    }

    func drawFeet(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat) {
        // Two small feet at the bottom
        let feetY = centerY + 12

        // Left foot
        let leftFootX = centerX - 10 * squishX
        context.fill(
            Path(CGRect(x: leftFootX, y: feetY, width: pixelSize * 1.5, height: pixelSize * 2)),
            with: .color(feetColor)
        )

        // Right foot
        let rightFootX = centerX + 6 * squishX
        context.fill(
            Path(CGRect(x: rightFootX, y: feetY, width: pixelSize * 1.5, height: pixelSize * 2)),
            with: .color(feetColor)
        )
    }

    func drawEyes(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat, squishX: CGFloat, squishY: CGFloat) {
        let eyeY = centerY - 2 * squishY
        let leftEyeX = centerX - 8 * squishX
        let rightEyeX = centerX + 4 * squishX

        // Eye appearance based on state
        switch state {
        case .sleeping:
            // Closed eyes - horizontal lines
            drawClosedEye(context: context, x: leftEyeX, y: eyeY)
            drawClosedEye(context: context, x: rightEyeX, y: eyeY)

        case .idle:
            // Normal eyes with occasional blink
            let shouldBlink = (frame % 120) < 5
            if shouldBlink {
                drawClosedEye(context: context, x: leftEyeX, y: eyeY)
                drawClosedEye(context: context, x: rightEyeX, y: eyeY)
            } else {
                drawNormalEye(context: context, x: leftEyeX, y: eyeY)
                drawNormalEye(context: context, x: rightEyeX, y: eyeY)
            }

        case .thinking:
            // Eyes looking up/to the side
            drawThinkingEye(context: context, x: leftEyeX, y: eyeY - 1)
            drawThinkingEye(context: context, x: rightEyeX, y: eyeY - 1)

        case .working:
            // Focused eyes
            drawFocusedEye(context: context, x: leftEyeX, y: eyeY)
            drawFocusedEye(context: context, x: rightEyeX, y: eyeY)

        case .attention:
            // Wide eyes
            drawWideEye(context: context, x: leftEyeX, y: eyeY)
            drawWideEye(context: context, x: rightEyeX, y: eyeY)

        case .success:
            // Happy ^ ^ eyes
            drawHappyEye(context: context, x: leftEyeX, y: eyeY)
            drawHappyEye(context: context, x: rightEyeX, y: eyeY)

        case .error:
            // Worried eyes
            drawWorriedEye(context: context, x: leftEyeX, y: eyeY)
            drawWorriedEye(context: context, x: rightEyeX, y: eyeY)

        case .hovering, .curious:
            // Curious big eyes looking at cursor
            let lookOffset: CGFloat = isHovering ? 1 : 0
            drawCuriousEye(context: context, x: leftEyeX + lookOffset, y: eyeY)
            drawCuriousEye(context: context, x: rightEyeX + lookOffset, y: eyeY)

        case .clicked:
            // Squished happy eyes
            drawHappyEye(context: context, x: leftEyeX, y: eyeY)
            drawHappyEye(context: context, x: rightEyeX, y: eyeY)

        case .waving:
            // Happy eyes while waving
            drawHappyEye(context: context, x: leftEyeX, y: eyeY)
            drawHappyEye(context: context, x: rightEyeX, y: eyeY)

        case .listening:
            // Attentive eyes
            drawAttentiveEye(context: context, x: leftEyeX, y: eyeY)
            drawAttentiveEye(context: context, x: rightEyeX, y: eyeY)
        }
    }

    // Eye drawing helpers
    func drawNormalEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // 2x2 pixel eye
        let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
        context.fill(Path(rect), with: .color(eyeColor))
    }

    func drawClosedEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Horizontal line
        let rect = CGRect(x: x, y: y + pixelSize * 0.5, width: pixelSize * 2, height: pixelSize * 0.8)
        context.fill(Path(rect), with: .color(eyeColor))
    }

    func drawThinkingEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Eye looking up - smaller and shifted up
        let rect = CGRect(x: x + pixelSize * 0.3, y: y - pixelSize * 0.5, width: pixelSize * 1.5, height: pixelSize * 1.5)
        context.fill(Path(rect), with: .color(eyeColor))
    }

    func drawFocusedEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Slightly narrowed
        let rect = CGRect(x: x, y: y + pixelSize * 0.3, width: pixelSize * 2, height: pixelSize * 1.5)
        context.fill(Path(rect), with: .color(eyeColor))
    }

    func drawWideEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Bigger eyes
        let rect = CGRect(x: x - pixelSize * 0.25, y: y - pixelSize * 0.25, width: pixelSize * 2.5, height: pixelSize * 2.5)
        context.fill(Path(rect), with: .color(eyeColor))
    }

    func drawHappyEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // ^ shape - two small rects forming an upward angle
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + pixelSize * 1.5))
        path.addLine(to: CGPoint(x: x + pixelSize, y: y))
        path.addLine(to: CGPoint(x: x + pixelSize * 2, y: y + pixelSize * 1.5))
        context.stroke(path, with: .color(eyeColor), lineWidth: pixelSize * 0.8)
    }

    func drawWorriedEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Slanted eyebrow effect
        let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
        context.fill(Path(rect), with: .color(eyeColor))
        // Small worry line above
        let worryLine = CGRect(x: x, y: y - pixelSize, width: pixelSize * 2, height: pixelSize * 0.5)
        context.fill(Path(worryLine), with: .color(eyeColor.opacity(0.5)))
    }

    func drawCuriousEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Slightly larger, rounded
        let rect = CGRect(x: x, y: y, width: pixelSize * 2.2, height: pixelSize * 2.2)
        context.fill(Path(roundedRect: rect, cornerRadius: pixelSize * 0.3), with: .color(eyeColor))
    }

    func drawAttentiveEye(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Normal but with highlight
        let rect = CGRect(x: x, y: y, width: pixelSize * 2, height: pixelSize * 2)
        context.fill(Path(rect), with: .color(eyeColor))
        // Small highlight
        let highlight = CGRect(x: x + pixelSize * 0.3, y: y + pixelSize * 0.3, width: pixelSize * 0.5, height: pixelSize * 0.5)
        context.fill(Path(highlight), with: .color(.white.opacity(0.7)))
    }
}
