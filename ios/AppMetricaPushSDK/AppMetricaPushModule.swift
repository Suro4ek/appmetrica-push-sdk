import Foundation
import React
import AppMetricaPush

@objc(AppMetricaPushModule)
class AppMetricaPushModule: NSObject, RCTBridgeModule {
    
    // MARK: - RCTBridgeModule Protocol
    
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    static func moduleName() -> String! {
        return "AppMetricaPushModule"
    }
    
    // MARK: - Initialization (Deprecated - use AppMetricaPushInitializer)
    
    @objc
    func initialize(_ config: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let debugMode = config["debugMode"] as? Bool ?? false
        
        DispatchQueue.main.async {
            // Инициализация AppMetrica Push SDK теперь происходит в AppMetricaPushInitializer
            // Этот метод оставлен для обратной совместимости
            // Основная инициализация должна происходить в AppDelegate.swift
            
            if debugMode {
                print("AppMetrica Push SDK ready (initialization handled by AppMetricaPushInitializer)")
            }
            
            resolver(true)
        }
    }
    
    // MARK: - Notification Analysis
    
    @objc
    func isNotificationFromAppMetrica(_ notification: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            // Преобразуем NSDictionary в [AnyHashable : Any] для AppMetrica
            let notificationDict = notification as? [AnyHashable : Any] ?? [:]
            let isRelatedToAppMetricaSDK = AppMetricaPush.isNotificationRelated(toSDK: notificationDict)
            resolver(isRelatedToAppMetricaSDK)
        }
    }
    
    // MARK: - SDK Information
    
    @objc
    func getSDKInfo(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let info: [String: Any] = [
                "version": "3.2.0",
                "platform": "ios",
                "sdkName": "AppMetrica Push SDK",
                "libraryVersion": "1.0.0"
            ]
            resolver(info)
        }
    }
    
    // MARK: - User Data Extraction
    
    @objc
    func getUserData(_ notification: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            // Преобразуем NSDictionary в [AnyHashable : Any] для AppMetrica
            let notificationDict = notification as? [AnyHashable : Any] ?? [:]
            // Получаем дополнительную информацию из push-уведомления согласно документации
            let userData = AppMetricaPush.userData(forNotification: notificationDict)
            resolver(userData)
        }
    }
    
}

