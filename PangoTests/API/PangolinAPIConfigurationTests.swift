import Testing
@testable import Pango

@Suite("Pangolin API configuration")
struct PangolinAPIConfigurationTests {
    @Test("normalizes a base URL")
    func normalizesBaseURL() throws {
        let configuration = try PangolinAPIConfiguration(
            baseURLString: "https://api.pangolin.net/",
            apiKey: "test-id.test-secret"
        )

        #expect(configuration.baseURL.absoluteString == "https://api.pangolin.net")
    }

    @Test("rejects a non-HTTPS URL")
    func rejectsNonHTTPSURL() {
        #expect(throws: PangolinAPIConfiguration.Error.invalidBaseURL) {
            try PangolinAPIConfiguration(
                baseURLString: "http://api.example.com",
                apiKey: "key"
            )
        }
    }

    @Test("rejects an empty API key")
    func rejectsEmptyKey() {
        #expect(throws: PangolinAPIConfiguration.Error.missingAPIKey) {
            try PangolinAPIConfiguration(
                baseURLString: "https://api.example.com",
                apiKey: "  "
            )
        }
    }

    @Test("removes a trailing API version path")
    func removesVersionPath() throws {
        let configuration = try PangolinAPIConfiguration(
            baseURLString: "https://api.example.com/v1/",
            apiKey: "key"
        )

        #expect(configuration.baseURL.absoluteString == "https://api.example.com")
    }
}
