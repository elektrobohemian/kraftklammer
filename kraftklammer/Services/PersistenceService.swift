//
//  PersistenceService.swift
//  Rewrite of clipboard-manager's unencrypted DBService originally created by
//  Luca Nardelli under MIT license.
//
//  Major changes by David Zellhöfer (2026):
//  * data will be saved encrypted
//  * added a function to clear all items: deleteAll()
//  * max. entries are now read from UserDefaults.standard and can be altered in the UI
//  * improved monitoring of usage frequency (e.g.: hits are no longer created by clipboard copy...)
//  * repeatedly pasted items will now obtain the same SHA256 hash and not an arbitrary UUID in order to make usage freq. monitoring persistent
//  * items are now filtered by usage freq. (hits) and their timestamp
//


import Foundation
import CryptoKit
import Security

final class PersistenceService {
    
    static var items: [ClipItem] = []
    static var filteredItems: [ClipItem] = []
    static var filter: String = ""
    // load the maximum number of saved items from UserDefaults (changes are persistent)
    static var MAX_ENTRIES = UserDefaults.standard.integer(forKey: "maxHistoryEntries")
    // defines the length of the string to be displayed in the ClipList
    static let MAX_PREVIEW_LENGTH = 256
    // will be bound to ClipViewModel
    static var listener: () -> Void = {}
    
    // the key extracted from the keychain
    static var encryptionKey: SymmetricKey?
    
    /// Sorts all items by timestamp and usage frequency.
    /// Optionally, it will filter the items if a search term is passed.
    /// - Parameter searchTerm: A String used for filtering the result. If the parameter is empty, all items will be retrieved.
    static func filterSortItems(searchTerm: String = "") {
        self.filter = searchTerm.uppercased()
        filteredItems = items.filter({ item in return filter.count == 0 || item.value.uppercased().contains(filter) })
            .sorted(by: {
                // ensure that the last used/added item stays on top
                if $0.timestamp > $1.timestamp { return true }
                if $1.timestamp == items.first?.timestamp { return false }
                // then sort descending by hits
                if $0.hits != $1.hits {
                    return $0.hits > $1.hits
                }
                // ... and timestamp
                return $0.timestamp > $1.timestamp
            }) // sorting by usage frequency and timestamp
        listener()
    }
    
    // called from ContentView
    static func getItemValue(_ row: Int) -> String {
        let item = filteredItems[row]
        item.updateUsage()
        if let value = getAttachment(item.id) {
            return value
        }
        return item.value
    }
    // called from ClipRow
    static func getItemValue(_ item: ClipItem) -> String {
        item.updateUsage()
        if let value = getAttachment(item.id) {
            return value
        }
        return item.value
    }
    
    /// Adds a pasted item to the clipboard history
    /// - Parameter item: the text to be added to the clipboard history.
    static func addItem(_ item: String) {
        let displayedText = String(item.prefix(MAX_PREVIEW_LENGTH))
        // create a SHA256 hash as ID for the pasted string in order to de-duplicate entries and track usage
        let id = SHA256.hash(data: Data(item.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
        // create a new ClipItem
        var newItem = ClipItem(id: id, value: displayedText)
        // check existence of entry based on hash value
        if let existing = items.firstIndex(where: { item in return item.id == id}) {
            //newItem.hits = items[existing].hits + 1 // removed because a hit should count actual pastes and not copy events
            deleteAttachment(items[existing].id)
            items.remove(at: existing)
        }
        if item.count > MAX_PREVIEW_LENGTH {
            saveAttachment(id: id, item: item)
        }
        items.insert(newItem, at: 0)
        
        if items.count > MAX_ENTRIES {
            deleteAttachment(items[items.count - 1].id)
#if DEBUG
            print("[DEBUG] Limit of \(MAX_ENTRIES) entries exceeded. Entry will be removed: \(PersistenceService.getItemValue(items[items.count - 1]))")
#endif
            items.remove(at: items.count - 1)
        }
        filterSortItems()
        
        saveEncrypted()
    }
    
    /// Deletes an item from the clipboard history and removes its serialization from disk.
    /// - Parameter index: Index of the item to be deleted.
    static func deleteItem(_ index:Int) {
        deleteAttachment(items[index].id)
        items.remove(at: index)
        filterSortItems()
        saveEncrypted()
    }
    
    /// Deletes all items from the clipboard history and removes their serialization from disk.
    static func deleteAll() {
        var i=0
        for item in items {
            deleteAttachment(items[i].id)
            i+=1
        }
        items.removeAll()
        filterSortItems()
        saveEncrypted()
    }
    
    /// Deletes an attachment, i.e. its full content exceeding the MAX_PREVIEW_LENGTH of a given ClipItem, from disk.
    /// - Parameter id: The SHA256 hash of the ClipItem.
    static func deleteAttachment(_ id: String) {
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let fileUrl = docFolder.appendingPathComponent("clips").appendingPathComponent(id)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
            } catch {
                print(error)
            }
        }
    }
    
    /// Retrieves and decrypts an attachment, i.e. its full content exceeding the MAX_PREVIEW_LENGTH of a given ClipItem, from disk.
    /// - Parameter id: The SHA256 hash of the ClipItem.
    static func getAttachment(_ id: String) -> String? {
        // get the symmetric key initialized by initialize()
        let key=self.encryptionKey!
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return nil}
        let fileUrl = docFolder.appendingPathComponent("clips_safe").appendingPathComponent(id)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl);
                guard let box = try? AES.GCM.SealedBox(combined: data),
                      let decrypted = try? AES.GCM.open(box, using: key) else { return "" }
                return String(data: decrypted, encoding: .utf8) ?? ""
            } catch {
                print(error)
            }
        }
        return nil
    }
    
    /// Encrypts and saves an attachment, i.e. its full content exceeding the MAX_PREVIEW_LENGTH of a given ClipItem, to disk.
    /// - Parameters:
    ///   - id: The SHA256 hash of the ClipItem.
    ///   - item: The content to be saved.
    static func saveAttachment(id: String, item: String) {
        // get the symmetric key initialized by initialize()
        let key=self.encryptionKey!
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        var fileUrl = docFolder.appendingPathComponent("clips_safe")
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                try FileManager.default.createDirectory(at: fileUrl, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error)
            }
        }
        fileUrl = fileUrl.appendingPathComponent(id)
        do {
            let data = Data(item.utf8)
            let sealed = try? AES.GCM.seal(data, using: key).combined
            try sealed!.write(to: fileUrl)
            //try item.write(to: fileUrl, atomically: false, encoding: .utf8)
        } catch {
            print(error)
        }
    }
    
    ///
    /// Initializes the PersistenceService.
    static func initialize() {
        // get or create the key needed for encryption
        self.encryptionKey = getOrCreateKey()
        let key=self.encryptionKey!
        
        // open the data storage and decrypt it
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let fileUrl = docFolder.appendingPathComponent("history.safe")
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                let data = try Data(contentsOf: fileUrl);
                guard let box = try? AES.GCM.SealedBox(combined: data),
                      let decrypted = try? AES.GCM.open(box, using: key) else { return }
                let decoder = JSONDecoder()
                items = try decoder.decode([ClipItem].self, from: decrypted)
                filterSortItems()
            } catch {
                print(error)
            }
        }
    }
    /// Saves all items encrypted to disk.
    static func saveEncrypted() {
        // get the symmetric key initialized by initialize()
        let key=self.encryptionKey!
        // prepare the file for writing
        guard let docFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let fileUrl = docFolder.appendingPathComponent("history.safe")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            let sealed = try? AES.GCM.seal(data, using: key).combined
            try sealed!.write(to: fileUrl)
            //print("[DEBUG] Data saved to \(fileUrl)")
        } catch {
            print(error)
        }
    }
    
    
    /// Provides a symmetric key for encryption. If it does not exist, it will be created and stored in macOS' keychain.
    /// - Returns: The newly created or retrieved SymmetricKey from the keychain.
    static func getOrCreateKey() -> SymmetricKey {
        let keychainKey = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Current App"
        
        if let keyData = loadFromKeychain(key: keychainKey) {
            return SymmetricKey(data: Data(base64Encoded: keyData)!)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0).base64EncodedString() }
        saveToKeychain(key: keychainKey, value: keyData)
        return newKey
    }
    
    /// Stores a symmetric key in macOS' keychain.
    /// - Parameters:
    ///   - key: Name of the key.
    ///   - value: The actual key.
    static func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary) // altes löschen
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieves a symmetric key from macOS' keychain.
    /// - Parameter key: Name of the key.
    /// - Returns: The actual key.
    static func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
