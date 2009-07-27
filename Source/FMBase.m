//
//  FMBase.m
//  SweetFM
//
//  Created by Q on 28.04.09.
//
//
//	Contributors: Eric Musgrove
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

#import "FMBase.h"
#import <openssl/md5.h>	// -lcrypto


@implementation FMBase

@synthesize lastError;

- (void)dealloc
{
	self.lastError = nil;
	[super dealloc];
}

- (NSString *)timestamp 
{
	return [NSString stringWithFormat:@"%i", (NSUInteger)[[NSDate date] timeIntervalSince1970]];	
}

- (NSData *)HTTPPost:(NSURL *)url data:(NSData *)data 
{
	return [self HTTPMimePost:url data:data mimeType:@"application/x-www-form-urlencoded"];
}

- (NSData *)HTTPMimePost:(NSURL *)url data:(NSData *)data mimeType:(NSString *)mimeType 
{
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	NSString *dataLength = [NSString stringWithFormat:@"%i", [data length]];
	
	[req setHTTPMethod:@"POST"];
	[req setValue:dataLength forHTTPHeaderField:@"Content-Length"];
	[req setValue:mimeType forHTTPHeaderField:@"Content-Type"];
	[req setHTTPBody:data];
	
	NSError *error=noErr;
	NSData *response = [NSURLConnection sendSynchronousRequest:req 
																					 returningResponse:nil 
																											 error:&error];
	
	if(error)
		return nil;
	
	return response;
}

- (NSData *)HTTPGetString:(NSString *)urlString 
{
	return [self HTTPGet:[NSURL URLWithString:urlString]];
}

- (NSData *)HTTPGet:(NSURL *)url 
{
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	request = [self setUserAgent:request];
	
	NSError *error=noErr;
	NSData *data = [NSURLConnection sendSynchronousRequest:request
																			 returningResponse:nil 
																									 error:&error];
	
	if(error)
		return nil;
	
	return data;
}

- (NSURLRequest *)setUserAgent:(NSURLRequest *)request 
{
	NSMutableURLRequest *newRequest = [request mutableCopy];
	[newRequest setValue:@"Last.fm Client 1.5.4.24670 (OS X)" forHTTPHeaderField:@"User-Agent"];
	return newRequest;
} 

- (NSDictionary *)parseAssignedList:(NSData *)data 
{	
	NSArray* lines = [[data UTF8String] componentsSeparatedByString:@"\n"];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	// Check if we have at least more than one line
	if([lines count] > 1) {		
		for(NSString *uLine in lines) {
			NSRange pos = [uLine rangeOfString:@"="];
			if(pos.location!=NSNotFound) {
				NSString* key = [uLine substringToIndex:pos.location];
				NSString* value = [uLine substringFromIndex:pos.location+1];
				[dict setValue:value forKey:key];
			}
		}
	}
	
	return [NSDictionary dictionaryWithDictionary:dict];	
}

- (NSArray *)parseList:(NSData *)data 
{
	return [[data UTF8String] componentsSeparatedByString:@"\n"];
}

@end

@implementation NSData (LMBaseAdditions)

- (NSString *)hexString 
{
	
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:[self length]*2];
	const unsigned char *dataBuffer = [self bytes];
	
	for (int i=0; i<[self length]; i++)
		[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[i]];
	
	return [[stringBuffer copy] autorelease];
}

- (NSString *)UTF8String 
{
	return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}

@end


@implementation NSString (LMBaseAdditions)

- (NSString *)md5 
{	
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	if (data) {
		NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
		if (digest && MD5([data bytes], [data length], [digest mutableBytes]))
			return [[digest hexString] lowercaseString];
	}
	
	return nil;	
}

- (BOOL)containsString:(NSString *)str
{
	return [self rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound;
}

@end
