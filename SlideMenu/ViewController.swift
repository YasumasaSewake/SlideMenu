//
//  ViewController.swift
//
//  Created by Yasumasa Sewake on 2016/04/23.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import UIKit

class ViewController: UIViewController {

  var arrowButton : ArrowButton?
  var slideMenu   : SlideMenu?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self._initSubviews()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func _initSubviews()
  {
    self.view.backgroundColor = UIColor.lightGrayColor()
    
    // スライドメニュー
    self.slideMenu = SlideMenu(frame: self.view.frame)
    self.view.addSubview(slideMenu!)

    // 矢印ボタン
    let oneSide : CGFloat  = NavigationBar.navigationBarHeight
    arrowButton = ArrowButton(frame:CGRectMake(10, 20, oneSide, oneSide ))
    arrowButton!.addTarget(self, action:#selector(ViewController.buttonTapped(_:)), forControlEvents:.TouchUpInside)

    // ナビゲーションバー
    let rect : CGRect = CGRectMake(0, 0, self.view.frame.width, 62)
    let navigationBar : NavigationBar = NavigationBar(frame:rect)
    self.view.addSubview(navigationBar)

    navigationBar.contentView().addSubview(arrowButton!)
    slideMenu!.updateDelegate = arrowButton
  }
  
  func buttonTapped(sender: UIButton)
  {
    print("buttonTapped")
    if arrowButton?.dispState == .Arrow
    {
      slideMenu!.close()
    }
    else
    {
      slideMenu!.open()
    }
  }
  
  
}

