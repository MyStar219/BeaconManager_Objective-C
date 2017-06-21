//
//  BeaconManagerDetailViewController.m
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import "BeaconManagerDetailViewController.h"
#import "BeaconManagerAppDelegate.h"

@interface BeaconManagerDetailViewController ()
- (void)configureView;
- (void)showFullUI;

-(void)powerConstantToUI:(NSInteger)pc;     // Takes an integer power constant (as returned by the beacon services) and maps it to the UI
-(void)timeIntervaltoUI:(NSInteger)ti;      // Takes an integer time interval (as returned by the beacon services) and maps it to the UI

-(NSInteger)uiToPowerConstant;              // Converts from the human readable form of the power level back into a power constant for the hardware
-(NSInteger)uiToTimeInterval;               // Converts from the human readable form of the time interval back into a time count for the hardware

-(BOOL)characteristicHasUUID:(CBCharacteristic*)charactertic uuid:(NSString*)uuidString;    // Convenience function for determing UUID type of a CBCharacteristic


@property (strong, nonatomic) IBOutlet UILabel* uuidLabel;
@property (strong, nonatomic) IBOutlet UILabel* statusLabel;

@property (strong, nonatomic) IBOutlet UITextField* uuidField;
@property (strong, nonatomic) IBOutlet UITextField* majorID;
@property (strong, nonatomic) IBOutlet UITextField* minorID;
@property (strong, nonatomic) IBOutlet UITextField* txPower;
@property (strong, nonatomic) IBOutlet UITextField* txInterval;

@property (strong, nonatomic) IBOutlet UIView* fullUI;

@property (strong, nonatomic) NSMutableArray* beaconCharacteristics;
@property (strong, nonatomic) NSArray* powerLevels;
@property (strong, nonatomic) NSArray* timeIntervals;

#define NUM_CHARACTERISTICS 3
@property (assign, nonatomic) NSInteger characteristicsWritten;

@end

@implementation BeaconManagerDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}


- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.uuidLabel.text = [_detailItem.identifier UUIDString];
    }
}

-(void)hideFullUI
{
    _fullUI.hidden = YES;
}

-(void)showFullUI
{
    _fullUI.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.beaconCharacteristics = [NSMutableArray array];
    
    // Human readable power levels and time intervals used throughout the UI
    self.powerLevels = [NSArray arrayWithObjects:@"-23 dB",@"-6 dB",@"0 dB", nil];
    self.timeIntervals = [NSArray arrayWithObjects:@"0.1 sec",@"0.5 sec",@"1.0 sec",@"5.0 sec",@"10.0 sec",@"20.0 sec", @"30.0 sec", nil];
    
    // Set up pickers for the TX power and TX interval field
    UIPickerView* txIntervalPicker = [[UIPickerView alloc] init];
    txIntervalPicker.dataSource = self;
    txIntervalPicker.delegate = self;
    _txInterval.inputView = txIntervalPicker;
    
    
    UIPickerView* txPowerPicker = [[UIPickerView alloc] init];
    txPowerPicker.dataSource = self;
    txPowerPicker.delegate = self;
    _txPower.inputView = txPowerPicker;
    
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}






-(void)viewWillAppear:(BOOL)animated
{
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Subscribe to notifications related to connection state
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconConnected:) name:@"beaconConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconConnectFailed:) name:@"beaconConnectFailed" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconServicesDiscovered:) name:@"beaconServicesDiscovered" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconServicesFailed:) name:@"beaconServicesDiscoveryFailed" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconCharacteristicRead:) name:@"beaconCharacteristicRead" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconCharacteristicReadFailed:) name:@"beaconCharacteristicReadFailed" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconCharacteristicWriteComplete:) name:@"beaconCharacteristicWriteComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconCharacteristicWriteFailed:) name:@"beaconCharacteristicWriteFailed" object:nil];


    
    // When the view is about to appear, we attempt to connect to the beacon
    [appDelegate.bleManager connectToBeacon:_detailItem];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // When the view is about to disappear, we disconnect from the beacon
    [appDelegate.bleManager disconnectFromBeacon:_detailItem];
    
    // Clean up notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UI Actions
-(IBAction)saveValues:(id)sender
{
    // Hide the big UI again, and go back to status
    _statusLabel.text = @"Writing values to beacon";
    [self hideFullUI];
    
    // Reset our save counter
    _characteristicsWritten = 0;
    
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    
    // Earlier, we held onto the characterists as they were discovered so that we could write them back now
    for (CBCharacteristic* characteristic in _beaconCharacteristics)
    {
        // Write them back now
        if ([self characteristicHasUUID:characteristic uuid:CHARACTERISTIC_BEACON_UUID])
        {
            // Convert the UUID back from a string into bytes
            CBUUID* uuid = [CBUUID UUIDWithString:_uuidField.text];
            [[appDelegate bleManager] writeBeaconCharacteristic:characteristic data:uuid.data];
        }
        else if ([self characteristicHasUUID:characteristic uuid:CHARACTERSITIC_BEACON_ID])
        {
            // Beacon ID is two 16-bit integers with the major and minor concatenated
            int16_t beaconID[2];
            
            beaconID[0] = [_majorID.text integerValue];
            beaconID[1] = [_minorID.text integerValue];
            
            NSData* newValue = [NSData dataWithBytes:beaconID length:2*sizeof(int16_t)];
            [[appDelegate bleManager] writeBeaconCharacteristic:characteristic data:newValue];
            
        }
        else if ([self characteristicHasUUID:characteristic uuid:CHARACTERISTIC_TX_SETTINGS])
        {
            // We need to convert back from human readable form to raw int_16 values
            int16_t txSettings[2];
            
            txSettings[0] = [self uiToPowerConstant];
            txSettings[1] = [self uiToTimeInterval];
            
            NSData* newValue = [NSData dataWithBytes:txSettings length:2*sizeof(int16_t)];
            [[appDelegate bleManager] writeBeaconCharacteristic:characteristic data:newValue];
            
        }
    }
    
}

-(IBAction)generateUUID:(id)sender
{
    // Populate the uuid field with a fresh UUID
    _uuidField.text = [[NSUUID UUID] UUIDString];
}


#pragma mark UI Conversion
-(void)powerConstantToUI:(NSInteger)pc
{
    // This table maps the power constants to human readable form - there are 3 valid modes available in our chipset
    _txPower.text = [_powerLevels objectAtIndex:pc];
}

-(void)timeIntervaltoUI:(NSInteger)ti
{
    // The time interval is interesting - it is an integer quantity of the number of 625ns ticks to wait between advertising broadcasts
    // We convert it to human readable form
    float seconds = ti*0.000625f;
    _txInterval.text = [NSString stringWithFormat:@"%.2f sec", seconds];
}

-(NSInteger)uiToPowerConstant
{
    // This table maps the power constants to human readable form - there are 3 valid modes available in our chipset
    return [_powerLevels indexOfObject:_txPower.text];
}

-(NSInteger)uiToTimeInterval
{
    // Need to get back to floating-point seconds to start with
    NSString* secondsOnly = [_txInterval.text substringToIndex:[_txInterval.text length]-4];        // Strips the " sec" off the back of the string
    
    CGFloat floatSeconds = [secondsOnly floatValue];    // Back to a decimal number
    CGFloat ti = floatSeconds / 0.000625f;  // Convert back into the number of 625ns ticks the hardware needs
    
    // Return result as integer
    return ti;
    
}

-(BOOL)characteristicHasUUID:(CBCharacteristic *)characteristic uuid:(NSString *)uuidString
{
    // There are only 3 characteristics, so we don't worry about being too fancy here
    CBUUID* uuid = [CBUUID UUIDWithString:uuidString];
    
    return [characteristic.UUID.data isEqualToData:uuid.data];

}

#pragma mark TextFieldDelegate Methods
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark Picker View Delegate and Data Source
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _txPower.inputView)
    {
        return _powerLevels.count;
    }
    else if (pickerView == _txInterval.inputView)
    {
        return _timeIntervals.count;
    }
    
    return 0;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == _txPower.inputView)
    {
        return _powerLevels[row];
    }
    else if (pickerView == _txInterval.inputView)
    {
        return _timeIntervals[row];
    }
    
    return nil;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == _txPower.inputView)
    {
        _txPower.text = _powerLevels[row];
        [_txPower resignFirstResponder];
    }
    else if (pickerView == _txInterval.inputView)
    {
        _txInterval.text = _timeIntervals[row];
        [_txInterval resignFirstResponder];
    }
}


#pragma mark Notification Handlers
-(void)beaconConnected:(NSNotification*)notification
{
    // First we update the status in the UI
    _statusLabel.text = @"Discovering Services";
    
    CBPeripheral* peripheral = [notification object];
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // We ask the peripheral to see if it supports our beacon configuration services
    [appDelegate.bleManager discoverBeaconConfigurationServices:peripheral];
    
    
}

-(void)beaconConnectFailed:(NSNotification*)notification
{
    // This is unexpected. We post an error message and leave the view.
    NSError* error = [notification.userInfo objectForKey:@"error"];
    UIAlertView* errorMessage = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:[NSString stringWithFormat:@"We could not connect to the beacon. The error message returned was: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [errorMessage show];
    
    // Pop back - this would allow the user to retry the connection
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)beaconServicesDiscovered:(NSNotification*)notification
{
    // First, we update the status in the UI
    _statusLabel.text = @"Reading Configuration";
    
    CBPeripheral* peripheral = [notification object];
    BeaconManagerAppDelegate* appDelegate = (BeaconManagerAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Read the configuration characteristics we need to populate the UI
    [appDelegate.bleManager loadBeaconConfigurationData:peripheral];
    
}

-(void)beaconServicesFailed:(NSNotification*)notification
{
    // This is unexpected. We post an error message and leave the view.
    NSError* error = [notification.userInfo objectForKey:@"error"];

    UIAlertView* errorMessage;
    if (error)
    {
        errorMessage = [[UIAlertView alloc] initWithTitle:@"Service Discovery Failed" message:[NSString stringWithFormat:@"We could not find beacon configuration services on the peripheral. The error message returned was: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    }
    else
    {
        errorMessage = [[UIAlertView alloc] initWithTitle:@"No Configuration Service" message:@"We could not find beacon configuration services on the peripheral." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    }
    
    [errorMessage show];
    
    // Pop back - this would allow the user to retry the connection
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)beaconCharacteristicRead:(NSNotification*)notification
{
    // Add the characteristic to our list
    [_beaconCharacteristics addObject:notification.object];
    
    // This is good - at the point that we start receiving characteristics back from the device, we can switch over to the full UI so that the user can see
    // the parameters and interact with their beacon
    [self showFullUI];
    
    // Which data is this? Look at the UUID of the characteristic coming in
    CBCharacteristic* characteristic = notification.object;
    
    
    
    // Need to compare the actual bytes, not just the pointer to see if a CBUUID matches
    if ([self characteristicHasUUID:characteristic uuid:CHARACTERISTIC_BEACON_UUID])
    {
        // These are the bytes of the beacon's broadcast UUID. Load them into the UUID field
        NSUUID* uuid = [[NSUUID alloc] initWithUUIDBytes:characteristic.value.bytes];
        _uuidField.text = [uuid UUIDString];
    }
    else if ([self characteristicHasUUID:characteristic uuid:CHARACTERSITIC_BEACON_ID])
    {
        // The id characteristic is a pair of 16-bit ints. One for the major, one for the minor
        int16_t* idc = (int16_t*)characteristic.value.bytes;
        
        _majorID.text = [NSString stringWithFormat:@"%d", idc[0]];
        _minorID.text = [NSString stringWithFormat:@"%d", idc[1]];
    }
    else if ([self characteristicHasUUID:characteristic uuid:CHARACTERISTIC_TX_SETTINGS])
    {
        // The TX settings are a pair of 16-bit ints. One for the power level, and one for the broadcast frequency
        int16_t* txc = (int16_t*)characteristic.value.bytes;
        
        [self powerConstantToUI:txc[0]];
        [self timeIntervaltoUI:txc[1]];
        
        
    }
    
    
}

-(void)beaconCharacteristicReadFailed:(NSNotification*)notification
{
    // This is unexpected. Let the user know
    NSError* error = [notification.userInfo objectForKey:@"error"];
    UIAlertView* errorMessage = [[UIAlertView alloc] initWithTitle:@"Beacon Characteristic Read Failed" message:[NSString stringWithFormat:@"We failed while trying to retrieve characteristics from the beacon. The error message returned was: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [errorMessage show];
    
}


-(void)beaconCharacteristicWriteComplete:(NSNotification*)notification
{
    // This is over simplifying things, but we just count the number of successful notifications here - if we get notifications back for the
    // right number, we leave the view
    _characteristicsWritten++;
    
    if (_characteristicsWritten == NUM_CHARACTERISTICS)
    {
        // All done
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


-(void)beaconCharacteristicWriteFailed:(NSNotification*)notification
{
    // This is unexpected. Let the user know
    NSError* error = [notification.userInfo objectForKey:@"error"];
    UIAlertView* errorMessage = [[UIAlertView alloc] initWithTitle:@"Beacon Characteristic Write Failed" message:[NSString stringWithFormat:@"We failed while trying to write characteristics from the beacon. The error message returned was: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [errorMessage show];
    
}




@end
