import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showBreathingSession = false
    @State private var selectedDate = Date()
    @State private var isPlantingMode = false
    @State private var showMonthPicker = false

    private var selectedMonth: Int { Calendar.current.component(.month, from: selectedDate) }
    private var selectedYear: Int { Calendar.current.component(.year, from: selectedDate) }

    var body: some View {
        ZStack {
            // Background Layer
            Color("Surface")
                .ignoresSafeArea()
            
            VStack {
                // Image Background
                GeometryReader { geo in
                    Image("BeBG")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height / 1.8)
                        .clipped()
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.75),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .ignoresSafeArea(edges: .top)
                
                Spacer()
            }
            
            // UI Overlay
            ScrollView {
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        // Left spacer to balance the menu button
                        Spacer()
                            .frame(width: 48) // Matches the menu button width
                        
                        Spacer()
                        
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                        
                        Spacer()
                        
                        Menu {
                            if let name = authManager.displayName {
                                Text(name)
                            }
                            Button(role: .destructive) {
                                authManager.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 48) // Fixed width for centering
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                
                Spacer()
                    .frame(height: 30)
                
                // Huge BrandGreen Button
                Button {
                    showBreathingSession = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color("BrandGreen"))
                            .frame(width: 180, height: 180)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "wind")
                                .font(.system(size: 32, weight: .light))
                            Text("Start Breathing")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                    }
                }
                
                Spacer()
                    .frame(height: 40)
                
                // Insights Row
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("20")
                            .font(.system(.headline, design: .serif).weight(.regular))
                            .foregroundColor(.black)
                        Text("Total breathing")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("10m")
                            .font(.system(.headline, design: .serif).weight(.regular))
                            .foregroundColor(.black)
                        Text("Total time")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("20")
                            .font(.system(.headline, design: .serif).weight(.regular))
                            .foregroundColor(.black)
                        Text("Exercises")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(Color(hex: "#F8F5F2"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 30)
                
                // Month Picker Row
                HStack(spacing: 40) {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    Button(action: {
                        showMonthPicker = true
                    }) {
                        ZStack {
                            Capsule()
                                .fill(Color("Surface").opacity(0.8))
                                .frame(width: 140, height: 36)

                            Text(selectedDate, format: .dateTime.month(.abbreviated).year())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                    }

                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }

                Spacer()
                    .frame(height: 24)

                // Garden
                GardenView(
                    month: selectedMonth,
                    year: selectedYear,
                    isPlantingMode: $isPlantingMode,
                    onTilePlanted: { tileId in
                        GardenPersistence.save(tileId: tileId, month: selectedMonth, year: selectedYear)
                    }
                )

                if isPlantingMode {
                    Text("Tap a tile to plant your flower")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }

                Spacer()
                    .frame(height: 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showBreathingSession) {
            BreathingSessionView(onAddToGarden: {
                showBreathingSession = false
                isPlantingMode = true
            })
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerView(selectedDate: $selectedDate, isPresented: $showMonthPicker)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    private let months = Calendar.current.monthSymbols
    private let years: [Int]
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array((currentYear - 5)...(currentYear + 5))
        
        let month = Calendar.current.component(.month, from: selectedDate.wrappedValue)
        let year = Calendar.current.component(.year, from: selectedDate.wrappedValue)
        self._selectedMonth = State(initialValue: month)
        self._selectedYear = State(initialValue: year)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Select Month")
                .font(.headline)
                .padding(.top, 20)
            
            HStack(spacing: 0) {
                // Month Picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(months[month - 1])
                            .tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150)
                
                // Year Picker
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
            }
            .frame(height: 160)
            
            Button("Done") {
                updateDate()
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandGreen"))
        }
    }
    
    private func updateDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HomeView()
}
