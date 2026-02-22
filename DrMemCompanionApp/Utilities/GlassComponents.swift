import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .modifier(GlassCardModifier())
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.75),
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    .white.opacity(0.4),
                                    .white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
                .shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
                .shadow(color: DrMemTheme.shadowColor, radius: 10, y: 5)
            }
    }
}

struct GlassInputBar: View {
    @Binding var text: String
    let placeholder: String
    let onSend: () -> Void
    let onMic: (() -> Void)?
    let onPlus: (() -> Void)?
    @State private var sendTrigger: Bool = false

    init(text: Binding<String>, placeholder: String = "Message...", onSend: @escaping () -> Void, onMic: (() -> Void)? = nil, onPlus: (() -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onSend = onSend
        self.onMic = onMic
        self.onPlus = onPlus
    }

    var body: some View {
        HStack(spacing: 8) {
            if let onPlus {
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DrMemTheme.warmGray)
                        .frame(width: 36, height: 36)
                }
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .fill(Color.white.opacity(0.45))
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                }

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let onMic {
                    Button(action: onMic) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background {
                                Circle().fill(DrMemTheme.terracotta)
                                Circle().fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.2), Color.clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                            }
                    }
                }
            } else {
                Button {
                    sendTrigger.toggle()
                    onSend()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle().fill(DrMemTheme.terracotta)
                            Circle().fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                        }
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: sendTrigger)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.35))
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: -2)
    }
}

struct GlassPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(DrMemTheme.terracotta)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                    }
                }
                .foregroundStyle(isSelected ? .white : DrMemTheme.darkText)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? AnyShapeStyle(Color.clear) : AnyShapeStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            ),
                            lineWidth: 0.6
                        )
                }
                .shadow(color: isSelected ? DrMemTheme.terracotta.opacity(0.3) : Color.clear, radius: 6, y: 3)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var tapTrigger: Bool = false

    var body: some View {
        Button {
            tapTrigger.toggle()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background {
                    Circle()
                        .fill(DrMemTheme.terracotta)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.25), Color.clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                }
                .shadow(color: DrMemTheme.terracotta.opacity(0.4), radius: 12, y: 6)
                .shadow(color: DrMemTheme.terracotta.opacity(0.15), radius: 3, y: 1)
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: tapTrigger)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask { content }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 14)
                    .frame(maxWidth: 180)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 10)
                    .frame(maxWidth: 120)
            }
            Spacer()
        }
        .padding(16)
        .modifier(GlassCardModifier())
        .modifier(ShimmerModifier())
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardModifier())
    }
}

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                DismissKeyboardBackgroundView()
            }
    }
}

struct DismissKeyboardBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dismiss))
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        @objc func dismiss() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct WarmBackground: View {
    var body: some View {
        DrMemTheme.meshBg
            .ignoresSafeArea()
    }
}
