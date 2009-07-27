//
//  QOperation.m
//  SweetFM
//
//  Created by Q on 13.05.09.
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

#import "QOperation.h"
#import "QHandler.h"
#import "FMBase.h"


@implementation QOperation

- (id)initWithValidatedInvocation:(NSInvocation *)anInvocation
{
	return [self initWithInvocation:anInvocation critical:NO callback:nil];
}

- (id)initWithCriticalValidatedInvocation:(NSInvocation *)anInvocation
{
	return [self initWithInvocation:anInvocation critical:YES callback:nil];
}

- (id)initWithInvocation:(NSInvocation *)anInvocation critical:(BOOL)crit callback:(SEL)sel
{	
	if(self = [super init])
	{
		invocation = [anInvocation retain];
		[invocation retainArguments];
		
		critical = crit;
		callback = sel;
	}
	
	return self;
}

- (void)dealloc
{
	[invocation release];
	[super dealloc];
}

- (void)main
{
	[invocation invoke];
	
	BOOL result;
	[invocation getReturnValue:&result];
	
	if([self isCancelled])
		return;
	
	if(!result && critical)
	{		
		FMBase *base = (FMBase *)[invocation target];
		[QHandler instance].lastErrorMessage = base.lastError;
		
		/*
		if([[QHandler instance].delegate respondsToSelector:@selector(queueHandlerCriticalProtocolErrorOccurred:)])
			[[QHandler instance].delegate performSelectorOnMainThread:@selector(queueHandlerCriticalProtocolErrorOccurred:)
			 withObject:[QHandler instance] 
			 waitUntilDone:NO];
		*/
		
		[[NSNotificationCenter defaultCenter] postNotificationName:QHandlerProtocolErrorNotification
																												object:nil];
		
		NSLog(@"Critical protocol error occurred, all following operations cancelled!");
		[[QHandler messages] cancelAllOperations];
	}
	else if(!result && !critical)
	{
		FMBase *base = (FMBase *)[invocation target];
		[QHandler instance].lastErrorMessage = base.lastError;
		
		/*
		if([[QHandler instance].delegate respondsToSelector:@selector(queueHandlerMinorProtocolErrorOccurred:)])
			[[QHandler instance].delegate performSelectorOnMainThread:@selector(queueHandlerMinorProtocolErrorOccurred:)
			 withObject:[QHandler instance] 
			 waitUntilDone:NO];
		 */
		
		[[NSNotificationCenter defaultCenter] postNotificationName:QHandlerMinorProtocolErrorNotification
																												object:nil];
	}
	else if(callback)
	{
		//
		// Invoke the callback selector in the delegate with returned object
		//
		if([[QHandler instance].delegate respondsToSelector:callback])
			[[QHandler instance].delegate performSelectorOnMainThread:callback 
			 withObject:[QHandler instance]
			 waitUntilDone:NO];
	}
}

@end
