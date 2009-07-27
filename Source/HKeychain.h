//
//  HKeychain.h
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

#import <Cocoa/Cocoa.h>

#import <Security/Security.h>
#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>


//
// Keychain item
//
@interface HKeychainItem : NSObject {

	SecKeychainItemRef	keychainItem_;
}

+ (HKeychainItem *)keychainItemWithRef:(SecKeychainItemRef)ref;

- (id)initWithRef:(SecKeychainItemRef)ref;

- (BOOL)setAccessForService:(NSString *)service withPath:(NSString *)path;
- (BOOL)setAccountPassword:(NSString *)password;
- (BOOL)setAccountName:(NSString *)account;

- (NSString *)accountPassword;
- (NSString *)accountName;

@end

//
// Keychain
//
@interface HKeychain : NSObject {

	SecKeychainRef	keychain_;
}

+ (HKeychain *)sharedKeychain;

- (HKeychainItem *)keychainItemForService:(NSString *)service;
- (HKeychainItem *)addKeychainItemForService:(NSString *)service
																	accountName:(NSString *)account
															accountPassword:(NSString *)password;

- (HKeychainItem *)keychainItemForServer:(NSString *)aServer;

@end
