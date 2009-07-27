//
//  ShortcutsView.m
//  SweetFM
//
//  Created by Q on 02.06.09.
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

#import "ShortcutsView.h"

#import "SRRecorderControl.h"
#import "SRValidator.h"

#import "CMHotKey.h"
#import "CMHotKeyCenter.h"
#import "CMKeyCombo.h"

#import "CApp.h"
#import "JSApp.h"

#import "XLog.h"



@implementation ShortcutsView

- (void)awakeFromNib
{
	//
	// Set autosave names and load key combos
	//
	NSDictionary *recorders = [NSDictionary dictionaryWithObjectsAndKeys:
														 toggleRecroder, @"kToggleRecorder",
														 profileRecorder, @"kProfileRecorder",
														 playPauseRecorder, @"kPlayPauseRecorder",
														 stopRecorder, @"kStopRecorder",
														 nextRecorder, @"kNextRecorder",
														 loveRecorder, @"kLoveRecorder",
														 playlistRecorder, @"kPlaylistRecorder",
														 banRecorder, @"kBanRecorder",
														 nil];
	
	for(NSString *key in recorders)
	{
		SRRecorderControl *recorder = [recorders objectForKey:key];
		[recorder setAutosaveName:key];
		[recorder loadKeyCombo];
	}
}

//
// Shortcut recorder delegate
//
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder
							 isKeyCode:(signed short)keyCode
					 andFlagsTaken:(unsigned int)flags 
									reason:(NSString **)aReason 
{
	XMark();
	SRValidator *valid = [[[SRValidator alloc] init] autorelease];
	
	NSError *err;
	BOOL taken = [valid isKeyCode:keyCode andFlagsTaken:flags error:&err];
	
	return taken;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder
			 keyComboDidChange:(KeyCombo)newKeyCombo 
{
	XMark();
	
	NSDictionary *recorders = [NSDictionary dictionaryWithObjectsAndKeys:
														 toggleRecroder, @"handleAppToggle", 
														 profileRecorder, @"handleOpenProfile",
														 playPauseRecorder, @"handlePlayPause",
														 stopRecorder, @"handleStop",
														 nextRecorder, @"handleNext",
														 loveRecorder, @"handleLove",
														 playlistRecorder, @"handlePlaylist",
														 banRecorder, @"handleBan",
														 nil];
	
	CMHotKeyCenter *center = [CMHotKeyCenter sharedCenter];
	
	for(NSString *slcString in recorders)
	{
		if([aRecorder isEqual:[recorders objectForKey:slcString]])
		{
			if(newKeyCombo.code == -1)
			{
				XLog(@"Unregister hotkey (%@)", slcString);
				[center unregisterHotKeyForIdentifier:slcString];
			}
			else
			{
				XLog(@"Register hotkey (%@)", slcString);
				unsigned int flags = [aRecorder cocoaToCarbonFlags:newKeyCombo.flags];
				CMKeyCombo *combo = [CMKeyCombo keyComboWithKeyCode:newKeyCombo.code
																									modifiers:flags];
			
				[center registerHotKeyForIdentifier:slcString
																		 target:self 
																		 action:NSSelectorFromString(slcString)
																	 keyCombo:combo];				
			}
		}
	}
}

//
// Hotkey handler methods
//
- (void)handleAppToggle
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:HotKeyToggleAppNotification
																											object:nil];
}

- (void)handleOpenProfile
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:OpenLastFMProfileNotification
																											object:nil];
}

- (void)handlePlayPause
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppPlayPauseNotification
																											object:nil];
}

- (void)handleStop
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppStopNotification
																											object:nil];
}

- (void)handleNext
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppNextNotification
																											object:nil];
}

- (void)handleLove
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppLoveNotification
																											object:nil];
}

- (void)handlePlaylist
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppAddToPlaylistNotification
																											object:nil];
}

- (void)handleBan
{
	XMark();
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppBanNotification
																											object:nil];
}

@end
