//
//  UIView+Extension.swift
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import UIKit

extension UIView
{
  var xOrigin: CGFloat {
    get {
      return frame.origin.x
    }
    set {
      var frame = self.frame
      frame.origin.x = newValue
      self.frame = frame
      }
  }

  var yOrigin: CGFloat {
    get {
      return frame.origin.y
    }
    set {
      var frame = self.frame
      frame.origin.y = newValue
      self.frame = frame
    }
  }

  var width: CGFloat {
    get {
      return frame.size.width
    }
    set {
      var frame = self.frame
      frame.size.width = newValue
      self.frame = frame
    }
  }

  var height: CGFloat {
    get {
      return frame.size.height
    }
    set {
      var frame = self.frame
      frame.size.height = newValue
      self.frame = frame
    }
  }
    
  var size: CGSize {
    get {
      return frame.size
    }
    set {
      var frame = self.frame
      frame.size = newValue
      self.frame = frame
    }
  }
}
