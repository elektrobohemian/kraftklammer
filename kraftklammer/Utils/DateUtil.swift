//
//  DateUtil.swift
//  clipboard-manager
//
//  Created by Luca Nardelli on 28/03/25.
//
//  Modifications by David Zellhöfer (2026):
//  * preparations for localization
//  * added documentation
//

import Foundation

struct DateUtil {
    static func formatRelativeDate(from timestamp: Int) -> String {
        if timestamp == 0 {
            return ""
        }
        let calendar = Calendar.current
        let now = Date()
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        if calendar.isDateInToday(date) {
            return String(localized:"Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized:"Yesterday")
        } else {
            let components = calendar.dateComponents([.year, .month, .day], from: date, to: now)

            if let year = components.year, year > 0 {
                return year == 1 ? String(localized:"1 year ago") : String(localized:"\(year) years ago")
            } else if let month = components.month, month > 0 {
                return month == 1 ? String(localized:"1 month ago") : String(localized:"\(month) months ago")
            } else if let day = components.day, day > 0 {
                return day == 1 ? String(localized:"1 day ago") : String(localized:"\(day) days ago")
            } else {
                return String(localized:"Just now")
            }
        }
    }
}
