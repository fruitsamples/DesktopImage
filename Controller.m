/*
     File: Controller.m
 Abstract: The primary window controller of this application.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "Controller.h"
#import "ControllerBrowsing.h"

@implementation Controller

- (void)dealloc
{
	[images release];
	[super dealloc];
}

- (void)updateScreenOptions:(NSScreen*)screen
{
	if (screen)
	{
		NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen];
		
		// the value is an NSNumber containing an NSImageScaling (scaling factor)
		NSNumber *scalingFactor = [screenOptions objectForKey:NSWorkspaceDesktopImageScalingKey];
		[scalingPopup selectItemAtIndex:[scalingFactor integerValue]];
		
		// the value is an NSNumber containing a BOOL (allow clipping)
		NSNumber *allowClipping = [screenOptions objectForKey:NSWorkspaceDesktopImageAllowClippingKey];
		[[clippingCheckbox cell] setState:[allowClipping boolValue]];
		
		// the value is an NSColor (fill color)
		NSColor *fillColorValue = [screenOptions objectForKey:NSWorkspaceDesktopImageFillColorKey];
		if (fillColorValue)
			[fillColor setColor:fillColorValue];
	}
}

- (void)awakeFromNib
{
	[self setupBrowsing];	// setup our image browser and initially point it to /Library/Desktop Pictures/
	
	// build the screens popup menu
	NSMenu *screensMenu = [[NSMenu alloc] initWithTitle:@"screens"];
	NSArray *screens = [NSScreen screens];
	
	NSScreen *iterScreen;
	NSUInteger screenIndex = 1;
	for (iterScreen in screens)
	{
		NSMenuItem *item;
		NSString *menuTitle;
		if (iterScreen == [NSScreen mainScreen])
		{
			menuTitle = [NSString stringWithString:@"Main Screen"];
		}
		else
		{
			menuTitle = [NSString stringWithFormat:@"Screen %ld", screenIndex];
		}
		item = [[NSMenuItem alloc] initWithTitle:menuTitle action:@selector(screensMenuAction:) keyEquivalent:@""];
		[item setRepresentedObject:[iterScreen retain]];
		[screensMenu addItem:item];
		if (iterScreen == [NSScreen mainScreen])
		{
			// select and remember the main screen at startup
			[screenPopup selectItem:item];
			curScreen = iterScreen;
		}
		[item release];
		screenIndex++;
	}
	
	[screenPopup setMenu:screensMenu];
	[screensMenu release];
	
	[self updateScreenOptions:curScreen];
}

- (IBAction)screensMenuAction:(id)sender
{
	NSMenuItem *chosenItem = (NSMenuItem *)sender;
	NSScreen *screen = [chosenItem representedObject];
	curScreen = screen;	// keep track of the current screen selection
	[self updateScreenOptions:screen];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


#pragma mark - Actions

- (IBAction)scalingAction:(id)sender
{
	// get the current screen options
	NSMutableDictionary *screenOptions = [[[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen] mutableCopy];
	
	// the value is an NSNumber containing an NSImageScaling (scaling factor)
	NSPopUpButton *popupButton = sender;
	NSNumber *scalingFactor = [NSNumber numberWithInt:[popupButton indexOfSelectedItem]];

	// swap out the old scaling factor with the new
	[screenOptions removeObjectForKey: NSWorkspaceDesktopImageScalingKey];
	[screenOptions setObject:scalingFactor forKey:NSWorkspaceDesktopImageScalingKey];
	
	NSError *error;
	NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:curScreen];
	if (![[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL forScreen:curScreen options:screenOptions error:&error])
	{
		[self presentError:error];
	}
	
	[screenOptions release];
}

- (IBAction)allowClippingAction:(id)sender
{
	// get the current screen options
	NSMutableDictionary *screenOptions = [[[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen] mutableCopy];
	
	// the value is an NSNumber containing a BOOL (allow clipping)
	NSButton *checkbox = sender;
	NSNumber *allowClipping = [NSNumber numberWithBool:[checkbox state]];
	
	// swap out the old clip value with the new
	[screenOptions removeObjectForKey: NSWorkspaceDesktopImageAllowClippingKey];
	[screenOptions setObject:allowClipping forKey:NSWorkspaceDesktopImageAllowClippingKey];
	
	NSError *error;
	NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:curScreen];
	if (![[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL forScreen:curScreen options:screenOptions error:&error])
	{
		[self presentError:error];
	}
	
	[screenOptions release];
}

- (IBAction)fillColorAction:(id)sender
{
	// get the current screen options
	NSMutableDictionary *screenOptions = [[[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen] mutableCopy];

	// the value is an NSColor (fill color)
	NSColorWell *colorWell = sender;
	NSColor *fillColorValue = [colorWell color];

	// swap out the old fill color with the new
	[screenOptions removeObjectForKey: NSWorkspaceDesktopImageFillColorKey];
	[screenOptions setObject:fillColorValue forKey:NSWorkspaceDesktopImageFillColorKey];
	
	NSError *error;
	NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:curScreen];
	if (![[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL forScreen:curScreen options:screenOptions error:&error])
	{
		[self presentError:error];
	}
	
	[screenOptions release];
}

@end
