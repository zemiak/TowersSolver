import Foundation

/// Helper for printing grids to the console using ASCII text.
public class GridPrinter {
    private var buffer: [UnicodeScalar] = []
    /// Used when diffing print
    private var lastPrintBuffer: String?
    private var _storingDiff = false
    
    public let bufferWidth: Int
    public let bufferHeight: Int
    
    /// Whether to highlight colors of changed areas diff-style (red for removed
    /// text, green for added text, and white for unchanged)
    public var diffingPrint = false
    
    public init(bufferWidth: Int, bufferHeight: Int) {
        self.bufferWidth = bufferWidth
        self.bufferHeight = bufferHeight
        
        // Initialize buffer string
        resetBuffer()
    }
    
    public func resetBuffer() {
        let line = Array(repeating: " " as UnicodeScalar, count: bufferWidth - 1)
        buffer = Array(repeating: line + ["\n"], count: bufferHeight).flatMap { $0 }
    }
    
    public func put(_ scalar: UnicodeScalar, x: Int, y: Int) {
        var offset = y * bufferWidth + x
        
        // Out of buffer's reach
        if offset >= buffer.count - 2 {
            return
        }
        if offset < 0 {
            return
        }
        
        // Wrap-around (- 2 to not eat the line-ending character at bufferWidth - 1)
        if offset % bufferWidth == (bufferWidth - 1) {
            offset += 1
            
            if offset >= buffer.count - 2 {
                return
            }
        }
        
        putChar(scalar, offset: offset)
        
        offset += 1
    }
    
    public func putString(_ string: String, x: Int, y: Int) {
        var offset = y * bufferWidth + x
        
        for c in string {
            // Out of buffer's reach
            if offset >= buffer.count - 2 {
                return
            }
            if offset < 0 {
                continue
            }
            
            // Wrap-around (- 2 to not eat the line-ending character at bufferWidth - 1)
            if offset % bufferWidth == (bufferWidth - 1) {
                offset += 1
                continue
            }
            
            putChar(c, offset: offset)
            
            offset += 1
        }
    }
    
    public func putRect(x: Int, y: Int, w: Int, h: Int) {
        for _x in x...x+w {
            put("-", x: _x, y: y)
            put("-", x: _x, y: y + h)
        }
        for _y in y...y+h {
            put("|", x: x, y: _y)
            put("|", x: x + w, y: _y)
        }
    }
    
    private func putChar(_ char: Character, offset: Int) {
        let index = buffer.index(buffer.startIndex, offsetBy: offset)
        
        buffer.replaceSubrange(index...index, with: char.unicodeScalars)
    }
    
    private func putChar(_ char: UnicodeScalar, offset: Int) {
        let index = buffer.index(buffer.startIndex, offsetBy: offset)
        
        buffer[index] = char
    }
    
    private func get(_ x: Int, _ y: Int) -> UnicodeScalar {
        var offset = y * bufferWidth + x
        
        if offset % bufferWidth == (bufferWidth - 1) {
            offset += 1
        }
        
        if offset >= buffer.count - 2 {
            return UnicodeScalar(0)
        }
        
        return buffer[offset]
    }
    
    public func line(index: Int) -> String {
        let offset = index * bufferWidth
        let offsetNext = (index + 1) * bufferWidth
        
        let offNext = offsetNext - 1
        
        return String(String.UnicodeScalarView(buffer[offset..<offNext]))
    }
    
    private func calculateDiffPrint(old: String, new: String) -> String {
        // Debug means Xcode console. Xcode console means no ANSI color output!
        #if DEBUG
            return new
        #else
            
            var outBuffer: [UnicodeScalar] = []
            
            // Use ScalarView as it's much faster to work with
            let oldScalars = old.unicodeScalars
            let newScalars = new.unicodeScalars
            
            outBuffer.reserveCapacity(max(oldScalars.count, newScalars.count))
            
            for (oldScalar, newScalar) in zip(oldScalars, newScalars) {
                if oldScalar == newScalar {
                    outBuffer.append(oldScalar)
                    continue
                }
                
                // Red when old != whitespace and new == whitespace
                if !CharacterSet.whitespacesAndNewlines.contains(oldScalar) &&
                    CharacterSet.whitespacesAndNewlines.contains(newScalar) {
                    outBuffer.append(contentsOf: ConsoleColor.red.terminalForeground.ansi.unicodeScalars)
                    outBuffer.append(oldScalar)
                    outBuffer.append(contentsOf: UInt8(0).ansi.unicodeScalars)
                }
                
                // Green when new != whitespace
                if !CharacterSet.whitespacesAndNewlines.contains(newScalar) {
                    outBuffer.append(contentsOf: ConsoleColor.green.terminalForeground.ansi.unicodeScalars)
                    outBuffer.append(newScalar)
                    outBuffer.append(contentsOf: UInt8(0).ansi.unicodeScalars)
                }
            }
            
            return String(String.UnicodeScalarView(outBuffer))
            
        #endif
    }
    
    /// Any print call made to this print grider while inside this block will
    /// only modify the diff stored, and not print its contents to stdout.
    public func storingDiff(do block: () -> ()) {
        _storingDiff = true
        block()
        _storingDiff = false
    }
    
    public func print(trimming: Bool = true) {
        let newBuffer = getPrintBuffer(trimming: trimming)
        
        if !_storingDiff {
            // Calc diff
            if let last = lastPrintBuffer {
                Swift.print(calculateDiffPrint(old: last, new: newBuffer))
            } else {
                Swift.print(newBuffer)
            }
        }
        
        lastPrintBuffer = newBuffer
    }
    
    private func getPrintBuffer(trimming: Bool = true) -> String {
        if !trimming {
            return String(String.UnicodeScalarView(buffer))
        }
        
        var maxY = 0
        
        for i in (0..<bufferHeight).reversed() {
            let l = line(index: i)
            if l.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                maxY = i
                break
            }
        }
        
        if maxY == 0 {
            return ""
        }
        
        var acc = ""
        for i in 0...maxY {
            let l = line(index: i)
            acc += l + "\n"
        }
        return acc
    }
    
    /// Joins dashes and vertical bars into box drawing ASCII chars
    public func joinBoxLines() {
        // Sides bitmap
        struct Sides: Hashable, OptionSet {
            var hashValue: Int {
                return rawValue
            }
            var rawValue: Int
            
            static let left   = Sides(rawValue: 1 << 0)
            static let right  = Sides(rawValue: 1 << 1)
            static let top    = Sides(rawValue: 1 << 2)
            static let bottom = Sides(rawValue: 1 << 3)
            
            init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }
        
        var substitutions: [Sides: UnicodeScalar] = [
            [.left]:   "─",
            [.right]:  "─",
            [.top]:    "│",
            [.bottom]: "│",
            [.left, .right]:   "─",
            [.top, .bottom]:   "│",
            [.bottom, .right]: "╭",
            [.top, .right]:    "╰",
            [.left, .bottom]:  "╮",
            [.left, .top]:     "╯",
            [.top, .right, .bottom]:  "├",
            [.top, .left, .bottom]:   "┤",
            [.left, .bottom, .right]: "┬",
            [.left, .top, .right]:    "┴",
            [.left, .top, .right, .bottom]: "┼"
        ]
        
        let isGrid = (["-", "|"] + substitutions.values).contains
        
        for y in 0..<bufferHeight {
            for x in 0..<bufferWidth {
                
                if !isGrid(get(x, y)) {
                    continue
                }
                
                var sides: Sides = []
                
                if x > 0 {
                    if isGrid(get(x - 1, y)) {
                        sides.insert(.left)
                    }
                }
                if x < bufferWidth - 2 {
                    if isGrid(get(x + 1, y)) {
                        sides.insert(.right)
                    }
                }
                
                if y > 0 {
                    if isGrid(get(x, y - 1)) {
                        sides.insert(.top)
                    }
                }
                if y < bufferHeight - 1 {
                    if isGrid(get(x, y + 1)) {
                        sides.insert(.bottom)
                    }
                }
                
                if let str = substitutions[sides] {
                    put(str, x: x, y: y)
                }
            }
        }
    }
    
    public static func cellWidth(for grid: Grid) -> Int {
        return 6
    }
    
    public static func cellHeight(for grid: Grid) -> Int {
        return 4
    }
}

public extension GridPrinter {
    
    /// Removes any prior diff buffer so the next print is clean of diff checks
    public func resetDiffPrint() {
        lastPrintBuffer = nil
    }
    
    public func printGrid(grid: Grid) {
        resetBuffer()
        
        let originX = 2
        let originY = 1
        
        let w = GridPrinter.cellWidth(for: grid)
        let h = GridPrinter.cellHeight(for: grid)
        
        let totalW = grid.size * w
        let totalH = grid.size * h
        
        for gy in 0..<grid.size {
            let y = gy * h + originY
            
            if grid.visibilities.left[gy] != 0 {
                putString(grid.visibilities.left[gy].description, x: originX - 2, y: y + h / 2)
            }
            
            if grid.visibilities.right[gy] != 0 {
                putString(grid.visibilities.right[gy].description, x: totalW + originX + 2, y: y + h / 2)
            }
            
            for gx in 0..<grid.size {
                let x = gx * w + originX
                
                putRect(x: x, y: y, w: w, h: h)
                
                // Fill cell contents
                switch grid.cellAt(x: gx, y: gy) {
                case .empty:
                    break
                case .hint(let set):
                    for (i, h) in set.sorted().enumerated() {
                        let _cx = x + 1 + (i * 2) % (w - 1)
                        let _cy = y + 1 + (i * 2) / (w - 1)
                        
                        putString(h.description, x: _cx, y: _cy)
                    }
                case .solved(let value):
                    putString(value.description, x: x + w / 2, y: y + h / 2)
                }
                
                if gy == 0 {
                    if grid.visibilities.top[gx] != 0 {
                        putString(grid.visibilities.top[gx].description, x: x + w / 2, y: originY - 1)
                    }
                    if grid.visibilities.bottom[gx] != 0 {
                        putString(grid.visibilities.bottom[gx].description, x: x + w / 2, y: totalH + originY + 1)
                    }
                }
            }
        }
        
        joinBoxLines()
        print()
    }
    
    static func printGrid(grid: Grid) {
        let printer = GridPrinter(bufferWidth: 80, bufferHeight: 35)
        printer.printGrid(grid: grid)
    }
}