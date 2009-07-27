//
//  CApp.m
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

#import "CApp.h"

#import "SkinWindow.h"
#import "JSApp.h"

#import "CDevices.h"
#import "CPreferences.h"

#import "HRemote.h"
#import "HGrowl.h"
#import "HSettings.h"

#import "XLog.h"
#import "SkinSelectView.h"
#import "SysInfo.h"

#import "SUUpdater.h"


NSString * const HotKeyToggleAppNotification = @"HotKeyToggleAppNotification";
NSString * const OpenLastFMProfileNotification = @"OpenLastFMProfileNotification";

NSString * const AppDemoWillQuitNotification = @"AppDemoWillQuitNotification";

@interface CApp (Private)

- (void)windowChangePinned;

- (void)willResignActive;
- (void)didBecomeActive;

- (void)hideMainWindow;
- (void)showMainWindow;

@end

@implementation CApp

- (void)awakeFromNib
{	
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	
	//
	// Check display settings for dock
	//
	if([HSettings showDockIcon])
	{
		XLog(@"Switching to dock mode...");
				
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		OSStatus status =  TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		
		if(status)
			NSLog(@"Error switching to foreground app mode (%i)", status);
		
		//
		// This is necessary. Otherwise in some cases the menubar is not displayed.
		//
		[[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle mainBundle] bundlePath]];
	}
	
	//
	// Check display settings for status bar
	//
	if([HSettings showStatusBarIcon])
	{
		NSStatusBar *bar = [NSStatusBar systemStatusBar];
		statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
		
		[statusItem setImage:[NSImage imageNamed:@"statusbar-black"]];
		[statusItem setAlternateImage:[NSImage imageNamed:@"statusbar-white"]];
		[statusItem setTarget:self];
		[statusItem setHighlightMode:YES];
		[statusItem setAction:@selector(showStatusBarMenu:)];
		[statusItem sendActionOn:NSLeftMouseDownMask | NSPeriodicMask];
	}

	//
	// Register notifications
	//
	[notify addObserver:self selector:@selector(appReady)
								 name:NSApplicationDidFinishLaunchingNotification object:nil];	
	[notify addObserver:self selector:@selector(skinFinishedLoading)
								 name:SkinViewDidFinishLoadingNotification object:nil];
	[notify addObserver:self selector:@selector(loadSkin)
								 name:SkinBundleChangedNotification object:nil];
	[notify addObserver:self selector:@selector(toggleApp)
								 name:HotKeyToggleAppNotification object:nil];
	[notify addObserver:self selector:@selector(willResignActive)
								 name:NSApplicationWillResignActiveNotification object:nil];
	[notify addObserver:self selector:@selector(didBecomeActive)
								 name:NSApplicationDidBecomeActiveNotification object:nil];
	[notify addObserver:self selector:@selector(willResignActive)
								 name:JSAppCloseWindowNotification object:nil];
	[notify addObserver:self selector:@selector(windowChangePinned)
								 name:JSAppPinToggleNotification object:nil];
		
	//
	// Register profile open notification
	//
	[notify addObserver:self selector:@selector(openProfilePage:)
								 name:OpenLastFMProfileNotification object:nil];
	
	//
	// Register to receive lastfm URL schemes
	//
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
																										 andSelector:@selector(getUrl:withReplyEvent:) 
																									 forEventClass:kInternetEventClass
																											andEventID:kAEGetURL];
	//
	// Load other NIBs
	//
	prefs = [[CPreferences alloc] init];
	
	//
	// Set default window level
	//
	inactiveWindowLevel = NSNormalWindowLevel;
	
	//
	// Install handlers
	//
	[HRemote install];
	[HGrowl install];
	[HSettings install];
}

- (void)appReady
{	
	//
	// Load skin
	//
	appProxy = [JSApp new];
	
	[self loadSkin];
}

- (void)loadSkin
{
	[skinWindow setAlphaValue:0];
	
	SkinBundle *bundle = [HSettings selectedSkin];
	[skinWindow loadSkinFromURL:[bundle location]
					 installScriptProxy:appProxy];
}

- (void)windowChangePinned
{
	[HSettings setWindowPinned:appProxy.pinned];
	XLog(@"Window pinned on level %i", [HSettings windowPinLevel]);
}

- (void)toggleApp
{
	XMark();
	
	if(![[NSApplication sharedApplication] isActive])
		[self showMainWindow];
	else if([skinWindow alphaValue])
		[self hideMainWindow];
	else
		[self showMainWindow];
}

- (void)willResignActive
{
	if(appProxy.pinned)
	{
		switch([HSettings windowPinLevel])
		{
			case PinOnTop: inactiveWindowLevel = NSStatusWindowLevel; break;
			default: inactiveWindowLevel = kCGDesktopWindowLevel; break;
		}
		
		[skinWindow setLevel:inactiveWindowLevel];
	}
	else
		[self hideMainWindow];
}

- (void)didBecomeActive
{
	[skinWindow setLevel:NSNormalWindowLevel];
	[self showMainWindow];
}

- (void)hideMainWindow
{
	windowShouldHide = YES;
	[[skinWindow animator] setAlphaValue:0.0f];
	[[NSApplication sharedApplication] deactivate];
	[self performSelector:@selector(delayedHide) withObject:nil afterDelay:0.5];
}

- (void)showMainWindow
{
	windowShouldHide = NO;
	[skinWindow makeKeyAndOrderFront:self];
	[[skinWindow animator] setAlphaValue:1.0f];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)delayedHide
{
	if(windowShouldHide)
		[skinWindow orderOut:self];
}

- (void)skinFinishedLoading
{
	XLog(@"skinFinishedLoading");
	[skinWindow setAlphaValue:1.0];
	[skinWindow makeKeyAndOrderFront:self];
	[skinWindow display];
	
	[appProxy uiSetScrobbleEnabled:[HSettings scrobbleEnabled]];
	
	//
	// Init device controller
	//
	if(!device)
		device = [[CDevices alloc] initWithAppProxy:appProxy];
	
	[device refreshInterface];
	
	//
	// Restore window state
	//
	[appProxy uiSetPinEnabled:[HSettings windowPinned]];
	[self windowChangePinned];
	
	//
	// Tune to last station if necessary (only first startup)
	//
	if(skinLoadedFirstTime)
		return;
	
	skinLoadedFirstTime = YES;
	
	NSString *station = [HSettings lastStation];
	if(station && [HSettings playOnStartup])
	{
		NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
		[notify postNotificationName:TuneToLastStationNotification object:station];
	}
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	XMark();
	
	//
	// Write received URL to settings
	//
	NSString *station = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	[HSettings setLastStation:station];
	
	if(station)
	{
		NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
		[notify postNotificationName:TuneToLastStationNotification object:[HSettings lastStation]];
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames 
{
	[prefs installSkinAtPath:[filenames objectAtIndex:0]];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag 
{
	[self didBecomeActive];
	return YES;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return [device deviceControlMenu];
}

- (NSMenu *)applicationStatusBarMenu
{
	NSMenu *menu = [self applicationDockMenu:[NSApplication sharedApplication]];
	
	//
	// Append control stuff
	//
	[menu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *item = nil;
	
	
	item = [[NSMenuItem alloc] initWithTitle:@"Show/Hide"
																		action:@selector(toggleApp) 
														 keyEquivalent:@""];
	[item setTarget:self];
	[menu addItem:item];
	[item release];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:@"Preferences..."
																		action:@selector(togglePreferences:) 
														 keyEquivalent:@""];
	[item setTarget:self];
	[menu addItem:item];
	[item release];
		
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:@"Close"
																		action:@selector(terminate:) 
														 keyEquivalent:@""];
	[item setTarget:[NSApplication sharedApplication]];
	[menu addItem:item];
	[item release];
	
	return menu;
}

- (void)showStatusBarMenu:(id)sender
{
	[statusItem popUpStatusItemMenu:[self applicationStatusBarMenu]];
}

//
// IBActions
//
#pragma mark IBActions
#pragma mark -

- (IBAction)togglePreferences:(id)sender
{
	[prefs toggleWindow];
}

- (IBAction)openProfilePage:(id)sender
{
	NSString *userName = [HSettings lastFmUserName];
	
	if(userName)
	{
		//
		// If username is not nil build URL and open user profile page
		//
		NSURL *url = [NSURL URLWithString:
									[NSString stringWithFormat:@"http://www.last.fm/user/%@", userName]];
		
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}

@end
