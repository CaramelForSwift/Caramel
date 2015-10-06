//
//  RuntimeTests.swift
//  Caramel
//
//  Created by Steve Streza on 31.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Quick
import Nimble
@testable import Caramel

class RuntimeSpec: QuickSpec {
	override func spec() {
		describe("Runtime") {
			context("environment variables") {
				it("should have the TestEnvironmentVariable variable") {
					expect(Process.environment("TestEnvironmentVariable")).to(equal("ItWorks"))
				}

				it("should not have a TestEnvironmentVariableTwo variable") {
					expect(Process.environment("TestEnvironmentVariableTwo")).to(beNil())
				}
			}
		}
	}
}