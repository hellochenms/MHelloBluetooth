//
//  DeviceDetailViewController.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "DeviceDetailViewController.h"

@interface DeviceDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *disConnectButton;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UIButton *unlockButton;
@end

@implementation DeviceDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.nameLabel.text = self.device.name;
    self.uuidLabel.text = self.device.uuidString;
}

#pragma mark - user event
- (IBAction)onTapConnect:(id)sender {
    [self.device connect];
}
- (IBAction)onTapUnbind:(id)sender {
    [self.device unbind];
}
- (IBAction)onTapLock:(id)sender {
    [self.device lock];
}
- (IBAction)onTapUnlok:(id)sender {
    [self.device unlock];
}

- (void)dealloc {
    [self.device disconnect];
}

@end
