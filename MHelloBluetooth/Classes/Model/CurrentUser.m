//
//  CurrentUser.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/9.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "CurrentUser.h"
#import "BluetoothDevice.h"

static NSString * const kBluetoothKeyUserDefaultsKey = @"kBluetoothKeyUserDefaultsKey";
static NSString * const kDeviceUUIDStringUserDefaultsKey = @"kDeviceUUIDStringUserDefaultsKey";

@implementation CurrentUser
+ (instancetype)sharedInstance {
    static CurrentUser *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [CurrentUser new];
    });
    
    return s_instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bluetoothDeviceKey = [self readBluetoothKey];
        _bluetoothDeviceUUIDString = [self readDeviceUUIDString];
        [self addNotifications];
    }
    
    return self;
}

#pragma mark - notification
- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(onReceiveBTDDeviceBindSuccessNotification:)
                                                name:BTDDeviceDidBindSuccessNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveBTDDeviceDidUnbindNotification)
                                                 name:BTDDeviceDidUnbindNotification
                                               object:nil];
}
- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)onReceiveBTDDeviceBindSuccessNotification:(NSNotification *)notification {
    NSString *bluetoothKey = [notification.userInfo objectForKey:BTDBluetoothKeyNotificationUserInfoKey];
    NSString *uuidString = [notification.userInfo objectForKey:BTDDeviceUUIDStringNotificationUserInfoKey];
    [self saveBluetoothKey:bluetoothKey uuidString:uuidString];
}
- (void)onReceiveBTDDeviceDidUnbindNotification {
    [self removeBluetoothInfos];
}
#pragma mark - bluetooth key
- (void)saveBluetoothKey:(NSString *)bluetoothKey uuidString:(NSString *)uuidString {
    [[NSUserDefaults standardUserDefaults] setObject:bluetoothKey forKey:kBluetoothKeyUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:uuidString forKey:kDeviceUUIDStringUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeBluetoothInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBluetoothKeyUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDeviceUUIDStringUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSString *)readBluetoothKey {
    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:kBluetoothKeyUserDefaultsKey];
    DDLogError(@"key(%@)", key);
    return key;
}
- (NSString *)readDeviceUUIDString {
    NSString *deviceUUIDString = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceUUIDStringUserDefaultsKey];
    DDLogError(@"deviceUUIDString(%@)", deviceUUIDString);
    return deviceUUIDString;
}

#pragma mark - dealloc 
- (void)dealloc {
    [self removeNotifications];
}

@end
