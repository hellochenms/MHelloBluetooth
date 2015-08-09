//
//  DeviceDetailViewController.h
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothDevice.h"

@interface DeviceDetailViewController : UIViewController
@property (nonatomic) BluetoothDevice *device;
@end
