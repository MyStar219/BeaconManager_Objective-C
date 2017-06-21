//
//  BLEManager.m
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import "BLEManager.h"


// IoT Design Shop Beacons always advertise a service with this UUID, so we can
// use it to scan for nearby beacons and limit our results to devices we recognize.
// Note - this service UUID *does not* change even if you update the beacon UUID on the
// device. You shouldn't need to modify this constant ever.




@interface BLEManager ()

@property (strong, nonatomic) id<BLEManagerDelegate> delegate;

@property (strong, nonatomic) CBCentralManager* CM;             // Core bluetooth central manager
@end

@implementation BLEManager

#pragma mark System Initialization

// Init function
-(id)initWithDelegate:(id<BLEManagerDelegate>)delegate
{
    if (self = [super init])
    {
        // Hold on to the delegate object
        self.delegate = delegate;
        
        // Set up our Core Bluetooth central manager
        //      We add the CBCentralManagerOptionShowPowerAlertKey so that the OS will automatically inform the user if
        //      they have Bluetooth turned off. This helps to avoid confusion!
        self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerOptionShowPowerAlertKey]];

    }
    return self;
}


#pragma mark Beacon Discovery

// Scans for beacons nearby
-(void)startScanningForBeacons
{
    // Only scan if Core Bluetooth is ready. This is important in iOS 8.
    if (self.CM.state == CBCentralManagerStatePoweredOn)
    {
    
        // We limit our scan to include only IoT Design Shop beacons (with the IOT_BEACON_UUID service).
        NSArray* scanServices = [NSArray arrayWithObject:[CBUUID UUIDWithString:IOT_BEACON_UUID]];
    
        // Begin scanning for peripherals - as peripherals are discovered, the system will call
        // centralManager:didDiscoverPeripheral: below in the CBCentralManagerDelegate implementation
        [_CM scanForPeripheralsWithServices:scanServices options:nil];
    }
    
}

// Stops any scans taking place
-(void)stopScannningForBeacons
{
    // Stop scanning for peripherals
    [self.CM stopScan];
}


#pragma mark Beacon Connections

// Attempt to connect to a specified beacon peripheral
-(void)connectToBeacon:(CBPeripheral*)beaconPeripheral
{
    // Initiate the connection - we don't need any of the optional parameters, so that param is just nil
    [_CM connectPeripheral:beaconPeripheral options:nil];
}

// Disconnect or cancel connection with a beacon
-(void)disconnectFromBeacon:(CBPeripheral*)beaconPeripheral
{
    // Shut down the connection
    [_CM cancelPeripheralConnection:beaconPeripheral];
}



#pragma mark Service Discovery

// Attempt to discover beacon configuration services
-(void)discoverBeaconConfigurationServices:(CBPeripheral*)beaconPeripheral
{
    // Initiate discovery of the beacon configuration service. This should succeeed whenever we have a valid
    // connection to an IoT Design Shop beacon, because all of the beacons provide this standard config
    // service in their firmware.
    [beaconPeripheral discoverServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:IOT_BEACON_UUID]]];
}

-(void)loadBeaconConfigurationData:(CBPeripheral *)beaconPeripheral
{
    // We're going to ask the peripheral to load all of the characteristics for the beacon service.
    // Because we know this service isn't too heavy, and we want all charactersitics it's ok to do this.
    // Typically, you would request a subset of the characteristics that you are interested in.
    CBUUID* beaconUUID = [CBUUID UUIDWithString:IOT_BEACON_UUID];
    for (CBService* service in beaconPeripheral.services)
    {
        // Important note here - you can't use equivalence on CBUUID's pointers. You need to compare their
        // data bytes.
        if ([service.UUID.data isEqualToData:beaconUUID.data])
        {
            [beaconPeripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}


#pragma mark Characteristic Updates
-(void)writeBeaconCharacteristic:(CBCharacteristic*)beaconCharacteristic data:(NSData*)data
{
    // Very straight forward - we ask to write the data with a response. This means that our peripheral:didWriteValueForCharacteristic:error:
    // will be called with the result of the data write operation.
    [beaconCharacteristic.service.peripheral writeValue:data forCharacteristic:beaconCharacteristic type:CBCharacteristicWriteWithResponse];
}



#pragma mark CBCentralManagerDelegate Implementation

// centralManagerDidUpdateState is called whenever the Core Bluetooth central manager updates
// state at the top level. You can use this to determine when the system is properly powered up and
// online.

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    // The Core Bluetooth Central Manager State is important - many operations will fail if the system
    // is not online when they are called
    NSLog(@">>> centralManagerDidUpdateState");
    
    if (_CM.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"Warning: CoreBluetooth is offline!");
    } else {
        NSLog(@"CoreBluetooth is online");
    }

    // Notify delegate
    [_delegate coreBluetoothStateUpdate:_CM];
    
}


// centralManager:didDiscoverPeripheral is called whenever the Core Bluetooth central manager discovers a
// new bluetooth device during a scan. We use this to inform our delegate that a peripheral was detected.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Notify the delegate
    [_delegate beaconFound:peripheral advertisingData:advertisementData];
}


// centralManager:didConnectPeripharal is called whenever a connection is successfully established to a device.
// We hand this message off to the delegate so that it can inform the rest of the App where needed.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Set this peripheral's delegate to be the BLEManager
    peripheral.delegate = self;
    
    // Notify the delegate
    [_delegate beaconConnected:peripheral];
}


// centralManager:didFailToConnectPeripheral is called when a connection attempt fails for a device.
// We hand this message off to the delegate so that it can inform the App. It is appropriate to retry if this occurs and you
// believe a connection should be possible
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [_delegate beaconConnectFailed:peripheral withError:error];
}


#pragma mark CBPeripheralDelegate Implementation
// peripheral:didDiscoverServices is called to report the result of a discoverServices call on a CBPeripheral. It differs a little bit from the
// central manager callbacks in that there is not a separate callback for failure. So, we handle the success and the failure conditions in the single
// callback, and dispatch the results to the delegate accordingly
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error || (peripheral.services.count == 0))
    {
        // Failure
        [_delegate beaconServiceDiscoveryFailed:peripheral withError:error];
    }
    else
    {
        // Success
        [_delegate beaconServicesDiscovered:peripheral];
        
    }
}

// peripheral:didDiscoverCharacteristicsForService is called when Core Bluetooth has finished retrieving the GATT characteristics for
// a specified service. In this particular case, we report back only if we fail to enumerate the characteristics. If we are successful,
// we forge ahead and ask the peripheral to load the values of all of the characteristics on our behalf.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error || (service.characteristics.count == 0))
    {
        // Failure
        [_delegate beaconCharacteristicReadFailed:peripheral withError:error];
    }
    else
    {
        // Ask the peripheral to pull down the data for the characteristics
        for (CBCharacteristic* characteristic in service.characteristics)
        {
            [peripheral readValueForCharacteristic:characteristic];
        }
        
    }
}

// peripheral:didUpdateValueForCharacteristic is called when the request to retrieve the value of a characteristic is complete. This is the
// end of the road for our "read" sequence of parameters from our device. This method will fire multiple times - once for each characteristic
// we read.
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        // Failure
        [_delegate beaconCharacteristicReadFailed:peripheral withError:error];
    }
    else
    {
        // Success
        [_delegate beaconCharacteristicRead:characteristic];
    }
}

// peripheral:didWriteValueForCharacteristic is called when the request to write a value into a characteristic is complete.
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        // Failure
        [_delegate beaconCharacteristicWriteFailed:characteristic withError:error];
    }
    else
    {
        // Success
        [_delegate beaconCharacteristicWriteComplete:characteristic];
    }
}

@end
