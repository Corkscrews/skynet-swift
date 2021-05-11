//
//  NSObject+blake2b_m.m
//  CryptoSwift
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

#import "NSObject+blake2b.h"
#import "blake2.h"

@implementation Blake2b
+(NSData*) hashWithDigestSize:(int)size data:(NSData*)data {
  NSInteger length = size/8;
  uint8_t hash[length];
  const uint8_t *pin = (const uint8_t*)[data bytes];
  blake2b(hash, length, pin, [data length], NULL, 0);
  return [NSData dataWithBytes:(const void *)hash length:length];
}
@end
