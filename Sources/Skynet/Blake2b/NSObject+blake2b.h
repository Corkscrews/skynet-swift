//
//  NSObject+blake2b_m.h
//  CryptoSwift
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Blake2b: NSObject
-(NSData*) hashWithDigestSize:(int)size data:(NSData*)data;
@end

NS_ASSUME_NONNULL_END
