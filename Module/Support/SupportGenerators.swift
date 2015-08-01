//
//  SupportGenerators.swift
//  Jelly
//
//  Created by Steve Streza on 1.8.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal struct GeneratorBatcher<T: GeneratorType, U where U == T.Element>: GeneratorType {
	typealias Element = [U]
	private(set) var generator: T
	let size: Int
	init(generator: T, size: Int) {
		self.generator = generator
		self.size = size
	}
	mutating func next() -> Element? {
		var elements: [U] = []
		
		var next: U? = nil
		repeat {
			if let nextThing = self.generator.next() {
				next = nextThing
				elements.append(nextThing)
			}
		} while (elements.count < self.size && next != nil)
		
		return elements.count > 0 ? elements : nil
	}
}

internal struct GeneratorMapper<T: GeneratorType, U>: GeneratorType {
	typealias Element = U
	
	private(set) var generator: T
	let mapper: (T.Element) -> U
	
	init(generator: T, mapper: (T.Element) -> U) {
		self.generator = generator
		self.mapper = mapper
	}
	
	mutating func next() -> Element? {
		if let nextThing = self.generator.next() {
			let mappedThing = self.mapper(nextThing)
			return mappedThing
		} else {
			return nil
		}
	}
}
