//
//  RecordStorage.swift
//  ShellGame
//
//  Created by Andrey Arzhannikov on 14.08.17.
//  Copyright © 2017 Handsome. All rights reserved.
//

import Foundation

class RecordStorage {
    
    static let shared = RecordStorage()
    
    private let recordKey = "record"
    private lazy var userDefaults = UserDefaults.standard
    
    private init(){}
    
    func save(record: Int) {
        userDefaults.set(record, forKey: recordKey)
        userDefaults.synchronize()
    }
    
    func load() -> Int {
        guard let recordString = userDefaults.string(forKey: recordKey),
            let record = Int(recordString) else {
                return 0
        }
        return record
    }
}
