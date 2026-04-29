import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showBreathingSession = false
    @State private var selectedDate = Date()
    @State private var isPlantingMode = false
    @State private var showMonthPicker = false
    
    // Stats
    @State private var totalFlowers = BreathingStats.totalFlowersPlanted()
    @State private var totalMinutes = BreathingStats.totalCalmMinutes()
    @State private var streak = BreathingStats.currentStreak()
    
    private let gregorian = Calendar(identifier: .gregorian)
    private var selectedMonth: Int { gregorian.component(.month, from: selectedDate) }
    private var selectedYear: Int { gregorian.component(.year, from: selectedDate) }
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var padScale: CGFloat { isPad ? 1.3 : 1.0 }

    private static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    private var selectedMonthName: String { Self.monthNames[selectedMonth - 1] }

    private func shiftMonth(by delta: Int) {
        selectedDate = gregorian.date(byAdding: .month, value: delta, to: selectedDate) ?? selectedDate
    }
    
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
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black, location: 0.5),
                                    .init(color: .black.opacity(0.8), location: 0.65),
                                    .init(color: .black.opacity(0.4), location: 0.8),
                                    .init(color: .black.opacity(0.1), location: 0.92),
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
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // Top Bar
                        HStack {
                            // Left spacer to balance the menu button
                            Spacer()
                                .frame(width: 48 * padScale) // Matches the menu button width
                            
                            Spacer()
                            
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 70 * padScale)
                            
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
                                    .font(.system(size: 24 * padScale))
                                    .foregroundColor(.white)
                                    .frame(width: 48 * padScale) // Fixed width for centering
                            }
                        }
                        .padding(.horizontal, 24 * padScale)
                        .padding(.top, 4 * padScale)
                        
                        Spacer()
                            .frame(height: 30 * padScale)
                        
                        // Start Breathing button — liquid glass
                        Button {
                            showBreathingSession = true
                        } label: {
                            VStack(spacing: 12 * padScale) {
                                Image(systemName: "wind")
                                    .font(.system(size: 32 * padScale, weight: .light))
                                Text("Start Breathing")
                                    .font(.system(size: 17 * padScale, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(width: 180 * padScale, height: 180 * padScale)
                            .glassEffect(
                                .regular.tint(Color("BrandGreen")).interactive(),
                                in: .circle
                            )
                        }
                        .environment(\.colorScheme, .dark)
                        
                        Spacer()
                            .frame(height: 40 * padScale)
                        
                        // Insights Row
                        HStack(spacing: 0) {
                            VStack(spacing: 4 * padScale) {
                                Text("\(totalFlowers)")
                                    .font(.system(size: 17 * padScale, weight: .regular, design: .serif))
                                    .foregroundColor(.black)
                                Text("Flowers Planted")
                                    .font(.system(size: 13 * padScale))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4 * padScale) {
                                Text("\(totalMinutes)m")
                                    .font(.system(size: 17 * padScale, weight: .regular, design: .serif))
                                    .foregroundColor(.black)
                                Text("Calm Minutes")
                                    .font(.system(size: 13 * padScale))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4 * padScale) {
                                Text("\(streak)")
                                    .font(.system(size: 17 * padScale, weight: .regular, design: .serif))
                                    .foregroundColor(.black)
                                Text("Day Streak")
                                    .font(.system(size: 13 * padScale))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 20 * padScale)
                        .background(Color(hex: "#F8F5F2"))
                        .cornerRadius(12 * padScale)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        .padding(.horizontal, 24 * padScale)
                        
                        Spacer()
                            .frame(height: 30 * padScale)
                        
                        // Month Picker Row
                        HStack(spacing: 40 * padScale) {
                            Button(action: { shiftMonth(by: -1) }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20 * padScale, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showMonthPicker = true
                                }
                            }) {
                                ZStack {
                                    Capsule()
                                        .fill(Color("Surface").opacity(0.8))
                                        .frame(width: 140 * padScale, height: 36 * padScale)
                                    
                                    Text("\(selectedMonthName) \(String(selectedYear))")
                                        .font(.system(size: 15 * padScale, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Button(action: { shiftMonth(by: 1) }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20 * padScale, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 40 * padScale)
                        
                        // Garden — Color.clear gives scrollTo an anchor without affecting layout
                        Color.clear.frame(height: 0).id("gardenSection")

                        GardenView(
                            month: selectedMonth,
                            year: selectedYear,
                            isPlantingMode: $isPlantingMode,
                            onTilePlanted: { tileId in
                                GardenPersistence.save(tileId: tileId, month: selectedMonth, year: selectedYear)
                            },
                            onSwipe: { delta in shiftMonth(by: delta) }
                        )
                        .id("\(selectedMonth)-\(selectedYear)")
                        .scaleEffect(padScale)
                        .frame(width: 340.5 * padScale, height: 402.1 * padScale)
                        
                        if isPlantingMode {
                            Text("Tap a tile to plant your flower")
                                .font(.system(size: 13 * padScale))
                                .foregroundColor(.secondary)
                                .padding(.top, 8 * padScale)
                        }
                        
                        Spacer()
                            .frame(height: 40 * padScale)
                    }
                    .onChange(of: isPlantingMode) { newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                    proxy.scrollTo("gardenSection", anchor: .center)
                                }
                            }
                        } else {
                            // Refresh stats when planting mode ends (flower was planted)
                            refreshStats()
                        }
                    }
                }
            }
            .onAppear {
                refreshStats()
            }
            .fullScreenCover(isPresented: $showBreathingSession) {
                BreathingSessionView(onAddToGarden: {
                    showBreathingSession = false
                    isPlantingMode = true
                })
            }
            
            if showMonthPicker {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showMonthPicker = false
                        }
                    }
                    .zIndex(1)
                
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 40 * padScale, height: 5 * padScale)
                            .padding(.top, 12 * padScale)
                        
                        MonthPickerView(selectedDate: $selectedDate, isPresented: $showMonthPicker)
                            .padding(.bottom, isPad ? 0 : 30)
                    }
                    .frame(maxWidth: isPad ? 400 * padScale : .infinity)
                    .background(Color("Surface"))
                    .cornerRadius(24 * padScale)
                    .padding(.bottom, isPad ? 20 * padScale : 0)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
    }
    
    private func refreshStats() {
        totalFlowers = BreathingStats.totalFlowersPlanted()
        totalMinutes = BreathingStats.totalCalmMinutes()
        streak = BreathingStats.currentStreak()
    }
}

struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    private let gregorian = Calendar(identifier: .gregorian)
    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
    private let years: [Int]

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var padScale: CGFloat { isPad ? 1.5 : 1.0 }

    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented

        let cal = Calendar(identifier: .gregorian)
        let currentYear = cal.component(.year, from: Date())
        self.years = Array((currentYear - 5)...(currentYear + 5))

        let month = cal.component(.month, from: selectedDate.wrappedValue)
        let year = cal.component(.year, from: selectedDate.wrappedValue)
        self._selectedMonth = State(initialValue: month)
        self._selectedYear = State(initialValue: year)
    }
    
    var body: some View {
        VStack(spacing: 10 * padScale) {
            Text("Select Month")
                .font(.system(size: 17 * padScale, weight: .semibold))
                .padding(.top, 10 * padScale)
            
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
            .scaleEffect(padScale)
            .frame(width: 250 * padScale, height: 160 * padScale)
            
            Button("Done") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    updateDate()
                    isPresented = false
                }
            }
            .font(.system(size: 17 * padScale, weight: .semibold))
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandGreen"))
            .padding(.bottom, 20 * padScale)
        }
        .padding(.horizontal, 20 * padScale)
    }
    
    private func updateDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        if let newDate = gregorian.date(from: components) {
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
        .environmentObject(AuthManager())
}
