import Testing
@testable import Domain

@Suite("Domain smoke")
struct DomainTests {
    @Test("Domain layer is reachable")
    func layerMarker() {
        #expect(Domain.layer == "Domain")
    }
}
