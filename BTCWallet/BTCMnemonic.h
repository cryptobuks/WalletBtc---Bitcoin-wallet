//
//  Created by Admin on 9/8/16.
//
#import <Foundation/Foundation.h>

@protocol BTCMnemonic<NSObject>
@required

- (NSString *)encodePhrase:(NSData *)data;
- (NSData *)decodePhrase:(NSString *)phrase; // phrase must be normalized
- (BOOL)wordIsValid:(NSString *)word; // true if word is a member of any known word list
- (BOOL)wordIsLocal:(NSString *)word; // true if word is a member of the word list for the current locale
- (BOOL)phraseIsValid:(NSString *)phrase; // true if all words and checksum are valid, phrase must be normalized
- (NSString *)cleanupPhrase:(NSString *)phrase; // minimally cleans up user input phrase, suitable for display/editing
- (NSString *)normalizePhrase:(NSString *)phrase; // normalizes phrase, suitable for decode/derivation
- (NSData *)deriveKeyFromPhrase:(NSString *)phrase withPassphrase:(NSString *)passphrase; // phrase must be normalized

@end
