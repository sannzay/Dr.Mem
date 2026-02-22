import SwiftUI

struct DrawerView: View {
    @Binding var selectedItem: DrawerItem
    @Binding var isOpen: Bool
    let onNewChat: () -> Void
    @State private var newChatTrigger: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                drawerHeader

                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(DrawerItem.allCases) { item in
                            drawerRow(item)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }

                Divider()
                    .padding(.horizontal, 16)

                drawerFooter
            }
            .frame(width: 280)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.clear],
                                    startPoint: .trailing,
                                    endPoint: .leading
                                )
                            )
                            .frame(width: 1)
                    }
                    .ignoresSafeArea()
            }

            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isOpen = false
                    }
                }
        }
    }

    private var drawerHeader: some View {
        HStack {
            Image(systemName: "stethoscope")
                .font(.title2)
                .foregroundStyle(DrMemTheme.terracotta)

            Text("Dr. Mem")
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(DrMemTheme.darkText)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isOpen = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func drawerRow(_ item: DrawerItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedItem = item
                isOpen = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(selectedItem == item ? DrMemTheme.terracotta : DrMemTheme.warmGray)
                    .frame(width: 24)

                Text(item.rawValue)
                    .font(.subheadline.weight(selectedItem == item ? .semibold : .regular))
                    .foregroundStyle(selectedItem == item ? DrMemTheme.darkText : DrMemTheme.warmGray)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if selectedItem == item {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DrMemTheme.terracotta.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(DrMemTheme.terracotta.opacity(0.15), lineWidth: 0.5)
                        }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedItem)
    }

    private var drawerFooter: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DrMemTheme.terracotta.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DrMemTheme.terracotta)
                }

            Text("Clinician")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                newChatTrigger.toggle()
                onNewChat()
            } label: {
                Text("New")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background {
                        Capsule().fill(DrMemTheme.terracotta)
                        Capsule().fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.2), Color.clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                    }
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: newChatTrigger)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
