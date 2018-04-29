import Commons

/// Represents an edge between two vertices.
///
/// Edges are bidirectional and always start from a lower vertex index pointing
/// to a higher vertex index.
public struct Edge: Hashable {
    public typealias Id = Key<Edge, Int>
    
    /// Starting vertex index for this edge
    public let start: Int
    /// Ending vertex index for this edge
    public let end: Int
    
    public var state: State
    
    /// Returns `true` if `state != .disabled`
    public var isEnabled: Bool {
        return state != .disabled
    }
    
    public var hashValue: Int {
        return start.hashValue + end.hashValue
    }
    
    public init(start: Int, end: Int) {
        self.start = min(start, end)
        self.end = max(start, end)
        state = .normal
    }
    
    /// Returns `true` if this edge shares a vertex index with a given edge.
    public func sharesVertex(with edge: Edge) -> Bool {
        return start == edge.start || end == edge.start
            || start == edge.end || end == edge.end
    }
    
    public static func ==(lhs: Edge, rhs: Edge) -> Bool {
        if lhs.start == rhs.start && lhs.end == rhs.end {
            return true
        }
        
        return lhs.start == rhs.end && lhs.end == rhs.start
    }
    
    /// Enumeration of possible states for an edge.
    ///
    /// - normal: Edge is not disabled nor marked as part of the solution.
    /// - marked: Edge is marked as part of the solution.
    /// - disabled: Edge is disabled. Used for marking an edge as definitely not
    /// part of the solution.
    public enum State {
        case normal
        case marked
        case disabled
    }
}

public extension Key where T == Edge, U == Int {
    /// Returns the edge represented by this edge ID on a given grid
    public func edge(in grid: LoopyGrid) -> Edge {
        return grid.edges[value]
    }
}

public extension Sequence where Element == Edge.Id {
    /// Returns the actual edges represented by this list of edge IDs on a given
    /// grid.
    public func edges(in grid: LoopyGrid) -> [Edge] {
        return map { $0.edge(in: grid) }
    }
}

public extension Sequence where Element == Edge {
    /// Returns `true` iff each edge is directly connected to the next, forming
    /// a singular chain.
    public var isUniqueSegment: Bool {
        let array = Array(self)
        if array.count == 1 {
            return true
        }
        
        // Take a list of all edges, pop the first edge, and check the remaining
        // list to see if an edge from the sequence is connected to it: if it is,
        // push that edge to the sequence edges and repeat for all edges until
        // either the list is empty or none of the remaining items are connected
        // to any of the edges in the sequence
        var rem = Array(array.dropFirst())
        var seq = [array[0]]
        
        while rem.count > 0 {
            for i in 0..<rem.count {
                let next = rem[i]
                
                if seq.contains(where: { $0.sharesVertex(with: next) }) {
                    seq.append(next)
                    rem.remove(at: i)
                    break
                } else if i == rem.count - 1 {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Returns `true` iff all edges in this sequence are connected, and they form
    /// a loop (i.e. all edges connected start-to-end).
    public var isLoop: Bool {
        let array = Array(self)
        
        // Minimal number of edges connected to form a loop must be 3.
        if array.count < 3 {
            return false
        }
        
        // Take the list of edges, pick a single vertex, and traverse the edges
        // using a vertex hopper which hops across from edge to edge using the
        // vertices as pivots.
        // At the end, the first edge picked must be the edge the vertex hopper
        // returns to.
        var remaining = Array(array.dropFirst())
        var collected = [array[0]]
        var current: Edge { return collected[collected.count - 1] }
        
        while remaining.count > 0 {
            for (i, edge) in remaining.enumerated() {
                if current.sharesVertex(with: edge) {
                    collected.append(edge)
                    remaining.remove(at: i)
                    break
                } else if i == remaining.count - 1 {
                    return false
                }
            }
        }
        
        return collected[0].sharesVertex(with: collected.last!)
    }
}