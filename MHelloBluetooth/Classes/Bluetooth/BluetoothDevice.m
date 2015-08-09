//
//  PeripheralHelper.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "BluetoothDevice.h"
#import "BluetoothConstants.h"
#import "CurrentUser.h"

NSString * const BTDDeviceDidBindSuccessNotification = @"BTDDeviceBindSuccessNotification";
NSString * const BTDBluetoothKeyNotificationUserInfoKey = @"BTDBluetoothKeyNotificationUserInfoKey";
NSString * const BTDDeviceUUIDStringNotificationUserInfoKey = @"BTDDeviceUUIDStringNotificationUserInfoKey";
NSString * const BTDDeviceDidUnbindNotification = @"BTDDeviceDidUnbindNotification";

static NSString * const kServiceUUIDString = @"000056ef-0000-1000-8000-00805f9b34fb";
static NSString * const kRequestCharacteristicUUIDString = @"000034e1-0000-1000-8000-00805f9b34fb";
static NSString * const kResponseCharacteristicUUIDString = @"000034e2-0000-1000-8000-00805f9b34fb";


@interface BluetoothDevice ()<CBPeripheralDelegate>
@property (nonatomic) CBPeripheral *peripheral;
@property (nonatomic, weak) CBCentralManager *centralManager;
@property (nonatomic) CBService *service;
@property (nonatomic) CBCharacteristic *requestCharacteristic;
@property (nonatomic) CBCharacteristic *responseCharacteristic;
@property (nonatomic) BOOL isVerifyByDefaultKey;
@property (nonatomic, copy) NSString *bluetoothKey;
@end

@implementation BluetoothDevice

- (instancetype)init {
    return [self initWithPeripheral:nil centralManager:nil];
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(CBCentralManager *)centralManager {
    self = [super init];
    if (self) {
        if (!peripheral || !centralManager) {
            return self;
        }
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _centralManager = centralManager;
        [self addNotifications];
    }
    
    return self;
}

#pragma mark - notifications
- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveBTCDidConnectDeviceNotification:)
                                                 name:BTCDidConnectDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveBTCDidDisconnectDeviceNotification:)
                                                 name:BTCDidDisconnectDeviceNotification
                                               object:nil];
}
- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)onReceiveBTCDidConnectDeviceNotification:(NSNotification *)notification {
    CBPeripheral *peripheral = [notification.userInfo objectForKey:BTCPeripheralNotificationUserInfoKey];
    if (peripheral != self.peripheral) {
        return;
    }
    NSError *error = [notification.userInfo objectForKey:BTCErrorNotificationUserInfoKey];
    if (error) {
        DDLogWarn(@"连接失败");
        return;
    }
    DDLogInfo(@"连接成功");
    // TODO: 查找services
    [self discoverServices];
}
- (void)onReceiveBTCDidDisconnectDeviceNotification:(NSNotification *)notification {
    CBPeripheral *peripheral = [notification.userInfo objectForKey:BTCPeripheralNotificationUserInfoKey];
    if (peripheral != self.peripheral) {
        return;
    }
    NSError *error = [notification.userInfo objectForKey:BTCErrorNotificationUserInfoKey];
    if (error) {
        // TODO: 重连
        DDLogWarn(@"连接被断开 error(%@)", error);
    } else {
        DDLogInfo(@"主动断开连接成功");
    }
    [self cleanWhenDisConnect];
    
}

#pragma mark - bind
- (void)bind {
    [self bind];
}
- (void)unbind {
    [[NSNotificationCenter defaultCenter] postNotificationName:BTDDeviceDidUnbindNotification object:nil];
    [self writeData:[self dataForUnBind] forCharacteristic:self.requestCharacteristic];
}

#pragma mark - connect
- (void)connect {
    [self.centralManager connectPeripheral:self.peripheral options:nil];
}
//- (void)reConnect {
//    [self.centralManager retrievePeripheralsWithIdentifiers:[self.peripheral]]
//}
- (void)disconnect {
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

#pragma mark - lock
- (void)lock {
    [self writeData:[self dataForLock] forCharacteristic:self.requestCharacteristic];
}
- (void)unlock {
    [self writeData:[self dataForUnlock] forCharacteristic:self.requestCharacteristic];
}

#pragma mark - service
- (void)discoverServices {
//    [self.peripheral discoverServices:nil];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUIDString]]];
}

#pragma mark - characteristic
- (void)discoverCharacteristics {
//    [self.peripheral discoverCharacteristics:nil forService:self.service];
    [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kRequestCharacteristicUUIDString],
                                               [CBUUID UUIDWithString:kResponseCharacteristicUUIDString]]
                                  forService:self.service];
}
- (void)writeData:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic {
    if (!characteristic) {
        DDLogError(@"characteristic不存在(%@)", characteristic);
        return;
    }
    DDLogDebug(@"准备写值data(%@)forCharacteristic(%@)", data, characteristic);
    [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        DDLogWarn(@"查找Service失败 error(%@)", error);
        return;
    }
    DDLogInfo(@"发现Service（%@）", peripheral.services);
    self.service = [peripheral.services firstObject];
    // TODO: 查找Charactor
    [self discoverCharacteristics];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogWarn(@"查找Characteristic失败 error(%@)", error);
        return;
    }
    DDLogInfo(@"发现Characteristics(%@) for Service(%@)", service, service.characteristics);
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
        NSString *uuidString = [[characteristic.UUID UUIDString] lowercaseString];
        if ([uuidString isEqualToString:kRequestCharacteristicUUIDString]) {
            self.requestCharacteristic = characteristic;
        } else if ([uuidString isEqualToString:kResponseCharacteristicUUIDString]) {
            self.responseCharacteristic = characteristic;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.responseCharacteristic];
        }
    }];
    
    if ([CurrentUser sharedInstance].bluetoothDeviceKey) {
        // 直接验证
        self.isVerifyByDefaultKey = NO;
        [self writeData:[self dataForVerifyByKey:[CurrentUser sharedInstance].bluetoothDeviceKey] forCharacteristic:self.requestCharacteristic];
    } else {
        // 使用默认key
        self.isVerifyByDefaultKey = YES;
        [self writeData:[self dataForVerifyDefaultKey] forCharacteristic:self.requestCharacteristic];
    }
//    [self writeData:[self dataForVerifyByKey:@"123456"] forCharacteristic:self.baseCharacteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogWarn(@"写值失败-characteristic(%@) error(%@)", characteristic, error);
        return;
    }
    DDLogInfo(@"写值成功-characteristic(%@)-value(%@)", characteristic, characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DDLogWarn(@"读值或Notify失败-characteristic(%@) error(%@)", characteristic, error);
        return;
    }
    DDLogInfo(@"读值或Notify成功-characteristic(%@)-value(%@)", characteristic, characteristic.value);
    Byte *bytes = (Byte *)characteristic.value.bytes;
    NSString *command = [NSString stringWithFormat:@"%02x", bytes[0]];
    NSString *content = [NSString stringWithFormat:@"%02x", bytes[1]];
    DDLogInfo(@"读值或Notify响应-command(%@) content(%@)", command, content);
    [self handleResponseWithCommand:command content:content];
}

#pragma mark - getter
- (NSString *)name {
    return self.peripheral.name;
}

- (NSString *)uuidString {
    return [self.peripheral.identifier UUIDString];
}

#pragma mark - data builder
- (NSData *)dataForVerifyDefaultKey {
    Byte bytes[7] = {0xb2, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return data;
}
- (NSData *)dataForVerifyByKey: (NSString *)key {
    Byte commandBytes[1] = {0xb2};
    NSMutableData *data = [NSMutableData dataWithBytes:commandBytes length:1];
    [data appendData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    DDLogDebug(@"data(%@) forKey(%@)", data, key);

    return data;
}
- (NSData *)dataForBindByKey: (NSString *)key {
    Byte commandBytes[1] = {0xb5};
    NSMutableData *data = [NSMutableData dataWithBytes:commandBytes length:1];
    [data appendData:[key dataUsingEncoding:NSUTF8StringEncoding]];
    DDLogDebug(@"data(%@) forKey(%@)", data, key);
    
    return data;
}
- (NSData *)dataForLock {
    Byte bytes[2] = {0xb6, 0x01};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return data;
}
- (NSData *)dataForUnlock {
    Byte bytes[2] = {0xb7, 0x01};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return data;
}
- (NSData *)dataForLockStatus {
    Byte bytes[1] = {0xb8};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return data;
}
- (NSData *)dataForUnBind {
    Byte bytes[1] = {0xb9};
    NSData *data = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    
    return data;
}

#pragma mark - response handle
- (void)handleResponseWithCommand:(NSString *)command content:(NSString *)content {
    command = [command lowercaseString];
    content = [content lowercaseString];
    // 验证key
    if ([command isEqualToString:@"a2"]) {
        if ([content isEqualToString:@"ff"]) {
            // 成功
            if (self.isVerifyByDefaultKey) {
                DDLogDebug(@"默认key验证成功，准备绑定用户key");
                // 绑定新key
                self.bluetoothKey = [self generateBluetoothDeviceKey];
                [self writeData:[self dataForBindByKey:self.bluetoothKey] forCharacteristic:self.requestCharacteristic];
            } else {
                // 不提示用户
                DDLogDebug(@"用户key验证成功");
            }
        } else if ([content isEqualToString:@"00"]) {
            if (self.isVerifyByDefaultKey) {
                // 提示用户reset箱子
                DDLogDebug(@"验证失败，请reset箱子后重试");
                
            } else {
                // 提示用户解绑箱子
                DDLogDebug(@"验证失败，请解绑箱子");
            }
        }
    }
    // 绑定
    else if ([command isEqualToString:@"a5"]) {
        if ([content isEqualToString:@"ff"]) {
            // 成功，save key，提示用户
            [[NSNotificationCenter defaultCenter] postNotificationName:BTDDeviceDidBindSuccessNotification
                                                                object:nil
                                                              userInfo:@{BTDBluetoothKeyNotificationUserInfoKey: self.bluetoothKey,
                                                                         BTDDeviceUUIDStringNotificationUserInfoKey: [self.peripheral.identifier UUIDString]}];
            DDLogDebug(@"用户key绑定成功");
        }
//        else {
//            // 失败，提示用户
//        }
    }
    // 上锁
    else if ([command isEqualToString:@"a6"]) {
        // 刷新UI，提示用户
        if ([content isEqualToString:@"ff"]) {
            // 成功
            DDLogDebug(@"上锁成功");
        } else if ([content isEqualToString:@"01"]) {
            // 拉链未扣好
            DDLogDebug(@"拉链未扣好");
        } else if ([content isEqualToString:@"02"]) {
            // 已经锁上了
            DDLogDebug(@"已经是上锁状态了");
        }
    }
    // 开锁
    else if ([command isEqualToString:@"a7"]) {
        // 刷新UI，提示用户
        if ([content isEqualToString:@"ff"]) {
            // 成功
            DDLogDebug(@"开锁成功");
        } else if ([content isEqualToString:@"02"]) {
            // 已经开锁了
            DDLogDebug(@"已经是开锁状态了");
        }
    }
    // 查询锁状态
    else if ([command isEqualToString:@"a8"]) {
        if ([content isEqualToString:@"00"]) {
            //
        } else if ([content isEqualToString:@"01"]) {
            //
        } else if ([content isEqualToString:@"02"]) {
            //
        } else if ([content isEqualToString:@"03"]) {
            //
        }
    }
    // 解绑
    else if ([command isEqualToString:@"a9"]) {
        // 刷新UI，提示用户
        if ([content isEqualToString:@"ff"]) {
            // 成功
            DDLogDebug(@"解绑成功");
            [self disconnect];
        }
    }
}

#pragma mark - clean
- (void)cleanWhenDisConnect {
    self.service = nil;
    self.requestCharacteristic = nil;
    self.responseCharacteristic = nil;
    self.bluetoothKey = nil;
}

#pragma mark - tools
- (NSString *)generateBluetoothDeviceKey {
//    NSString *bluetoothDeviceKey = [NSString stringWithFormat:@"%06u", arc4random() % 1000000];
//
//    return bluetoothDeviceKey;
    
    return @"222222";
}

#pragma mark - dealloc
- (void)dealloc {
    [self removeNotifications];
}

@end
