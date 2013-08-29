//
//  PaintSettingViewController.m
//  Paint
//
//  Created by Nguyen Van Kiet on 8/28/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import "PaintSettingViewController.h"

@interface PaintSettingViewController (){
    NSArray *lstTitles;
}

@end

@implementation PaintSettingViewController
@synthesize mainTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title= @"Về Weeat";
    
    mainTableView.delegate= self;
    mainTableView.dataSource= self;
    
    lstTitles= [NSArray arrayWithObjects:@"Rate & Review", @"Like us on Facebook", @"Give us Feedback", nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"common_bg.png"]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return lstTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle= UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text= [lstTitles objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString * theUrl= nil;
    switch (indexPath.row) {
        case 0:
        {
            theUrl = @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=635884720&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software";
            [self openURL:theUrl];
            break;
        }
        case 1:
        {
            theUrl= @"https://www.facebook.com/vpaintapp";
            [self openURL:theUrl];
            break;
        }
        case 2:
        {
            [self giveUsFeedback];
            break;
        }
        default:
            break;
    }
}

-(void)giveUsFeedback{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"[vPaint] Give us Feedback"];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"laptrinhngonngu@yahoo.com", nil];
        [mailer setToRecipients:toRecipients];
        
        [self presentModalViewController:mailer animated:YES];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Your phone does not support sending email!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)openURL:(NSString*)theUrl{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:theUrl]];
}

- (IBAction)btnClose:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void)viewDidUnload {
    [self setMainTableView:nil];
    [super viewDidUnload];
}
@end
