DesktopImage

"DesktopImage" is a Cocoa sample application that demonstrates how to use the NSDesktopImages category of NSWorkspace.  It shows how to use this set of APIs to set the desktop image for a given screen.  An NSURL is used to describe that image.

An "options" dictionary controls how the image is presented: scaling factor, clipping state which affects the interpretation of Proportional scaling types, and fill color applied to any empty space around the image.


Sample Requirements
The supplied Xcode project was created using Xcode v3.2 running under Mac OS X 10.6 or later.


Using the Sample
Build and run the sample using Xcode.  At the top of the window select which monitor you want to be affected.  Then apply any of the 3 screen options.  Next choose the image from a grid of images.  You can browse to another directory by using the path popup control at the bottom.

To review the code that sets the desktop image, refer to this method in ControllerBrowsing.h:
	- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser


Changes from Previous Versions
n/a


Packaging List
Controller.h
Controller.m
The main controller class in charge of the app's main window.

ControllerBrowsing.h
ControllerBrowsing.m
An extension or category of Controller class responsible for controlling the IKImageBrowserView.


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting page.


Developer Technical Support
The Apple Developer Connection Developer Technical Support (DTS) team is made up of highly qualified engineers with development expertise in key Apple technologies. Whether you need direct one-on-one support troubleshooting issues, hands-on assistance to accelerate a project, or helpful guidance to the right documentation and sample code, Apple engineers are ready to help you.  Refer to the Apple Developer Technical Support page.

Copyright (C) 2008-2009 Apple Inc. All rights reserved.