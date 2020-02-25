//
//  Valet.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/17/17.
//  Copyright © 2017 Square, Inc.
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


/// Reads and writes keychain elements.
@objc(VALValet)
public final class Valet: NSObject {

    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    public class func valet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        findOrCreate(identifier, configuration: .valet(accessibility))
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    public class func iCloudValet(with identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(identifier, configuration: .iCloud(accessibility))
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: SharedAccessGroupIdentifier, accessibility: Accessibility) -> Valet {
        findOrCreate(identifier, configuration: .valet(accessibility))
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func iCloudSharedAccessGroupValet(with identifier: SharedAccessGroupIdentifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(identifier, configuration: .iCloud(accessibility))
    }

    #if os(macOS)
    /// Creates a Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    public class func valet(withExplicitlySet identifier: Identifier, accessibility: Accessibility) -> Valet {
        findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    public class func iCloudValet(withExplicitlySet identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }

    /// Creates a shared-access-group Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    public class func sharedAccessGroupValet(withExplicitlySet identifier: SharedAccessGroupIdentifier, accessibility: Accessibility) -> Valet {
        findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud-shared-access-group Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    public class func iCloudSharedAccessGroupValet(withExplicitlySet identifier: SharedAccessGroupIdentifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }
    #endif
    
    // MARK: Equatable
    
    /// - Returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: Valet, rhs: Valet) -> Bool {
        lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, Valet>.strongToWeakObjects()

    // MARK: Private Class Functions

    private class func findOrCreate(_ identifier: Identifier, configuration: Configuration) -> Valet {
        let service: Service = .standard(identifier, configuration)
        let key = service.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet = Valet(identifier: identifier, configuration: configuration)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    private class func findOrCreate(_ identifier: SharedAccessGroupIdentifier, configuration: Configuration) -> Valet {
        let service: Service = .sharedAccessGroup(identifier, configuration)
        let key = service.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet = Valet(sharedAccess: identifier, configuration: configuration)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }


    #if os(macOS)
    private class func findOrCreate(explicitlySet identifier: Identifier, configuration: Configuration) -> Valet {
        let service: Service = .standardOverride(service: identifier, configuration)
        let key = service.description + configuration.description + configuration.accessibility.description + identifier.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet = Valet(overrideIdentifier: identifier, configuration: configuration)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    private class func findOrCreate(explicitlySet identifier: SharedAccessGroupIdentifier, configuration: Configuration) -> Valet {
        let service: Service = .sharedAccessGroupOverride(service: identifier, configuration)
        let key = service.description + configuration.description + configuration.accessibility.description + identifier.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet = Valet(overrideSharedAccess: identifier, configuration: configuration)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    #endif
    
    // MARK: Initialization

    @available(*, unavailable)
    public override init() {
        fatalError("Use the class methods above to create usable Valet objects")
    }
    
    private convenience init(identifier: Identifier, configuration: Configuration) {
        self.init(
            identifier: identifier,
            service: .standard(identifier, configuration),
            configuration: configuration)
    }
    
    private convenience init(sharedAccess groupIdentifier: SharedAccessGroupIdentifier, configuration: Configuration) {
        self.init(
            identifier: groupIdentifier.asIdentifier,
            service: .sharedAccessGroup(groupIdentifier, configuration),
            configuration: configuration)
    }

    private init(identifier: Identifier, service: Service, configuration: Configuration) {
        self.identifier = identifier
        self.configuration = configuration
        self.service = service
        accessibility = configuration.accessibility
        baseKeychainQuery = service.generateBaseQuery()
    }

    #if os(macOS)
    private init(overrideIdentifier: Identifier, configuration: Configuration) {
        self.identifier = overrideIdentifier
        self.configuration = configuration
        service = .standardOverride(service: identifier, configuration)
        accessibility = configuration.accessibility
        baseKeychainQuery = service.generateBaseQuery()
    }

    private init(overrideSharedAccess identifier: SharedAccessGroupIdentifier, configuration: Configuration) {
        self.identifier = identifier.asIdentifier
        self.configuration = configuration
        service = .sharedAccessGroupOverride(service: identifier, configuration)
        accessibility = configuration.accessibility
        baseKeychainQuery = service.generateBaseQuery()
    }
    #endif

    // MARK: CustomStringConvertible

    public override var description: String {
        "\(super.description) \(identifier.description) \(configuration.prettyDescription)"
    }

    // MARK: Hashable
    
    public override var hash: Int {
        service.description.hashValue
    }
    
    // MARK: Public Properties
    
    @objc
    public let accessibility: Accessibility
    public let identifier: Identifier

    // MARK: Public Methods
    
    /// - Returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - Note: Determined by writing a value to the keychain and then reading it back out.
    @objc
    public func canAccessKeychain() -> Bool {
        execute(in: lock) {
            return Keychain.canAccess(attributes: baseKeychainQuery)
        }
    }

    /// - Parameters:
    ///   - object: A Data value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `object` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func setObject(_ object: Data, forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.setObject(object, forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameter key: A key used to retrieve the desired object from the keychain.
    /// - Returns: The data currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func object(forKey key: String) throws -> Data {
        try execute(in: lock) {
            try Keychain.object(forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - Throws: An error of type `KeychainError`.
    public func containsObject(forKey key: String) throws -> Bool {
        try execute(in: lock) {
            let status = Keychain.performCopy(forKey: key, options: baseKeychainQuery)
            switch status {
            case errSecSuccess:
                return true
            case errSecItemNotFound:
                return false
            default:
                throw KeychainError(status: status)
            }
        }
    }

    /// - Parameters:
    ///   - string: A String value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `string` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func setString(_ string: String, forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.setString(string, forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameter key: A key used to retrieve the desired object from the keychain.
    /// - Returns: The string currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func string(forKey key: String) throws -> String {
        try execute(in: lock) {
            try Keychain.string(forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// - Returns: The set of all (String) keys currently stored in this Valet instance. If no items are found, will return an empty set.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func allKeys() throws -> Set<String> {
        try execute(in: lock) {
            try Keychain.allKeys(options: baseKeychainQuery)
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - Parameter key: A key used to remove the desired object from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeObject(forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.removeObject(forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeAllObjects() throws {
        try execute(in: lock) {
            try Keychain.removeAllObjects(matching: baseKeychainQuery)
        }
    }

    /// Migrates objects matching the input query into the receiving Valet instance.
    /// - Parameters:
    ///   - query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) throws {
        try execute(in: lock) {
            try Keychain.migrateObjects(matching: query, into: baseKeychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects in the input Valet into the receiving Valet instance.
    /// - Parameters:
    ///   - valet: An objects whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(from valet: Valet, removeOnCompletion: Bool) throws {
        try migrateObjects(matching: valet.baseKeychainQuery, removeOnCompletion: removeOnCompletion)
    }

    /// Call this method if your Valet used to have its accessibility set to `always`.
    /// This method migrates objects set on a Valet with the same type and identifier, but with its accessibility set to `always` (which was possible prior to Valet 4.0) to the current Valet.
    /// - Parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: Bool) throws {
        var keychainQuery = baseKeychainQuery

        #if os(macOS)
        if #available(OSX 10.15, *) {
            // Don't over-specify our query. We don't know if the values were written post-Catalina.
            keychainQuery[kSecUseDataProtectionKeychain as String] = nil
        }
        #endif

        keychainQuery[kSecAttrAccessible as String] = "dk" // kSecAttrAccessibleAlways, but with the value hardcoded to avoid a build warning.
        let accessibilityDescription = "AccessibleAlways"
        let serviceAttribute: String
        switch service {
        case let .sharedAccessGroup(sharedAccessGroupIdentifier, _):
            serviceAttribute = Service.sharedAccessGroup(with: configuration, identifier: sharedAccessGroupIdentifier, accessibilityDescription: accessibilityDescription)
        case .standard:
            serviceAttribute = Service.standard(with: configuration, identifier: identifier, accessibilityDescription: accessibilityDescription)
        #if os(macOS)
        case let .sharedAccessGroupOverride(sharedAccessGroupIdentifier, _):
            serviceAttribute = sharedAccessGroupIdentifier.description
        case .standardOverride:
            serviceAttribute = identifier.description
        #endif
        }
        keychainQuery[kSecAttrService as String] = serviceAttribute
        try migrateObjects(matching: keychainQuery, removeOnCompletion: removeOnCompletion)
    }

    /// Call this method if your Valet used to have its accessibility set to `alwaysThisDeviceOnly`.
    /// This method migrates objects set on a Valet with the same type and identifier, but with its accessibility set to `alwaysThisDeviceOnly` (which was possible prior to Valet 4.0) to the current Valet.
    /// - Parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: Bool) throws {
        var keychainQuery = baseKeychainQuery

        #if os(macOS)
        if #available(OSX 10.15, *) {
            // Don't over-specify our query. We don't know if the values were written post-Catalina.
            keychainQuery[kSecUseDataProtectionKeychain as String] = nil
        }
        #endif

        keychainQuery[kSecAttrAccessible as String] = "dku" // kSecAttrAccessibleAlwaysThisDeviceOnly, but with the value hardcoded to avoid a build warning.
        let accessibilityDescription = "AccessibleAlwaysThisDeviceOnly"
        let serviceAttribute: String
        switch service {
        case let .sharedAccessGroup(identifier, _):
            serviceAttribute = Service.sharedAccessGroup(with: configuration, identifier: identifier, accessibilityDescription: accessibilityDescription)
        case .standard:
            serviceAttribute = Service.standard(with: configuration, identifier: identifier, accessibilityDescription: accessibilityDescription)
        #if os(macOS)
        case .sharedAccessGroupOverride:
            serviceAttribute = Service.sharedAccessGroup(with: configuration, explicitlySetIdentifier: identifier, accessibilityDescription: accessibilityDescription)
        case .standardOverride:
            serviceAttribute = Service.standard(with: configuration, identifier: identifier, accessibilityDescription: accessibilityDescription)
        #endif
        }
        keychainQuery[kSecAttrService as String] = serviceAttribute
        try migrateObjects(matching: keychainQuery, removeOnCompletion: removeOnCompletion)
    }

    #if os(macOS)
    /// Migrates objects that were written to this Valet prior to macOS 10.15 to a format that can be read on macOS 10.15 and later. The new format is backwards compatible, allowing these values to be read on older operating systems.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @available(macOS 10.15, *)
    @objc
    public func migrateObjectsFromPreCatalina() throws {
        var keychainQuery = baseKeychainQuery
        keychainQuery[kSecUseDataProtectionKeychain as String] = false

        // We do not need to remove these items on completion, since we are updating the kSecUseDataProtectionKeychain attribute in-place.
        try migrateObjects(matching: keychainQuery, removeOnCompletion: false)
    }
    #endif

    // MARK: Internal Properties

    internal let configuration: Configuration
    internal let service: Service
    internal let baseKeychainQuery: [String : AnyHashable]

    // MARK: Private Properties

    private let lock = NSLock()
}


// MARK: - Objective-C Compatibility


extension Valet {

    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithIdentifier:accessibility:)
    public class func 🚫swift_vanillaValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, accessibility: accessibility)
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes iCloud-shared keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithIdentifier:accessibility:)
    public class func 🚫swift_iCloudValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return iCloudValet(with: identifier, accessibility: accessibility)
    }

    /// - Parameters:
    ///   - appIDPrefix: The application's App ID prefix. This string can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - identifier: An identifier that cooresponds to a value in keychain-access-groups in the application's Entitlements file. This string must not be empty.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    @available(swift, obsoleted: 1.0)
    @objc(sharedAccessGroupValetWithAppIDPrefix:sharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_vanillaSharedAccessGroupValet(appIDPrefix: String, nonEmptyIdentifier identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = SharedAccessGroupIdentifier(appIDPrefix: appIDPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes iCloud-shared keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithAppIDPrefix:sharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_iCloudSharedAccessGroupValet(appIDPrefix: String, nonEmptyIdentifier identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = SharedAccessGroupIdentifier(appIDPrefix: appIDPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return iCloudSharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }

    #if os(macOS)
    /// Creates a Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    @available(swift, obsoleted: 1.0)
    @objc(valetWithExplicitlySetIdentifier:accessibility:)
    public class func 🚫swift_valet(withExplicitlySet identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithExplicitlySetIdentifier:accessibility:)
    public class func 🚫swift_iCloudValet(withExplicitlySet identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }

    /// Creates a shared-access-group Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - appIDPrefix: The application's App ID prefix. This string can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    @available(swift, obsoleted: 1.0)
    @objc(valetWithAppIDPrefix:explicitlySetSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_sharedAccessGroupValet(appIDPrefix: String, withExplicitlySet identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = SharedAccessGroupIdentifier(appIDPrefix: appIDPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud-shared-access-group Valet with an explicitly set kSecAttrService.
    /// - Parameters:
    ///   - appIDPrefix: The application's App ID prefix. This string can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - Warning: Using an explicitly set kSecAttrService bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.
    /// - SeeAlso: https://github.com/square/Valet/issues/140
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithAppIDPrefix:explicitlySetSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_iCloudSharedAccessGroupValet(appIDPrefix: String, withExplicitlySet identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = SharedAccessGroupIdentifier(appIDPrefix: appIDPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }
    #endif

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise. Will return `false` if the keychain is not accessible.
    /// - Note: Will never prompt the user for Face ID, Touch ID, or password.
    @available(swift, obsoleted: 1.0)
    @objc(containsObjectForKey:)
    public func 🚫swift_containsObject(forKey key: String) -> Bool {
        guard let containsObject = try? containsObject(forKey: key) else {
            return false
        }
        return containsObject
    }

}

// MARK: - Testing

internal extension Valet {

    // MARK: Permutations

    class func permutations(with identifier: Identifier) -> [Valet] {
        Accessibility.allCases.map { accessibility in
            .valet(with: identifier, accessibility: accessibility)
        }
    }

    class func permutations(with identifier: SharedAccessGroupIdentifier) -> [Valet] {
        Accessibility.allCases.map { accessibility in
            .sharedAccessGroupValet(with: identifier, accessibility: accessibility)
        }
    }

    class func iCloudPermutations(with identifier: Identifier) -> [Valet] {
        CloudAccessibility.allCases.map { cloudAccessibility in
            .iCloudValet(with: identifier, accessibility: cloudAccessibility)
        }
    }

    class func iCloudPermutations(with identifier: SharedAccessGroupIdentifier) -> [Valet] {
        CloudAccessibility.allCases.map { cloudAccessibility in
            .iCloudSharedAccessGroupValet(with: identifier, accessibility: cloudAccessibility)
        }
    }

    #if os(macOS)
    class func permutations(withExplictlySet identifier: Identifier, shared: Bool = false) -> [Valet] {
        Accessibility.allCases.map { accessibility in
            .valet(withExplicitlySet: identifier, accessibility: accessibility)
        }
    }

    class func permutations(withExplictlySet identifier: SharedAccessGroupIdentifier) -> [Valet] {
        Accessibility.allCases.map { accessibility in
            .sharedAccessGroupValet(withExplicitlySet: identifier, accessibility: accessibility)
        }
    }

    class func iCloudPermutations(withExplictlySet identifier: Identifier, shared: Bool = false) -> [Valet] {
        CloudAccessibility.allCases.map { cloudAccessibility in
            .iCloudValet(withExplicitlySet: identifier, accessibility: cloudAccessibility)
        }
    }

    class func iCloudPermutations(withExplictlySet identifier: SharedAccessGroupIdentifier) -> [Valet] {
        CloudAccessibility.allCases.map { cloudAccessibility in
            .iCloudSharedAccessGroupValet(withExplicitlySet: identifier, accessibility: cloudAccessibility)
        }
    }
    #endif

}
