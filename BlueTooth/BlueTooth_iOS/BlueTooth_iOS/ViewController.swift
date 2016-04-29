//
//  ViewController.swift
//
//  Created by Yasumasa Sewake on 2016/04/22.
//
//  Released under the MIT license
//  http://opensource.org/licenses/mit-license.php
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, CBPeripheralManagerDelegate, MainTableViewDelegate {
  var peripheralManager: CBPeripheralManager!
  var characteristic_notify   : CBMutableCharacteristic?
  var characteristic_rawData   : CBMutableCharacteristic?
  
  let serviceUUID = CBUUID(string: "8BC13A59-87F8-492D-A952-AEABA4B80496")
  let characteristicUUID_notify   = CBUUID(string: "E398090E-3592-44FA-9EC9-CE835111FCFF")
  let characteristicUUID_rawData = CBUUID(string: "26477304-5B13-4D04-8103-918AB4DCDED9")

  var bleRawData    : BLERawData = BLERawData()
  @IBOutlet weak var indicateView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

    self.characteristic_notify = CBMutableCharacteristic(
      type:characteristicUUID_notify,
      properties:[CBCharacteristicProperties.Write, CBCharacteristicProperties.Notify],
      value:nil,
      permissions:[CBAttributePermissions.Writeable, CBAttributePermissions.Readable])
    
    self.characteristic_rawData = CBMutableCharacteristic(
      type:characteristicUUID_rawData,
      properties:[CBCharacteristicProperties.Notify, CBCharacteristicProperties.Read],
      value:nil,
      permissions:[CBAttributePermissions.Readable])
    
    let mainTableView = self.view as! MainTableView
    mainTableView.callback = self
    
    self.enableView(false)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  func onSelect(indexRow: Int)
  {
    self.enableView(false)
    
    let mainTableView = self.view as! MainTableView
    
    bleRawData.reset()
    bleRawData.data = mainTableView.cellData[indexRow]
    
    var data : [UInt8] = [UInt8](count:4, repeatedValue:0)
    data[0] = UInt8(indexRow)

    let buffer : [UInt8] = toByteArray( (bleRawData.data?.length)! )
    data += buffer  // 8byte
    
    let sendData = NSData(bytes:data, length:8)
    peripheralManager.updateValue(sendData, forCharacteristic:self.characteristic_notify!, onSubscribedCentrals: nil)
  }
  
  func toByteArray<T>(value: T ) -> [UInt8] {
    var val : T = value
    return withUnsafePointer(&val) {
      Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
    }
  }
  
  func enableView( enable : Bool )
  {
    self.view.userInteractionEnabled = enable
    if enable == true
    {
      indicateView.hidden = true
    }
    else
    {
      indicateView.hidden = false
    }
  }
}

// MARK: - CBPeripheralManagerDelegate Delgate
extension MainViewController {
  
  func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
    
    switch(peripheral.state) {
    case CBPeripheralManagerState.Unknown:
      print("state:Unknown")
    case CBPeripheralManagerState.Resetting:
      print("state:Resetting")
    case CBPeripheralManagerState.Unsupported:
      print("state:Unsupported")
    case CBPeripheralManagerState.Unauthorized:
      print("state:Unauthorized")
    case CBPeripheralManagerState.PoweredOff:
      print("state:PoweredOff")
    case CBPeripheralManagerState.PoweredOn:
      print("state:PoweredOn")
      
      //アドバタイズ開始(見つけて通知)
      let name : String = Device.sharedManager.name!
      
      let advertisementData : [String : AnyObject] = [CBAdvertisementDataLocalNameKey:name, CBAdvertisementDataServiceUUIDsKey:[self.serviceUUID]]
      peripheralManager.startAdvertising(advertisementData) // 意図しない接続ぎれは、startAdvertisingから再度行う必要がある

      // サービス生成
      let service = CBMutableService(type: serviceUUID, primary: true)
      service.characteristics = [self.characteristic_notify!, self.characteristic_rawData!] // キャラクタリスクを指定
      peripheralManager.addService(service)
    }
  }
  
  //アドバタイズを開始した(非接続でもコールされる)
  func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
    
    if error == nil {
      print("PeripheralがAdvertisingを開始しました")
    } else {
      print("PeripheralがAdvertisingの開始に失敗しました\(error)")
    }
  }
  
  // サービス追加結果
  func peripheralManager(
                      peripheral : CBPeripheralManager,
            didAddService service: CBService,
                           error : NSError? )
  {
    if let error = error {
      print("サービスの追加に失敗 error: \(error)")
      return
    }
    
    print("サービスの追加に成功")
    // ここまで来てから、セントラルはサービスを検索できる
  }

  func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic)
  {
    print("Subscribeリクエストを受信")
    print("Subscribe中のセントラル: \(characteristic.service.UUID)")
    
    self.enableView(true)
  }

  func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic)
  {
    print("Notify停止リクエストを受信")
    print("Notify中のセントラル: \(characteristic.service.UUID)")
    
    self.enableView(true)
  }
  
  func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest)
  {
    if request.characteristic.UUID.isEqual(self.characteristicUUID_rawData) == false {
      // characteristicUUID が一致しない
      peripheralManager.respondToRequest(request, withResult:CBATTError.InvalidHandle)
    }
    
    if ( request.offset >= BLERawData.maxTransferSize ) {
      // 512byte以上は送れない
      peripheralManager.respondToRequest(request, withResult:CBATTError.InvalidOffset)
      return
    }

    // 適当な位置のデータを送信
    request.value = bleRawData.getPacketData(request.offset)
    peripheralManager.respondToRequest(request, withResult:CBATTError.Success)
  }

  func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest])
  {
    for request in requests {
      
      if request.characteristic.UUID.isEqual(self.characteristicUUID_notify) {
        print("Write Requestを受信:\(request.value)")
        self.enableView(true)
        peripheralManager.respondToRequest(requests[0], withResult: CBATTError.Success)
        return;
      }
    }
    
    // セントラルのdidWriteValueForCharacteristic がエラーになる
    peripheralManager.respondToRequest(requests[0], withResult: CBATTError.WriteNotPermitted)
  }
}

