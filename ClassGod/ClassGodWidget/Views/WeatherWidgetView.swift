//
//  WeatherWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct WeatherWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }
    
    private var smallView: some View {
        ZStack {
            Color.black
            if weather.city.isEmpty {
                emptyView
            } else {
                VStack(spacing: 3) {
                    Image(systemName: weather.condition.rawValue)
                        .font(.system(size: 25))
                        .foregroundStyle(.cyan)
                    Text(temperatureText)
                        .font(.system(size: 19, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(weather.city)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                    Text(conditionText)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(8)
            }
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            if weather.city.isEmpty {
                emptyView
            } else {
                HStack(spacing: 14) {
                    Image(systemName: weather.condition.rawValue)
                        .font(.system(size: 34))
                        .foregroundStyle(.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(temperatureText)
                            .font(.system(size: 27, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(weather.city)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                        Text(conditionText)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        metricRow("WIDGET_FEELS_LIKE", value: formatted(weather.apparentTemperature))
                        metricRow("WIDGET_HIGH_LOW", value: "\(formatted(weather.high)) / \(formatted(weather.low))")
                        metricRow("WIDGET_HUMIDITY", value: "\(weather.humidity)%")
                        HStack(spacing: 3) {
                            Text("WIDGET_UPDATED")
                            Text(weather.updatedAt, style: .relative)
                        }
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.28))
                    }
                }
                .padding(12)
            }
        }
    }

    private var weather: WidgetWeatherSnapshot { entry.weather }

    private var temperatureText: String {
        "\(WidgetWeatherPolicy.temperatureText(weather.temperature, unit: weather.unit))\(weather.unit == .celsius ? "C" : "F")"
    }

    private func formatted(_ value: Double) -> String {
        "\(WidgetWeatherPolicy.temperatureText(value, unit: weather.unit))\(weather.unit == .celsius ? "C" : "F")"
    }

    private var conditionText: LocalizedStringKey {
        switch weather.condition {
        case .clearDay: "WIDGET_WEATHER_CLEAR"
        case .clearNight: "WIDGET_WEATHER_CLEAR_NIGHT"
        case .partlyCloudy: "WIDGET_WEATHER_PARTLY_CLOUDY"
        case .cloudy: "WIDGET_WEATHER_CLOUDY"
        case .rain: "WIDGET_WEATHER_RAIN"
        case .thunderstorm: "WIDGET_WEATHER_STORM"
        case .snow: "WIDGET_WEATHER_SNOW"
        case .fog: "WIDGET_WEATHER_FOG"
        case .wind: "WIDGET_WEATHER_WIND"
        }
    }

    private func metricRow(_ label: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .foregroundStyle(.white.opacity(0.72))
        }
        .font(.system(size: 8, design: .monospaced))
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 24))
                .foregroundStyle(.cyan.opacity(0.55))
            Text("WIDGET_WEATHER_NOT_CONFIGURED")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(10)
    }
}
