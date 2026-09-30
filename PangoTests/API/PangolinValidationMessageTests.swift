import Foundation
import Testing
@testable import Pango

struct PangolinValidationMessageTests {
    @Test(arguments: [
        ("Validation error: Too small: expected string to have >=4 characters at \"name\"", "Name must contain at least 4 characters."),
        ("Validation error: String must contain at most 255 character(s) at \"name\"", "Name must contain at most 255 characters."),
        ("Validation error: Invalid email address at \"email\"", "Enter a valid email address."),
        ("Validation error: Invalid URL at \"authUrl\"", "Auth URL must be a valid URL."),
        ("Validation error: Too big: expected number to be <=65535 at \"port\"", "Port must be at most 65535."),
        ("Validation error: Too small: expected array to have >=1 items at \"siteIds\"", "Select 1 or more items for Sites."),
        ("INVALID_PORT", "Port must be between 1 and 65535."),
        ("PATH_REQUIRED", "Enter a matching path before setting a rewrite path.")
    ])
    func translatesValidation(message: String, expected: String) throws {
        let bundle = try localizedBundle("en")
        let error = PangolinAPIError.serverRejected(status: 400, message: message)
        #expect(error.localizedMessage(bundle: bundle) == expected)
    }

    @Test(arguments: [
        ("Too small: expected string to have >=1 characters at \"name\"", "Enter a value for Name."),
        ("Number must be greater than or equal to 1 at \"interval\"", "Interval must be at least 1."),
        ("Too small: expected number to be >0 at \"validHours\"", "Valid For must be greater than 0."),
        ("Invalid input: expected int, received number at \"port\"", "Port must be a whole number."),
        ("Invalid input: expected string, received undefined at \"clientSecret\"", "Enter a value for Client Secret."),
        ("Invalid subdomain", "Enter a valid subdomain using letters, digits, and hyphens."),
        ("Invalid string at \"pincode\"", "PIN must contain exactly 6 digits (0–9).")
    ])
    func translatesOtherFormRules(detail: String, expected: String) throws {
        let error = PangolinAPIError.serverRejected(status: 400, message: "Validation error: " + detail)
        #expect(error.localizedMessage(bundle: try localizedBundle("en")) == expected)
    }

    @Test func doesNotDisplayRejectedValues() throws {
        let error = PangolinAPIError.serverRejected(status: 400, message: "Validation error: secret-value-must-not-appear at \"clientSecret\"")
        #expect(error.localizedMessage(bundle: try localizedBundle("en")) == "Check the value entered for Client Secret.")
    }

    @Test func translatesSpanish() throws {
        let bundle = try localizedBundle("es-419")
        let error = PangolinAPIError.serverRejected(status: 422, message: "Validation error: Invalid email address at \"email\"")
        #expect(error.localizedMessage(bundle: bundle) == "Ingresa una dirección de correo electrónico válida.")
    }

    @Test func showsMultipleFieldErrors() throws {
        let error = PangolinAPIError.serverRejected(status: 400, message: "Validation error: Invalid URL at \"authUrl\"; Invalid URL at \"tokenUrl\"")
        #expect(error.localizedMessage(bundle: try localizedBundle("en")) == "Auth URL must be a valid URL.\nToken URL must be a valid URL.")
    }

    @Test(arguments: ["Internal details: secret", "Validation error: secret at \"unknownField\"", "Validation error: secret", ""])
    func keepsUnknownErrorsGeneric(message: String) throws {
        let error = PangolinAPIError.serverRejected(status: 400, message: message)
        #expect(error.localizedMessage(bundle: try localizedBundle("en")) == "Pangolin rejected the request.")
    }

    private func localizedBundle(_ language: String) throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }
}
