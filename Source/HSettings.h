//
//  HSettings.h
//  SweetFM
//
//  Created by Q on 26.05.09.
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


@class SkinBundle;

extern NSString * const SkinBundleChangedNotification;
extern NSString * const TuneToLastStationNotification;

extern NSString * const CurrentStationPlaylistName;
extern NSString * const SweetFMPlaylistName;

extern NSString * const EQChangedNotification;

typedef enum {
	ExportNone,
	ExportOnLoved,
	ExportOnAddToPlaylist,
	ExportOnLoveAndAddToPlaylist,
	ExportAllways
} ExportCondition;

typedef enum {
	PinOnDesktop = 0,
	PinOnTop
} PinLevel;

@interface HSettings : NSObject {

}

+ (HSettings *)install;
+ (HSettings *)instance;
+ (void)resetToDefaults;

+ (NSDictionary *)defaultValues;

//
// Application
//
+ (BOOL)showDockIcon;
+ (BOOL)showStatusBarIcon;

//
// License
//
+ (NSString *)licenseName;
+ (void)setLicenseName:(NSString *)aName;
+ (NSString *)licenseKey;
+ (void)setLicenseKey:(NSString *)aKey;
+ (void)removeLicenseInformation;

//
// Skype
//
+ (BOOL)skypeMoodEnabled;

//
// Window
//
+ (BOOL)windowPinned;
+ (void)setWindowPinned:(BOOL)pin;

+ (PinLevel)windowPinLevel;
+ (void)setWindowPinLevel:(PinLevel)theLevel;

//
// Auth
//
+ (NSString *)lastFmUserName;
+ (void)setLastFmUserName:(NSString *)aUser;

+ (NSString *)lastFmPassword;
+ (void)setLastFmPassword:(NSString *)aPass;

// KVC compliance
- (NSString *)lastFmUserName;
- (void)setLastFmUserName:(NSString *)aUser;

- (NSString *)lastFmPassword;
- (void)setLastFmPassword:(NSString *)aPass;

//
// Scrobble
//
+ (NSUInteger)scrobblePercentage;

+ (BOOL)scrobbleEnabled;
+ (void)setScrobbleEnabled:(BOOL)scr;

//
// Cover
//
+ (BOOL)coverDownloadEnabled;

//
// Lyrics
//
+ (BOOL)lyricDownloadEnabled;

//
// Skins
//
+ (SkinBundle *)selectedSkin;
+ (void)setSelectedSkinBundleName:(NSString *)name;
+ (NSString *)skinPath;

//
// Stations
//
+ (NSArray *)shuffleNames;
+ (BOOL)playOnStartup;

+ (void)setLastStation:(NSString *)theStation;
+ (NSString *)lastStation;

//
// Export
//
+ (BOOL)exportTracks;
+ (BOOL)exportWarningShown;
+ (NSString *)exportPlaylistName;
+ (ExportCondition)exportOn;
+ (void)incrementCashtistic;

//
// Radio
//
+ (void)setRadioVolume:(double)vol;
+ (double)radioVolume;

//
// EQ
//
+ (BOOL)eqEnabled;

+ (double)eqGain;
+ (void)setEqGain:(double)theGain;

+ (NSArray *)eqPreset;
+ (void)setEqPreset:(NSArray *)thePreset;

+ (NSArray *)eqPresetBand32:(double)band32 band64:(double)band64 band125:(double)band125
										band250:(double)band250 band500:(double)band500 band1k:(double)band1k
										 band2k:(double)band2k band4k:(double)band4k band8k:(double)band8k band16k:(double)band16k;
+ (NSArray *)eqPresetFlat;
+ (NSArray *)eqPresetAcoustic;
+ (NSArray *)eqPresetDance;
+ (NSArray *)eqPresetElectronic;
+ (NSArray *)eqPresetHipHop;
+ (NSArray *)eqPresetJazz;
+ (NSArray *)eqPresetBass;
+ (NSArray *)eqPresetTreble;
+ (NSArray *)eqPresetPop;
+ (NSArray *)eqPresetRock;

@end
