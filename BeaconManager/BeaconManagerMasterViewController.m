//
//  BeaconManagerMasterViewController.m
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BeaconManagerAppDelegate.h"
#import "BeaconManagerMasterViewController.h"
#import "BeaconManagerDetailViewController.h"

@interface BeaconManagerMasterViewController ()

@property (strong,nonatomic) NSMutableArray* foundBeacons;

@end

@implementation BeaconManagerMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create some storage for our beacons
    self.foundBeacons = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated
{
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Subscribe to notifications for found beacons - we want to receive all "beaconFound" messages in this object, because
    // we use them to refresh our table view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coreBluetoothStateUpdated:) name:@"centralStateUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBeacon:) name:@"beaconFound" object:nil];
    
    [appDelegate.bleManager startScanningForBeacons];

}

-(void)viewWillDisappear:(BOOL)animated
{
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];

    // Suspend scanning for beacnos
    [appDelegate.bleManager stopScannningForBeacons];
    
    // Clear beacon list, because it will be repopulated when we scan again
    [_foundBeacons removeAllObjects];
    [self.tableView reloadData];
}


#pragma mark Central State Management
-(void)coreBluetoothStateUpdated:(NSNotification*)notification
{
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];

    // Check the state of the bluetooth central manager
    CBCentralManager* manager = (CBCentralManager*)notification.object;
    
    if (manager.state == CBCentralManagerStatePoweredOn)
    {
        // Commence scanning for nearby IoT Design Shop beacons
        [appDelegate.bleManager startScanningForBeacons];

    }
    else
    {
        // Suspend scanning for beacnos
        [appDelegate.bleManager stopScannningForBeacons];
    }
    
}



#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // We always return at least 1 entry - this is to have a placeholder message that says that no beacons have been found.
    return MAX(_foundBeacons.count, 1);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    if (_foundBeacons.count == 0)
    {
        // No beacons yet - add a message indicating so
        cell.textLabel.text = @"No beacons have been found.";
        cell.textLabel.font = [UIFont italicSystemFontOfSize:12.0f];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        // Add the beacon to the list
        CBPeripheral* beaconForRow = (CBPeripheral*)[_foundBeacons objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"IoT DS Beacon (%@)",beaconForRow.identifier.UUIDString];
        cell.textLabel.font = [UIFont systemFontOfSize:9.0f];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    return cell;
}

#pragma mark Notifications
-(void)newBeacon:(NSNotification*)notification
{
    // This method gets called whenever a new beacon device is discovered
    // We use it to add the beacon to our list of discovered beacons, and
    // then we trigger a reload of our main data table
    
    if (![_foundBeacons containsObject:notification.object])
    {
        [_foundBeacons addObject:notification.object];
        [self.tableView reloadData];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // We tell the detail view controller which beacon the user has selected
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
        CBPeripheral* beacon = _foundBeacons[indexPath.row];
        [[segue destinationViewController] setDetailItem:beacon];
    }
}

@end
