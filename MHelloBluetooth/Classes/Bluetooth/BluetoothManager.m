//
//  BluetoothManager.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "BluetoothManager.h"
#import "Device.h"

NSString * const BMFindDeviceNotification = @"BMFindDeviceNotification";
NSString * const BMDeviceNotificationUserInfoKey = @"BMDeviceNotificationUserInfoKey";
NSString * const BMScanFaildNotification = @"BMScanFaildNotification";

@implementation BluetoothManager
+ (instancetype)sharedInstance {
    static BluetoothManager *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [BluetoothManager new];
    });
    
    return s_instance;
}

//
- (void)scan {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL isSuccess = YES;//(arc4random() % 2 == 0);
        if (isSuccess) {
            Device *device = [Device new];
            device.name = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
            [[NSNotificationCenter defaultCenter] postNotificationName:BMFindDeviceNotification
                                                                object:nil
                                                              userInfo:@{BMDeviceNotificationUserInfoKey: device}];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:BMScanFaildNotification object:nil];
        }
    });
}

- (void)cancelScan {
    // TODO: 应该cancel
    // TODO: 通知应该指明是否cancel导致
    [[NSNotificationCenter defaultCenter] postNotificationName:BMScanFaildNotification object:nil];
}

@end
