//
//  SecureEnclaveValet.swift
//  Valet
//
//  Created by Dan Federman on 9/18/17.
//  Copyright © 2017 Square, Inc.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation


/// Reads and writes keychain elements that are stored on the Secure Enclave using Accessibility attribute `.whenPasscodeSetThisDeviceOnly`. Accessing these keychain elements will require the user to confirm their presence via Touch ID, Face ID, or passcode entry. If no passcode is set on the device, accessing the keychain via a `SecureEnclaveValet` will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device.
public final class SecureEnclaveValet: NSObject {
    
    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    /// - parameter flavor: A description of the SecureEnclaveValet's capabilities.
    /// - returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.standard(identifier, .secureEnclave(.alwaysPrompt(accessControl))).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(identifier: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter flavor: A description of the SecureEnclaveValet's capabilities.
    /// - returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.sharedAccessGroup(identifier, .secureEnclave(.alwaysPrompt(accessControl))).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(sharedAccess: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: SecureEnclaveValet, rhs: SecureEnclaveValet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, SecureEnclaveValet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, deprecated)
    public override init() {
        fatalError("Do not use this initializer")
    }
    
    private init(identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        service = .standard(identifier, .secureEnclave(SecureEnclave.Flavor.alwaysPrompt(accessControl)))
        keychainQuery = service.generateBaseQuery()
        self.identifier = identifier
        self.accessControl = accessControl
    }
    
    private init(sharedAccess identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        service = .sharedAccessGroup(identifier, .secureEnclave(SecureEnclave.Flavor.alwaysPrompt(accessControl)))
        keychainQuery = service.generateBaseQuery()
        self.identifier = identifier
        self.accessControl = accessControl
    }
    
    // MARK: Hashable
    
    public override var hashValue: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let identifier: Identifier
    public let accessControl: SecureEnclaveAccessControl
    
    // MARK: Public Methods
    
    /// - returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - note: Determined by writing a value to the keychain and then reading it back out. Will never prompt the user for Face ID, Touch ID, or password.
    public func canAccessKeychain() -> Bool {
        return SecureEnclave.canAccessKeychain(with: service, identifier: identifier)
    }
    
    /// - parameter object: A Data value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `object` from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @discardableResult
    public func set(object: Data, for key: Key) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.set(object: object, for: key, options: keychainQuery)
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `nil` if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
    public func object(for key: Key, withPrompt userPrompt: String) -> SecureEnclave.Result<Data> {
        return execute(in: lock) {
            return SecureEnclave.object(for: key, withPrompt: userPrompt, options: keychainQuery)
        }
    }
    
    /// - parameter key: The key to look up in the keychain.
    /// - returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - note: Will never prompt the user for Face ID, Touch ID, or password.
    public func containsObject(for key: Key) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.containsObject(for: key, options: keychainQuery)
        }
    }
    
    /// - parameter string: A String value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `string` from the keychain.
    /// @return NO if the keychain is not accessible.
    @discardableResult
    public func set(string: String, for key: Key) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.set(string: string, for: key, options: keychainQuery)
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    public func string(for key: Key, withPrompt userPrompt: String) -> SecureEnclave.Result<String> {
        return execute(in: lock) {
            return SecureEnclave.string(for: key, withPrompt: userPrompt, options: keychainQuery)
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @discardableResult
    public func removeObject(for key: Key) -> Bool {
        return execute(in: lock) {
            switch Keychain.removeObject(for: key, options: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @discardableResult
    public func removeAllObjects() -> Bool {
        return execute(in: lock) {
            switch Keychain.removeAllObjects(matching: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
        }
    }
    
    // MARK: Private Properties
    
    private let service: Service
    private let lock = NSLock()
    private let keychainQuery: [String : AnyHashable]
}