//
//  NSString+FormatUtilities.m
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

#import "NSString+FormatUtilities.h"

#import <openssl/md5.h>	// -lcrypto


@implementation NSString (URLEscaping)

- (NSString *)escapedUTF8String
{
	/*
	 CHAR     ESC
	 ------   ----
	 SPACE    %20
	 #        %23
	 $        %24
	 %        %25
	 &        %26
	 /        %2F
	 :        %3A
	 ;        %3B
	 <        %3C
	 =        %3D
	 >        %3E
	 ?        %3F
	 @        %40
	 [        %5B
	 \        %5C
	 ]        %5D
	 ^        %5E
	 `        %60
	 {        %7B
	 |        %7C
	 }        %7D
	 ~        %7E
	 */
	
	//
	// Do percents first, otherwise the'll be overwritten
	//
	NSString *safe = [[self copy] autorelease];
	// = [self stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
	
	NSMutableDictionary *replace = [NSMutableDictionary dictionary];
	[replace setObject:@"%23" forKey:@"#"];
	[replace setObject:@"%24" forKey:@"$"];
	[replace setObject:@"%26" forKey:@"&"];
	[replace setObject:@"%2F" forKey:@"/"];
	[replace setObject:@"%3A" forKey:@":"];
	[replace setObject:@"%3B" forKey:@";"];
	[replace setObject:@"%3C" forKey:@"<"];
	[replace setObject:@"%3D" forKey:@"="];
	[replace setObject:@"%3E" forKey:@">"];
	[replace setObject:@"%3F" forKey:@"?"];
	[replace setObject:@"%40" forKey:@"@"];
	[replace setObject:@"%5B" forKey:@"["];
	[replace setObject:@"%5C" forKey:@"\\"];
	[replace setObject:@"%5D" forKey:@"]"];
	[replace setObject:@"%5E" forKey:@"^"];
	[replace setObject:@"%60" forKey:@"`"];
	[replace setObject:@"%7B" forKey:@"{"];
	[replace setObject:@"%7C" forKey:@"|"];
	[replace setObject:@"%7D" forKey:@"}"];
	[replace setObject:@"%7E" forKey:@"~"];
	[replace setObject:@"%20" forKey:@" "];
	
	for(NSString *key in replace)
		safe = [safe stringByReplacingOccurrencesOfString:key withString:[replace objectForKey:key]];
	
	return [NSString stringWithString:safe];
}

- (NSString *)escape
{
	NSString *esc = [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [esc stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
}

- (NSString *)escapeAllURLCharacters
{
	return [self escapeAllURLCharactersAndUseWhitespacePlus:NO];
}

- (NSString *)escapeAllURLCharactersAndUseWhitespacePlus:(BOOL)wp
{
	NSString *esc = [[self stringByAddingPercentEscapesUsingEncoding:
									 NSUTF8StringEncoding] escapedUTF8String];

	if(wp)
		esc = [esc stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
	
	return esc;	
}

@end

@implementation NSString (FormatUtilities)

- (NSString *)stringByTrimmingLeadSpaces
{
	if(![self length])
		return nil;
	
	NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
	
	int loc=0;	
	while([set characterIsMember:[self characterAtIndex:loc]])
		loc++;

	return [self substringFromIndex:loc];
}

- (NSString *)empty
{
	if(self == nil)
		return @"";
	
	return self;
}

- (NSString *)md5Hash 
{	
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	if (data) {
		NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
		if (digest && MD5([data bytes], [data length], [digest mutableBytes]))
		{
			NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:[digest length]*2];
			const unsigned char *dataBuffer = [digest bytes];
			
			for (int i=0; i<[self length]; i++)
				[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[i]];
			
			return [stringBuffer lowercaseString];
		}
	}
	
	return nil;	
}

@end
