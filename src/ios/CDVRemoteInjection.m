//
//  CDVRemoteInjection.m
//

#import "CDVRemoteInjection.h"
#import <Foundation/Foundation.h>
#import <Cordova/CDVAvailability.h>

@implementation CDVRemoteInjectionWebViewNotificationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation: (WKNavigation *)navigation
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kCDVRemoteInjectionWebViewDidFinishNavigation object:webView]];

    [self.wrappedDelegate webView:webView didFinishNavigation: navigation];
}

@end


@implementation CDVRemoteInjectionPlugin {

}

- (WKWebView *) findWebView
{
    return (WKWebView *)[[self webViewEngine] engineWebView];
}


- (void) pluginInitialize
{
    [super pluginInitialize];

    // Hook to inject cordova into the page.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webView: didFinishNavigation:)
                                                 name:kCDVRemoteInjectionWebViewDidFinishNavigation
                                               object:nil];

    WKWebView *webView = [self findWebView];

    // Wrap the current delegate with our own so we can hook into web view events.
    notificationDelegate = [[CDVRemoteInjectionWebViewNotificationDelegate alloc] init];
    notificationDelegate.wrappedDelegate = [webView navigationDelegate];
    [webView setNavigationDelegate:notificationDelegate];
}

/*
 After page load inject cordova and its plugins.
 */
- (void) webView:(WKWebView *)webView didFinishNavigation: (WKNavigation *)navigation
{
    WKWebView *myWebView = [self findWebView];
    NSString *scheme = myWebView.URL.scheme;

    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        [self injectCordova: myWebView];
    } else {
        NSLog(@"Unsupported scheme for cordova injection: %@.  Skipping...", scheme);
    }
}

- (void) injectCordova:(WKWebView*)webView
{
    NSArray *jsPaths = [self jsPathsToInject];

    NSString *path;
    for (path in jsPaths) {
        NSString *jsFilePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];

        NSURL *jsURL = [NSURL fileURLWithPath:jsFilePath];
        NSString *js = [NSString stringWithContentsOfFile:jsURL.path encoding:NSUTF8StringEncoding error:nil];

        NSLog(@"Injecting JS file into remote site: %@", jsURL.path);
        [webView evaluateJavaScript:js completionHandler:nil];
    }
}

- (NSArray *) jsPathsToInject
{
    // Array of paths that represent JS files to inject into the WebView.  Order is important.
    NSMutableArray *jsPaths = [NSMutableArray new];

    // Pre injection files.
    for (id path in [self preInjectionJSFiles]) {
        [jsPaths addObject: path];
    }

    [jsPaths addObject:@"www/cordova.js"];

    // We load the plugin code manually rather than allow cordova to load them (via
    // cordova_plugins.js).  The reason for this is the WebView will attempt to load the
    // file in the origin of the page (e.g. https://example.com/plugins/plugin/plugin.js).
    // By loading them first cordova will skip the loading process altogether.
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[NSBundle mainBundle] pathForResource:@"www/plugins" ofType:nil]];

    NSString *path;
    while (path = [directoryEnumerator nextObject])
    {
        if ([path hasSuffix: @".js"]) {
            [jsPaths addObject: [NSString stringWithFormat:@"%@/%@", @"www/plugins", path]];
        }
    }
    // Initialize cordova plugin registry.
    [jsPaths addObject:@"www/cordova_plugins.js"];

    return jsPaths;
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

@end
