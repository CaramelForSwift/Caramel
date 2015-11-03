# Caramel

Caramel is a cross-platform module for building server applications in Swift.

Caramel is **not** production-ready, use at your own discretion. Discussion about design and architecture is welcome. 

# Design goals

## Design APIs to be Swifty, not around the limitations of C or Foundation.

APIs like `fread` and `NSFileManager` were designed decades ago, around the design requirements of C-based languages. Approach API design by thinking about what is the most Swifty way to do things before taking inspiration from the past.

## Never import Apple-specific frameworks, such as Foundation, except for Apple-specific optimizations

Although development and testing of the core framework may always be easier with Xcode on Macs, this is a cross-platform module, and we cannot become dependent on Apple's closed-source libraries. The only time it is okay to depend on Apple's frameworks is if it is an optimization on Apple's frameworks, as long as it is compliant with APIs working on non-Apple platforms.

## Always expose Swift native types. Never expose legacy data types or unsafe types.

Under the hood we may need to use POSIX APIs, or import the Darwin module, etc. These APIs often expose legacy data types, or rely on `UnsafePointer` types. All public APIs should absorb these legacy types into higher-order types, and unsafety should be absorbed by the framework. (A notable exception would be the `Data` class, which may expose an `UnsafePointer` for binary data, but other APIs should return `Data` types).

## Reduce interdependence between types in their base implementations, add it via extensions.

As much as possible, each type should not depend on other types in its base class. Instead, try to isolate interdependence into extensions. This keeps base types cleaner, easier to isolate, easier to test, and better encapsulated. But let the best API design win.

# Contributor Code of Conduct

As contributors and maintainers of this project, and in the interest of fostering an open and welcoming community, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, or nationality.

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery
* Personal attacks
* Trolling or insulting/derogatory comments
* Public or private harassment
* Publishing other's private information, such as physical or electronic addresses, without explicit permission
* Other unethical or unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. By adopting this Code of Conduct, project maintainers commit themselves to fairly and consistently applying these principles to every aspect of managing this project. Project maintainers who do not follow or enforce the Code of Conduct may be permanently removed from the project team.

This code of conduct applies both within project spaces and in public spaces when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This Code of Conduct is adapted from the [Contributor Covenant](http://contributor-covenant.org), version 1.2.0, available at [http://contributor-covenant.org/version/1/2/0/](http://contributor-covenant.org/version/1/2/0/), and is open for discussion if does not adequately protect people who want to be a member of the community.

# License (MIT) 

Copyright (c) 2015 Steve Streza

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


