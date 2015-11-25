/*
     File: ControllerBrowsing.m
 Abstract: An extension or category of the Controller class responsible for the IKImageBrowserView.
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


// our datasource object : represents one item in the image browser
@interface MyImageObject : NSObject
{
    NSString *path; 
}
@end

@implementation MyImageObject

- (void)dealloc
{
	[path release];
	[super dealloc];
}

- (void)setPath:(NSString *)aPath
{
	if (path != aPath)
	{
		[path release];
		path = [aPath copy];
	}
}

#pragma mark -
#pragma mark item data source protocol

- (NSString *)imageRepresentationType
{
	return IKImageBrowserPathRepresentationType;
}

- (id)imageRepresentation
{
	return path;
}

- (NSString *)imageUID
{
	return path;
}

- (id)imageTitle
{
	return [path lastPathComponent];
}

@end


@implementation Controller(Browsing)

#pragma mark -
#pragma mark import images from file system

// -------------------------------------------------------------------------------
//	addImagesFromDirectory:path
//
//	code that parse a repository and add all entries to our datasource array.
// -------------------------------------------------------------------------------
- (void)addImageWithPath:(NSString *)path
{   
	MyImageObject *item;
    
	NSString *filename = [path lastPathComponent];

	// skip '.*'
	if ([filename length] > 0)
	{
		unichar ch = [filename characterAtIndex:0];
		if (ch == '.')
		{
			return;
		}
	}
	
	item = [[MyImageObject alloc] init];	
	[item setPath:path];
	[images addObject:item];
	[item release];
}

// -------------------------------------------------------------------------------
//	addImagesFromDirectory:path
// -------------------------------------------------------------------------------
- (void)addImagesFromDirectory:(NSString *)path
{
	int i, n;
	BOOL dir;
	
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
	if (dir)
	{
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
		
		n = [content count];
        
		for (i=0; i<n; i++)
			[self addImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
	}
	else
	{
		[self addImageWithPath:path];
	}
	
	[imageBrowser reloadData];
}


#pragma mark -
#pragma mark Setup Browsing

// -------------------------------------------------------------------------------
//	setupBrowsing:
// -------------------------------------------------------------------------------
- (void)setupBrowsing
{
	// allocate our datasource array: will contain instances of MyImageObject
	images = [[NSMutableArray alloc] init];
    
	// as default, add the contents of /Library/Desktop Pictures/ to the image browser
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *finalPath = [libraryDirectory stringByAppendingPathComponent:@"Desktop Pictures"];
	[self addImagesFromDirectory:finalPath];
	
	// set the same location to our path control
	[pathControl setURL:[NSURL fileURLWithPath:finalPath]];
}

// -------------------------------------------------------------------------------
//	changeLocationAction:sender:
// -------------------------------------------------------------------------------
- (IBAction)changeLocationAction:(id)sender
{
	NSPathControl* pathCntl = (NSPathControl *)sender;
	
	NSPathComponentCell *component = [pathCntl clickedPathComponentCell];	// find the path component selected
	[images removeAllObjects];						// remove the old content since we are switching directories
	[self addImagesFromDirectory:[[component URL] path]];	// add the new content
	[pathCntl setURL:[component URL]];			// set the url to the path control
	[imageBrowser reloadData];				// make sure the browser reloads its content
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel
{	
	// change the wind title and choose buttons title
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setTitle:@"Choose a directory of images"];
	[openPanel setPrompt:@"Choose"];
}

// -------------------------------------------------------------------------------
//	menuItemAction:sender:
//
//  This is the action method from our custom menu item: "Home" or "Desktop Pictures". 
// -------------------------------------------------------------------------------
- (void)menuItemAction:(id)sender
{
	// set the path control to home directory
	[pathControl setURL:[sender representedObject]];	// goto the URL set on this menu item
	
	[images removeAllObjects];		// remove the old content since we are switching directories
	[self addImagesFromDirectory:[sender representedObject]];	// add the new content
}

// -------------------------------------------------------------------------------
//	willPopUpMenu:menu:
//
//	Before the menu is displayed, add the "Home" directory.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	// add the "Home" menu item
	NSMenuItem* newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Home" action:@selector(menuItemAction:) keyEquivalent:@""];
	[newItem setTarget:self];
	[newItem setRepresentedObject:NSHomeDirectory()];	// use the URL upon menu item selection in "menuItemAction"
	NSImage* menuItemIcon = [[NSWorkspace sharedWorkspace] iconForFile:NSHomeDirectory()];
	[menuItemIcon setSize:NSMakeSize(16, 16)];
	[newItem setImage:menuItemIcon];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:newItem];
	[newItem release];
	
	// add the Desktop Pictures menu item
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *finalPath = [libraryDirectory stringByAppendingPathComponent:@"Desktop Pictures"];
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Desktop Pictures" action:@selector(menuItemAction:) keyEquivalent:@""];
	[newItem setTarget:self];
	[newItem setRepresentedObject:finalPath];			// use the URL upon menu item selection in "menuItemAction"
	menuItemIcon = [[NSWorkspace sharedWorkspace] iconForFile:finalPath];
	[menuItemIcon setSize:NSMakeSize(16, 16)];
	[newItem setImage:menuItemIcon];
	[menu addItem:newItem];
	[newItem release];
}


#pragma mark -
#pragma mark Actions

// -------------------------------------------------------------------------------
//	zoomSliderDidChange:sender:
// -------------------------------------------------------------------------------
- (IBAction)zoomSliderDidChange:(id)sender
{
	[imageBrowser setZoomValue:[sender floatValue]];
}


#pragma mark -
#pragma mark IKImageBrowserDataSource

// -------------------------------------------------------------------------------
//	numberOfItemsInImageBrowser:view:
//
// Implement image-browser's datasource protocol.
// Our datasource representation is a simple mutable array.
// -------------------------------------------------------------------------------
- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
	return [images count];
}

// -------------------------------------------------------------------------------
//	imageBrowser:itemAtIndex:index
// -------------------------------------------------------------------------------
- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
	return [images objectAtIndex:index];
}


#pragma mark -
#pragma mark optional datasource methods

// -------------------------------------------------------------------------------
//	imageBrowser:removeItemsAtIndexes:indexes
//
//	User wants to remove one or more items within the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[images removeObjectsAtIndexes:indexes];
	[imageBrowser reloadData];
}

// -------------------------------------------------------------------------------
//	imageBrowser:moveItemsAtIndexes:indexes:toIndex
//
//	User wants to move an image within the image browser.
// -------------------------------------------------------------------------------
- (BOOL)imageBrowser:(IKImageBrowserView *)aBrowser moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(unsigned int)destinationIndex
{
	NSArray *tempArray = [images objectsAtIndexes:indexes];
	[images removeObjectsAtIndexes:indexes];
	
	destinationIndex -= [indexes countOfIndexesInRange:NSMakeRange(0, destinationIndex)];
	[images insertObjects:tempArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [tempArray count])]];
	[imageBrowser reloadData];
	
	return YES;
}


#pragma mark -
#pragma mark IKImageBrowserDelegate

// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
	NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];	
	
	if ([selectionIndexes count] > 0)
	{
		MyImageObject *anItem = [images objectAtIndex:[selectionIndexes firstIndex]];
		NSString* path = [anItem imageRepresentation];
		
		BOOL isDirectory = NO;
		[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];

		if (!isDirectory)
		{
			NSURL *imageURL = [NSURL fileURLWithPath:path];
			NSError *error = nil;
			[[NSWorkspace sharedWorkspace] setDesktopImageURL:imageURL forScreen:curScreen options:nil error:&error];
			if (error)
				[NSApp presentError:error];
		}
	}
}

@end
