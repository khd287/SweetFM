//
//  JSProxy.m
//  SweetFM
//
//  Created by Q on 22.05.09.
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

#import "JSProxy.h"
#import "NSData+Base64.h"
#import "XLog.h"


@implementation JSProxy

@synthesize scriptObject;

- (NSString *)javascriptName
{
	return [NSString stringWithString:@"proxy"];
}

- (void)dealloc
{
	[scriptObject release];
	[super dealloc];
}

- (void)setValue:(NSString *)value forAttribute:(NSString *)attr inObjectWithID:(NSString *)objID
{
	if(![value length] || ![attr length] || ![objID length])
		return;
	
	NSString *exec = [NSString stringWithFormat:
										@"document.getElementById('%@').%@ = \"%@\"", 
										objID,
										attr,
										value];
	
	[scriptObject evaluateWebScript:exec];
}

- (NSArray *)returnValuesForMethodCall:(NSString *)method
{
	WebScriptObject *obj = [scriptObject callWebScriptMethod:method
																						 withArguments:nil];
	
	NSMutableArray *mutable = [NSMutableArray array];
	
	int idx = 0;
	id returnValue = nil;
	
	while((returnValue = [obj webScriptValueAtIndex:idx]) != [WebUndefined undefined])
	{
		[mutable addObject:returnValue];
		idx++;
	}
	
	return [NSArray arrayWithArray:mutable];
}

//
// Utility methods
//
+ (NSString *)base64EncodedImage:(NSImage *)image forType:(NSBitmapImageFileType)type
{
	if(image==nil)
		return nil;
	
	if(![[image representations] count])
		return nil;

	// 
	// Get bitmap rep
	//
	NSBitmapImageRep *bitmapRep = nil;
	bitmapRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	
	NSData *imgData = [bitmapRep representationUsingType:type properties:nil];
	
	return [imgData base64Encoding];
}

+ (NSString *)imageSourceBase64PNG:(NSImage *)image
{
	if(image==nil)
		return nil;
	
	NSString *base64 = [JSProxy base64EncodedImage:image forType:NSPNGFileType];
	
	if(base64)
		return [NSString stringWithFormat:@"data:image/png;base64,%@", base64];
	
	return nil;	
}

+ (NSString *)imageSourceBase64JPEG:(NSImage *)image
{
	if(image==nil)
		return nil;
	
	NSString *base64 = [JSProxy base64EncodedImage:image forType:NSJPEGFileType];
	
	if(base64)
		return [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64];
	
	return nil;	
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector 
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property 
{
	return NO;
}

@end



