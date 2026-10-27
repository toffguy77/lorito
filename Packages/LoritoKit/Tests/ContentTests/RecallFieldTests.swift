import Testing
import Foundation
import Domain

@Suite("Card recall field")
struct RecallFieldTests {
    @Test("recall decodes when present and is nil when absent")
    func decodes() throws {
        let json = """
        [{"id":"A1-01","level":"A1","themeID":"a1-1","order":1,"title":"T","aliases":[],"related":[],"tags":[],"body":"b","recall":"**¿el или la?** *mano*"},
         {"id":"A1-02","level":"A1","themeID":"a1-1","order":2,"title":"T2","aliases":[],"related":[],"tags":[],"body":"b"}]
        """
        let cards = try JSONDecoder().decode([Card].self, from: Data(json.utf8))
        #expect(cards[0].recall == "**¿el или la?** *mano*")
        #expect(cards[1].recall == nil)
    }
}
