import SwiftUI

func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title).font(.headline)
        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color(.systemBackground))
    .cornerRadius(14)
    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
}

func sectionHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.title3).fontWeight(.bold)
        Text(subtitle).font(.caption).foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
