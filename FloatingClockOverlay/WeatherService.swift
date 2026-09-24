import Foundation
import CoreLocation
import SwiftUI

// MARK: - Weather Condition

enum WeatherCondition: String {
    case clear, cloudy, rain, snow, thunderstorm, fog, hot
}

// MARK: - Time of Day

enum TimeOfDay: String {
    case dawn, day, dusk, night

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<7:   return .dawn
        case 7..<18:  return .day
        case 18..<20: return .dusk
        default:      return .night
        }
    }
}

// MARK: - Weather Color Palette

struct WeatherPalette {
    let particle: Color
    let glow: Color
    let text: Color
    let secondary: Color
    let emoji: String

    static func palette(for condition: WeatherCondition, time: TimeOfDay) -> WeatherPalette {
        switch (condition, time) {
        // ── Clear ──────────────────────────────
        case (.clear, .dawn):
            return WeatherPalette(particle: Color(hex: "FF9E6C"), glow: Color(hex: "FFB88C"),
                                  text: Color(hex: "FFF5E6"), secondary: Color(hex: "FF7E45"), emoji: "🌅")
        case (.clear, .day):
            return WeatherPalette(particle: Color(hex: "FFD700"), glow: Color(hex: "FFA500"),
                                  text: .white, secondary: Color(hex: "FFE44D"), emoji: "☀️")
        case (.clear, .dusk):
            return WeatherPalette(particle: Color(hex: "E86F3A"), glow: Color(hex: "C44DFF"),
                                  text: Color(hex: "FFF0E0"), secondary: Color(hex: "FF6B9D"), emoji: "🌇")
        case (.clear, .night):
            return WeatherPalette(particle: Color(hex: "C0C0C0"), glow: Color(hex: "8899BB"),
                                  text: Color(hex: "E8F0FF"), secondary: Color(hex: "6677AA"), emoji: "🌙")

        // ── Hot ────────────────────────────────
        case (.hot, .dawn):
            return WeatherPalette(particle: Color(hex: "FF6B35"), glow: Color(hex: "FF4500"),
                                  text: Color(hex: "FFEECC"), secondary: Color(hex: "FF8C00"), emoji: "🌅")
        case (.hot, .day):
            return WeatherPalette(particle: Color(hex: "FF4500"), glow: Color(hex: "FF0000"),
                                  text: .white, secondary: Color(hex: "FFD700"), emoji: "🔥")
        case (.hot, .dusk):
            return WeatherPalette(particle: Color(hex: "FF3300"), glow: Color(hex: "CC2200"),
                                  text: Color(hex: "FFE8D0"), secondary: Color(hex: "FF6633"), emoji: "🌇")
        case (.hot, .night):
            return WeatherPalette(particle: Color(hex: "CC5500"), glow: Color(hex: "AA3300"),
                                  text: Color(hex: "FFD0A0"), secondary: Color(hex: "884400"), emoji: "🌙")

        // ── Rain ───────────────────────────────
        case (.rain, .dawn):
            return WeatherPalette(particle: Color(hex: "7BAFD4"), glow: Color(hex: "FF9E6C"),
                                  text: Color(hex: "E8F0FF"), secondary: Color(hex: "A0C8E8"), emoji: "🌦")
        case (.rain, .day):
            return WeatherPalette(particle: Color(hex: "4A90D9"), glow: Color(hex: "6BAED6"),
                                  text: .white, secondary: Color(hex: "7CB9E8"), emoji: "🌧")
        case (.rain, .dusk):
            return WeatherPalette(particle: Color(hex: "6A7FBB"), glow: Color(hex: "9966CC"),
                                  text: Color(hex: "E8E0F0"), secondary: Color(hex: "8877AA"), emoji: "🌧")
        case (.rain, .night):
            return WeatherPalette(particle: Color(hex: "5577AA"), glow: Color(hex: "334466"),
                                  text: Color(hex: "C8D8F0"), secondary: Color(hex: "445588"), emoji: "🌧")

        // ── Snow ───────────────────────────────
        case (.snow, .dawn):
            return WeatherPalette(particle: Color(hex: "FFE0E0"), glow: Color(hex: "FFB0A0"),
                                  text: Color(hex: "FFF5F0"), secondary: Color(hex: "FFCCBB"), emoji: "🌨")
        case (.snow, .day):
            return WeatherPalette(particle: .white, glow: Color(hex: "B0D4F1"),
                                  text: .white, secondary: Color(hex: "E0F0FF"), emoji: "❄️")
        case (.snow, .dusk):
            return WeatherPalette(particle: Color(hex: "E8D0E8"), glow: Color(hex: "CC88BB"),
                                  text: Color(hex: "F0E8F0"), secondary: Color(hex: "DDAACC"), emoji: "🌨")
        case (.snow, .night):
            return WeatherPalette(particle: Color(hex: "B8C8E0"), glow: Color(hex: "6688AA"),
                                  text: Color(hex: "D8E8FF"), secondary: Color(hex: "8899BB"), emoji: "❄️")

        // ── Thunderstorm ───────────────────────
        case (.thunderstorm, .dawn):
            return WeatherPalette(particle: Color(hex: "7090B0"), glow: Color(hex: "FFEE55"),
                                  text: Color(hex: "E0E8F0"), secondary: Color(hex: "8888CC"), emoji: "⛈")
        case (.thunderstorm, .day):
            return WeatherPalette(particle: Color(hex: "4A6080"), glow: Color(hex: "FFD700"),
                                  text: .white, secondary: Color(hex: "6688AA"), emoji: "⛈")
        case (.thunderstorm, .dusk):
            return WeatherPalette(particle: Color(hex: "555588"), glow: Color(hex: "EEDD44"),
                                  text: Color(hex: "E0D8F0"), secondary: Color(hex: "776699"), emoji: "⛈")
        case (.thunderstorm, .night):
            return WeatherPalette(particle: Color(hex: "334466"), glow: Color(hex: "FFFF88"),
                                  text: Color(hex: "C0D0E8"), secondary: Color(hex: "445566"), emoji: "⛈")

        // ── Cloudy ─────────────────────────────
        case (.cloudy, .dawn):
            return WeatherPalette(particle: Color(hex: "DDBBAA"), glow: Color(hex: "FFAA77"),
                                  text: Color(hex: "FFF0E0"), secondary: Color(hex: "CCAA99"), emoji: "⛅")
        case (.cloudy, .day):
            return WeatherPalette(particle: Color(hex: "CCCCCC"), glow: Color(hex: "AABBCC"),
                                  text: .white, secondary: Color(hex: "BBBBCC"), emoji: "☁️")
        case (.cloudy, .dusk):
            return WeatherPalette(particle: Color(hex: "AA8899"), glow: Color(hex: "CC77AA"),
                                  text: Color(hex: "F0E0E8"), secondary: Color(hex: "9977AA"), emoji: "☁️")
        case (.cloudy, .night):
            return WeatherPalette(particle: Color(hex: "667788"), glow: Color(hex: "445566"),
                                  text: Color(hex: "C8D0E0"), secondary: Color(hex: "556677"), emoji: "☁️")

        // ── Fog ────────────────────────────────
        case (.fog, .dawn):
            return WeatherPalette(particle: Color(hex: "DDCCBB"), glow: Color(hex: "FFBB88"),
                                  text: Color(hex: "FFF0E0"), secondary: Color(hex: "CCBBAA"), emoji: "🌫")
        case (.fog, .day):
            return WeatherPalette(particle: Color(hex: "CCCCCC"), glow: Color(hex: "AAAAAA"),
                                  text: .white, secondary: Color(hex: "BBBBBB"), emoji: "🌫")
        case (.fog, .dusk):
            return WeatherPalette(particle: Color(hex: "998888"), glow: Color(hex: "886688"),
                                  text: Color(hex: "E8E0E0"), secondary: Color(hex: "887788"), emoji: "🌫")
        case (.fog, .night):
            return WeatherPalette(particle: Color(hex: "556666"), glow: Color(hex: "334455"),
                                  text: Color(hex: "C0D0D8"), secondary: Color(hex: "445555"), emoji: "🌫")
        }
    }
}

// MARK: - Weather Service

final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    @Published var condition: WeatherCondition = .clear
    @Published var temperature: Int = 0
    @Published var timeOfDay: TimeOfDay = .day
    @Published var isLoaded = false

    var palette: WeatherPalette {
        WeatherPalette.palette(for: condition, time: timeOfDay)
    }

    private let locationManager = CLLocationManager()
    private var lastFetch: Date = .distantPast
    private var timeUpdateTimer: Timer?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        timeOfDay = TimeOfDay.current
    }

    func startIfNeeded() {
        timeOfDay = TimeOfDay.current
        if timeUpdateTimer == nil {
            timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.timeOfDay = TimeOfDay.current
            }
        }
        guard Date().timeIntervalSince(lastFetch) > 600 else { return }
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        locationManager.stopUpdatingLocation()
        fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fetchWeather(lat: 43.65, lon: -79.38)
    }

    private func fetchWeather(lat: Double, lon: Double) {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&timezone=auto"
        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let current = json["current"] as? [String: Any] {
                    let temp = (current["temperature_2m"] as? Double) ?? 0
                    let code = (current["weather_code"] as? Int) ?? 0
                    DispatchQueue.main.async {
                        self.temperature = Int(temp)
                        self.condition = Self.mapCode(code, temp: temp)
                        self.isLoaded = true
                        self.lastFetch = Date()
                    }
                }
            } catch {}
        }.resume()
    }

    private static func mapCode(_ code: Int, temp: Double) -> WeatherCondition {
        switch code {
        case 0, 1:          return temp > 32 ? .hot : .clear
        case 2, 3:          return .cloudy
        case 45, 48:        return .fog
        case 51...67:       return .rain
        case 71...77:       return .snow
        case 80...82:       return .rain
        case 85, 86:        return .snow
        case 95, 96, 99:    return .thunderstorm
        default:            return .clear
        }
    }
}
