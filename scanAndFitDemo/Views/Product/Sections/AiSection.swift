//product AI section
import SwiftUI

extension ProductDetailView {

    var aiVerdictSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Analysis").font(.headline)
                    if let resp = aiResponse {
                        let riskLabel = resp.riskLevel?.capitalized ?? (resp.healthScore ?? 0 < 40 ? "Dangerous" : "Safe")
                        Text(riskLabel)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(gradeColor(currentGrade))
                    } else {
                        Text("Not analyzed yet").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isAnalyzing {
                    ProgressView()
                } else {
                    Button(aiResponse != nil ? "Analyze again" : "Analyze with AI") {
                        if let item = foodItem { Task { await startAIAnalysis(for: item) } }
                    }
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color("AppGreen"))
                    .cornerRadius(20)
                    .disabled(foodItem == nil)
                }
            }
            
            if let resp = aiResponse, let verdict = resp.verdict {
                Text(verdict).font(.subheadline).foregroundColor(.secondary)
            } else if !isAnalyzing {
                Text("Tap Analyze with AI to check this product against your profile.")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            // Risks
            if let risks = aiResponse?.risks, !risks.isEmpty {
                aiSectionCard(title: "Risks", subtitle: "What may be a problem", bgColor: Color(hex: "#FFF3E8")) {
                    ForEach(risks) { risk in
                        aiIssueRow(title: risk.ingredient ?? "Issue",
                                   body: risk.reason ?? "Needs attention.",
                                   severity: risk.severity)
                    }
                }
            }
            
            // diet conflicts
            if let conflicts = aiResponse?.dietConflicts, !conflicts.isEmpty {
                aiSectionCard(title: "Diet conflicts", subtitle: "Compared with active diets", bgColor: Color(hex: "#F0F7FF")) {
                    ForEach(conflicts) { conflict in
                        aiIssueRow(title: conflict.dietCode ?? "Diet conflict",
                                   body: conflict.reason ?? "May not match one of the selected diets.",
                                   severity: conflict.severity)
                    }
                }
            }
            
            // sources
            if let sources = aiResponse?.sources, !sources.isEmpty {
                aiSectionCard(title: "Sources", subtitle: "Evidence used by AI", bgColor: Color(.systemGray6)) {
                    ForEach(sources.prefix(4)) { source in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(source.title ?? "Source").font(.caption).fontWeight(.bold)
                            Text(source.url ?? source.sourceType ?? "No link").font(.caption2).foregroundColor(.secondary)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    @ViewBuilder
    private func aiSectionCard<Content: View>(title: String, subtitle: String, bgColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).fontWeight(.bold)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
            content()
        }
        .padding(14)
        .background(bgColor)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
    }

    @ViewBuilder
    private func aiIssueRow(title: String, body: String, severity: String?) -> some View {
        let sColor = severityColor(severity)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).fontWeight(.bold)
                Spacer()
                Text((severity ?? "note").capitalized)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(sColor).cornerRadius(6)
            }
            Text(body).font(.caption).foregroundColor(.secondary)
            Divider()
        }
        .padding(.vertical, 4)
    }

    private func severityColor(_ s: String?) -> Color {
        switch s?.lowercased() {
        case "high": return Color(hex: "#DC2626")
        case "medium": return Color(hex: "#D97706")
        case "low": return Color(hex: "#2563EB")
        default: return .gray
        }
    }
}
