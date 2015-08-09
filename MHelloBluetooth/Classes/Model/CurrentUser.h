//
//  CurrentUser.h
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/9.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrentUser : NSObject
@property (nonatomic, copy) NSString *bluetoothDeviceUUIDString;
@property (nonatomic, copy) NSString *bluetoothDeviceKey;
+ (instancetype)sharedInstance;
@end
