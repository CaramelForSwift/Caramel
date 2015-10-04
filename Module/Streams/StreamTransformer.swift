//
//  StreamTransformer.swift
//  Jelly
//
//  Created by Steve Streza on 23.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public final class Transformer<T: StreamBuffer, U: StreamBuffer> {
	public typealias Input = T
	public typealias Output = U
	
	private(set) var transformer: (T, Transformer<T, U>) -> (U)
	
	init(transformer: (T, Transformer<T, U>) -> U) {
		self.transformer = transformer
	}
	
	private var inputBuffer: Input = Input()
	func receive(input: Input) {
		inputBuffer.append(input)
	}
	
	func transform(input: Input) -> Output {
		return self.transformer(input, self)
	}
}
