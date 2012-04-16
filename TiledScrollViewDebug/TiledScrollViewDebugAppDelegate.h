//
//  TiledScrollViewDebugAppDelegate.h
//  TiledScrollViewDebug
//
//  Created by Hiren on 4/15/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface TiledScrollViewDebugAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *mainVC;

@end
