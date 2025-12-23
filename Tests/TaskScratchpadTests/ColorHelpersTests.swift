import Testing
import SwiftUI
@testable import TaskScratchpadCore

@Suite("Color Helpers")
struct ColorHelpersTests {

    @Test("Parse valid hex colors")
    func parseValidHex() {
        #expect(Color.parseHex("#6EA8FE") == 0x6EA8FE)
        #expect(Color.parseHex("#000000") == 0x000000)
        #expect(Color.parseHex("#FFFFFF") == 0xFFFFFF)
        #expect(Color.parseHex("#ff0000") == 0xFF0000)
        #expect(Color.parseHex("6EA8FE") == 0x6EA8FE) // without #
    }

    @Test("Parse invalid hex colors returns nil")
    func parseInvalidHex() {
        #expect(Color.parseHex("") == nil)
        #expect(Color.parseHex("#") == nil)
        #expect(Color.parseHex("#12345") == nil) // too short
        #expect(Color.parseHex("#1234567") == nil) // too long
        #expect(Color.parseHex("#GGGGGG") == nil) // invalid chars
        #expect(Color.parseHex("not a color") == nil)
    }

    @Test("isValidHex returns correct boolean")
    func isValidHex() {
        #expect(Color.isValidHex("#6EA8FE") == true)
        #expect(Color.isValidHex("#000000") == true)
        #expect(Color.isValidHex("") == false)
        #expect(Color.isValidHex("#GGG") == false)
    }

    @Test("Color palette has expected count")
    func paletteCount() {
        #expect(ColorPalette.colors.count == 8)
    }

    @Test("Color palette cycling works correctly")
    func paletteCycling() {
        let first = ColorPalette.color(at: 0)
        let ninth = ColorPalette.color(at: 8) // should wrap to index 0
        #expect(first == ninth)

        let second = ColorPalette.color(at: 1)
        let tenth = ColorPalette.color(at: 9) // should wrap to index 1
        #expect(second == tenth)
    }

    @Test("All palette colors are valid hex")
    func allPaletteColorsValid() {
        for hex in ColorPalette.colors {
            #expect(Color.isValidHex(hex), "Expected \(hex) to be valid hex")
        }
    }

    @Test("Color initializer creates color from valid hex")
    func colorFromHex() {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)

        let invalidColor = Color(hex: "invalid")
        #expect(invalidColor == nil)
    }
}

