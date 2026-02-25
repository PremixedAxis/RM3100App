//
//  ContentView.swift
//  LearningApp
//
//  Created by Temporary Dev User on 1/23/26.
//
import SwiftUI

struct Sample: Identifiable {
    let id = UUID()
    let time: Double
    let x: Double
    let y: Double
    let z: Double
}

struct ContentView: View {
    @State private var allSamples: [Sample] = []
    @State private var visibleSamples: [Sample] = []
    @State private var index = 0

    var currentHeading: Double? {
        guard let s = visibleSamples.last else { return nil }
        
        let radians = atan2(s.y, s.x)
        var degrees = radians * 180 / .pi
        
        if degrees < 0 {
            degrees += 360
        }
        
        return degrees
    }


    var body: some View {
        TabView {
            
            // Tab 1 — Existing View
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    TelemetrySceneView(samples: visibleSamples)
                        .frame(height: 400)
                    
                    Text("3D RELATIVE ORIENTATION")
                        .font(.caption.bold())
                        .padding()
                        .background(.black.opacity(0.5))
                        .foregroundColor(.white)
                }
                
                Divider()
                
                ScrollViewReader { proxy in
                    List(visibleSamples) { sample in
                        HStack {
                            Text("t:" + String(format: "%6.1f", sample.time))
                                .frame(width: 80, alignment: .trailing)
                            Text("x:" + String(format: "%7.2f", sample.x))
                                .frame(width: 100, alignment: .trailing)
                            Text("y:" + String(format: "%7.2f", sample.y))
                                .frame(width: 100, alignment: .trailing)
                            Text("z:" + String(format: "%7.2f", sample.z))
                                .frame(width: 100, alignment: .trailing)
                        }
                        .font(.system(size: 14, design: .monospaced))
                        .id(sample.id)
                    }
                    .onChange(of: visibleSamples.count) {
                        if let last = visibleSamples.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .tabItem {
                Label("Telemetry", systemImage: "cube")
            }
            
            // Tab 2 — Heading Only
            VStack {
                if let heading = currentHeading {
                    Text(String(format: "%.1f°", heading))
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                } else {
                    Text("--")
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                }
            }
            .tabItem {
                Label("Heading", systemImage: "location.north")
            }
        }
        .onAppear {
            allSamples = loadCSV()
            startStreaming()
        }
    }



    func loadCSV() -> [Sample] {
        guard let url = Bundle.main.url(forResource: "telemetry", withExtension: "csv"),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }

        let lines = contents.split(separator: "\n").dropFirst()

        return lines.compactMap { line in
            let parts = line.split(separator: ",")
            guard parts.count == 4,
                  let t = Double(parts[0]),
                  let x = Double(parts[1]),
                  let y = Double(parts[2]),
                  let z = Double(parts[3])
            else { return nil }

            return Sample(time: t, x: x, y: y, z: z)
        }
    }

    func startStreaming() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard index < allSamples.count else {
                timer.invalidate()
                return
            }

            visibleSamples.append(allSamples[index])
            index += 1
        }
    }
}
