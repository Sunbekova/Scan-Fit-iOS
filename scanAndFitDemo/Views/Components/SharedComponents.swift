import SwiftUI

// MARK: - Primary Button

struct SFPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isLoading ? Color("AppGreen").opacity(0.7) : Color("AppGreen"))
            .cornerRadius(14)
        }
        .disabled(isLoading)
    }
}

// MARK: - Text Field

struct SFTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Secure Field

struct SFSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.secondary)
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Food Row View

struct FoodRowView: View {
    let item: FoodItem
    let showFavorite: Bool
    let onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Image
            Group {
                if let urlStr = item.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    if let cal = item.calories {
                        Text(cal)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let grade = item.grade {
                        Text(grade.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradeColor(grade).opacity(0.15))
                            .foregroundColor(gradeColor(grade))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Favorite icon
            if showFavorite, let toggle = onFavoriteToggle {
                Button(action: toggle) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(item.isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color("AppGreen").opacity(0.1))
            .overlay(
                Image(systemName: "fork.knife")
                    .foregroundColor(Color("AppGreen").opacity(0.5))
            )
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A": return .green
        case "B": return Color(hex: "#8BC34A")
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default: return .gray
        }
    }
}

// MARK: - Grade Badge

struct GradeBadgeView: View {
    let grade: String

    var color: Color {
        switch grade.uppercased() {
        case "A": return Color(hex: "#2E7D32")
        case "B": return Color(hex: "#8BC34A")
        case "C": return Color(hex: "#FBC02D")
        case "D": return Color(hex: "#F57C00")
        case "E": return Color(hex: "#D32F2F")
        default: return .gray
        }
    }

    var body: some View {
        Text(grade.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}
