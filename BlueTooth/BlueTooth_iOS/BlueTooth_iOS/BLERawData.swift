//
//  BLERawData.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Foundation

class BLERawData
{
  static let maxTransferSize = (512)
  
  var data           : NSData? = nil
  var _currentPacket : Int = 0
  
  var numOfPackets : Int {
    get {
      let remnant : Int = data!.length % BLERawData.maxTransferSize
      return data!.length / BLERawData.maxTransferSize + Int(remnant > 0 ? 1 : 0)
    }
  }
  
  var currentPacket : Int {
    get {
      return _currentPacket
    }
  }
  
  init()
  {
    reset()
  }
  
  func reset()
  {
    _currentPacket = -1
  }
  
  func getPacketData( offset: Int ) -> NSData
  {
    var value : NSData
    
    // 一番初めのgetPacetDtaではなく、offset 0 が場合はパケットを次に進めていい
    if offset == 0
    {
      _currentPacket += 1
    }
    
    let dataOffset = _currentPacket * BLERawData.maxTransferSize
    let cutLength  = BLERawData.maxTransferSize - offset
    var cutRange : NSRange = NSMakeRange( offset + dataOffset, cutLength )
    
    if cutRange.location + cutRange.length > data?.length
    {
      let remain = data!.length - cutRange.location
      cutRange.length = remain
    }
    
    print("getPacketData:\(cutRange)")
    
    value = data!.subdataWithRange( cutRange )
    
    return value
  }
  
  
  
}