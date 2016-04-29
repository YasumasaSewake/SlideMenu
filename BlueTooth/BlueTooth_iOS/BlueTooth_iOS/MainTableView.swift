//
//  MainTableView.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation
import UIKit

protocol MainTableViewDelegate
{
  func onSelect( indexRow : Int )
}

class MainTableView : UITableView, UITableViewDelegate, UITableViewDataSource
{
  var cellData : [NSData] = []
  var callback : MainTableViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
    
    self.delegate = self
    self.dataSource = self
 
    var path : String = NSBundle.mainBundle().pathForResource("-shared-img-thumb-ELFAIMG_4483_TP_V", ofType:"jpg")!
    var data : NSData =  NSData(contentsOfFile:path)!
    cellData.append(data)

    path = NSBundle.mainBundle().pathForResource("-shared-img-thumb-gohan151214258719_TP_V", ofType:"jpg")!
    data =  NSData(contentsOfFile:path)!
    cellData.append(data)

    path = NSBundle.mainBundle().pathForResource("-shared-img-thumb-PAK130608062166_TP_V", ofType:"jpg")!
    data =  NSData(contentsOfFile:path)!
    cellData.append(data)

    self.registerClass(UITableViewCell.self, forCellReuseIdentifier:"cell")
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    callback?.onSelect(indexPath.row)
  }
  
  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
  {
    return 62.0
  }

  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
  {
    return 100.0
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return cellData.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    
    let index = indexPath.row
    let data = cellData[index]

    cell.imageView!.contentMode = .ScaleAspectFit
    cell.imageView!.image = UIImage(data:data)
    cell.textLabel!.text = "送信"
    
    return cell
  }

  
}