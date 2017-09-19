import Core
import HTTP
import Vapor
import TLS
import XCTest

class ApplicationTests: XCTestCase {
    func testHTTPSClient() throws {
        let queue = DispatchQueue(label: "test")
        
        let SSL = try AppleSSLClient()
        try SSL.connect(hostname: "google.com", port: 443).blockingAwait()
        try SSL.initializeSSLClient(hostname: "google.com")
        
        let parser = ResponseParser()
        let serializer = RequestSerializer()
        
        let promise = Promise<Response>()
        
        SSL.stream(to: parser).drain { response in
            promise.complete(response)
        }
        
        serializer.drain { message in
            message.message.withUnsafeBytes { (pointer: BytesPointer) in
                SSL.inputStream(ByteBuffer(start: pointer, count: message.message.count))
            }
        }
        
        SSL.start(on: queue)
        serializer.inputStream(Request())
        
        XCTAssertNoThrow(try promise.future.blockingAwait(timeout: .seconds(15)))
    }
    
    static let allTests = [
        ("testHTTPSClient", testHTTPSClient),
    ]
}
