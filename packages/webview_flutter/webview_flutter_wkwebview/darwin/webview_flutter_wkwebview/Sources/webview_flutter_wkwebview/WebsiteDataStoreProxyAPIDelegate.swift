// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

/// ProxyApi implementation for `WKWebsiteDataStore`.
///
/// This class may handle instantiating native object instances that are attached to a Dart instance
/// or handle method calls on the associated native class or an instance of that class.
class WebsiteDataStoreProxyAPIDelegate: PigeonApiDelegateWKWebsiteDataStore {
  func defaultDataStore(pigeonApi: PigeonApiWKWebsiteDataStore) -> WKWebsiteDataStore {
    return WKWebsiteDataStore.default()
  }

  func initWithIdentifier(pigeonApi: PigeonApiWKWebsiteDataStore, identifier: String?) throws
    -> WKWebsiteDataStore
  {
    if #available(iOS 17.0, *) {
      var uuid: UUID
      if let id = identifier, let parsedUUID = UUID(uuidString: id) {
        uuid = parsedUUID
      } else {
        uuid = UUID()
      }
      let dataStore = WKWebsiteDataStore(forIdentifier: uuid)
      let config: WKWebViewConfiguration = WKWebViewConfiguration()
      config.websiteDataStore = dataStore
      return dataStore
    } else {
      // iOS 17 以下版本使用默认数据存储
      return WKWebsiteDataStore.default()
    }
  }

  func httpCookieStore(pigeonApi: PigeonApiWKWebsiteDataStore, pigeonInstance: WKWebsiteDataStore)
    -> WKHTTPCookieStore
  {
    return pigeonInstance.httpCookieStore
  }

  func removeDataOfTypes(
    pigeonApi: PigeonApiWKWebsiteDataStore, pigeonInstance: WKWebsiteDataStore,
    dataTypes: [WebsiteDataType], modificationTimeInSecondsSinceEpoch: Double,
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    let nativeDataTypes = Set(
      dataTypes.map {
        switch $0 {
        case .cookies:
          return WKWebsiteDataTypeCookies
        case .memoryCache:
          return WKWebsiteDataTypeMemoryCache
        case .diskCache:
          return WKWebsiteDataTypeDiskCache
        case .offlineWebApplicationCache:
          return WKWebsiteDataTypeOfflineWebApplicationCache
        case .localStorage:
          return WKWebsiteDataTypeLocalStorage
        case .sessionStorage:
          return WKWebsiteDataTypeSessionStorage
        case .webSQLDatabases:
          return WKWebsiteDataTypeWebSQLDatabases
        case .indexedDBDatabases:
          return WKWebsiteDataTypeIndexedDBDatabases
        }
      })

    pigeonInstance.fetchDataRecords(ofTypes: nativeDataTypes) { records in
      if records.isEmpty {
        completion(.success(false))
      } else {
        pigeonInstance.removeData(
          ofTypes: nativeDataTypes,
          modifiedSince: Date(timeIntervalSince1970: modificationTimeInSecondsSinceEpoch)
        ) {
          completion(.success(true))
        }
      }
    }
  }
}
