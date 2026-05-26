import 'dart:typed_data';
import 'dart:math';

class SHA1 {
  static Uint8List hash(Uint8List message) {
    int originalLengthInBits = message.length * 8;
    int paddingLength = (448 - (originalLengthInBits + 8) % 512) % 512;
    if (paddingLength < 0) paddingLength += 512;
    
    int paddedLength = message.length + 1 + (paddingLength ~/ 8) + 8;
    Uint8List padded = Uint8List(paddedLength);
    padded.setAll(0, message);
    padded[message.length] = 0x80;
    
    ByteData.view(padded.buffer).setUint64(paddedLength - 8, originalLengthInBits, Endian.big);
    
    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;
    
    int rotateLeft(int value, int shift) {
      return ((value << shift) & 0xFFFFFFFF) | ((value & 0xFFFFFFFF) >> (32 - shift));
    }
    
    for (int i = 0; i < paddedLength; i += 64) {
      Uint32List w = Uint32List(80);
      ByteData blockData = ByteData.view(padded.buffer, i, 64);
      for (int t = 0; t < 16; t++) {
        w[t] = blockData.getUint32(t * 4, Endian.big);
      }
      for (int t = 16; t < 80; t++) {
        w[t] = rotateLeft(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1);
      }
      
      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      
      for (int t = 0; t < 80; t++) {
        int f, k;
        if (t < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (t < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (t < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        
        int temp = (rotateLeft(a, 5) + f + e + k + w[t]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = rotateLeft(b, 30);
        b = a;
        a = temp;
      }
      
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }
    
    Uint8List result = Uint8List(20);
    ByteData resultData = ByteData.view(result.buffer);
    resultData.setUint32(0, h0, Endian.big);
    resultData.setUint32(4, h1, Endian.big);
    resultData.setUint32(8, h2, Endian.big);
    resultData.setUint32(12, h3, Endian.big);
    resultData.setUint32(16, h4, Endian.big);
    return result;
  }
}

class HMAC {
  static Uint8List sha1(Uint8List key, Uint8List message) {
    int blockSize = 64;
    Uint8List workingKey = key;
    if (key.length > blockSize) {
      workingKey = SHA1.hash(key);
    }
    
    Uint8List paddedKey = Uint8List(blockSize);
    paddedKey.setAll(0, workingKey);
    
    Uint8List oKeyPad = Uint8List(blockSize);
    Uint8List iKeyPad = Uint8List(blockSize);
    for (int i = 0; i < blockSize; i++) {
      oKeyPad[i] = paddedKey[i] ^ 0x5c;
      iKeyPad[i] = paddedKey[i] ^ 0x36;
    }
    
    Uint8List innerMessage = Uint8List(blockSize + message.length);
    innerMessage.setAll(0, iKeyPad);
    innerMessage.setAll(blockSize, message);
    Uint8List innerHash = SHA1.hash(innerMessage);
    
    Uint8List outerMessage = Uint8List(blockSize + innerHash.length);
    outerMessage.setAll(0, oKeyPad);
    outerMessage.setAll(blockSize, innerHash);
    return SHA1.hash(outerMessage);
  }
}

class Base32 {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static Uint8List decode(String base32) {
    String cleaned = base32.trim().toUpperCase().replaceAll('=', '');
    if (cleaned.isEmpty) return Uint8List(0);

    int length = cleaned.length;
    int buffer = 0;
    int bitsLeft = 0;
    List<int> result = [];

    for (int i = 0; i < length; i++) {
      int val = _alphabet.indexOf(cleaned[i]);
      if (val == -1) {
        throw ArgumentError('Invalid Base32 character: ${cleaned[i]}');
      }
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        result.add((buffer >> bitsLeft) & 0xFF);
      }
    }
    return Uint8List.fromList(result);
  }
  
  static String encode(Uint8List bytes) {
    int i = 0;
    int index = 0;
    int digit = 0;
    int currByte;
    int nextByte;
    StringBuffer base32 = StringBuffer();

    while (i < bytes.length) {
      currByte = bytes[i];

      if (index > 3) {
        if ((i + 1) < bytes.length) {
          nextByte = bytes[i + 1];
        } else {
          nextByte = 0;
        }

        digit = currByte & (0xFF >> index);
        index = (index + 5) % 8;
        digit <<= index;
        digit |= nextByte >> (8 - index);
        i++;
      } else {
        digit = (currByte >> (8 - (index + 5))) & 0x1F;
        index = (index + 5) % 8;
        if (index == 0) {
          i++;
        }
      }
      base32.write(_alphabet[digit]);
    }
    return base32.toString();
  }
}

class TOTP {
  static String generateCode(String secret, int timeSeconds, {int interval = 30}) {
    Uint8List key = Base32.decode(secret);
    int counter = timeSeconds ~/ interval;
    
    Uint8List counterBytes = Uint8List(8);
    ByteData.view(counterBytes.buffer).setUint64(0, counter, Endian.big);
    
    Uint8List hash = HMAC.sha1(key, counterBytes);
    
    int offset = hash[19] & 0xf;
    int binary = ((hash[offset] & 0x7f) << 24) |
                 ((hash[offset + 1] & 0xff) << 16) |
                 ((hash[offset + 2] & 0xff) << 8) |
                 (hash[offset + 3] & 0xff);
                 
    int otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  static bool verifyCode(String secret, String code, {int window = 2}) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String cleanCode = code.trim().replaceAll(' ', '');
    for (int i = -window; i <= window; i++) {
      String generated = generateCode(secret, now + (i * 30));
      if (generated == cleanCode) {
        return true;
      }
    }
    return false;
  }

  static String generateSecretKey() {
    Random rand = Random.secure();
    Uint8List bytes = Uint8List(10); // 80 bits is standard and works perfectly for Google Authenticator
    for (int i = 0; i < 10; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return Base32.encode(bytes);
  }
  
  static String getOtpAuthUrl({
    required String secret,
    required String email,
    String issuer = 'myMove',
  }) {
    String cleanEmail = Uri.encodeComponent(email);
    String cleanIssuer = Uri.encodeComponent(issuer);
    return 'otpauth://totp/$cleanIssuer:$cleanEmail?secret=$secret&issuer=$cleanIssuer';
  }
}
