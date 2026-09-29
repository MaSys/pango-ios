import Foundation

struct UsersPage: Decodable {
    let users: [User]
    let pagination: Pagination
}

struct PangolinUserService: Sendable {
    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listAllUsers(pageSize: Int = 1_000) async throws -> [User] {
        var users: [User] = []
        var requestedPage = 1
        while true {
            let response: PangolinResponse<UsersPage> = try await client.send(
                .get, path: "/org/\(organizationId)/users",
                queryItems: [
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                    URLQueryItem(name: "page", value: String(requestedPage))
                ]
            )
            guard response.success, !response.error else {
                throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
            }
            guard let result = response.data else { throw PangolinAPIError.decoding }
            users.append(contentsOf: result.users)
            guard result.pagination.pageSize > 0,
                  ResourcePagination.hasNextPage(total: result.pagination.total,
                    page: result.pagination.page, pageSize: result.pagination.pageSize) else {
                return users
            }
            let nextPage = result.pagination.page + 1
            guard nextPage > requestedPage else { throw PangolinAPIError.decoding }
            requestedPage = nextPage
        }
    }
}
