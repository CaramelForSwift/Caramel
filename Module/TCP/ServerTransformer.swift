//
//  ServerTransformer.swift
//  Caramel
//
//  Created by Steve Streza on 10/19/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class ServerTransformer<T: Listenable, U: Transforming, V: Transforming where T.InputStream.Sequence == U.Input, T.OutputStream.Sequence == V.Output>: Listenable {
    public typealias Listening = T

    public typealias InputTransformer = U
    public typealias OutputTransformer = V

    public typealias InputStream  = TransformingPushStream<Listening.InputStream,  InputTransformer.Output,  InputTransformer>
//    public typealias OutputStream = TransformingPushStream<Listening.OutputStream, OutputTransformer.Output, OutputTransformer>
    public typealias OutputStream = Listening.OutputStream

    public typealias Input = InputStream.Sequence
    public typealias Output = OutputStream.Sequence

    public typealias Connection = NetConnection<InputStream, OutputStream>

    public func listen(listenerHandler: ServerTransformer.ListenHandler) throws {
        try self.listening.listen(({ (connection: NetConnection<Listening.InputStream, Listening.OutputStream>) -> Void in
            let mappedInput = TransformingPushStream(inputStream: connection.incoming, transformer: self.inputTransformer)
//            let mappedOutput = TransformingPushStream(inputStream: connection.outgoing, transformer: self.outputTransformer)
            let newConnection = NetConnection(incoming: mappedInput, outgoing: connection.outgoing)
            listenerHandler(newConnection)
        }) as! Listening.ListenHandler)
    }

    private let listening: Listening
    private let inputTransformer: InputTransformer
    private let outputTransformer: OutputTransformer

    public init(listening: Listening, inputTransformer: InputTransformer, outputTransformer: OutputTransformer) {
        self.listening = listening
        self.inputTransformer = inputTransformer
        self.outputTransformer = outputTransformer
    }
}

public extension Listenable where
    Self.InputStream.Sequence: DataConvertible,
    Self.OutputStream.Sequence == Data
{
    public func toStringUnicodeScalarsViewWithEncoding(encoding: String.Encoding) -> ServerTransformer<Self, DataToStringUnicodeScalarViewTransformer<Self.InputStream.Sequence>, StringUnicodeScalarViewToDataTransformer> {
        let dataToStringScalars: DataToStringUnicodeScalarViewTransformer<Self.InputStream.Sequence>  = DataToStringUnicodeScalarViewTransformer(encoding: encoding)
        let stringScalarsToData = StringUnicodeScalarViewToDataTransformer(encoding: encoding)
        return ServerTransformer(listening: self, inputTransformer: dataToStringScalars, outputTransformer: stringScalarsToData)
    }
}

public extension Listenable where
    Self.InputStream.Sequence == String.UnicodeScalarView
{
    public func stringsSplitBy(character: UnicodeScalar) -> ServerTransformer<Self, UnicodeScalarViewToSplitStringTransformer, IdentityTransformer<Self.OutputStream.Sequence>> {
        let foo = UnicodeScalarViewToSplitStringTransformer(splitter: character)
        return ServerTransformer(listening: self, inputTransformer: foo, outputTransformer: IdentityTransformer())
    }

    public var stringsSplitByNewline: ServerTransformer<Self, UnicodeScalarViewToSplitStringTransformer, IdentityTransformer<Self.OutputStream.Sequence>> {
        return stringsSplitBy("\n")
    }
}
