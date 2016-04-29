//
//  ImageScrollView.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//
import Foundation
import Cocoa

class ImageScrollView : NSScrollView
{
  static let maxPage = 3
  var imageViews : [NSImageView] = []
  
  required init?(coder: NSCoder) {
    super.init(coder:coder)
    
    // maxPage 分のコンテンツサイズを取る
    let size = CGSizeMake( self.frame.width * CGFloat(ImageScrollView.maxPage), self.frame.height)
    self.documentView!.setFrameSize(size)
    
    for i in 0...ImageScrollView.maxPage
    {
      let frame = CGRectMake( CGFloat(i) * self.frame.width, 0, self.frame.width, self.frame.height )
      let iamgeView = NSImageView(frame:frame)
      
      self.documentView!.addSubview(iamgeView)
      imageViews.append(iamgeView)
    }
  }
  
  func setIndex( index : Int )
  {
    let xPos : CGFloat = CGFloat(index) * self.frame.width
    
    // アニメーションさせながらスクロール
    NSAnimationContext.beginGrouping()
    let clipView : NSClipView = self.contentView
    var newOrigin : CGPoint = clipView.bounds.origin
    newOrigin.x = xPos;
    clipView.animator().setBoundsOrigin(newOrigin)
    NSAnimationContext.endGrouping()
  }
  
}