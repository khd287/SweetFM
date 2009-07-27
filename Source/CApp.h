//
//  CApp.h
//  SweetFM
//
//  Created by Q on 23.05.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>

@class SkinWindow;
@class JSApp;

@class CDevices;
@class CPreferences;

@class SUUpdater;


extern NSString * const HotKeyToggleAppNotification;
extern NSString * const OpenLastFMProfileNotification;

extern NSString * const AppDemoWillQuitNotification;

@interface CApp : NSObject {

	IBOutlet SkinWindow *skinWindow;
	
	BOOL windowShouldHide;
	BOOL skinLoadedFirstTime;
	
	JSApp *appProxy;
	
	CGWindowLevel inactiveWindowLevel;
	NSStatusItem *statusItem;
		
	//
	// Other NIB handlers
	//
	CPreferences *prefs;
	
	//
	// Controller
	//
	CDevices *device;
}

- (NSMenu *)applicationStatusBarMenu;
- (void)showStatusBarMenu:(id)sender;

- (IBAction)togglePreferences:(id)sender;
- (IBAction)openProfilePage:(id)sender;

- (void)loadSkin;

@end
