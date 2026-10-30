import Testing

struct CommandTests {
    @Test(arguments: ["0", "0.5", "1", "0.025"])
    func acceptsValidSeekFractions(_ value: String) {
        #expect(Command.seekFraction(value) != nil)
    }

    @Test(arguments: [nil, "", "-0.1", "1.01", "nan", "inf", "abc", "0.5; quit"])
    func rejectsInvalidSeekFractions(_ value: String?) {
        #expect(Command.seekFraction(value) == nil)
    }

    @Test func notificationNamesAreUnique() {
        let names = Set(Command.allCases.map(\.notification))
        #expect(names.count == Command.allCases.count)
    }
}
