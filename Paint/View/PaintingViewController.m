//
//  PaintViewController.m
//  Paint
//
//  Created by Nguyen Van Kiet on 8/20/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import "PaintingViewController.h"
#import "PaintingView.h"

#import "InfColorPicker.h"
#import "MBProgressHUD.h"

#import "NSData+Base64.h"
#import "PaintSettingViewController.h"


//CONSTANTS:
#define kHue                    0.0
#define kBrightness             1.0
#define kSaturation             1.0
#define kAlpha                  1.0

#define kPointSize              10.0

@interface PaintingViewController (){
    SystemSoundID undoSound;
    SystemSoundID redoSound;
}
@end

@implementation PaintingViewController
@synthesize prevColor;
@synthesize prevPointSize;
@synthesize prevOpacity;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    CGColorRef color = [UIColor colorWithHue:kHue
                                   saturation:kSaturation
                                  brightness:kBrightness
                                       alpha:kAlpha].CGColor;
    
    const CGFloat *components = CGColorGetComponents(color);
    
    self.prevColor= [UIColor colorWithRed:components[0] green:components[1]  blue:components[2] alpha:kAlpha];
    self.prevOpacity= kAlpha;
    self.prevPointSize= kPointSize;
    
	[self.paintingView setBrushWithRed:components[0] green:components[1] blue:components[2] opacity:prevOpacity pointSize:prevPointSize];
    
    NSURL *urlStart = [[NSBundle mainBundle] URLForResource:@"poof" withExtension:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)urlStart, &undoSound);
    
    urlStart = [[NSBundle mainBundle] URLForResource:@"scribble" withExtension:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)urlStart, &redoSound);
    
    NSCalendar *calendar = [NSCalendar currentCalendar]; 
    NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
    [dateComponents setHour:10];
    [dateComponents setMinute:0];
    
    //Schedule the notification
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.fireDate= [calendar dateFromComponents:dateComponents]; 
    localNotification.repeatInterval = NSDayCalendarUnit;//10h everyday
    localNotification.alertBody = @"Come back to make fun drawings together with friends";
    localNotification.alertAction = @"Show me";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (IBAction)btnPickColor:(id)sender {
    
    InfColorPickerController* picker = [InfColorPickerController colorPickerViewController];
	
	picker.sourceColor = self.prevColor;
    picker.opacity= self.prevOpacity;
    picker.pointSize= self.prevPointSize;
	picker.delegate = self;
	
    [self presentPopupViewController:picker animationType:MJPopupViewAnimationFade];
}
- (IBAction)btnBlank:(id)sender {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Erase Painting?"
                                                      message:@"You cannot undo this!"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Erase", nil];
    [message show];
}


- (IBAction)btnSetting:(id)sender {
    PaintSettingViewController *paintSetting = [[PaintSettingViewController alloc] initWithNibName:@"PaintSettingViewController" bundle:nil];
    [self presentModalViewController:paintSetting animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 1:{
            [self.paintingView erase];
            AudioServicesPlaySystemSound(undoSound);
            break;
        }
        default:
            break;
    }
}


- (IBAction)btnUndo:(id)sender {
    [self.paintingView undoPaint];
    
    AudioServicesPlaySystemSound(undoSound);
}


- (IBAction)btnRedo:(id)sender {
    [self.paintingView redoPaint];
    
     AudioServicesPlaySystemSound(redoSound);
}

- (IBAction)btnShare:(id)sender {
    
    UIActionSheet *sheet= [[UIActionSheet alloc] initWithTitle:@""
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"Save to Photos App", @"Post to Facebook", @"Send in Email", nil];
    
   
    [sheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:{
            [self saveToPhotosApp];
            break;
        }
        case 1:{
            [self postToFacebook];
            break;
        }
        case 2:{
            [self sendInEmail];
            break;
        }
        default:
            break;
    }
}

-(void)saveToPhotosApp{
    UIImage *img= [self.paintingView convertOpenglESViewToImage];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Saving...";
    UIImageWriteToSavedPhotosAlbum(img, self, @selector(thisImage:didFinishSavingWithError:contextInfo:), nil);
}

- (void)thisImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void*)contextInfo {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (error) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Saving to photo Album has some errors!";
        [self performSelector: @selector(didFinishSaveToPhotosApp) withObject:nil afterDelay:0.2f];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Successfully saved to photo Album!";
        [self performSelector: @selector(didFinishSaveToPhotosApp) withObject:nil afterDelay:0.5f];
    }
}

-(void)didFinishSaveToPhotosApp{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

-(void)sendInEmail{
    
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject: @"Check out what I drew on my vPaint"];
        
        NSMutableString *emailBody = [[NSMutableString alloc] initWithString:@"<html><body>"];
        [emailBody appendString:@"<p>I just drew this on my vPaint app. With vPaint: Collaborative Drawing, you can make fun drawings together with a friend. vPaint is available for iPhone, iPod touch, iPad, and Android.</p>"];
        UIImage *emailImage = [self.paintingView convertOpenglESViewToImage];
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(emailImage)];
        NSString *base64String = [imageData base64EncodedString];
        [emailBody appendString:[NSString stringWithFormat:@"<p><b><img src='data:image/png;base64,%@'></b></p>",base64String]];
        [emailBody appendString:@"</body></html>"];
        
        [mailer setMessageBody:emailBody isHTML:YES];
        [self presentModalViewController:mailer animated:YES];
    }
    else
    {
       [[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:@"Your phone does not support sending mail!"
                                   delegate:nil
                              cancelButtonTitle:@"OK"
                         otherButtonTitles:nil] show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissModalViewControllerAnimated:YES];
}


-(void)postToFacebook{
    
    if ([[FBSession activeSession]isOpen]) {
        if ([FBSession.activeSession.permissions
             indexOfObject:@"publish_actions"] == NSNotFound) {
            [FBSession.activeSession
             requestNewPublishPermissions:@[@"publish_actions"]
             defaultAudience:FBSessionDefaultAudienceFriends
             completionHandler:^(FBSession *session, NSError *error) {
                 if (!error) {
                     [self autoSharePaintingToFacebook];
                 }
             }];
        } else {
            [self autoSharePaintingToFacebook];
        }
    }else{
        [FBSession openActiveSessionWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                           defaultAudience:FBSessionDefaultAudienceFriends
                                              allowLoginUI:YES
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             if (!error && status == FBSessionStateOpen) {
                                                 [self autoSharePaintingToFacebook];
                                             }else{
                                                 [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                             message:@"Authentication failed. Changing authentication by Setting -> Privacy -> Facebook -> Check On vPaint!"
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"OK"
                                                                   otherButtonTitles:nil] show];
                                                  
                                             }
                                         }];
    }
}

- (void)autoSharePaintingToFacebook{
     NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithCapacity:2];
    
     NSMutableString *message= [[NSMutableString alloc] init];
     [message appendFormat:@"%@\n\n%@\n",@"#VPaintApp by Me",@"View more here https://www.facebook.com/vpaintapp"];
     [postParams setObject:message forKey:@"message"];
    
     UIImage *img= [self.paintingView convertOpenglESViewToImage];
     [postParams setObject:img forKey:@"file"];
    
     [FBRequestConnection
     startWithGraphPath:@"me/photos"
     parameters:postParams
     HTTPMethod:@"POST"
     completionHandler:^(FBRequestConnection *connection,
                         id result,
                         NSError *error) {
         NSString *alertText;
         if (error) {
             alertText = [NSString stringWithFormat:
                          @"error: domain = %@, code = %d",
                          error.domain, error.code];
             
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                         message:alertText
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
         } else {
             [[[UIAlertView alloc] initWithTitle:@"vPaint"
                                         message:@"Successfully shared to Facebook!"
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
         }
     }];
}

-(void)colorPickerControllerDidFinish:(InfColorPickerController *)controller{
    
    self.prevColor= controller.resultColor;
    self.prevOpacity=  controller.slideOpacity.value;
    self.prevPointSize=controller.slidePointSize.value;
   
    const CGFloat *components = CGColorGetComponents(controller.resultColor.CGColor);
    
	[self.paintingView setBrushWithRed:components[0] green:components[1] blue:components[2] opacity:prevOpacity pointSize:prevPointSize];
    
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (IBAction)btnConnect:(id)sender {
    
    [[[UIAlertView alloc] initWithTitle:@"vPaint"
                                message:@"Collaborative Drawing with Friends. Comming soon!"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPaintingView:nil];
    [super viewDidUnload];
}
@end
