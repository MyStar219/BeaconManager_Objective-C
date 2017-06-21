//
//  BeaconManagerDetailViewController.h
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import "BLEManager.h"
#import <UIKit/UIKit.h>

@interface BeaconManagerDetailViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) CBPeripheral* detailItem;

@end
