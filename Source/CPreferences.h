//
//  CPreferences.h
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

#import <Cocoa/Cocoa.h>


@class SkinSelectView;
@class HSettings;

@interface CPreferences : NSObject {

	IBOutlet NSWindow *window;
	IBOutlet NSToolbar *toolbar;
	
	IBOutlet NSView *general;
	IBOutlet NSView *lastfm;
	IBOutlet NSView *shortcuts;
	IBOutlet SkinSelectView *skins;
	IBOutlet NSView *equalizer;
	IBOutlet NSView *advanced;
	
	IBOutlet NSSlider *eqGain;
	IBOutlet NSSlider *eqBand32;
	IBOutlet NSSlider *eqBand64;
	IBOutlet NSSlider *eqBand125;
	IBOutlet NSSlider *eqBand250;
	IBOutlet NSSlider *eqBand500;
	IBOutlet NSSlider *eqBand1k;
	IBOutlet NSSlider *eqBand2k;
	IBOutlet NSSlider *eqBand4k;
	IBOutlet NSSlider *eqBand8k;
	IBOutlet NSSlider *eqBand16k;
	
	IBOutlet NSPopUpButton *eqPreset;
	
	IBOutlet NSPopUpButton *playlists;
		
	NSToolbarItem *selectedItem;
	NSView *newView;
	
	NSDictionary *presetDict;
}

@property (retain) NSToolbarItem *selectedItem;
@property (retain) NSView *newView;

- (HSettings *)settings;

- (void)installSkinAtPath:(NSString *)path;
- (void)toggleWindow;

- (void)animateToView:(NSView *)aView toolbarItem:(NSToolbarItem *)aItem;

- (void)presetSet:(NSNotification *)notify;

//
// IBActions
//
- (IBAction)showGeneral:(id)sender;
- (IBAction)showLastFM:(id)sender;
- (IBAction)showShortcuts:(id)sender;
- (IBAction)showSkins:(id)sender;
- (IBAction)showEqualizer:(id)sender;
- (IBAction)showAdvanced:(id)sender;

- (IBAction)presetChanged:(id)sender;
- (IBAction)gainModified:(id)sender;
- (IBAction)bandModified:(id)sender;

- (IBAction)openLastFMPage:(id)sender;
- (IBAction)showTrackExportWarning:(id)sender;
- (IBAction)revertAllSettings:(id)sender;

@end
