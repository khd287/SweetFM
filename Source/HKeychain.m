//
//  HKeychain.m
//  SweetFM
//
//  Created by Q on 31.05.09.
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

#import "HKeychain.h"

#import "SynthesizeSingleton.h"


@implementation HKeychain

SYNTHESIZE_SINGLETON_FOR_CLASS(HKeychain, sharedKeychain);

- (HKeychainItem *)keychainItemForService:(NSString *)service
{	
	SecKeychainItemRef itemRef;
	
	const char *cstr = [service UTF8String];
	
	OSStatus status = SecKeychainFindGenericPassword(keychain_, strlen(cstr), cstr, 0, NULL, 0, NULL, &itemRef);
	
	if(status==noErr) {
		return [HKeychainItem keychainItemWithRef:itemRef];
	}
	
	return nil;
}

- (HKeychainItem *)addKeychainItemForService:(NSString *)service
																	accountName:(NSString *)account
															accountPassword:(NSString *)password 
{	
	SecKeychainItemRef itemRef;
	
	OSStatus status = SecKeychainAddGenericPassword(keychain_,						
																									[service lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
																									[service cStringUsingEncoding:NSUTF8StringEncoding],			
																									[account lengthOfBytesUsingEncoding:NSUTF8StringEncoding],		
																									[account cStringUsingEncoding:NSUTF8StringEncoding],				
																									[password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
																									[password cStringUsingEncoding:NSUTF8StringEncoding],		
																									&itemRef
																									);
	
	if(status==noErr)	
		return [HKeychainItem keychainItemWithRef:itemRef];
	
	return nil;
}

- (HKeychainItem *)keychainItemForServer:(NSString *)aServer
{	
	SecKeychainItemRef itemRef;
	const char *server = [aServer UTF8String];
	
	OSStatus status = SecKeychainFindInternetPassword(NULL,
																										strlen(server), server, 
																										0, NULL, 
																										0, NULL,
																										0, NULL,
																										0, 
																										kSecProtocolTypeAny,
																										kSecAuthenticationTypeAny,
																										0, NULL, 
																										&itemRef);
	
	if(status==noErr) {
		return [HKeychainItem keychainItemWithRef:itemRef];
	}
	
	return nil;
}

@end

@implementation HKeychainItem

+ (HKeychainItem *)keychainItemWithRef:(SecKeychainItemRef)ref 
{
	return [[[HKeychainItem alloc] initWithRef:ref] autorelease];
}

- (id)initWithRef:(SecKeychainItemRef)ref 
{
	if(self = [super init])
		keychainItem_ = ref;
	
	return self;
}

- (BOOL)setAccessForService:(NSString *)service withPath:(NSString *)path 
{	
	// Create a trusted app ref for passed path
	SecTrustedApplicationRef* trustedApp;
	OSStatus status = SecTrustedApplicationCreateFromPath([path cStringUsingEncoding:NSUTF8StringEncoding],
																												trustedApp);
	
	if(status!=noErr)
		return NO;
	
	// Create new access object with service name and trusted apps
	NSArray* trustedList = [[NSArray alloc] initWithObjects:(id*)trustedApp
																										count:1];
	SecAccessRef accessRef;
	
	status = SecAccessCreate((CFStringRef)service,
													 (CFArrayRef)trustedList,
													 &accessRef
													 );
	
	[trustedList release];
	
	if(status!=noErr)
		return NO;
	
	// Get associated keychain
	SecKeychainRef keychainRef;
	status = SecKeychainItemCopyKeychain(keychainItem_, &keychainRef);
	
	if(status!=noErr)
		return NO;
	
	// Set access on default keychain
	status = SecKeychainSetAccess(keychainRef, accessRef);
	
	return (status!=noErr) ? NO : YES;
}

- (BOOL)setAccountPassword:(NSString *)password 
{	
	OSStatus status = SecKeychainItemModifyAttributesAndData(
																													 keychainItem_,         
																													 NULL,            
																													 [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],  
																													 [password cStringUsingEncoding:NSUTF8StringEncoding]        
																													 );
	
	return (status==noErr) ? YES : NO;
}

- (BOOL)setAccountName:(NSString *)account 
{	
	SecKeychainAttributeList	list;
	SecKeychainAttribute			attr;
	
	list.count = 1;
	list.attr = &attr;
	
	attr.tag = kSecAccountItemAttr;
	attr.data = (void*)[account cStringUsingEncoding:NSUTF8StringEncoding];
	attr.length = [account lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	OSStatus status = SecKeychainItemModifyAttributesAndData(keychainItem_, &list, 0, NULL);
	
	return (status==noErr) ? YES : NO;
}

- (NSString *)accountPassword 
{	
	UInt32			length;
	void*				outData;
	
	if(SecKeychainItemCopyContent(keychainItem_, NULL, NULL, &length, &outData)==noErr) {
		NSString *password = [NSString stringWithCString:outData length:length];
		SecKeychainItemFreeContent(NULL, outData);
		return password;
	}
	
	return @"";
}

- (NSString *)accountName 
{	
	SecKeychainAttributeList list;
	SecKeychainAttribute attr;
	
	list.count = 1;
	list.attr = &attr;
	attr.tag = kSecAccountItemAttr;
	
	SecKeychainItemCopyContent(keychainItem_, NULL, &list, NULL, NULL);
	
	if(attr.data != NULL) {
		NSString *accName = [NSString stringWithCString:attr.data length:attr.length];
		SecKeychainItemFreeContent(&list, NULL);
		return accName;
	}
	
	return @"";
}

@end