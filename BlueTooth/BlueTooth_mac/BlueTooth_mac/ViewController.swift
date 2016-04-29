//
//  ViewController.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import Cocoa
import CoreBluetooth

class MainViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate
{
  let maxTransferSize = (512)
  
  var serviceUUID        : CBUUID = CBUUID(string:"8BC13A59-87F8-492D-A952-AEABA4B80496")
  let characteristicUUID_notify  = CBUUID(string: "E398090E-3592-44FA-9EC9-CE835111FCFF")
  let characteristicUUID_rawData = CBUUID(string: "26477304-5B13-4D04-8103-918AB4DCDED9")
  
  var centralManager          : CBCentralManager!
  var peripherals             : [CBPeripheral] = []
  var characteristic_notify   : CBCharacteristic?
  var characteristic_rawData  : CBCharacteristic?
  var validPeripheral         : CBPeripheral?
  var imageData               : NSMutableData = NSMutableData()

  var index           : UInt8 = 0
  var length          : Int32 = 0
  
  @IBOutlet weak var imageScrollView: ImageScrollView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  @IBOutlet weak var tranfer: NSTextField!
  @IBOutlet weak var state: NSTextField!
  
  override func viewDidLoad()
  {
    super.viewDidLoad()

    // 初期化
    centralManager = CBCentralManager(delegate:self, queue:dispatch_get_main_queue())   
  }

  override func viewDidDisappear()
  {
    super.viewDidDisappear()
    centralManager.stopScan()
  }
  
  override var representedObject: AnyObject?
  {
    didSet
    {
      // Update the view, if already loaded.
    }
  }
}

// MARK: - CBCentralManagerDelegate Delgate
extension MainViewController {
  
  func centralManagerDidUpdateState(central: CBCentralManager)
  {
    switch( central.state )
    {
    case CBCentralManagerState.Unknown:
      print("state:Unknown")
    case CBCentralManagerState.Resetting:
      print("state:Resetting")
    case CBCentralManagerState.Unsupported:
      print("state:Unsupported")
    case CBCentralManagerState.Unauthorized:
      print("state:Unauthorized")
    case CBCentralManagerState.PoweredOff:
      print("state:PoweredOff")
    case CBCentralManagerState.PoweredOn:
      // サービスのUUIDを指定してスキャン開始
      centralManager.scanForPeripheralsWithServices([self.serviceUUID], options:nil)
      state.stringValue = "state:PoweredOn　ペリフェラルのスキャンを開始"
    }
  }
  
  // スキャン結果を受信し続ける
  func centralManager(central: CBCentralManager,
                      didDiscoverPeripheral peripheral: CBPeripheral,
                      advertisementData: [String : AnyObject],
                      RSSI: NSNumber)
  {
    print("スキャン中")

    // 未接続だったら
    if (peripheral.state == CBPeripheralState.Disconnected ) {
      // 端末のデリゲートフック用
      peripheral.delegate = self

      // 接続要求をしたものは保存しておく
      peripherals.append(peripheral)
      centralManager.connectPeripheral(peripheral, options:nil)
    }
  }

  // ペリフェラルへの接続が成功すると呼ばれる
  func centralManager(central: CBCentralManager,
                      didConnectPeripheral peripheral: CBPeripheral)
  {
    state.stringValue = "接続に成功しました: \(peripheral.name)"
    peripheral.discoverServices([self.serviceUUID])
    
    // スキャン停止
    centralManager.stopScan()
  }

  // ペリフェラルへの接続が失敗すると呼ばれる
  func centralManager(central: CBCentralManager,
                      didFailToConnectPeripheral peripheral: CBPeripheral,
                                                  error: NSError?)
  {
    state.stringValue = "接続に成功しました: \(peripheral.name)"
    peripherals.removeAll(keepCapacity:false)
  }

  func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices:[CBService])
  {
    state.stringValue = "ペリフェラルのGATTが更新されました"
    self.self.validPeripheral = nil
    
    peripheral.discoverServices([self.serviceUUID])
  }
  
  func peripheral(peripheral: CBPeripheral,
                  didDiscoverServices error: NSError?) {
    
    if let error = error {
      print("error: \(error)")
      return
    }

    if (peripheral.services!.count == 0
     && peripheral.state == CBPeripheralState.Connected ) {
      // サービスのUUIDが一致していて、接続済みだがサービス自体がない場合は、接続が切れていると見なして、スキャンからやり直し
      // 消費電力に最善ではないが、Macなのであまり気にしない
      centralManager.scanForPeripheralsWithServices([self.serviceUUID], options:nil)
      state.stringValue = "ペリフェラルの再スキャンを開始"
      return;
    }

    state.stringValue = "サービスが見つかりました"
    
    let services = peripheral.services
    for service in services! {
      if service.UUID.isEqual(self.serviceUUID) {
        peripheral.discoverCharacteristics([self.characteristicUUID_notify], forService:service)
        peripheral.discoverCharacteristics([self.characteristicUUID_rawData], forService:service)
        state.stringValue = "キャラクタリスティックの検索開始を要求"
      }
    }
  }

  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service:CBService, error:NSError?) {

    if let error = error {
      print("error: \(error)")
      return
    }
  
    // 見つかった時の処理
    let characteristics = service.characteristics
    for characteristic in characteristics! {
      if characteristic.UUID.isEqual(self.characteristicUUID_notify)
      || characteristic.UUID.isEqual(self.characteristicUUID_rawData)
      {
        print("...キャラクタリスティックのUUIDの一致を確認：\(characteristic)")
        state.stringValue = "データ更新通知の受け取りを開始を要求"
        peripheral.setNotifyValue(true, forCharacteristic:characteristic)
      }
    }
  }
  
  func peripheral(peripheral: CBPeripheral,
                  didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic,
                                                              error:NSError?)
  {
    if let error = error {
      print("...データ更新通知の受け取りを開始できませんでした: \(error)")
      state.stringValue = "...データ更新通知の受け取りを開始できませんでした: \(error)"
    }
    else {
      print("<<<データ更新通知の受け取りを開始します>>>")
      state.stringValue = "データ更新通知の受け取りを開始"
      
      // characteristic を保存 (再接続で使用)
      if characteristic.UUID.isEqual(self.characteristicUUID_notify)
      {
        self.characteristic_notify = characteristic
      }

      
      if characteristic.UUID.isEqual(self.characteristicUUID_rawData)
      {
        self.characteristic_rawData = characteristic
      }
      
      
      self.validPeripheral = peripheral
    }
  }

  func peripheral(peripheral: CBPeripheral,
                  didUpdateValueForCharacteristic characteristic:CBCharacteristic,
                                                  error: NSError?)
  {
    state.stringValue = "データを受信中..."
    
    if let error = error {
      print("Read/Notify通知通知エラー: \(error)")
      state.stringValue = "Read/Notify通知通知エラー"
      return
    }

    if characteristic.UUID.isEqual(characteristicUUID_notify)
    {
      imageData.length = 0 // clear
      
      var buffer = [UInt8](count:4, repeatedValue:0)
      characteristic.value!.getBytes(&buffer, range:NSRange(location:0, length:1))
      self.index = fromByteArray(buffer, UInt8.self)
      let index : Int = Int(self.index)
      imageScrollView.imageViews[index].image = nil
      
      
      imageScrollView.setIndex(Int(self.index))
      
      characteristic.value!.getBytes(&buffer, range:NSRange(location:4, length:4))
      self.length = fromByteArray(buffer, Int32.self)
      progressIndicator.maxValue = Double(self.length)
  
      print("index:\(index):length\(length)")
      
      self.validPeripheral?.readValueForCharacteristic(self.characteristic_rawData!)
    }
    else if characteristic.UUID.isEqual(characteristicUUID_rawData)
    {
      imageData.appendData(characteristic.value!)
      print("recive:\(imageData.length)")
      progressIndicator.doubleValue = Double(imageData.length)
  
      tranfer.stringValue = String("\(imageData.length)/\(self.length) bytes")
      
      let length = characteristic.value!.length
      if length == self.maxTransferSize
      {
        self.validPeripheral?.readValueForCharacteristic(self.characteristic_rawData!)
      }
      else
      {
        let index : Int = Int(self.index)
        imageScrollView.imageViews[index].image = NSImage(data:imageData)
        
        let buffer = [UInt8](count:1, repeatedValue:0xFF)
        let dummy : NSData = NSData(bytes:buffer, length:1)
        self.validPeripheral?.writeValue(dummy, forCharacteristic:self.characteristic_notify!, type:.WithoutResponse)
        state.stringValue = "画像の受信が終了しました"
      }
    }
  }
  
  func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
    return value.withUnsafeBufferPointer {
      return UnsafePointer<T>($0.baseAddress).memory
    }
  }
  
  func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
  {
    if let error = error {
      print("Writeに失敗: \(error)")
      return;
    }
    
    print("Writeの通知 characteristic UUID: \(characteristic.UUID), value: \(characteristic.value)")
  }

}

