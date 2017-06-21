//
//  BLEManager.h
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>
#import "BLEManagerDelegate.h"

// BLEManager manages connections to Bluetooth Low Energy (BLE) peripherals. In this case, the BLE peripheral
// is the IoT Design Shop iBeacon and the interface provided for managing the beacon. However, this class can
// be used as the foundation for other types of BLE connections if you wish.


// UUID for master beacon configuration services - peripherals which have this service are IoT Design Shop
// Beacons (as far as we are concerned, anyhow!)
#define IOT_BEACON_UUID     @"2173E519-9155-4862-AB64-7953AB146156"

// UUID's for the characteristics provided by the service. We have one to retrieve the UUID of the beacon,
// one for Major/Minor ID on the beacon, and one for transmit power and frequency.
#define CHARACTERISTIC_BEACON_UUID      @"2173E519-9155-4862-AB64-7953AB146157"
#define CHARACTERSITIC_BEACON_ID        @"2173E519-9155-4862-AB64-7953AB146158"
#define CHARACTERISTIC_TX_SETTINGS      @"2173E519-9155-4862-AB64-7953AB146159"


@interface BLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

-(id)initWithDelegate:(id<BLEManagerDelegate>)delegate;

// --- Beacon Discovery -----------

// Starts scanning for nearby beacons which provide IoT Design Shop beacon services
-(void)startScanningForBeacons;

// Stops scanning for beacons
-(void)stopScannningForBeacons;

// --- Beacon Connections -----------

// Attempt to connect to a specified beacon peripheral
-(void)connectToBeacon:(CBPeripheral*)beaconPeripheral;

// Disconnect or cancel connection with a beacon
-(void)disconnectFromBeacon:(CBPeripheral*)beaconPeripheral;

// --- Service Discovery -----------

// Attempt to discover beacon configuration services
-(void)discoverBeaconConfigurationServices:(CBPeripheral*)beaconPeripheral;

// Load beacon configuration data
-(void)loadBeaconConfigurationData:(CBPeripheral*)beaconPeripheral;

// -- Characteristic Updates -------
-(void)writeBeaconCharacteristic:(CBCharacteristic*)beaconCharacteristic data:(NSData*)data;


@end
