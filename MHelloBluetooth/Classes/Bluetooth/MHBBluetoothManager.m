//
//  BluetoothManager.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "MHBBluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothDevice.h"
#import "BluetoothConstants.h"

NSString * const BMFindDeviceNotification = @"BMFindDeviceNotification";
NSString * const BMDeviceNotificationUserInfoKey = @"BMDeviceNotificationUserInfoKey";
//NSString * const BMScanFaildNotification = @"BMScanFaildNotification";

@interface MHBBluetoothManager ()<CBCentralManagerDelegate>
@property (nonatomic) CBCentralManager *centralManager;
@end

@implementation MHBBluetoothManager
+ (instancetype)sharedInstance {
    static MHBBluetoothManager *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [MHBBluetoothManager new];
    });
    
    return s_instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

//
- (void)scan {
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
     NSLog(@"开始扫描-self.centralManager(%@)", self.centralManager);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        BOOL isSuccess = YES;//(arc4random() % 2 == 0);
//        if (isSuccess) {
//            Device *device = [Device new];
//            device.name = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
//            [[NSNotificationCenter defaultCenter] postNotificationName:BMFindDeviceNotification
//                                                                object:nil
//                                                              userInfo:@{BMDeviceNotificationUserInfoKey: device}];
//        } else {
//            [[NSNotificationCenter defaultCenter] postNotificationName:BMScanFaildNotification object:nil];
//        }
//    });
}

- (void)cancelScan {
    [self.centralManager stopScan];
    // TODO: 应该cancel
    // TODO: 通知应该指明是否cancel导致
//    [[NSNotificationCenter defaultCenter] postNotificationName:BMScanFaildNotification object:nil];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"蓝牙状态: %d", central.state);
    // 检查状态
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙未启动");
    }
}

// 扫描后回调
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
//    DDLogInfo(@"peripheral(%@) advertisementData(%@)  %s", peripheral, advertisementData);
    BluetoothDevice *device = [[BluetoothDevice alloc] initWithPeripheral:peripheral centralManager:self.centralManager];
    [[NSNotificationCenter defaultCenter] postNotificationName:BMFindDeviceNotification
                                                        object:nil
                                                      userInfo:@{BMDeviceNotificationUserInfoKey:device}];
}

// 连接后
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DDLogInfo(@"连接成功peripheral(%@)", peripheral);
    [[NSNotificationCenter defaultCenter] postNotificationName:BTCDidConnectDeviceNotification
                                                        object:nil
                                                      userInfo:@{BTCPeripheralNotificationUserInfoKey:peripheral}];
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DDLogWarn(@"连接失败peripheral(%@) error(%@)", peripheral, error);
    [[NSNotificationCenter defaultCenter] postNotificationName:BTCDidConnectDeviceNotification
                                                        object:nil
                                                      userInfo:@{BTCPeripheralNotificationUserInfoKey:peripheral,
                                                                 BTCErrorNotificationUserInfoKey:[NSError new]}];
}

//// 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DDLogInfo(@"断开连接peripheral(%@) error(%@)", peripheral, error);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:peripheral forKey:BTCPeripheralNotificationUserInfoKey];
    if (error) {
        [userInfo setObject:error forKey:BTCErrorNotificationUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BTCDidDisconnectDeviceNotification
                                                        object:nil
                                                      userInfo:userInfo];
}


#pragma mark -
- (BluetoothDevice *)deviceForUUIDString:(NSString *)uuidString {
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc] initWithUUIDString:uuidString]]];
    if ([peripherals count] <= 0) {
        return nil;
    }
    
    return [[BluetoothDevice alloc] initWithPeripheral:[peripherals firstObject] centralManager:self.centralManager];
}

@end
