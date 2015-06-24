//
//  ServiceSelectorActionSheet.swift
//  Prototype
//
//  Created by Cameron Pulsford on 2/27/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

import UIKit

class ServiceSelectorActionSheet {

    private let actionSheet: SCUActionSheet
    private let services: [ServiceItem]

    init(services: [SAVService], room: SAVRoom?) {
        if services.count == 0 {
            fatalError("There should have been at least one service")
        }

        self.services = parseServices(services, room)

        actionSheet = SCUActionSheet(title: nil, buttonTitles: map(self.services, { $0.title }), cancelTitle: NSLocalizedString("Cancel", comment: ""), destructiveTitle: nil)
        actionSheet.maximumTableHeightPercentage = 0.75
        actionSheet.showTableSeparatorLines = true
        actionSheet.titleFont = Fonts.caption1
        actionSheet.titleTextColor = SCUColors.shared().color03shade06

        actionSheet.buttonFont = Fonts.body
        actionSheet.buttonTextColor = Colors.color1shade1
        actionSheet.buttonTextSelectedColor = SCUColors.shared().color01

        actionSheet.cancelButtonFont = Fonts.caption1
        actionSheet.cancelTextColor = SCUColors.shared().color03shade06

        actionSheet.cancelBackgroundSelectedColor = UIColor.clearColor()
        actionSheet.buttonBackgroundColor = UIColor.clearColor()
        actionSheet.buttonBackgroundSelectedColor = UIColor.clearColor()
        actionSheet.cancelBackgroundColor = UIColor.clearColor()
        actionSheet.separatorColor = UIColor.clearColor()

        let gradient = SCUGradientView(frame: CGRectZero, andColors: [SCUColors.shared().color03.colorWithAlphaComponent(0.1), SCUColors.shared().color03])
        gradient.locations = [0, 0.8]
        actionSheet.maskingView = gradient

        actionSheet.callback = { index in
            if index >= 0 {
                if let service = self.services[index].service {
                    interfaceCoordinator?.transitionToState(.Service(service))
                }
            }

            self.actionSheet.callback = nil
        }
    }

    func present() {
        actionSheet.showInView(RootViewController.view)
    }

}

private class ServiceItem {
    private var title = "Unknown"
    private var service: SAVService!
}

private func parseServices(services: [SAVService], room: SAVRoom?) -> [ServiceItem] {
    var sortedServices = [SAVService]()
    let servicesGroupedByComponent = groupBy(services) { $0.component! }

    for key in sorted(servicesGroupedByComponent.keys) {
        if let unsortedServices = servicesGroupedByComponent[key] {
            sortedServices += sorted(unsortedServices) {
                $0.uniquePresentableName.lowercaseString < $1.uniquePresentableName.lowercaseString
            }
        }
    }

    return map(sortedServices, { (service) -> ServiceItem in
        let item = ServiceItem()

        if let title = service.alias {
            if let roomName = service.zoneName where room == nil {
                item.title = "\(title) - \(roomName)"
            } else {
                item.title = title
            }
        }

        item.service = service
        return item
    })
}
