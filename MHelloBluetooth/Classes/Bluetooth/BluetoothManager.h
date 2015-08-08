//
//  BluetoothManager.h
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const BMFindDeviceNotification;
extern NSString * const BMDeviceNotificationUserInfoKey;
extern NSString * const BMScanFaildNotification;

@interface BluetoothManager : NSObject
+ (instancetype)sharedInstance;
- (void)scan;
- (void)cancelScan;
@end
