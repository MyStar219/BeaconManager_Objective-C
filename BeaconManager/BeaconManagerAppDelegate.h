//
//  BeaconManagerAppDelegate.h
//  BeaconManager
//
//  Created by Trent Shumay on 2/21/2014.
//  Copyright (c) 2014 IoT Design Shop. All rights reserved.
//

#import "BLEManager.h"
#import "BLEManagerDelegate.h"
#import <UIKit/UIKit.h>

@interface BeaconManagerAppDelegate : UIResponder <UIApplicationDelegate, BLEManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) BLEManager* bleManager;

@end
