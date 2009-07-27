//
//  HSettings.m
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

#import "HSettings.h"

#import "SkinSelectView.h"
#import "SynthesizeSingleton.h"
#import "HKeychain.h"
#import "XLog.h"


//
// Keychain
//
NSString * const KeychainServiceName  = @"SweetFM";

// 
// User defaults
//
NSString * const ScrobbleEnabledSetting = @"kScrobbleEnabled";
NSString * const ScrobblePercentageSetting = @"kScrobblePercentage";
NSString * const SkinSelectedBundle = @"kSkinSelectedBundle";
NSString * const ShuffleNames = @"kShuffleNames";
NSString * const ExportPlaylistName = @"kExportPlaylistName";
NSString * const ExportTracks = @"kExportTracks";
NSString * const AmazonCoverDownload = @"kAmazonCoverDownload";
NSString * const PlayOnStartup = @"kPlayOnStartup";
NSString * const LastStation = @"kLastStation";
NSString * const ExportOn = @"kExportOn";
NSString * const ExportWarningShown = @"kExportWarningShown";
NSString * const WindowPinned = @"kWindowPinned";
NSString * const WindowPinLevel = @"kWindowPinLevel";
NSString * const ShowInDock = @"kShowInDock";
NSString * const ShowInStatusBar = @"kShowInStatusBar";
NSString * const SkypeMood = @"kSkypeMood";
NSString * const EQEnabled = @"kEQEnabled";
NSString * const EQPreset = @"kEQPreset";
NSString * const EQGain = @"kEQGain";
NSString * const RadioVolume = @"kRadioVolume";
NSString * const DownloadLyrics = @"kDownloadLyrics";
NSString * const CashtisticsCounter = @"kCashtisticsCounter";

//
// License
//
NSString * const LicenseName = @"kLicenseName";
NSString * const LicenseKey = @"kLicenseKey";

//
// Notifications
//
NSString * const SkinBundleChangedNotification = @"SkinBundleChangedNotification";
NSString * const TuneToLastStationNotification = @"TuneToLastStationNotification";

NSString * const EQChangedNotification = @"EQChangedNotification";

//
// Playlists
//
NSString * const CurrentStationPlaylistName = @"Current Station";
NSString * const SweetFMPlaylistName = @"SweetFM";


@interface HSettings (Private)

+ (void)_fillInLastFmWebLogin;

@end

@implementation HSettings

SYNTHESIZE_SINGLETON_FOR_CLASS(HSettings, instance);

- (id)init
{
	if(self = [super init])
	{
		if(![HSettings lastFmUserName])
		{
			[HSettings _fillInLastFmWebLogin];
		}

		//
		// Add observer for ShowInMenuBar setting
		//
		NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
		[controller addObserver:self
								 forKeyPath:[NSString stringWithFormat:@"values.%@", ShowInStatusBar]
										options:NSKeyValueObservingOptionNew
										context:NULL];
		
		//
		// Add observer for EQ switch
		//
		[controller addObserver:self
								 forKeyPath:[NSString stringWithFormat:@"values.%@", EQEnabled]
										options:NSKeyValueObservingOptionNew
										context:NULL];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
											ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	XMark();
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if([keyPath isEqual:[NSString stringWithFormat:@"values.%@", ShowInStatusBar]])
	{
		if(![HSettings showStatusBarIcon])
			[defaults setBool:YES forKey:ShowInDock];
	}
	else if([keyPath isEqual:[NSString stringWithFormat:@"values.%@", EQEnabled]])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:EQChangedNotification object:nil];
	}
}

+ (void)initialize 
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	//
	// Register defaults
	//
	[[NSUserDefaults standardUserDefaults] registerDefaults:[HSettings defaultValues]];
	
	[pool release];
}

+ (HSettings *)install
{
	//
	// Try to retrieve password...
	// In case the app was modified, it prevents a system lockup (media key tap).
	//
	[HSettings lastFmUserName];
	[HSettings lastFmPassword];
	
	return [HSettings instance];
}

+ (void)resetToDefaults
{
	for(NSString *key in [HSettings defaultValues])
	{
		if([key isEqualToString:CashtisticsCounter])
			continue;
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	}
}

+ (NSDictionary *)defaultValues
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES], ScrobbleEnabledSetting,
					[NSNumber numberWithInt:75], ScrobblePercentageSetting,
					@"Fibre.sweets", SkinSelectedBundle,
					[NSArray arrayWithObjects:@"Rock", @"Alternative", @"House", 
					 @"Dance", @"Pop", @"Acoustic", nil], ShuffleNames,
					@"SweetFM", ExportPlaylistName,
					[NSNumber numberWithBool:NO], AmazonCoverDownload,
					[NSNumber numberWithBool:NO], PlayOnStartup,
					[NSNumber numberWithBool:NO], ExportTracks,
					[NSNumber numberWithInt:ExportAllways], ExportOn,
					@"lastfm://user/last.hq/personal", LastStation,
					[NSNumber numberWithBool:NO], ExportWarningShown,
					[NSNumber numberWithInt:NO], WindowPinned,
					[NSNumber numberWithInt:PinOnDesktop], WindowPinLevel,
					[NSNumber numberWithBool:YES], ShowInDock,
					[NSNumber numberWithBool:YES], ShowInStatusBar,
					[NSNumber numberWithBool:NO], SkypeMood,
					[NSNumber numberWithBool:NO], EQEnabled,
					[HSettings eqPresetFlat], EQPreset,
					[NSNumber numberWithDouble:50.0f], EQGain,
					[NSNumber numberWithDouble:1.0f], RadioVolume,
					[NSNumber numberWithBool:YES], DownloadLyrics, //Change not implemented yet! Set to NO when implemented!
					[NSNumber numberWithInt:0], CashtisticsCounter,
					nil];
}

+ (BOOL)showDockIcon
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ShowInDock];
}

+ (BOOL)showStatusBarIcon
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ShowInStatusBar];
}

+ (NSString *)licenseName
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:LicenseName];
}

+ (void)setLicenseName:(NSString *)aName
{
	[[NSUserDefaults standardUserDefaults] setObject:aName forKey:LicenseName];
}

+ (NSString *)licenseKey
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:LicenseKey];
}

+ (void)setLicenseKey:(NSString *)aKey
{
	[[NSUserDefaults standardUserDefaults] setObject:aKey forKey:LicenseKey];
}

+ (void)removeLicenseInformation
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:LicenseName];
	[defaults removeObjectForKey:LicenseKey];
}

+ (BOOL)skypeMoodEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:SkypeMood];
}

+ (BOOL)windowPinned
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:WindowPinned];
}

+ (void)setWindowPinned:(BOOL)pin
{
	[[NSUserDefaults standardUserDefaults] setBool:pin forKey:WindowPinned];
}

+ (PinLevel)windowPinLevel
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:WindowPinLevel];
}

+ (void)setWindowPinLevel:(PinLevel)theLevel
{
	[[NSUserDefaults standardUserDefaults] setInteger:theLevel forKey:WindowPinLevel];
}

+ (NSString *)lastFmUserName
{
	return [[HSettings instance] lastFmUserName];
}

+ (void)setLastFmUserName:(NSString *)aUser
{
	return [[HSettings instance] setLastFmUserName:aUser];
}

+ (NSString *)lastFmPassword
{
	return [[HSettings instance] lastFmPassword];
}

+ (void)setLastFmPassword:(NSString *)aPass
{
	return [[HSettings instance] setLastFmPassword:aPass];
}

- (NSString *)lastFmUserName
{
	//return @"eriza86";
	HKeychain *chain = [HKeychain sharedKeychain];
	HKeychainItem *item = [chain keychainItemForService:KeychainServiceName];
	
	return [item accountName];
}

- (void)setLastFmUserName:(NSString *)aUser
{
	HKeychain *chain = [HKeychain sharedKeychain];
	HKeychainItem *item = [chain keychainItemForService:KeychainServiceName];
	
	if(item)
		[item setAccountName:aUser];
	else
		item = [chain addKeychainItemForService:KeychainServiceName
																accountName:aUser
														accountPassword:@""];
}

- (NSString *)lastFmPassword
{
	//return @"flateric";
	HKeychain *chain = [HKeychain sharedKeychain];
	HKeychainItem *item = [chain keychainItemForService:KeychainServiceName];
	
	return [item accountPassword];
}

- (void)setLastFmPassword:(NSString *)aPass
{
	HKeychain *chain = [HKeychain sharedKeychain];
	HKeychainItem *item = [chain keychainItemForService:KeychainServiceName];
	
	if(item)
		[item setAccountPassword:aPass];
	else
		item = [chain addKeychainItemForService:KeychainServiceName
																accountName:@""
														accountPassword:aPass];
}

+ (NSUInteger)scrobblePercentage
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:ScrobblePercentageSetting];
}

+ (BOOL)scrobbleEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ScrobbleEnabledSetting];
}

+ (void)setScrobbleEnabled:(BOOL)scr
{
	[[NSUserDefaults standardUserDefaults] setBool:scr forKey:ScrobbleEnabledSetting];
}

+ (BOOL)coverDownloadEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:AmazonCoverDownload];
}

+ (BOOL)lyricDownloadEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DownloadLyrics];
}

+ (SkinBundle *)selectedSkin
{
	NSString *bundle = [[NSUserDefaults standardUserDefaults] stringForKey:SkinSelectedBundle];	
	NSString *bundlePath = [NSString stringWithFormat:@"%@/%@", [self skinPath], bundle];
	NSString *defaultBundlePath = [NSString stringWithFormat:@"%@/Fibre.sweets", [self skinPath]];
	
	XLog(bundlePath);
	XLog(defaultBundlePath);
	
	if([[NSFileManager defaultManager] fileExistsAtPath:bundlePath])
		return [[[SkinBundle alloc] initWithPath:bundlePath] autorelease];
	else if([[NSFileManager defaultManager] fileExistsAtPath:defaultBundlePath])
		return [[[SkinBundle alloc] initWithPath:defaultBundlePath] autorelease];
		
	return nil;
}

+ (void)setSelectedSkinBundleName:(NSString *)name
{
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:SkinSelectedBundle];
	[[NSNotificationCenter defaultCenter] postNotificationName:SkinBundleChangedNotification object:name];
}

+ (NSString *)skinPath
{
	return [NSString stringWithFormat:@"%@/Contents/Skins", [[NSBundle mainBundle] bundlePath]];
}

+ (NSArray *)shuffleNames
{
	return [[NSUserDefaults standardUserDefaults] arrayForKey:ShuffleNames];
}

+ (BOOL)playOnStartup
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PlayOnStartup];
}

+ (void)setLastStation:(NSString *)theStation
{
	[[NSUserDefaults standardUserDefaults] setObject:theStation forKey:LastStation];
}

+ (NSString *)lastStation
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:LastStation];
}

+ (BOOL)exportTracks
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ExportTracks];
}

+ (BOOL)exportWarningShown
{
	BOOL warningShown = [[NSUserDefaults standardUserDefaults] boolForKey:ExportWarningShown];
	
	//
	// We set status to "shown" if the value is requested the first time
	//
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ExportWarningShown];
	
	return warningShown;
}

+ (NSString *)exportPlaylistName
{
	NSString *playlist = [[NSUserDefaults standardUserDefaults] stringForKey:ExportPlaylistName];
	
	if([playlist isEqualToString:CurrentStationPlaylistName])
		return nil;
	
	return playlist;
}

+ (ExportCondition)exportOn
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:ExportOn];
}

+ (void)incrementCashtistic
{
	NSUInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:CashtisticsCounter];
	[[NSUserDefaults standardUserDefaults] setInteger:++val forKey:CashtisticsCounter];
}

//
// Radio
//
+ (void)setRadioVolume:(double)vol
{
	[[NSUserDefaults standardUserDefaults] setDouble:vol forKey:RadioVolume];
}

+ (double)radioVolume
{
	return [[NSUserDefaults standardUserDefaults] doubleForKey:RadioVolume];
}

//
// EQ
//
+ (BOOL)eqEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:EQEnabled];
}

+ (double)eqGain
{
	return [[NSUserDefaults standardUserDefaults] doubleForKey:EQGain];
}

+ (void)setEqGain:(double)theGain
{
	[[NSUserDefaults standardUserDefaults] setDouble:theGain forKey:EQGain];
	[[NSNotificationCenter defaultCenter] postNotificationName:EQChangedNotification object:nil];
}

+ (NSArray *)eqPreset
{
	return [[NSUserDefaults standardUserDefaults] arrayForKey:EQPreset];
}

+ (void)setEqPreset:(NSArray *)thePreset
{
	[[NSUserDefaults standardUserDefaults] setObject:thePreset forKey:EQPreset];
	[[NSNotificationCenter defaultCenter] postNotificationName:EQChangedNotification object:nil];
}

+ (NSArray *)eqPresetBand32:(double)band32 band64:(double)band64 band125:(double)band125
										band250:(double)band250 band500:(double)band500 band1k:(double)band1k
										 band2k:(double)band2k band4k:(double)band4k band8k:(double)band8k band16k:(double)band16k
{
	double band20 = band32; //50.0f;
	double band25 = band32; //(band20+band32)/2.0f;
	
	double band40 = band32 + (band64-band32)/3.0f;
	double band50 = band32 + 2.0f*(band64-band32)/3.0f;
	
	double band80 = band64 + (band125-band64)/3.0f;
	double band100 = band64 + 2.0f*(band125-band64)/3.0f;
	
	double band160 = band125 + (band250-band125)/3.0f;
	double band200 = band125 + 2.0f*(band250-band125)/3.0f;
	
	double band315 = band250 + (band500-band250)/3.0f;
	double band400 = band250 + 2.0f*(band500-band250)/3.0f;
	
	double band630 = band500 + (band1k-band500)/3.0f;
	double band800 = band500 + 2.0f*(band1k-band500)/3.0f;
	
	double band1_25k = band1k + (band2k-band1k)/3.0f;
	double band1_6k = band1k + 2.0f*(band2k-band1k)/3.0f;
	
	double band2_5k = band2k + (band4k-band2k)/3.0f;
	double band3_15k = band2k + 2.0f*(band4k-band2k)/3.0f;
	
	double band5k = band4k + (band8k-band4k)/3.0f;
	double band6_3k = band4k + 2.0f*(band8k-band4k)/3.0f;
	
	double band10k = band8k + (band16k-band8k)/3.0f;
	double band12_5k = band8k + 2.0f*(band16k-band8k)/3.0f;
	
	double band22k = band16k; //50.0f;
	double band20k = band16k; //band16k + (band22k-band16k)/3.0f;
	
	NSArray *eqBands = [NSArray arrayWithObjects:
											[NSNumber numberWithDouble:band20],
											[NSNumber numberWithDouble:band25],
											[NSNumber numberWithDouble:band32],
											[NSNumber numberWithDouble:band40],
											[NSNumber numberWithDouble:band50],
											[NSNumber numberWithDouble:band64],
											[NSNumber numberWithDouble:band80],
											[NSNumber numberWithDouble:band100],
											[NSNumber numberWithDouble:band125],
											[NSNumber numberWithDouble:band160],
											[NSNumber numberWithDouble:band200],
											[NSNumber numberWithDouble:band250],
											[NSNumber numberWithDouble:band315],
											[NSNumber numberWithDouble:band400],
											[NSNumber numberWithDouble:band500],
											[NSNumber numberWithDouble:band630],
											[NSNumber numberWithDouble:band800],
											[NSNumber numberWithDouble:band1k],
											[NSNumber numberWithDouble:band1_25k],
											[NSNumber numberWithDouble:band1_6k],
											[NSNumber numberWithDouble:band2k],
											[NSNumber numberWithDouble:band2_5k],
											[NSNumber numberWithDouble:band3_15k],
											[NSNumber numberWithDouble:band4k],
											[NSNumber numberWithDouble:band5k],
											[NSNumber numberWithDouble:band6_3k],
											[NSNumber numberWithDouble:band8k],
											[NSNumber numberWithDouble:band10k],
											[NSNumber numberWithDouble:band12_5k],
											[NSNumber numberWithDouble:band16k],
											[NSNumber numberWithDouble:band20k],
											[NSNumber numberWithDouble:band22k],
											nil];
	
	return eqBands;
}

+ (NSArray *)eqPresetFlat
{
	NSMutableArray *flat = [NSMutableArray array];
	
	for(int i=0; i<32; i++)
		[flat addObject:[NSNumber numberWithDouble:50.0f]];
	
	return [NSArray arrayWithArray:flat];
}

+ (NSArray *)eqPresetAcoustic
{
	return [HSettings eqPresetBand32:65 band64:65 band125:62 
													 band250:53 band500:58 band1k:52
														band2k:61 band4k:62 band8k:61 
													 band16k:58];
}

+ (NSArray *)eqPresetDance
{
	return [HSettings eqPresetBand32:61 band64:70 band125:65
													 band250:50 band500:55 band1k:62
														band2k:66 band4k:64 band8k:61 
													 band16k:50];
}

+ (NSArray *)eqPresetElectronic
{
	return [HSettings eqPresetBand32:62 band64:61 band125:53
													 band250:50 band500:42 band1k:58
														band2k:52 band4k:54 band8k:63 
													 band16k:65];
}

+ (NSArray *)eqPresetHipHop
{
	return [HSettings eqPresetBand32:65 band64:62 band125:53
													 band250:60 band500:48 band1k:48
														band2k:55 band4k:48 band8k:55 
													 band16k:59];
}

+ (NSArray *)eqPresetJazz
{
	return [HSettings eqPresetBand32:62 band64:60 band125:55
													 band250:57 band500:45 band1k:45
														band2k:50 band4k:55 band8k:60 
													 band16k:62];
}

+ (NSArray *)eqPresetBass
{
	return [HSettings eqPresetBand32:69 band64:64 band125:61
													 band250:58 band500:54 band1k:50
														band2k:50 band4k:50 band8k:50 
													 band16k:50];
}

+ (NSArray *)eqPresetTreble
{
	return [HSettings eqPresetBand32:50 band64:50 band125:50
													 band250:50 band500:50 band1k:55
														band2k:58 band4k:61 band8k:64 
													 band16k:68];
}

+ (NSArray *)eqPresetPop
{
	return [HSettings eqPresetBand32:45 band64:47 band125:50
													 band250:56 band500:63 band1k:62
														band2k:57 band4k:50 band8k:47 
													 band16k:45];
}

+ (NSArray *)eqPresetRock
{
	return [HSettings eqPresetBand32:65 band64:62 band125:60
													 band250:54 band500:50 band1k:48
														band2k:51 band4k:58 band8k:61 
													 band16k:63];
}

@end

@implementation HSettings (Private)

+ (void)_fillInLastFmWebLogin
{
	HKeychainItem *lastItem = [[HKeychain sharedKeychain]
														 keychainItemForServer:@"www.last.fm"];
	if(lastItem) {
		[HSettings setLastFmUserName:[lastItem accountName]];
		[HSettings setLastFmPassword:[lastItem accountPassword]];
	}
}

@end
