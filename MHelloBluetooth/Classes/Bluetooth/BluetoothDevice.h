//
//  PeripheralHelper.h
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

extern NSString * const BTDDeviceDidBindSuccessNotification;
extern NSString * const BTDDeviceUUIDStringNotificationUserInfoKey;
extern NSString * const BTDBluetoothKeyNotificationUserInfoKey;
extern NSString * const BTDDeviceDidUnbindNotification;

@interface BluetoothDevice : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *uuidString;
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(CBCentralManager *)centralManager;
- (void)bind;
- (void)unbind;
- (void)connect;
- (void)lock;
- (void)unlock;
- (NSString *)generateBluetoothDeviceKey;

- (void)disconnect;
@end
