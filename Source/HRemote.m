//
//  HRemote.m
//  SweetFM
//
//  Created by Q on 24.05.09.
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

#import "HRemote.h"

#import "SynthesizeSingleton.h"
#import "Remote.h"


NSString * const HRemotePlayPausePressedNotification = @"HRemotePlayPausePressedNotification";
NSString * const HRemoteNextPressedNotification = @"HRemoteNextPressedNotification";
NSString * const HRemotePreviousPressedNotification = @"HRemotePreviousPressedNotification";
NSString * const HRemoteVolumeUpPressedNotification = @"HRemoteVolumeUpPressedNotification";
NSString * const HRemoteVolumeDownPressedNotification = @"HRemoteVolumeDownPressedNotification";


@implementation HRemote

SYNTHESIZE_SINGLETON_FOR_CLASS(HRemote, install);

- (id)init
{
	if(self = [super init])
	{
		// Initialize remote
		MultiClickRemoteBehavior* remoteControlBehavior = [[MultiClickRemoteBehavior alloc] init];	
		[remoteControlBehavior setDelegate:self];
		
		remote = [[RemoteControlContainer alloc] initWithDelegate:remoteControlBehavior];
		[remote instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];	
		
		[(RemoteControl*)remote setOpenInExclusiveMode:YES];
		[remote startListening:self];
		
		[remoteControlBehavior release];
	}
	
	return self;
}

- (void)dealloc
{
	[remote release];
	[super dealloc];
}

- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown clickCount:(unsigned int)clickCount {
		
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	if(!pressedDown) {
		if(buttonIdentifier==kRemoteButtonPlay)
			[center postNotificationName:HRemotePlayPausePressedNotification object:self];
		else if(buttonIdentifier==kRemoteButtonRight)
			[center postNotificationName:HRemoteNextPressedNotification object:self];
		else if(buttonIdentifier==kRemoteButtonLeft)
			[center postNotificationName:HRemotePreviousPressedNotification object:self];
		else if(buttonIdentifier==kRemoteButtonPlus)
			[center postNotificationName:HRemoteVolumeUpPressedNotification object:self];
		else if(buttonIdentifier==kRemoteButtonMinus)
			[center postNotificationName:HRemoteVolumeDownPressedNotification object:self];
	}
}

@end
