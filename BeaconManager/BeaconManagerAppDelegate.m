//
//  BeaconManagerAppDelegate.m
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import "BeaconManagerAppDelegate.h"

@implementation BeaconManagerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    self.bleManager = [[BLEManager alloc] initWithDelegate:self];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark BLEManagerDelegate Methods

-(void)coreBluetoothStateUpdate:(CBCentralManager*)manager
{
    // This method is called whenever the Core Bluetooth Central Manager changes state. Many operations require
    // the manager to be online before being called, so this is used to tell the App that Core Bluetooth is ready to go
    [[NSNotificationCenter defaultCenter] postNotificationName:@"centralStateUpdate" object:manager];
}

-(void)beaconFound:(CBPeripheral*)peripheral  advertisingData:(NSDictionary*)adData
{
    // This method is called whenever beacons are detected during a scan. Because various parts of our
    // UI use this information, we are dispatching it via the Notification Center to allow various
    // other objects to subscribe to these events.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconFound" object:peripheral userInfo:adData];
}

-(void)beaconConnected:(CBPeripheral *)peripheral
{
    // This method is called when a successful connection is established to a beacon. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconConnected" object:peripheral];
}

-(void)beaconConnectFailed:(CBPeripheral *)peripheral withError:(NSError *)error
{
    // This method is called when an attempted beacon connection fails. Beacuse various parts of the UI may use this
    // information, we dispatch it via the Notification Center
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconConnectFailed" object:peripheral userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
}

-(void)beaconServicesDiscovered:(CBPeripheral*)peripheral
{
    // This method is called if beacon configuration services have been successfully discovered on a peripheral. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconServicesDiscovered" object:peripheral];

}

-(void)beaconServiceDiscoveryFailed:(CBPeripheral*)peripheral withError:(NSError*)error
{
    // This method is called if beacon configuration services cannot be found on a peripheral. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconServicesDiscoveryFailed" object:peripheral userInfo:(error?[NSDictionary dictionaryWithObject:error forKey:@"error"]:nil)];

}

-(void)beaconCharacteristicRead:(CBCharacteristic*)characteristic
{
    // This method is called when a service characteristic is successfully read from the peripheral. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconCharacteristicRead" object:characteristic];

}

-(void)beaconCharacteristicReadFailed:(CBPeripheral*)peripheral withError:(NSError*)error
{
    // This method is called if we failed to read beacon characteristics on a peripheral. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconCharacteristicReadFailed" object:peripheral userInfo:(error?[NSDictionary dictionaryWithObject:error forKey:@"error"]:nil)];

}

-(void)beaconCharacteristicWriteComplete:(CBCharacteristic*)characteristic
{
    // This method is called when a service characteristic is successfully written to a peripheral. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconCharacteristicWriteComplete" object:characteristic];
}

-(void)beaconCharacteristicWriteFailed:(CBCharacteristic*)characteristic withError:(NSError*)error
{
    // This method is called when a characteristic write fails. Because various parts of the UI
    // may use this information, we dispatch it via the Notification Center.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beaconCharacteristicWriteFailed" object:characteristic userInfo:(error?[NSDictionary dictionaryWithObject:error forKey:@"error"]:nil)];

}




@end
