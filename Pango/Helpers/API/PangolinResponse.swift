struct PangolinResponse<Value: Decodable>: Decodable {
    let data: Value?
    let success: Bool
    let error: Bool
    let message: String
    let status: Int
}

struct PangolinEmptyResponse: Decodable, Equatable {
}
