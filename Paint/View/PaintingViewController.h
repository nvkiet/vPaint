//
//  PaintViewController.h
//  Paint
//
//  Created by Nguyen Van Kiet on 8/20/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PaintingView.h"
#import "InfColorPickerController.h"
#import "UIViewController+MJPopupViewController.h"
#import <MessageUI/MessageUI.h>
#import <FacebookSDK/FacebookSDK.h>
#import <AudioToolbox/AudioToolbox.h>

@interface PaintingViewController : UIViewController<InfColorPickerControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIColor *prevColor;
@property (nonatomic) float prevPointSize;
@property (nonatomic) float prevOpacity;

@property (weak, nonatomic) IBOutlet PaintingView *paintingView;



@end
