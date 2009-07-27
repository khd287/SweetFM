//
//  PlayerTest.m
//  StreamKitTest
//
//  Created by Q on 05.07.09.
//
//

#import "PlayerTest.h"





@implementation PlayerTest

- (id)init
{
	if(self = [super init])
	{
		// Init stuff
	}
	
	return self;
}

- (void)test
{
	NSURL *location = [NSURL URLWithString:@"http://www.chalkpad.net/stream.mp3"];
	SKMP3Synth *synth = [[SKMP3Synth alloc] init];
	
	player = [[SKPlayer alloc] initWithURL:location
														 synthesizer:synth
																	buffer:[SKBuffer bufferWithSize:500*1024]];
	
	[player play];
	
	[NSThread detachNewThreadSelector:@selector(playerTimer)
													 toTarget:self
												 withObject:nil];
}

- (void)playerTimer
{
	do
	{
		[NSThread sleepForTimeInterval:1];
		
		//NSLog(@"progress (secs): %f", [player position]);
	}
	while(true);
}

@end
