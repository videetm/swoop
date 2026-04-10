import ClockKit

final class ComplicationProvider: NSObject, CLKComplicationDataSource {

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let manager = WatchSessionManager.shared
        let score = Int(manager.readinessScore)
        let template: CLKComplicationTemplate

        switch complication.family {
        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallSimpleText()
            t.textProvider = CLKSimpleTextProvider(text: "\(score)")
            template = t
        case .modularSmall:
            let t = CLKComplicationTemplateModularSmallSimpleText()
            t.textProvider = CLKSimpleTextProvider(text: "\(score)")
            template = t
        case .graphicCorner:
            let t = CLKComplicationTemplateGraphicCornerStackText()
            t.outerTextProvider = CLKSimpleTextProvider(text: "RDY")
            t.innerTextProvider = CLKSimpleTextProvider(text: "\(score)")
            template = t
        default:
            handler(nil)
            return
        }

        handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
    }

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        handler([
            CLKComplicationDescriptor(
                identifier: "swoop.readiness",
                displayName: "SWOOP Readiness",
                supportedFamilies: [.circularSmall, .modularSmall, .graphicCorner]
            )
        ])
    }
}
