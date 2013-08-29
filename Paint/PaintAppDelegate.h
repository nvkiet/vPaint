//
//  PaintAppDelegate.h
//  Paint
//
//  Created by Nguyen Van Kiet on 8/20/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PaintingViewController;

@interface PaintAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) PaintingViewController *viewController;

@end
