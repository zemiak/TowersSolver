public final class SolverStepMetadata {
    private var metadata: [String: Any] = [:]
    
    public subscript<T>(_ name: String, type type: T.Type) -> T? {
        get {
            return metadata[name] as? T
        }
        set {
             metadata[name] = newValue
        }
    }
    
    public init() {
        
    }
    
    public func storeVertexState(_ vertex: Int, from grid: LoopyGrid) {
        metadata["_vertex\(vertex)"] = grid.edgesSharing(vertexIndex: vertex).map(grid.edgeWithId)
    }
    
    public func matchesStoredVertexState(_ vertex: Int, from grid: LoopyGrid) -> Bool {
        guard let edges = self["_vertex\(vertex)", type: [Edge].self] else {
            return false
        }
        
        let newEdges = grid.edgesSharing(vertexIndex: vertex)
        for i in 0..<newEdges.count {
            if grid.edges[newEdges[i].value] != edges[i] {
                return false
            }
        }
        
        return true
    }
    
    public func storeFaceState(_ faceId: Face.Id, from grid: LoopyGrid) {
        metadata["_face\(faceId.value)"] = grid.edges(forFace: faceId).map(grid.edgeWithId)
    }
    
    public func matchesStoredFaceState(_ faceId: Face.Id, from grid: LoopyGrid) -> Bool {
        return self["_face\(faceId.value)", type: [Edge].self] == grid.edges(forFace: faceId).map(grid.edgeWithId)
    }
    
    public func markFace(_ faceId: Face.Id) {
        metadata["_individualFace\(faceId.value)"] = true
    }
    
    public func isFaceMarked(_ faceId: Face.Id) -> Bool {
        return self["_individualFace\(faceId.value)", type: Bool.self] == true
    }
    
    /// Marks a global flag to this metadata that stipulates an overall action
    /// was already taken.
    public func markFlag() {
        metadata["_flag"] = true
    }
    
    /// Returns `true` if `markFlag()` has been invoked previously in this metadata
    /// instance.
    public func isFlagMarked() -> Bool {
        return self["_flag", type: Bool.self] == true
    }
}