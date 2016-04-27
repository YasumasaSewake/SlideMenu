//
//  ArrowButton.swift
//
//  Created by Yasumasa Sewake on 2016/04/23.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation
import UIKit

enum DispState {
  case Arrow
  case threeLine
  case None
}

class ArrowButton : UIButton, SlideMenuDelegate {
  
  var ratio : CGFloat = 0
  var full  : CGFloat = 0
  var half  : CGFloat = 0
  var quarter : CGFloat = 0
  var offset : CGFloat = 0

  var dispState : DispState = .threeLine
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!

    self._init()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self._init()
  }
  
  func _init()
  {
    // 回転中は、自身の大きさが変わるので基準となる幅をとっておく
    full    = self.width * 0.6
    half    = full / 2
    quarter = half / 2
    
    offset  = self.width * 0.2
  }
  
  func motion(ratio:CGFloat)
  {
    self._updateDispState(ratio)
    
    self.ratio = ratio
    self.layer.setNeedsDisplay()

    var angle : CGFloat = ratio
    if self.dispState == .Arrow && (Float(fabs(ratio - 1.0)) > FLT_EPSILON)
    {
      angle = 1 + ( 1 - ratio )
    }
    
    var transform = CATransform3DMakeScale(1.0 - 0.2 * self.ratio, 1.0 - 0.2 * self.ratio, 1.0) // 縮小
    transform = CATransform3DRotate(transform, angle * CGFloat(M_PI), 0.0, 0.0, 1.0);           // 回転
    self.layer.transform = transform
  }
  
  func _updateDispState(ratio : CGFloat )
  {
    if Float(fabs(ratio - 1.0)) < FLT_EPSILON
    {
      self.dispState = .Arrow
      print("size:\(self.frame.size)")
    }
    else if Float(fabs(ratio)) < FLT_EPSILON
    {
      self.dispState = .threeLine
    }
  }
  
  override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
    
    // クリアカラーで塗りつぶし
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.0);
    CGContextFillRect(ctx, self.bounds)
    
    self._topLine(ctx)
    self._midLine(ctx)
    self._botLine(ctx)
  }

  func _topLine(ctx: CGContext)
  {
    let start = CGPointMake(offset+half*self.ratio, offset+quarter - quarter*self.ratio)
    let end   = CGPointMake(offset+full, offset+quarter + quarter*self.ratio)
    
    self._drawLine( ctx, startPoint: start, endPoint: end )
  }

  func _botLine(ctx: CGContext)
  {
    let start = CGPointMake(offset + half*self.ratio, offset+half+quarter + quarter*self.ratio)
    let end   = CGPointMake(offset+full, offset+half+quarter - quarter*self.ratio)

    self._drawLine( ctx, startPoint: start, endPoint: end )
  }

  func _midLine(ctx: CGContext)
  {
    let start = CGPointMake( offset, offset+half)
    let end   = CGPointMake( offset+full, offset+half)
    
    self._drawLine( ctx, startPoint: start, endPoint: end )
  }
  
  func _drawLine( ctx: CGContext, startPoint : CGPoint, endPoint : CGPoint )
  {
    let path : CGMutablePath = CGPathCreateMutable()
    
    CGContextSetLineWidth(ctx, 3.0);
    
    // 線の色を指定
    CGContextSetStrokeColorWithColor(ctx, UIColor.grayColor().CGColor);
    
    // 丸く
    CGContextSetLineCap(ctx, .Round);
    
    // 線を引く
    CGPathMoveToPoint(path,    nil, startPoint.x, startPoint.y) // 始まりの点
    CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)     // 終わりの点
    CGPathCloseSubpath(path)                    // 線を閉じる
    
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
  }
  
  override func drawRect(rect: CGRect) {
  }
  
  func updatePosition( position : CGFloat )
  {
    self.motion(position)
  }
}