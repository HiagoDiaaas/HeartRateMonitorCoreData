//
//  DetailViewController.swift
//  HeartRateMonitorCoreData
//
//  Created by Hiago Santos Martins Dias on 28/01/23.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var BPMTableView: UITableView!
    var arrayData = [HeartRateDataItem]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAllItems()
        BPMTableView.dataSource = self
        BPMTableView.delegate = self
        BPMTableView.reloadData()
    }
    
    func getAllItems() {
        do {
            arrayData = try context.fetch(HeartRateDataItem.fetchRequest())
            
            DispatchQueue.main.async {
                self.BPMTableView.reloadData()
            }
        }
        
        catch {
            print("error")
        }
    }
    
    
    
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bpmCell", for: indexPath)
            let data = arrayData[indexPath.row]

            cell.textLabel?.text = data.bpm
            return cell
    }
    
    
}
