//
//  Device.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation
import UIKit

class Device : NSObject{
  static let sharedManager = Device()
  
  var name : String!
  
  override private init() {
    super.init()

    _update()
  }

//MARK:private
  private func _update() {
    self.name = UIDevice.currentDevice().name
    
  }
}