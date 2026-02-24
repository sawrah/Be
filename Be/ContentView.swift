import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showInstruction = false
    @State private var showBreathInstruction = false
    @State private var shouldDropPetals = false
    
    @StateObject private var micMonitor = MicMonitor()

    var body: some View {
        ZStack {
            ARViewContainer(onPlaced: {
                withAnimation(.easeOut(duration: 0.5)) {
                    showInstruction = false
                }
                
                // Wait 3 seconds then show breath instruction
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        showBreathInstruction = true
                    }
                    micMonitor.startMonitoring()
                }
            }, shouldDropPetals: $shouldDropPetals)
            .edgesIgnoringSafeArea(.all)
            
            if showInstruction {
                VStack {
                    Spacer()
                    Text("Please place the flower on a surface")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
            
            if showBreathInstruction {
                VStack {
                    Spacer()
                    Text(micMonitor.isBlowing ? "Great! Keep blowing!" : "Blow to make petals fall")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
                .transition(.opacity)
                .onChange(of: micMonitor.isBlowing) { oldValue, newValue in

                    
                    // Trigger when blowing STARTS (transitions from false to true)
                    if !oldValue && newValue {
                        shouldDropPetals = true
                        
                        // Reset the trigger after a brief moment so it can fire again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            shouldDropPetals = false
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                showInstruction = true
            }
        }
    }
}

#Preview {
    ContentView()
}
