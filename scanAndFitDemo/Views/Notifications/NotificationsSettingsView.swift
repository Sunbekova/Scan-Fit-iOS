import SwiftUI

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var mealReminder = UserDefaults.standard.bool(forKey: "notif_meal")
    @State private var waterReminder = UserDefaults.standard.bool(forKey: "notif_water")
    @State private var mealHour = UserDefaults.standard.integer(forKey: "notif_meal_hour") == 0
        ? 9 : UserDefaults.standard.integer(forKey: "notif_meal_hour")

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !notificationManager.isAuthorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are disabled".localized)
                                .font(.subheadline).fontWeight(.semibold)
                            Text("Enable notifications in iPhone Settings to receive reminders.".localized)
                                .font(.caption).foregroundColor(.secondary)
                            Button("Open Settings".localized) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption).foregroundColor(Color("AppGreen"))
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Daily Reminders".localized)) {
                    Toggle(isOn: $mealReminder) {
                        Label("Meal Reminder".localized, systemImage: "fork.knife")
                    }
                    .tint(Color("AppGreen"))
                    .onChange(of: mealReminder) { _, on in
                        UserDefaults.standard.set(on, forKey: "notif_meal")
                        if on { notificationManager.scheduleDailyReminder(hour: mealHour) }
                        else { notificationManager.cancelAllReminders() }
                    }

                    if mealReminder {
                        HStack {
                            Label("Reminder Time".localized, systemImage: "clock")
                            Spacer()
                            Picker("", selection: $mealHour) {
                                ForEach(6..<23) { h in
                                    Text("\(String(format: "%02d", h)):00").tag(h)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppGreen"))
                            .onChange(of: mealHour) { _, h in
                                UserDefaults.standard.set(h, forKey: "notif_meal_hour")
                                if mealReminder { notificationManager.scheduleDailyReminder(hour: h) }
                            }
                        }
                    }

                    Toggle(isOn: $waterReminder) {
                        Label("Water Reminder".localized, systemImage: "drop.fill")
                    }
                    .tint(Color("AppGreen"))
                    .onChange(of: waterReminder) { _, on in
                        UserDefaults.standard.set(on, forKey: "notif_water")
                        if on { notificationManager.scheduleWaterReminder() }
                    }
                }

                Section(header: Text("Push Notifications".localized)) {
                    HStack {
                        Image(systemName: "bell.badge.fill").foregroundColor(Color("AppGreen"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Health Tips".localized).font(.subheadline)
                            Text("Receive personalized nutrition tips".localized)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                    }
                }
            }
            .navigationTitle("Notifications".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(Color("AppGreen"))
                    }
                }
            }
            .onAppear { notificationManager.checkAuthorizationStatus() }
        }
    }
}
