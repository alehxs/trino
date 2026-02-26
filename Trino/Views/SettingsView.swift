import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    // Bridges the Int hour/minute properties to a single Date for DatePicker
    private var cutoffTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: settings.cutoffHour,
                    minute: settings.cutoffMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                settings.cutoffHour   = comps.hour   ?? 21
                settings.cutoffMinute = comps.minute ?? 0
            }
        )
    }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Appearance") {
                    HStack {
                        Text("Accent color")
                        Spacer()
                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button {
                                    settings.theme = theme
                                } label: {
                                    Circle()
                                        .fill(theme.accent)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if settings.theme == theme {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 2.5)
                                                    .padding(3)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Picker("Week starts on", selection: $settings.weekStartsOnMonday) {
                        Text("Sunday").tag(false)
                        Text("Monday").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DatePicker(
                        "Daily cut-off",
                        selection: cutoffTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Cut-off Time")
                } footer: {
                    Text("Task swaps scheduled after this time take effect the following day.")
                }

                Section("Reminders") {
                    Toggle("Morning check-in", isOn: $settings.morningReminderEnabled)
                    if settings.morningReminderEnabled {
                        DatePicker("Time", selection: $settings.morningReminderTime, displayedComponents: .hourAndMinute)
                    }

                    Toggle("Midday check-in", isOn: $settings.middayReminderEnabled)
                    if settings.middayReminderEnabled {
                        DatePicker("Time", selection: $settings.middayReminderTime, displayedComponents: .hourAndMinute)
                    }

                    Toggle("Evening deadline", isOn: $settings.eveningReminderEnabled)
                    if settings.eveningReminderEnabled {
                        DatePicker("Time", selection: $settings.eveningReminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .glassEffect(in: .circle)
                }
            }
            .onChange(of: settings.morningReminderEnabled) { reschedule() }
            .onChange(of: settings.morningReminderTime)    { reschedule() }
            .onChange(of: settings.middayReminderEnabled)  { reschedule() }
            .onChange(of: settings.middayReminderTime)     { reschedule() }
            .onChange(of: settings.eveningReminderEnabled) { reschedule() }
            .onChange(of: settings.eveningReminderTime)    { reschedule() }
        }
    }

    private func reschedule() {
        NotificationService.scheduleNotifications(settings: settings)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsStore())
}
