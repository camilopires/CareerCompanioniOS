import SwiftUI

/// Animated splash screen showing the Career Companion logo
/// The characters animate upward toward the star
struct SplashScreenView: View {
    @State private var logoOffset: CGFloat = 50
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var starGlow: Double = 0
    @State private var isAnimating = false

    let onComplete: () -> Void

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Background gradient matching the logo colors
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.45, blue: 0.85), // Purple top
                    Color(red: 0.4, green: 0.65, blue: 0.55),  // Green-teal middle
                    Color(red: 0.3, green: 0.5, blue: 0.7)     // Blue bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo with animation
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .offset(y: reduceMotion ? 0 : logoOffset)
                    .scaleEffect(reduceMotion ? 1 : logoScale)
                    .opacity(logoOpacity)

                // App name
                Text("Career Companion")
                    .font(Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .opacity(logoOpacity)

                // Tagline
                Text("Your journey to success")
                    .font(Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(logoOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        if reduceMotion {
            // Skip animation for reduce motion users
            logoOpacity = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
            return
        }

        // Phase 1: Fade in and initial position
        withAnimation(.easeOut(duration: 0.5)) {
            logoOpacity = 1
        }

        // Phase 2: Move up toward the star (characters walking)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            logoOffset = 0
            logoScale = 1.0
        }

        // Phase 3: Star glow pulse
        withAnimation(.easeInOut(duration: 0.6).delay(0.8)) {
            starGlow = 1
        }

        // Complete and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Theme.successHaptic()
            onComplete()
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash complete")
    }
}
