//
//  Copyright (c) 2010 Cédric Luthi
//

#import <AppKit/NSEvent.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@interface NSEvent (Undocumented)
+ (CGFloat) standardMagnificationThreshold;
@end


static CGFloat cumulativeMagnifyDelta = 0.0;
static BOOL canZoomIn = YES;
static BOOL canZoomOut = YES;

void docZoom_magnifyWithEvent(id self, SEL _cmd, NSEvent *event)
{
	id webView = [self performSelector:@selector(webView)];
	CGFloat threshold = [NSEvent standardMagnificationThreshold];
	cumulativeMagnifyDelta += [event magnification];
	if (canZoomIn && cumulativeMagnifyDelta > threshold)
	{
		[webView performSelector:@selector(zoomPageIn:) withObject:self];
		cumulativeMagnifyDelta = 0.0;
		canZoomIn = NO;
		canZoomOut = YES;
	}
	else if (canZoomOut && cumulativeMagnifyDelta < -threshold)
	{
		[webView performSelector:@selector(zoomPageOut:) withObject:self];
		cumulativeMagnifyDelta = 0.0;
		canZoomOut = NO;
		canZoomIn = YES;
	}
}

void docZoom_beginGestureWithEvent(id self, SEL _cmd, NSEvent *event)
{
	cumulativeMagnifyDelta	= 0.0;
	canZoomIn = YES;
	canZoomOut = YES;
}

@interface DocZoom : NSObject
@end

@implementation DocZoom

+ (void) pluginDidLoad:(NSBundle *)plugin
{
	Class DVWindow = NSClassFromString(@"DVWindow");
	SEL beginGestureWithEvent = @selector(beginGestureWithEvent:);
	SEL magnifyWithEvent = @selector(magnifyWithEvent:);
	Method DVWindow_magnifyWithEvent = class_getInstanceMethod(DVWindow, magnifyWithEvent);
	
	BOOL success = class_addMethod(DVWindow, beginGestureWithEvent, (IMP)docZoom_beginGestureWithEvent, method_getTypeEncoding(DVWindow_magnifyWithEvent));
	if (success)
		method_setImplementation(DVWindow_magnifyWithEvent, (IMP)docZoom_magnifyWithEvent);
	
	NSString *pluginName = [[[plugin bundlePath] lastPathComponent] stringByDeletingPathExtension];
	NSString *version = [plugin objectForInfoDictionaryKey:@"CFBundleVersion"];
	BOOL isXcode = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Xcode"];
	if (isXcode)
	{
		if (success)
			NSLog(@"%@ %@ loaded successfully", pluginName, version);
		else
			NSLog(@"%@ %@ failed to load", pluginName, version);		
	}
}

@end
