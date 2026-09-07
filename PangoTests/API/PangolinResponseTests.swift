import Foundation
import Testing
@testable import Pango

@Suite("Pangolin response envelope")
struct PangolinResponseTests {
    private struct Payload: Decodable, Equatable {
        let value: String
    }

    @Test("decodes successful data")
    func decodesSuccessfulData() throws {
        let data = Data(#"{"data":{"value":"synthetic"},"success":true,"error":false,"message":"","status":200}"#.utf8)

        let response = try JSONDecoder().decode(PangolinResponse<Payload>.self, from: data)

        #expect(response.data == Payload(value: "synthetic"))
        #expect(response.success)
        #expect(!response.error)
        #expect(response.status == 200)
    }

    @Test("decodes a successful response without data")
    func decodesSuccessfulResponseWithoutData() throws {
        let data = Data(#"{"success":true,"error":false,"message":"Saved","status":200}"#.utf8)

        let response = try JSONDecoder().decode(PangolinResponse<PangolinEmptyResponse>.self, from: data)

        #expect(response.data == nil)
        #expect(response.message == "Saved")
    }

    @Test("preserves a server rejection")
    func preservesServerRejection() throws {
        let data = Data(#"{"success":false,"error":true,"message":"Synthetic rejection","status":422}"#.utf8)

        let response = try JSONDecoder().decode(PangolinResponse<PangolinEmptyResponse>.self, from: data)

        #expect(response.error)
        #expect(response.message == "Synthetic rejection")
        #expect(response.status == 422)
    }
}
