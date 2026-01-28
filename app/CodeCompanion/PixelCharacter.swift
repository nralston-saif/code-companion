import SwiftUI

struct PixelCharacter: View {
    let state: CompanionState
    let frame: Int
    let isHovering: Bool
    let eyeOffset: CGPoint
    var breathingScale: CGFloat = 1.0
    var dragWiggle: CGFloat = 0
    var skin: CompanionSkin = .defaultSkin
    var mood: PetMood = .neutral

    private var bodyColor: Color { skin.bodyColor }
    private var feetColor: Color { skin.feetColor }
    private var blushColor: Color { skin.blushColor }
    private let eyeColor = Color.black
    private let pixelSize: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2 + dragWiggle
            let centerY = size.height / 2
            let bounceOffset = calculateBounce()
            let squishX = calculateSquishX() * breathingScale
            let squishY = calculateSquishY() * breathingScale
            let stretchY = calculateStretchY()

            drawBody(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY * stretchY)
            drawFeet(context: context, centerX: centerX, centerY: centerY + bounceOffset + (stretchY > 1 ? 4 : 0), squishX: squishX)
            drawEyes(context: context, centerX: centerX, centerY: centerY + bounceOffset, squishX: squishX, squishY: squishY)

            // Draw mouth for yawning
            if state == .yawning {
                drawYawningMouth(context: context, centerX: centerX, centerY: centerY + bounceOffset)
            }

            // Draw blush for petted/giggling
            if state == .petted || state == .giggling {
                drawBlush(context: context, centerX: centerX, centerY: centerY + bounceOffset)
            }

            // Draw scratch indicator
            if state == .scratchingHead {
                drawScratchIndicator(context: context, centerX: centerX, centerY: centerY + bounceOffset)
            }

            // Draw mood indicators
            if mood == .happy && state == .idle {
                drawHappySparkles(context: context, centerX: centerX, centerY: centerY + bounceOffset)
            }
        }
        .frame(width: 60, height: 60)
    }

    private func calculateBounce() -> CGFloat {
        switch state {
        case .attention: return sin(Double(frame) * 0.5) * 3
        case .success: return -abs(sin(Double(frame) * 0.4) * 4)
        case .hovering, .curious: return sin(Double(frame) * 0.2) * 1
        case .giggling: return -abs(sin(Double(frame) * 0.6) * 5)
        case .settling: return sin(Double(frame) * 1.5) * 2 * max(0, 1 - CGFloat(frame % 30) / 30)
        case .dragging: return sin(Double(frame) * 0.8) * 2
        default: return 0
        }
    }

    private func calculateStretchY() -> CGFloat {
        switch state {
        case .stretching:
            // Animate stretch up then down
            let phase = sin(Double(frame) * 0.15)
            return 1.0 + CGFloat(max(0, phase)) * 0.25
        default: return 1.0
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
        let eyeY = centerY - 4 * squishY  // Moved eyes up
        let leftEyeX = centerX - 8 * squishX
        let rightEyeX = centerX + 4 * squishX

        // Apply eye offset based on window position (looking toward screen center)
        let offsetX = eyeOffset.x
        let offsetY = eyeOffset.y

        let drawBothEyes: (EyeStyle, CGFloat, CGFloat, CGFloat) -> Void = { style, leftX, rightX, yOffset in
            self.drawEye(context: context, style: style, x: leftX + offsetX, y: eyeY + yOffset + offsetY)
            self.drawEye(context: context, style: style, x: rightX + offsetX, y: eyeY + yOffset + offsetY)
        }

        switch state {
        case .sleeping:
            // Sleeping eyes don't follow screen center
            self.drawEye(context: context, style: .closed, x: leftEyeX, y: eyeY)
            self.drawEye(context: context, style: .closed, x: rightEyeX, y: eyeY)

        case .idle, .settling:
            // Mood affects idle eyes
            if mood == .sad {
                // Sad droopy eyes
                self.drawEye(context: context, style: .droopy, x: leftEyeX, y: eyeY + 1)
                self.drawEye(context: context, style: .droopy, x: rightEyeX, y: eyeY + 1)
            } else {
                let style: EyeStyle = (frame % 120) < 5 ? .closed : .normal
                if style == .closed {
                    self.drawEye(context: context, style: .closed, x: leftEyeX, y: eyeY)
                    self.drawEye(context: context, style: .closed, x: rightEyeX, y: eyeY)
                } else {
                    // Happy gets slightly bigger/brighter eyes
                    let eyeStyle: EyeStyle = mood == .happy ? .attentive : .normal
                    drawBothEyes(eyeStyle, leftEyeX, rightEyeX, 0)
                }
            }

        case .thinking, .scratchingHead:
            // Thinking eyes look up, but still affected by horizontal offset
            self.drawEye(context: context, style: .thinking, x: leftEyeX + offsetX, y: eyeY)
            self.drawEye(context: context, style: .thinking, x: rightEyeX + offsetX, y: eyeY)

        case .working, .dragging:
            drawBothEyes(.focused, leftEyeX, rightEyeX, 0)

        case .attention:
            drawBothEyes(.wide, leftEyeX, rightEyeX, 0)

        case .success, .clicked, .waving, .petted:
            // Happy eyes (curved) don't need offset - they're stylized
            self.drawEye(context: context, style: .happy, x: leftEyeX, y: eyeY)
            self.drawEye(context: context, style: .happy, x: rightEyeX, y: eyeY)

        case .giggling:
            // Extra happy - big curved eyes
            self.drawEye(context: context, style: .happy, x: leftEyeX, y: eyeY - 1)
            self.drawEye(context: context, style: .happy, x: rightEyeX, y: eyeY - 1)

        case .error:
            drawBothEyes(.worried, leftEyeX, rightEyeX, 0)

        case .hovering, .curious:
            let lookOffset: CGFloat = isHovering ? 1 : 0
            drawBothEyes(.curious, leftEyeX + lookOffset, rightEyeX + lookOffset, 0)

        case .listening:
            drawBothEyes(.attentive, leftEyeX, rightEyeX, 0)

        case .yawning:
            self.drawEye(context: context, style: .droopy, x: leftEyeX, y: eyeY)
            self.drawEye(context: context, style: .droopy, x: rightEyeX, y: eyeY)

        case .stretching:
            // Eyes closed during stretch
            self.drawEye(context: context, style: .closed, x: leftEyeX, y: eyeY)
            self.drawEye(context: context, style: .closed, x: rightEyeX, y: eyeY)

        case .lookingAround:
            // Eyes slowly glance left/right
            let dartOffset = sin(Double(frame) * 0.08) * 2
            self.drawEye(context: context, style: .normal, x: leftEyeX + CGFloat(dartOffset), y: eyeY)
            self.drawEye(context: context, style: .normal, x: rightEyeX + CGFloat(dartOffset), y: eyeY)

        case .dizzy:
            self.drawEye(context: context, style: .spiral, x: leftEyeX, y: eyeY)
            self.drawEye(context: context, style: .spiral, x: rightEyeX, y: eyeY)
        }
    }

    private enum EyeStyle {
        case normal, closed, thinking, focused, wide, happy, worried, curious, attentive
        case droopy      // For yawning
        case spiral      // For dizzy
        case darting     // For looking around
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

        case .droopy:
            // Half-closed sleepy eyes for yawning
            let rect = CGRect(x: x, y: y + pixelSize * 0.3, width: pixelSize * 2, height: pixelSize * 1.2)
            context.fill(Path(rect), with: .color(eyeColor))

        case .spiral:
            // Spiral/dizzy eyes - draw X pattern
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + pixelSize * 2, y: y + pixelSize * 2))
            path.move(to: CGPoint(x: x + pixelSize * 2, y: y))
            path.addLine(to: CGPoint(x: x, y: y + pixelSize * 2))
            context.stroke(path, with: .color(eyeColor), lineWidth: pixelSize * 0.5)

        case .darting:
            // Slightly smaller alert eyes
            let rect = CGRect(x: x, y: y, width: pixelSize * 1.8, height: pixelSize * 2)
            context.fill(Path(rect), with: .color(eyeColor))
        }
    }

    // MARK: - Additional Drawing Functions

    private func drawYawningMouth(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat) {
        // Draw an open mouth (oval) below the eyes
        let mouthY = centerY + 6
        let mouthRect = CGRect(x: centerX - pixelSize * 1.5, y: mouthY, width: pixelSize * 3, height: pixelSize * 2)
        var mouthPath = Path()
        mouthPath.addEllipse(in: mouthRect)
        context.fill(mouthPath, with: .color(Color(red: 0.3, green: 0.2, blue: 0.2)))
    }

    private func drawBlush(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat) {
        // Draw pink blush circles on cheeks
        let blushY = centerY
        let leftBlush = CGRect(x: centerX - 16, y: blushY, width: pixelSize * 2, height: pixelSize * 1.5)
        let rightBlush = CGRect(x: centerX + 10, y: blushY, width: pixelSize * 2, height: pixelSize * 1.5)
        var blushPath = Path()
        blushPath.addEllipse(in: leftBlush)
        blushPath.addEllipse(in: rightBlush)
        context.fill(blushPath, with: .color(blushColor.opacity(0.6)))
    }

    private func drawScratchIndicator(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat) {
        // Draw small motion lines near the head
        let indicatorX = centerX + 18
        let indicatorY = centerY - 12
        let offset = sin(Double(frame) * 0.5) * 2

        for i in 0..<3 {
            let y = indicatorY + CGFloat(i * 3) + CGFloat(offset)
            var path = Path()
            path.move(to: CGPoint(x: indicatorX, y: y))
            path.addLine(to: CGPoint(x: indicatorX + 4, y: y - 1))
            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1)
        }
    }

    private func drawHappySparkles(context: GraphicsContext, centerX: CGFloat, centerY: CGFloat) {
        // Small sparkles around a happy companion
        let sparklePositions: [(CGFloat, CGFloat)] = [(-18, -10), (20, -8), (-15, 8)]
        for (i, pos) in sparklePositions.enumerated() {
            let phase = Double(frame + i * 20) * 0.1
            let opacity = (sin(phase) + 1) / 4 // 0 to 0.5
            let sparkleSize: CGFloat = 3

            let x = centerX + pos.0
            let y = centerY + pos.1

            // Draw a small star/sparkle
            var path = Path()
            path.move(to: CGPoint(x: x, y: y - sparkleSize))
            path.addLine(to: CGPoint(x: x, y: y + sparkleSize))
            path.move(to: CGPoint(x: x - sparkleSize, y: y))
            path.addLine(to: CGPoint(x: x + sparkleSize, y: y))
            context.stroke(path, with: .color(.yellow.opacity(opacity)), lineWidth: 1.5)
        }
    }
}
