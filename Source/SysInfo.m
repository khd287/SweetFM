//
//  SysInfo.m
//  SweetFM
//
//  Created by Q on 09.06.09.
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

#import "SysInfo.h"


NSString * SysInfoGetAppVersionString()
{
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [info objectForKey:@"CFBundleVersion"];
}

NSString * SysInfoGetArchitecture()
{
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/uname"];
	
	NSArray *arguments;
	arguments = [NSArray arrayWithObject:@"-m"];
	[task setArguments: arguments];
	
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	NSString *sysArch = [string stringByTrimmingCharactersInSet:
											 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[string release];
	[task release];
	
	return sysArch;
}

NSString * SysInfoGetMacOSVersionString()
{
	NSDictionary * sv = [NSDictionary dictionaryWithContentsOfFile:
											 @"/System/Library/CoreServices/SystemVersion.plist"];
	
	return [sv objectForKey:@"ProductVersion"];
}

NSString * SysInfoGetWebKitVersionString()
{
	NSDictionary * sv = [NSDictionary dictionaryWithContentsOfFile:
											 @"/System/Library/Frameworks/WebKit.framework/Resources/Info.plist"];
	
	return [sv objectForKey:@"CFBundleVersion"];
}
