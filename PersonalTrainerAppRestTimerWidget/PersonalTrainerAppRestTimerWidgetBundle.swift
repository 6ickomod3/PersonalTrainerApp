//
//  PersonalTrainerAppRestTimerWidgetBundle.swift
//  PersonalTrainerAppRestTimerWidget
//
//  Created by Ji Dai on 11/30/25.
//

import WidgetKit
import SwiftUI

@main
struct PersonalTrainerAppRestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PersonalTrainerAppRestTimerWidget()
        PersonalTrainerAppRestTimerWidgetControl()
        PersonalTrainerAppRestTimerWidgetLiveActivity()
    }
}
