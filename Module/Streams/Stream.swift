public protocol Buffered: AnyObject {
    typealias Sequence: StreamBuffer
    
    var buffer: Sequence { get set }
    var isAtEnd: Bool { get }    
}
