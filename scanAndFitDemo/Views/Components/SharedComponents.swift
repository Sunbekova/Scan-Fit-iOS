import SwiftUI

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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color("AppGreen"))
            .cornerRadius(28)
            .shadow(color: Color("AppGreen").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
    }
}

// MARK: - Text Field
struct SFTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if let iconName = icon, !iconName.isEmpty {
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .autocapitalization(.none)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color(.systemGray6).opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Secure Field
struct CleanSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .font(.system(size: 16))
            .autocapitalization(.none)
            .textContentType(.newPassword)
            .padding()
            .frame(height: 56)
            .background(Color(.systemGray6).opacity(0.6))
            .cornerRadius(12)
    }
}

// MARK: - Food Row View
struct FoodRowView: View {
    let item: FoodItem
    let showFavorite: Bool
    let onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
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
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    if let cal = item.calories {
                        Text(cal)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    if let grade = item.grade {
                        GradeBadgeView(grade: grade)
                    }
                }
            }

            Spacer()

            if showFavorite, let toggle = onFavoriteToggle {
                Button(action: toggle) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(item.isFavorite ? .red : .gray.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("AppGreen").opacity(0.1))
            .overlay(
                Image(systemName: "carrot.fill")
                    .foregroundColor(Color("AppGreen").opacity(0.5))
            )
    }
}

// MARK: - Grade Badge
struct GradeBadgeView: View {
    let grade: String

    var color: Color {
        switch grade.uppercased() {
        case "A": return Color.green
        case "B": return Color.green.opacity(0.7)
        case "C": return Color.yellow
        case "D": return Color.orange
        case "E": return Color.red
        default: return .gray
        }
    }

    var body: some View {
        Text(grade.uppercased())
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}
