import SwiftUI

struct CalendarSection: View {
    @ObservedObject var trackerVM: TrackerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(trackerVM.weekDays(for: trackerVM.selectedDate), id: \.self) { day in
                    let isSelected = trackerVM.isSameDay(day, trackerVM.selectedDate)
                    let isEnabled = trackerVM.canSelectDate(day)
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 11))
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color("AppGreen") : Color(.systemGray6))
                    .foregroundColor(
                        isSelected ? .white : (isEnabled ? .primary : .secondary.opacity(0.4))
                    )
                    .cornerRadius(10)
                    .opacity(isEnabled ? 1.0 : 0.4)
                    .onTapGesture {
                        guard isEnabled else { return }
                        trackerVM.selectedDate = day
                    }
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    var minDate: Date? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let minDate = minDate {
                    DatePicker("Select date",
                               selection: $selectedDate,
                               in: minDate...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                } else {
                    DatePicker("Select date",
                               selection: $selectedDate,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                }
            }
            .navigationTitle("Pick Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
