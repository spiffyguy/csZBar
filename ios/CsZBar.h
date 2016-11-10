#import <Cordova/CDV.h>

#import "ZBarSDK.h"
#import <UIKit/UIKit.h>

@interface CsZBar : CDVPlugin <ZBarReaderDelegate>

- (void)scan: (CDVInvokedUrlCommand*)command;
- (void)toggleflash;
- (void)stopScanning;
- (void)lockLensPosition;
- (void)setDisplayText:(CDVInvokedUrlCommand*)command;



@end
