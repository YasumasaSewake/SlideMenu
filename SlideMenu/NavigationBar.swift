//
//  NavigationBar.swift
//
//  Created by Yasumasa Sewake on 2016/04/23.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation
import UIKit

class NavigationBar : UIView
{
  var effect : UIBlurEffect?
  var effectView : UIVisualEffectView?
  var leftButton : UIButton?
  var title      : UILabel?

  static let navigationBarHeight : CGFloat = 44.0
  
  var statubBarHeight : CGFloat {
    get {
      return UIApplication.sharedApplication().statusBarFrame.size.height
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
    
    self._init()
  }
  
  override init(frame: CGRect) {
    super.init(frame:frame)
    self._init()
  }
  
  private func _init()
  {
    self.title = UILabel(frame:CGRectZero)
    self.title!.text = "title"
    self.title!.font = UIFont.systemFontOfSize(20.0)
    self.title!.sizeToFit()
    
    self.effect = UIBlurEffect(style:.ExtraLight)
    self.effectView = UIVisualEffectView(effect: effect)
  }
  
  override func willMoveToWindow(newWindow: UIWindow?)
  {
    self.addSubview(self.effectView!)
    self.effectView!.addSubview(self.title!)
  }
  
  override func layoutSubviews()
  {
    var center = self.center
    center.y += statubBarHeight / 2
    
    self.title!.center = center
    self.effectView!.frame = CGRectMake(0, 0, self.width, statubBarHeight + NavigationBar.navigationBarHeight)
  }
  
//MARK:public
  func contentView() -> UIView
  {
    return self.effectView!
  }
}