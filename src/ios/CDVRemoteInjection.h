//
//  CDVRemoteInjection.h
//

#import <WebKit/WebKit.h>
#import <Cordova/CDVPlugin.h>

#define kCDVRemoteInjectionWebViewDidFinishNavigation @"CDVRemoteInjectionWebViewDidFinishNavigation"

@interface CDVRemoteInjectionWebViewNotificationDelegate : NSObject <WKNavigationDelegate>
    @property (nonatomic,retain) id<WKNavigationDelegate> wrappedDelegate;
@end

@interface CDVRemoteInjectionPlugin : CDVPlugin
{
    CDVRemoteInjectionWebViewNotificationDelegate *notificationDelegate;
}

@property NSArray *preInjectionJSFiles;

@end
