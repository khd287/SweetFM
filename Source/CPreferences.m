//
//  CPreferences.m
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

#import "CPreferences.h"

#import <QuartzCore/QuartzCore.h>

#import "SkinSelectView.h"
#import "HSettings.h"
#import "XLog.h"
#import "Exporter.h"
#import "TFScrobble.h"

#import "JSApp.h"


@implementation CPreferences

@synthesize newView, selectedItem;

+ (void)initialize 
{
	//
	// Load the scrobble transformer
	//
	TFScrobble *transformer = [[TFScrobble alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"ScrobbleDisplayTransformer"];
	[transformer release];
}

- (id)init
{
	if(self = [super init])
	{
		XLog(@"Init prefs");
		[NSBundle loadNibNamed:@"Prefs" owner:self];
	}
	
	return self;
}

- (void)dealloc
{
	self.newView = nil;
	self.selectedItem = nil;
	[super dealloc];
}

- (void)awakeFromNib
{
	NSLog(@"Prefs loaded");
	// 
	// Select general item
	//
	[self animateToView:general toolbarItem:[[toolbar items] objectAtIndex:0]];
	
	//
	// Build playlist menu
	//
	NSArray *staticLists = [[Exporter instance] staticPlaylists];
	NSString *exportTo = [HSettings exportPlaylistName];
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem *item = nil;
	
	//
	// Add current station item
	//
	item = [[NSMenuItem alloc] initWithTitle:CurrentStationPlaylistName action:nil keyEquivalent:@""];
	[item setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
	[item setTag:-1];
	[menu addItem:item];
	[item release];
	
	//
	// Add SweetFM playlist item
	//
	item = [[NSMenuItem alloc] initWithTitle:SweetFMPlaylistName action:nil keyEquivalent:@""];
	[item setImage:[NSImage imageNamed:@"pref-playlistGreen"]];
	[menu addItem:item];
	[item release];
	
	//
	// Add static iTunes lists
	//
	for(NSString *list in staticLists)
	{
		if([list isEqualToString:SweetFMPlaylistName])
			continue;
		
		item = [[NSMenuItem alloc] initWithTitle:list action:nil keyEquivalent:@""];
		[item setImage:[NSImage imageNamed:@"pref-playlist"]];
		[menu addItem:item];
		[item release];
	}
	
	[playlists setMenu:menu];	
	
	if(exportTo)
		[playlists selectItemWithTitle:exportTo];
	else
		[playlists selectItemWithTitle:CurrentStationPlaylistName];
	
	[menu release];
	
	//
	// Load EQ
	//	
	NSString *itemName = @"Custom";
	NSArray *preset = [HSettings eqPreset];
	
	presetDict = [[NSDictionary dictionaryWithObjectsAndKeys:
								 [HSettings eqPresetFlat], @"Flat",
								 [HSettings eqPresetAcoustic], @"Acoustic",
								 [HSettings eqPresetDance], @"Dance",
								 [HSettings eqPresetElectronic], @"Electronic",
								 [HSettings eqPresetHipHop], @"Hip-Hop",
								 [HSettings eqPresetJazz], @"Jazz",
								 [HSettings eqPresetBass], @"Bass",
								 [HSettings eqPresetTreble], @"Treble",
								 [HSettings eqPresetPop], @"Pop",
								 [HSettings eqPresetRock], @"Rock",
								 nil] retain];
	
	for(NSString *key in presetDict)
	{
		NSArray *p = [presetDict objectForKey:key];
		if([p isEqualToArray:preset])
		{
			itemName = key;
			break;
		}
	}
											
	[eqPreset selectItemWithTitle:itemName];
	
	//
	// Register for EQ notifications
	//
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presetSet:)
																							 name:EQChangedNotification object:nil];
	
	//
	// Load preset
	//
	[self presetSet:nil];
}

- (HSettings *)settings
{
	return [HSettings instance];
}

- (void)installSkinAtPath:(NSString *)path
{
	XLog(path);
	
	NSString *target = [[HSettings skinPath] stringByAppendingPathComponent:[path lastPathComponent]];
	[[NSFileManager defaultManager] copyPath:path toPath:target handler:nil];
	[skins reload];
}

- (void)toggleWindow
{
	if([window isVisible])
		[window orderOut:self];
	else
		[window makeKeyAndOrderFront:self];
}

- (void)animateToView:(NSView *)aView toolbarItem:(NSToolbarItem *)aItem
{
	if(!aView || [[aItem itemIdentifier] isEqualToString:[selectedItem itemIdentifier]])
		return;
	
	[toolbar setSelectedItemIdentifier:[aItem itemIdentifier]];
	
	
	for(NSView *subview in [[window contentView] subviews])
		[subview removeFromSuperview];
	
	[window setTitle:[aItem label]];
	[[window contentView] setNeedsDisplay:YES];
	self.newView = aView;
	
	NSSize oldSize = [[window contentView] frame].size;
	NSSize newSize = [newView frame].size;
	
	NSSize diff = NSMakeSize(newSize.width-oldSize.width, newSize.height-oldSize.height);
	
	NSRect oldFrame = [window frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x, 
															 oldFrame.origin.y-diff.height, 
															 oldFrame.size.width+diff.width, 
															 oldFrame.size.height+diff.height);
	
	CABasicAnimation *ani = [CABasicAnimation animation];
	ani.fromValue = [NSValue valueWithRect:oldFrame];
	ani.toValue = [NSValue valueWithRect:newFrame];
	ani.delegate = self;
	
	[window setAnimations:[NSDictionary dictionaryWithObject:ani forKey:@"frame"]];
	[[window animator] setFrame:newFrame display:YES animate:YES];
	
	self.selectedItem = aItem;
}

- (IBAction)showGeneral:(id)sender
{
	[self animateToView:general toolbarItem:sender];
}

- (IBAction)showLastFM:(id)sender
{
	[self animateToView:lastfm toolbarItem:sender];
}

- (IBAction)showShortcuts:(id)sender
{
	[self animateToView:shortcuts toolbarItem:sender];
}

- (IBAction)showSkins:(id)sender
{
	[self animateToView:skins toolbarItem:sender];
}

- (IBAction)showEqualizer:(id)sender
{
	[self animateToView:equalizer toolbarItem:sender];
}

- (IBAction)showAdvanced:(id)sender
{
	[self animateToView:advanced toolbarItem:sender];
}

- (void)presetSet:(NSNotification *)notify
{
	XMark();
	
	NSString *itemName = @"Custom";
	NSArray *preset = [HSettings eqPreset];
	
	presetDict = [[NSDictionary dictionaryWithObjectsAndKeys:
								 [HSettings eqPresetFlat], @"Flat",
								 [HSettings eqPresetAcoustic], @"Acoustic",
								 [HSettings eqPresetDance], @"Dance",
								 [HSettings eqPresetElectronic], @"Electronic",
								 [HSettings eqPresetHipHop], @"Hip-Hop",
								 [HSettings eqPresetJazz], @"Jazz",
								 [HSettings eqPresetBass], @"Bass",
								 [HSettings eqPresetTreble], @"Treble",
								 [HSettings eqPresetPop], @"Pop",
								 [HSettings eqPresetRock], @"Rock",
								 nil] retain];
	
	for(NSString *key in presetDict)
	{
		NSArray *p = [presetDict objectForKey:key];
		if([p isEqualToArray:preset])
		{
			itemName = key;
			break;
		}
	}
	
	[eqPreset selectItemWithTitle:itemName];
	
	[eqBand32 setDoubleValue:[(NSNumber *)[preset objectAtIndex:2] doubleValue]];
	[eqBand64 setDoubleValue:[(NSNumber *)[preset objectAtIndex:5] doubleValue]];
	[eqBand125 setDoubleValue:[(NSNumber *)[preset objectAtIndex:8] doubleValue]];
	[eqBand250 setDoubleValue:[(NSNumber *)[preset objectAtIndex:11] doubleValue]];
	[eqBand500 setDoubleValue:[(NSNumber *)[preset objectAtIndex:14] doubleValue]];
	[eqBand1k setDoubleValue:[(NSNumber *)[preset objectAtIndex:17] doubleValue]];
	[eqBand2k setDoubleValue:[(NSNumber *)[preset objectAtIndex:20] doubleValue]];
	[eqBand4k setDoubleValue:[(NSNumber *)[preset objectAtIndex:23] doubleValue]];
	[eqBand8k setDoubleValue:[(NSNumber *)[preset objectAtIndex:26] doubleValue]];
	[eqBand16k setDoubleValue:[(NSNumber *)[preset objectAtIndex:29] doubleValue]];
	
	[eqGain setDoubleValue:[HSettings eqGain]];
}

- (IBAction)presetChanged:(id)sender
{
	XMark();

	NSString *title = [eqPreset title];
	
	for(NSString *key in presetDict)
	{
		if([title isEqualToString:key])
		{
			[HSettings setEqPreset:[presetDict objectForKey:key]];
			break;
		}
	}
}

- (IBAction)gainModified:(id)sender
{
	XMark();
	
	[HSettings setEqGain:[eqGain doubleValue]];
}

- (IBAction)bandModified:(id)sender
{
	XMark();
	
	//
	// Calculate other bands
	//
	double band32 = [eqBand32 doubleValue];
	double band64 = [eqBand64 doubleValue];
	double band125 = [eqBand125 doubleValue];
	double band250 = [eqBand250 doubleValue];
	double band500 = [eqBand500 doubleValue];
	double band1k = [eqBand1k doubleValue];
	double band2k = [eqBand2k doubleValue];
	double band4k = [eqBand4k doubleValue];
	double band8k = [eqBand8k doubleValue];
	double band16k = [eqBand16k doubleValue];
	
	NSArray *eqBands = [HSettings eqPresetBand32:band32 band64:band64 band125:band125 
																			 band250:band250 band500:band500 band1k:band1k
																				band2k:band2k band4k:band4k band8k:band8k 
																			 band16k:band16k];
	
	[HSettings setEqPreset:eqBands];
}

- (IBAction)openLastFMPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.last.fm"]];
}

- (IBAction)showTrackExportWarning:(id)sender
{
	XMark();
	if(![HSettings exportWarningShown])
	{
		//
		// Run alert panel...
		//
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert addButtonWithTitle:@"Roger that"];
		[alert setMessageText:@"Track export warning"];
		[alert setInformativeText:@"Please make sure that recording of radio streams for private use is allowed in your country. If you like a track or album, buy it!"];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:window modalDelegate:nil
										 didEndSelector:nil contextInfo:nil];
	}
}

- (IBAction)revertAllSettings:(id)sender
{
	[HSettings resetToDefaults];
}

//
// CAAnimation delegate
//
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag 
{
	[[window contentView] addSubview:newView];
}

//
// NSToolbar delegate
//
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)aToolbar 
{
	return [[aToolbar items] valueForKey:@"itemIdentifier"];
}

@end
