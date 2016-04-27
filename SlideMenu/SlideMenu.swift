//
//  SlideMenu.swift
//
//  Created by Yasumasa Sewake on 2016/04/23.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation
import UIKit

enum Direction
{
  case None
  case Open
  case Close
}

protocol SlideMenuDelegate {
  func updatePosition( position : CGFloat )
}

class SlideMenu : UIView
{
  let baseAreaCoef  : CGFloat = 0.70 // 幅の70%がスライドメニューの大きさ
  let touchAreaCoef : CGFloat = 0.05 // 幅の10%が触れるエリア
  let touchView     : UIView  = UIView()
  
  var xPos           : CGFloat = 0.0
  var xOriginAtTouch : CGFloat = 0.0
  var panGesture     : UIPanGestureRecognizer?
  var tapGesture     : UITapGestureRecognizer?
  
  var _layoutOnce    : dispatch_once_t = 0
  var updateDelegate : SlideMenuDelegate?
  var displayLink    : CADisplayLink?
  var direction      : Direction = .None
  
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
    self.backgroundColor = UIColor.greenColor()

    touchView.backgroundColor = UIColor.clearColor()

    panGesture = UIPanGestureRecognizer(target:self, action:#selector(SlideMenu._panGesture(_:)))
    touchView.addGestureRecognizer(panGesture!)

    tapGesture = UITapGestureRecognizer(target:self, action:#selector(SlideMenu._tapGesture(_:)))
    touchView.addGestureRecognizer(tapGesture!)

    self._initDisplayLink()
  }
  
  override func layoutSubviews()
  {
    super.layoutSubviews()
    
    let baseSize = self.frame.size
    xPos =  baseSize.width * baseAreaCoef

    let navigationHeight = NavigationBar.navigationBarHeight + 20
    
    self.frame = CGRectMake( -xPos, navigationHeight, baseSize.width * baseAreaCoef, baseSize.height - navigationHeight)
    self.touchView.frame = CGRectMake(0, navigationHeight, baseSize.width * self.touchAreaCoef, baseSize.height - navigationHeight)
  }
  
  override func willMoveToWindow(newWindow: UIWindow?)
  {
    self.superview!.addSubview(self.touchView)
  }
  
//MARK:public
  func open()
  {
    self.direction = .Open
    self._startDisplayLink()
  }
  
  func close()
  {
    self.direction = .Close
    self._startDisplayLink()
  }
  
//MARK:private
  func _tapGesture(sender: UIPanGestureRecognizer)
  {
    self.close()
  }
  
  func _panGesture(sender: UIPanGestureRecognizer)
  {
    if sender.state == .Began
    {
      self._began(sender)
    }
    else if sender.state == .Changed
    {
      self._changed(sender)
    }
    else if sender.state == .Ended
    {
      self._ended(sender)
    }
  }
  
  func _began(sender:UIPanGestureRecognizer)
  {
    xOriginAtTouch  = _xOriginAtTouchView(sender)
    
    if self._isOpen() == true
    {
      xOriginAtTouch -= touchView.width
    }
    
    self.direction = .None // 開くとも閉じるとも
    self._startDisplayLink()
  }
  
  func _changed(sender:UIPanGestureRecognizer)
  {
    // スクリーン座標を元に計算する
    let xOrigin  : CGFloat  = _xOriginAtWindow(sender)
    
    let moveTo = -xPos + xOrigin - xOriginAtTouch
    
    // 移動上限チェック
    if ( moveTo > 0.0 ) {
      return
    }
    
    // 移動
    self.xOrigin = moveTo
  }

  func _ended(sender:UIPanGestureRecognizer)
  {
    // 座標によってどちら(open/close)に寄せるか決める
    if self.xOrigin > -xPos / 2
    {
      self.open()
    }
    else
    {
      self.close()
    }
  }
  
  private func _initDisplayLink()
  {
    self.displayLink = CADisplayLink.init(target:self, selector:#selector(SlideMenu._displayRefresh(_:)))
    self.displayLink?.frameInterval = 1
    self.displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode:NSRunLoopCommonModes)
    self.displayLink?.paused = true
  }
  
  func _startDisplayLink()
  {
    // 少し過剰な気もするが、画面更新に適当なタイミングがないのでDisplayLinkを使用する
    self.displayLink?.paused = false
  }
  
  func _stopDisplayLink()
  {
    self.displayLink?.paused = true
  }
  
  func _displayRefresh(displayLink:CADisplayLink)
  {
    var raito : CGFloat = 1 + self.xOrigin/xPos
    
    // 上下限の確認
    if ( raito < 0 || 1 < raito ) {
      return;
    }
    
    if ( self.direction != .None )
    {
      let stop = self._moveTo(self.direction) as Bool
      if stop == true
      {
        raito = self.direction == .Open ? 1 : 0
        self.direction = .None
      }
    }

    // 通知
    self.updateDelegate?.updatePosition(raito)
  }
  
  func _moveTo( direction : Direction ) -> Bool
  {
    let distance : CGFloat = 10.0
    let xCurrent : CGFloat = self.xOrigin
    
    // open/close なら
    if direction == .Open
    {
      if xCurrent + distance < 0
      {
        self.xOrigin += distance
      }
      else
      {
        self.xOrigin = 0
        self.touchView.frame = self.frame
        self._stopDisplayLink()
        return true
      }
    }
    else if direction == .Close
    {
      if xCurrent - distance < -xPos
      {
        let baseSize = self.frame.size

        self.xOrigin = -xPos
        self.touchView.frame = CGRectMake(0, 0, baseSize.width * self.touchAreaCoef, baseSize.height)
        self._stopDisplayLink()
        return true
      }
      else
      {
        self.xOrigin -= distance
      }
    }
    
    return false
  }
  
  func _xOriginAtWindow(sender:UIPanGestureRecognizer) -> CGFloat
  {
    let window : UIWindow = (UIApplication.sharedApplication().delegate!.window)!!
    let pt  : CGPoint  = sender.locationOfTouch(0, inView:window)

    return pt.x
  }
  
  func _xOriginAtTouchView(sender:UIPanGestureRecognizer) -> CGFloat
  {
    var pt : CGPoint = CGPointZero
    pt = sender.locationInView(touchView)

    return pt.x
  }
  
  func _isOpen() -> Bool
  {
    if Float(fabs(self.xOrigin)) < FLT_EPSILON
    {
      return true
    }
    
    return false
  }
  
}