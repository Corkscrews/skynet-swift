//
//  NSObject+blake2b_m.m
//  CryptoSwift
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

#import "NSObject+blake2b.h"
#import "blake2.h"

@implementation Blake2b
-(NSData*) hashWithDigestSize:(int)size data:(NSData*)data {

  uint8_t hash[size/8];
  const uint8_t *pin = (const uint8_t*)[data bytes];

  blake2b(hash, size/8, pin, [data length], NULL, 0);

//  uint8_t hash[size/8];
//  uint8_t key[BLAKE2B_KEYBYTES];
//  size_t i;
//
//  for( i = 0; i < BLAKE2B_KEYBYTES; ++i )
//      key[i] = ( uint8_t )i;
//
//  blake2b_state S;
//  int err = 0;
//
//  if( (err = blake2b_init_key(&S, size, key, BLAKE2B_KEYBYTES)) < 0 ) {
//    return 0;
//  }
//
//  const uint8_t *pin = (const uint8_t*)[data bytes];
//
//  if ( (err = blake2b_update(&S, pin, size)) < 0 ) {
//    return 0;
//  }
//
//  if ( (err = blake2b_final(&S, hash, size)) < 0) {
//    return 0;
//  }

  return [NSData dataWithBytes:(const void *)hash length:size];
}
@end
