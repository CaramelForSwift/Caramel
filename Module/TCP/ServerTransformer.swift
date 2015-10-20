//
//  ServerTransformer.swift
//  Caramel
//
//  Created by Steve Streza on 10/19/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class ServerTransformer<S: Listenable, T: Pushable, U: Pushable where S.Input: StreamBuffer, S.Output: StreamBuffer, T.Sequence: StreamBuffer, U.Sequence: StreamBuffer>: Listenable {
    public typealias Source = S

    public typealias InputStream = T
    public typealias OutputStream = U

    public typealias TransformedInput = Source.Input
    public typealias TransformedOutput = Source.Output

    public func listen(port: UInt16, listener: ServerTransformer.ListenHandler) throws {
        try self.source.listen(port, listener: ({ (connection: NetConnection<Source.InputStream, Source.OutputStream>) in
            let mappedIncoming = TransformingPushStream(inputStream: connection.incoming, transformer: self.inputTransformer)
            let mappedOutgoing = TransformingPushStream(inputStream: connection.outgoing, transformer: self.outputTransformer)
            let newConnection = NetConnection(incoming: mappedIncoming, outgoing: connection.outgoing)
            listener(newConnection)
            print("Farts \(connection)")
        } as! Source.ListenHandler))
    }

    public typealias InputTransformer = Transformer<TransformedInput, InputStream.Sequence>
    public typealias OutputTransformer = Transformer<OutputStream.Sequence, TransformedOutput>

    private let source: Source
    private let inputTransformer: InputTransformer
    private let outputTransformer: OutputTransformer
    public init(source: Source, input: InputTransformer, output: OutputTransformer) {
        self.source = source
        self.inputTransformer = input
        self.outputTransformer = output
    }
}

public extension Listenable where
    Self.InputStream: StreamBuffer,
    Self.InputStream.Sequence: DataConvertible,
    Self.OutputStream: StreamBuffer,
    Self.OutputStream.Sequence == Data
{
    func dataToStringWithEncoding(encoding: String.Encoding) -> ServerTransformer<Self, String.UnicodeScalarView, String.UnicodeScalarView>? {
        let dataToString: DataToStringUnicodeScalarViewTransformer<Self.InputStream.Sequence> = DataToStringUnicodeScalarViewTransformer(encoding: encoding)
        let stringToData = StringUnicodeScalarViewToDataTransformer(encoding: encoding)
        return ServerTransformer(source: self, input: dataToString, output: stringToData)
    }
}

