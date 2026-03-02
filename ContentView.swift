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
            
            // Tab 1 — Heading and Compass
            VStack(spacing: 40) {
                
                if let heading = currentHeading {
                    Text(String(format: "%.1f°", heading))
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                    
                    CompassView(heading: heading)
                        .frame(width: 300, height: 300)
                } else {
                    Text("--")
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                }
            }
            .tabItem {
                Label("Heading", systemImage: "location.north")
            }
            
            // Tab 2 — Existing View
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

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct CompassView: View {
    var heading: Double
    
    var body: some View {
        ZStack {
            
            // Outer circle
            Circle()
                .stroke(Color.black, lineWidth: 3)
            
            // Cardinal letters
            GeometryReader { geo in
                let size = geo.size.width
                let radius = size / 2
                
                ZStack {
                    Text("N")
                        .position(x: radius, y: 30)
                    
                    Text("E")
                        .position(x: size - 30, y: radius)
                    
                    Text("S")
                        .position(x: radius, y: size - 30)
                    
                    Text("W")
                        .position(x: 30, y: radius)
                }
                .font(.system(size: 24, weight: .bold))
            }
            
            // Tick marks every 30 degrees
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 12)
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            // Needle (triangle)
            Triangle()
                .fill(Color.red)
                .frame(width: 20, height: 140)
                .offset(y: -70)
                // Adjust so 0° = North (top)
                .rotationEffect(.degrees(heading))
                .animation(.linear(duration: 0.1), value: heading)
        }
    }
}


