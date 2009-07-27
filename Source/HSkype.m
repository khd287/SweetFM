//
//  HSkype.m
//  SweetFM
//
//  Created by Q on 05.06.09.
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

#import "HSkype.h"

#import "SynthesizeSingleton.h"
#import "SkypeAPI.h"
#import "HSettings.h"


@implementation HSkype

@synthesize skypeConnected;

SYNTHESIZE_SINGLETON_FOR_CLASS(HSkype, instance);

- (id)init
{
	if(self = [super init])
	{
		[SkypeAPI setSkypeDelegate:self];
		//[SkypeAPI connect];
		
		skypeConnected = NO;
		statusBuffer = [[NSMutableArray alloc] init];
		
		//
		// Register for terminate notification (to clear skype status)
		//
		NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
		[notify addObserver:self selector:@selector(appWillTerminate)
									 name:NSApplicationWillTerminateNotification object:nil];
	}
	
	return self;
}

- (NSString*)clientApplicationName
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (void)skypeAttachResponse:(unsigned)aAttachResponseCode
{
	switch (aAttachResponseCode)
	{
		case 0:
			NSLog(@"Failed to connect");
			skypeConnected = NO;
			break;
		case 1:
			NSLog(@"Successfully connected to Skype!");
			skypeConnected = YES;
			
			if([statusBuffer count])
			{
				[self setSkypeStatus:[statusBuffer lastObject]];
				[statusBuffer removeAllObjects];
			}
			
			break;
		default:
			NSLog(@"Unknown response from Skype");
			skypeConnected = NO;
			break;
	}
}

- (void)appWillTerminate
{
	[self setSkypeStatus:nil];
}

- (void)setSkypeStatus:(NSString *)theStatus
{
	if(![HSettings skypeMoodEnabled])
		return;
	
	if(!skypeConnected)
	{
		[statusBuffer addObject:theStatus];
		[SkypeAPI connect];
	}
	else
	{
		NSString *cmd = nil;
		
		if(theStatus)
			cmd = [NSString stringWithFormat:@"SET PROFILE MOOD_TEXT %@ (SweetFM)", theStatus];
		else
			cmd = @"SET PROFILE MOOD_TEXT";
		
		[SkypeAPI sendSkypeCommand:cmd];
	}
}

@end
