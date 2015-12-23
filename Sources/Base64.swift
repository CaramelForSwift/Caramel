//
//  Base64.swift
//  Caramel
//
//  Created by Steve Streza on 20.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

#if os(Linux)
import Glibc
#endif

private let characterLookupTable = [
	UInt8(65) /* A */, 
	UInt8(66) /* B */, 
	UInt8(67) /* C */, 
	UInt8(68) /* D */, 
	UInt8(69) /* E */, 
	UInt8(70) /* F */, 
	UInt8(71) /* G */, 
	UInt8(72) /* H */, 
	UInt8(73) /* I */, 
	UInt8(74) /* J */, 
	UInt8(75) /* K */, 
	UInt8(76) /* L */, 
	UInt8(77) /* M */, 
	UInt8(78) /* N */, 
	UInt8(79) /* O */, 
	UInt8(80) /* P */, 
	UInt8(81) /* Q */, 
	UInt8(82) /* R */, 
	UInt8(83) /* S */, 
	UInt8(84) /* T */, 
	UInt8(85) /* U */, 
	UInt8(86) /* V */, 
	UInt8(87) /* W */, 
	UInt8(88) /* X */, 
	UInt8(89) /* Y */, 
	UInt8(90) /* Z */, 
	UInt8(97) /* a */, 
	UInt8(98) /* b */, 
	UInt8(99) /* c */, 
	UInt8(100) /* d */, 
	UInt8(101) /* e */, 
	UInt8(102) /* f */, 
	UInt8(103) /* g */, 
	UInt8(104) /* h */, 
	UInt8(105) /* i */, 
	UInt8(106) /* j */, 
	UInt8(107) /* k */, 
	UInt8(108) /* l */, 
	UInt8(109) /* m */, 
	UInt8(110) /* n */, 
	UInt8(111) /* o */, 
	UInt8(112) /* p */, 
	UInt8(113) /* q */, 
	UInt8(114) /* r */, 
	UInt8(115) /* s */, 
	UInt8(116) /* t */, 
	UInt8(117) /* u */, 
	UInt8(118) /* v */, 
	UInt8(119) /* w */, 
	UInt8(120) /* x */, 
	UInt8(121) /* y */, 
	UInt8(122) /* z */, 
	UInt8(48) /* 0 */, 
	UInt8(49) /* 1 */, 
	UInt8(50) /* 2 */, 
	UInt8(51) /* 3 */, 
	UInt8(52) /* 4 */, 
	UInt8(53) /* 5 */, 
	UInt8(54) /* 6 */, 
	UInt8(55) /* 7 */, 
	UInt8(56) /* 8 */, 
	UInt8(57) /* 9 */, 
	UInt8(43) /* + */, 
	UInt8(47) /* / */, 
	UInt8(61) /* = */
]

private let filler = UInt8(61)

public extension Pullable where Self.Sequence: DataConvertible {
	var base64Encode: TransformingPullStream<Self, Data, Base64EncodeTransformer<Sequence>> {
		return self.transformWith(Base64EncodeTransformer())
	}
}

public extension Pushable where Self.Sequence: DataConvertible {
	var base64Encode: TransformingPushStream<Self, Data, Base64EncodeTransformer<Sequence>> {
		return self.transformWith(Base64EncodeTransformer())
	}
}

public extension DataConvertible {
	var base64EncodedData: Data {
        return self.stream.base64Encode.drain()
	}
	var base64EncodedString: String? {
        return self.base64EncodedData.UTF8String
	}
}

public class Base64EncodeTransformer<T: DataConvertible>: Transformer<T, Data> {
	public override func transform(input: T) -> Data {
		var data = input.data
		let numberOfOutBytes = Int(ceil(Double(data.bytes.count) / 3) * 4)
		var newData = Data(numberOfZeroes: numberOfOutBytes)
		var highestIndex = data.bytes.startIndex
		var encodedDataIndex = 0
		for i in data.bytes.startIndex.stride(to: data.bytes.endIndex, by: 3) {
			let byte0 = (i + 0 < data.bytes.endIndex) ? data.bytes[i + 0] : 0
			let byte1 = (i + 1 < data.bytes.endIndex) ? data.bytes[i + 1] : 0
			let byte2 = (i + 2 < data.bytes.endIndex) ? data.bytes[i + 2] : 0
			
			let outByte0 = (byte0 & 0xFC) >> 2
			let outByte1 = ((byte0 & 0x03) << 4) | ((byte1 & 0xF0) >> 4)
			let outByte2 = ((byte1 & 0x0F) << 2) | ((byte2 & 0xC0) >> 6)
			let outByte3 = (byte2 & 0x3F)
			
			newData.bytes[i + 0] = characterLookupTable[characterLookupTable.startIndex.advancedBy(Int(outByte0))]
			newData.bytes[i + 1] = characterLookupTable[characterLookupTable.startIndex.advancedBy(Int(outByte1))]
			newData.bytes[i + 2] = characterLookupTable[characterLookupTable.startIndex.advancedBy(Int(outByte2))]
			newData.bytes[i + 3] = characterLookupTable[characterLookupTable.startIndex.advancedBy(Int(outByte3))]
			
			if (i + 2 >= data.bytes.endIndex) {
				newData.bytes[i+3] = filler
			}
			if (i + 1 >= data.bytes.endIndex) {
				newData.bytes[i+2] = filler
			}
			
			highestIndex = i + 3
			encodedDataIndex += 4
		}

		if data.bytes.count > highestIndex {
			data.bytes.removeRange(Range<Array<Byte>.Index>(start: data.bytes.startIndex, end: highestIndex))
			print("- \(data.bytes.count)")
			self.appendToBuffer(data as! T)
		}
		
		if encodedDataIndex < newData.bytes.endIndex {
			print("delta: \(encodedDataIndex) to \(newData.bytes.endIndex) \(encodedDataIndex % 3)")
			newData.bytes.removeRange(Range<Array<Byte>.Index>(start: encodedDataIndex, end: newData.bytes.endIndex))
		}
		return newData
	}
	public override func finish() throws -> Data? {
		var data = Data()
		let buffer = self.drainBuffer()
		
		return data
	}
}
