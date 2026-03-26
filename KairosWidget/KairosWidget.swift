import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct KairosEntry: TimelineEntry {
    var date: Date
    var data: KairosWidgetData?

    static var current: KairosEntry {
        KairosEntry(date: .now, data: KairosWidgetData.load())
    }

    static var placeholder: KairosEntry {
        KairosEntry(date: .now, data: .placeholder)
    }
}

// MARK: - Timeline Provider

struct KairosWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> KairosEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (KairosEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .current)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KairosEntry>) -> Void) {
        let entry   = KairosEntry.current
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Small Widget

struct KairosSmallWidget: Widget {
    let kind = "KairosSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KairosWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
                .widgetURL(URL(string: "kairos://pulse"))
        }
        .configurationDisplayName("Pulse")
        .description("Energy level and year progress at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium Widget

struct KairosMediumWidget: Widget {
    let kind = "KairosMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KairosWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
                .widgetURL(URL(string: "kairos://pulse"))
        }
        .configurationDisplayName("Year Overview")
        .description("Progress across all life domains.")
        .supportedFamilies([.systemMedium])
    }
}
