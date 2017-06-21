//
//  BLEManagerDelegate.h
//  BeaconManager
//
//  Created by Trent Shumay on 2/22/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLEManagerDelegate <NSObject>

// This method is called when the CoreBluetooth Central Manager updates state. Some operations require
// the system to be online before calling them, so this is important for the system as a whole
-(void)coreBluetoothStateUpdate:(CBCentralManager*)manager;

// This method is called during scans whenever new IoT Design Shop Beacons are located nearby.
// If you stop scanning, and restart later, beacons will be reported again.
-(void)beaconFound:(CBPeripheral*)peripheral  advertisingData:(NSDictionary*)adData;

// This method is called whenever a device connection attempt is completed successfully
-(void)beaconConnected:(CBPeripheral*)peripheral;

// This method is called whenever a device connection attempt fails
-(void)beaconConnectFailed:(CBPeripheral*)peripheral withError:(NSError*)error;

// This method is called if beacon configuration services are successfully discovered on a peripheral
-(void)beaconServicesDiscovered:(CBPeripheral*)peripheral;

// This method is called if beacon configuration services cannot be discovered on a peripheral
-(void)beaconServiceDiscoveryFailed:(CBPeripheral*)peripheral withError:(NSError*)error;

// This method is called when a beacon characteristic is successfully read from the peripheral
-(void)beaconCharacteristicRead:(CBCharacteristic*)characteristic;

// This method is called if beacon characteristics fail to load form the peripheral
-(void)beaconCharacteristicReadFailed:(CBPeripheral*)peripheral withError:(NSError*)error;

// This method is called when a beacon characteristic is successfully written to the peripheral
-(void)beaconCharacteristicWriteComplete:(CBCharacteristic*)characteristic;

// This method is called if a beacon characteristic write fails
-(void)beaconCharacteristicWriteFailed:(CBCharacteristic*)characteristic withError:(NSError*)error;


@end