#import "CsZBar.h"
#import <AVFoundation/AVFoundation.h>
#import "AlmaZBarReaderViewController.h"

#pragma mark - State

@interface CsZBar ()
@property bool scanInProgress;
@property NSString *scanCallbackId;
@property AlmaZBarReaderViewController *scanReader;
@property BOOL scanMultiple;
@property BOOL playBeep;
@property AVAudioPlayer *soundBeep;

@end

#pragma mark - Synthesize

@implementation CsZBar

@synthesize scanInProgress;
@synthesize scanCallbackId;
@synthesize scanReader;
@synthesize scanMultiple;
@synthesize playBeep;
@synthesize soundBeep;

#pragma mark - Cordova Plugin

- (void)pluginInitialize {
    self.scanInProgress = NO;
    self.scanMultiple = NO;
    self.playBeep = NO;
    
    NSString *soundPath = [NSString stringWithFormat:@"%@/SoundBeep.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
    self.soundBeep = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Plugin API

UIBarButtonItem *buttonLockFocus;
UITextView *myTextView;

- (void)scan: (CDVInvokedUrlCommand*)command; 
{
    if (self.scanInProgress) {
        [self.commandDelegate
         sendPluginResult: [CDVPluginResult
                            resultWithStatus: CDVCommandStatus_ERROR
                            messageAsString:@"A scan is already in progress."]
         callbackId: [command callbackId]];
    } else {
        self.scanInProgress = YES;
        self.scanCallbackId = [command callbackId];
        self.scanReader = [AlmaZBarReaderViewController new];

        self.scanReader.readerDelegate = self;
        self.scanReader.supportedOrientationsMask = ZBarOrientationMask(UIInterfaceOrientationPortrait);

        // Get user parameters
        NSDictionary *params = (NSDictionary*) [command argumentAtIndex:0];
        NSString *camera = [params objectForKey:@"camera"];
        if([camera isEqualToString:@"front"]) {
            // We do not set any specific device for the default "back" setting,
            // as not all devices will have a rear-facing camera.
            self.scanReader.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;

        NSString *flash = [params objectForKey:@"flash"];
        
        if ([flash isEqualToString:@"on"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        } else if ([flash isEqualToString:@"off"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        }else if ([flash isEqualToString:@"auto"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }

        self.scanMultiple = ([[params objectForKey:@"scan_multiple"] boolValue] == YES);
        
        self.playBeep = ([[params objectForKey:@"play_beep"] boolValue] == YES);
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 110000
        // Hack to hide the bottom bar's Info button... originally based on http://stackoverflow.com/a/16353530
	NSInteger infoButtonIndex;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
            infoButtonIndex = 1;
        } else {
            infoButtonIndex = 3;
        }
        UIView *infoButton = [[[[[self.scanReader.view.subviews objectAtIndex:2] subviews] objectAtIndex:0] subviews] objectAtIndex:infoButtonIndex];
        [infoButton setHidden:YES];
#endif
        
        //UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:@"Press Me" forState:UIControlStateNormal]; [button sizeToFit]; [self.view addSubview:button];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        BOOL drawSight = [params objectForKey:@"drawSight"] ? [[params objectForKey:@"drawSight"] boolValue] : true;
        UIToolbar *toolbarViewFlash = [[UIToolbar alloc] init];
        
        //The bar length it depends on the orientation
        toolbarViewFlash.frame = CGRectMake(0.0, 0, (screenWidth > screenHeight ?screenWidth:screenHeight), 44.0);
        toolbarViewFlash.barStyle = UIBarStyleBlackOpaque;
        UIBarButtonItem *buttonFlash = [[UIBarButtonItem alloc] initWithTitle:@"Flash" style:UIBarButtonItemStyleDone target:self action:@selector(toggleflash)];
        
        buttonLockFocus = [[UIBarButtonItem alloc] initWithTitle:@"LockFocus" style:UIBarButtonItemStyleDone target:self action:@selector(lockLensPosition)];
        buttonLockFocus.tag= 1;
        
        NSArray *buttons = [NSArray arrayWithObjects: buttonFlash,buttonLockFocus, nil];
        [toolbarViewFlash setItems:buttons animated:NO];
        [self.scanReader.view addSubview:toolbarViewFlash];

        if (drawSight) {
            CGFloat dim = screenWidth < screenHeight ? screenWidth / 1.1 : screenHeight / 1.1;
            UIView *polygonView = [[UIView alloc] initWithFrame: CGRectMake  ( (screenWidth/2) - (dim/2), (screenHeight/2) - (dim/2), dim, dim)];
            
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0,dim / 2, dim, 1)];
            lineView.backgroundColor = [UIColor redColor];
            [polygonView addSubview:lineView];

            self.scanReader.cameraOverlayView = polygonView;
        }
        
        if (self.scanMultiple) {
            /* DOESN'T WORK ON iOS 10
            UIButton *cancelButton = [[[[[[[self.scanReader.view.subviews objectAtIndex:2] subviews] objectAtIndex:0] subviews] objectAtIndex:2] subviews] objectAtIndex:0];
            [cancelButton setTitle:@"Done" forState:UIControlStateNormal];
            */
            
            myTextView = [[UITextView alloc] init];
            myTextView.editable = NO;
            myTextView.text = @"Start Scanning...";
            myTextView.textColor = [UIColor blackColor];
            myTextView.frame = CGRectMake(0, (screenWidth > screenHeight ?screenWidth:screenHeight) - 115, (screenWidth > screenHeight ?screenWidth:screenHeight), 115);
            
            CGRectMake(0.0, 0, (screenWidth > screenHeight ?screenWidth:screenHeight), 44.0);
            
            [self.scanReader.view addSubview:myTextView];
        }

        [self.viewController presentViewController:self.scanReader animated:YES completion:nil];
    }
}

- (void)lockLensPosition {
    if (buttonLockFocus.tag == 1) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            [device setFocusMode:AVCaptureFocusModeLocked];
            [device setFocusModeLockedWithLensPosition:0.3 completionHandler:nil];
        } else {
            [device setFocusMode:AVCaptureFocusModeLocked];
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        [device unlockForConfiguration];
        buttonLockFocus.tag= 0;
        [buttonLockFocus setTitle:@"UnlockFocus"];
    } else {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];
        [device setFocusMode:AVCaptureFocusModeAutoFocus];
        [device unlockForConfiguration];
        buttonLockFocus.tag= 1;
        [buttonLockFocus setTitle:@"LockFocus"];
    }
}

- (void)setDisplayText: (CDVInvokedUrlCommand*)command{
    NSDictionary *params = (NSDictionary*) [command argumentAtIndex:0];
    NSString *textValue = [params objectForKey:@"text"];
    
    myTextView.text= textValue;
}

- (void)toggleflash {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if (device.torchAvailable == 1) {
        if (device.torchMode == 0) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }
    }
    
    [device unlockForConfiguration];
}

- (void)stopScanning{ // TODO: add text as a parameter for the messageAsString
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: @"cancelled"]];
    }];
}

#pragma mark - Helpers

- (void)sendScanResult: (CDVPluginResult*)result {
    [self.commandDelegate sendPluginResult: result callbackId: self.scanCallbackId];
}

#pragma mark - ZBarReaderDelegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    return;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    if ([self.scanReader isBeingDismissed]) {
        return;
    }
    
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    ZBarSymbol *symbol = nil;
    CDVPluginResult* pluginResult = nil;
    for (symbol in results) break; // get the first result

    if (self.playBeep) {
        [self.soundBeep play];
    }

    if (!self.scanMultiple) {
        [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
            self.scanInProgress = NO;
            [self sendScanResult: [CDVPluginResult
                                   resultWithStatus: CDVCommandStatus_OK
                                   messageAsString: symbol.data]];
        }];
    } else {
        for (symbol in results) {
            pluginResult= [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: symbol.data];
            [pluginResult setKeepCallbackAsBool:YES];
            [self sendScanResult: pluginResult];
            myTextView.text= symbol.data;
        }
    }
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [self stopScanning];
}

- (void) readerControllerDidFailToRead:(ZBarReaderController*)reader withRetry:(BOOL)retry {
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                                resultWithStatus: CDVCommandStatus_ERROR
                                messageAsString: @"Failed"]];
    }];
}

@end
