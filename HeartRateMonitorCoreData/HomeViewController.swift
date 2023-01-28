//
//  ViewController.swift
//  HeartRateMonitorCoreData
//
//  Created by Hiago Santos Martins Dias on 27/01/23.
//

import CoreBluetooth
import UIKit
import CoreData

let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")


class HRMViewController: UIViewController {

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var isPoweredOn = false
    var arrayData = [HeartRateDataItem]()
    
    @IBOutlet weak var heartRateLabel: UILabel!
    
    
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    
    
    @IBAction func connectButtonClicked(_ sender: Any) {
        if isPoweredOn {
            centralManager.connect(heartRatePeripheral)
        } else {
            print("cannot connect")
        }
        
    }
    
    @IBAction func disconnectButtonClicked(_ sender: Any) {
        if isPoweredOn {
            if heartRatePeripheral.state == .connected {
                centralManager.cancelPeripheralConnection(heartRatePeripheral)
            } else {
                print("peripheral not connected")
            }
            
        } else {
            print("pheripheral not connected")
        }
        
        
    }
    

  override func viewDidLoad() {
    super.viewDidLoad()
    //resetAllRecords(in: "HeartRateDataItem")
      
    centralManager = CBCentralManager(delegate: self, queue: nil)
      
    
    heartRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: heartRateLabel.font!.pointSize, weight: .regular)
      
      getAllItems()
      
  }

  func onHeartRateReceived(_ heartRate: Int) {
    heartRateLabel.text = String(heartRate)
    print("BPM: \(heartRate)")
  }
    
    // MARK: CORE DATA
    
    func getAllItems() {
        do {
            arrayData = try context.fetch(HeartRateDataItem.fetchRequest())
            
            DispatchQueue.main.async {
                //self.homeTableView.reloadData()
                print(self.arrayData)
            }
        }
        
        catch {
            print("error")
        }
    }
    
    func createItem(bpm: String) {
        // Check if the new bpm value is different from the last value in the arrayData
        if arrayData.count == 0 || arrayData.last!.bpm != bpm {
            let newItem = HeartRateDataItem(context: context)
            newItem.bpm = bpm
            arrayData.append(newItem)
            do {
                try context.save()
            } catch {
                print("error")
            }
        }
    }

    
    func resetAllRecords(in HeartRateDataItem : String)
        {
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: HeartRateDataItem)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            do
            {
                try context.execute(deleteRequest)
                try context.save()
            }
            catch
            {
                print ("There was an error")
            }
        }
    
    
}

extension HRMViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            isPoweredOn = true
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
        @unknown default:
            print("ERROR")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print(peripheral)
        //print(RSSI)
        heartRatePeripheral = peripheral
        heartRatePeripheral.delegate = self
        centralManager.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Disconnection failed with error: \(error!.localizedDescription)")
        } else {
            print("Disconnected successfully")
        }
    }
}

extension HRMViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            //print(characteristic)
            
            if characteristic.properties.contains(.notify) {
              print("\(characteristic.uuid): properties contains .notify")
              peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
      switch characteristic.uuid {
      case heartRateMeasurementCharacteristicCBUUID:
        let bpm = heartRate(from: characteristic)
        onHeartRateReceived(bpm)
        createItem(bpm: String(bpm))
      default:
        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        // Heart Rate Value Format is in the 2nd byte
        return Int(byteArray[1])
      } else {
        // Heart Rate Value Format is in the 2nd and 3rd bytes
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }

    
}

