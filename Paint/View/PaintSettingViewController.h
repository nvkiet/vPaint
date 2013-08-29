//
//  PaintSettingViewController.h
//  Paint
//
//  Created by Nguyen Van Kiet on 8/28/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface PaintSettingViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;


@end
