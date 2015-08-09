//
//  ViewController.m
//  MHelloBluetooth
//
//  Created by thatsoul on 15/8/8.
//  Copyright (c) 2015年 chenms.m2. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothDevice.h"
#import "MHBBluetoothManager.h"
#import "DeviceDetailViewController.h"
#import "CurrentUser.h"

static NSString * const cellIdentifier = @"cellIdentifier";

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelScanButton;
@property (weak, nonatomic) IBOutlet UIButton *retrieveButton;
@property (nonatomic) NSMutableArray *devices;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // model
    self.devices = [NSMutableArray array];
    
    // UI
    self.cancelScanButton.enabled = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //
    [self addNotifications];
}

#pragma mark - user event
- (IBAction)onTapScan:(id)sender {
    [self refreshUIBeforeLoadData];
    [self.devices removeAllObjects];
    [self.tableView reloadData];
    [[MHBBluetoothManager sharedInstance] scan];
}
- (IBAction)onTapCancelScan:(id)sender {
    [[MHBBluetoothManager sharedInstance] cancelScan];
    [self refreshUIAfterLoadData];
}

- (IBAction)onTapRetrieve:(id)sender {
    [self.devices removeAllObjects];
    [self.tableView reloadData];
    if ([CurrentUser sharedInstance].bluetoothDeviceUUIDString) {
        BluetoothDevice *device = [[MHBBluetoothManager sharedInstance] deviceForUUIDString:[CurrentUser sharedInstance].bluetoothDeviceUUIDString];
        [self.devices addObject:device];
        [self.tableView reloadData];
    }
}

#pragma mark - notifications
- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveBMFindDeviceNotification:)
                                                 name:BMFindDeviceNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(onReceiveBMScanFaildNotification)
//                                                 name:BMScanFaildNotification
//                                               object:nil];
}
- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)onReceiveBMFindDeviceNotification:(NSNotification *)notification {
    BluetoothDevice *device = [notification.userInfo objectForKey:BMDeviceNotificationUserInfoKey];
    [self.devices addObject:device];
    [self.tableView reloadData];
    [self refreshUIAfterLoadData];
}
//- (void)onReceiveBMScanFaildNotification {
//    NSLog(@"扫描失败");
//    [self refreshUIAfterLoadData];
//}


#pragma mark - refresh UI for load data
- (void)refreshUIBeforeLoadData {
    self.scanButton.enabled = NO;
    self.cancelScanButton.enabled = YES;
}
- (void)refreshUIAfterLoadData {
    self.scanButton.enabled = YES;
    self.cancelScanButton.enabled = NO;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    BluetoothDevice *device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceDetailViewController *controller = [DeviceDetailViewController new];
    controller.device = [self.devices objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - dealloc
- (void)dealloc {
    [self removeNotifications];
}

@end
