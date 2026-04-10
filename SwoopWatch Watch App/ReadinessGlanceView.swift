import SwiftUI

struct ReadinessGlanceView: View {

    @State private var manager = WatchSessionManager.shared

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.02, blue: 0.2).ignoresSafeArea()

            VStack(spacing: 6) {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.readinessScore / 100))
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(manager.readinessScore))")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("RDY")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                HStack(spacing: 12) {
                    miniStat(label: "SLP", value: "\(Int(manager.sleepScore))", color: .blue)
                    miniStat(label: "LDR", value: "\(Int(manager.loadScore))", color: .pink)
                    miniStat(label: "HRV", value: "\(Int(manager.hrv))", color: .green)
                }
            }
        }
    }

    private var scoreColor: Color {
        switch manager.readinessScore {
        case 67...: return .green
        case 34..<67: return .purple
        default: return .pink
        }
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}
