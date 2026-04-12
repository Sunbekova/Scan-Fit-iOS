// AI verdict section - matches Android ProductDetailFragment AI layout
import SwiftUI

extension ProductDetailView {

    var aiVerdictSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Analysis").font(.headline)
                    if let resp = aiResponse {
                        let riskLabel = resp.riskLevel?.capitalized
                            ?? (( resp.healthScore ?? 0) < 40 ? "Dangerous" : "Safe")
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
                Text(verdict)
                    .font(.subheadline).foregroundColor(.secondary)
            } else if !isAnalyzing {
                Text("Tap Analyze with AI to check this product against your profile.")
                    .font(.caption).foregroundColor(.secondary)
            }

            if let ctx = aiResponse?.userContextUsed, ctx.hasUserInformation == true {
                Label("Personalized for your health profile", systemImage: "person.badge.shield.checkmark.fill")
                    .font(.caption)
                    .foregroundColor(Color("AppGreen"))
            }

            // Risks
            if let risks = aiResponse?.risks, !risks.isEmpty {
                aiSectionCard(title: "Risks", subtitle: "What may be a problem",
                              bgColor: Color(hex: "#FFF3E8")) {
                    ForEach(risks) { risk in
                        aiIssueRow(title: risk.ingredient ?? "Issue",
                                   body: risk.reason ?? "Needs attention.",
                                   severity: risk.severity)
                    }
                }
            }
            
            // diet conflicts
            if let conflicts = aiResponse?.dietConflicts, !conflicts.isEmpty {
                aiSectionCard(title: "Diet conflicts", subtitle: "Compared with active diets",
                              bgColor: Color(hex: "#F0F7FF")) {
                    ForEach(conflicts) { conflict in
                        aiIssueRow(title: conflict.dietCode ?? "Diet conflict",
                                   body: conflict.reason ?? "May not match one of the selected diets.",
                                   severity: conflict.severity)
                    }
                }
            }

            if let impact = aiResponse?.dailyImpact {
                dailyImpactSection(impact: impact)
            }

            // Alternatives
            if let alternatives = aiResponse?.alternatives, !alternatives.isEmpty {
                aiSectionCard(title: "Alternatives", subtitle: "Healthier options to consider",
                              bgColor: Color(.systemGray6)) {
                    ForEach(alternatives) { alt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alt.name ?? "Alternative").font(.caption).fontWeight(.bold)
                            if let reason = alt.reason {
                                Text(reason).font(.caption).foregroundColor(.secondary)
                            }
                            if let link = alt.kaspiLink, !link.isEmpty {
                                Link("Find on Kaspi →", destination: URL(string: link) ?? URL(string: "https://kaspi.kz")!)
                                    .font(.caption2)
                                    .foregroundColor(Color("AppGreen"))
                            }
                            Divider()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Sources
            if let sources = aiResponse?.sources, !sources.isEmpty {
                aiSectionCard(title: "Sources", subtitle: "Evidence used by AI",
                              bgColor: Color(.systemGray6)) {
                    ForEach(sources.prefix(4)) { source in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(source.title ?? "Source").font(.caption).fontWeight(.bold)
                            Text(source.url ?? source.sourceType ?? "No link")
                                .font(.caption2).foregroundColor(.secondary)
                            Divider()
                        }
                    }
                }
            }

            if analysisFailed {
                Text("Analysis failed. Please try again.")
                    .font(.caption).foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }


    @ViewBuilder
    private func dailyImpactSection(impact: AnalysisDailyImpact) -> some View {
        let items: [(String, AnalysisDailyImpactItem?)] = [
            ("Calories", impact.calories),
            ("Carbs", impact.carbs),
            ("Fat", impact.fat),
            ("Proteins", impact.proteins),
            ("Fiber", impact.fiber),
            ("Sodium", impact.sodium),
            ("Sugar", impact.sugar),
        ].filter { $0.1 != nil }

        if !items.isEmpty {
            aiSectionCard(title: "Daily Impact", subtitle: "How this product affects your daily goals",
                          bgColor: Color(hex: "#F0FFF4")) {
                ForEach(items, id: \.0) { name, item in
                    if let item = item {
                        dailyImpactRow(name: name, item: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dailyImpactRow(name: String, item: AnalysisDailyImpactItem) -> some View {
        let statusColor: Color = {
            switch item.status?.lowercased() {
            case "ok", "good": return Color(hex: "#16A34A")
            case "warning": return Color(hex: "#D97706")
            case "exceeded", "danger": return Color(hex: "#DC2626")
            default: return .secondary
            }
        }()

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.caption).fontWeight(.bold)
                Spacer()
                if let status = item.status {
                    Text(status.capitalized)
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor).cornerRadius(6)
                }
            }
            if let after = item.afterThisProduct, let goal = item.goalToday, goal > 0 {
                let progress = min(after / goal, 1.0)
                ProgressView(value: progress)
                    .accentColor(statusColor)
            }
            if let message = item.message {
                Text(message).font(.caption2).foregroundColor(.secondary)
            }
            Divider()
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    func aiSectionCard<Content: View>(title: String, subtitle: String,
                                      bgColor: Color, @ViewBuilder content: () -> Content) -> some View {
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
    func aiIssueRow(title: String, body: String, severity: String?) -> some View {
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

    func severityColor(_ s: String?) -> Color {
        switch s?.lowercased() {
        case "high": return Color(hex: "#DC2626")
        case "medium": return Color(hex: "#D97706")
        case "low": return Color(hex: "#2563EB")
        default: return .gray
        }
    }
}
