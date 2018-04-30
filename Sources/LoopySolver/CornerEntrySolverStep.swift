/// A solver step that deals with loopy lines that touch a face in a corner in
/// such a way that the line has to traverse through the face, marking a minimal
/// number of edges around the face.
///
/// Ex: On the following field, the top-right marked edge has to pass through the
/// 1-hinted face to be able to continue. Since we know that it will have to cross
/// the edges of the face, we know the left edge of the cell cannot be marked
/// (since it would exceed the requiremet for the cell), and the right and bottom
/// edges of the face also cannot be marked, since it would require marking the
/// two edges to make the corner, which would exceed the requirement, as well.
///
///     . _ . _ .
///     ! _ ! _ ║
///     ! _ ! 1 !
///
public class CornerEntrySolverStep: SolverStep {
    public func apply(to field: LoopyField) -> LoopyField {
        let solver = InternalSolver(field: field)
        solver.apply()
        return solver.field
    }
}

private class InternalSolver {
    var controller: LoopyFieldController
    
    var field: LoopyField {
        return controller.field
    }
    
    init(field: LoopyField) {
        controller = LoopyFieldController(field: field)
    }
    
    func apply() {
        for i in 0..<field.vertices.count {
            applyToVertex(i)
        }
    }
    
    func applyToVertex(_ vertexIndex: Int) {
        let edgeIds = field.edgesSharing(vertexIndex: vertexIndex)
        let edges = edgeIds.edges(in: field)
        
        let marked = edges.filter { $0.state == .marked }
        let normal = edges.filter { $0.state == .normal }
        
        // Can only do work on loose ends of a loopy line (a vertex with a single
        // marked edge)
        guard marked.count == 1 else {
            return
        }
        
        // Find the face that all path candidate edges share
        let allFaces = normal.map { Set(field.facesSharing(edge: $0)) }
        if allFaces.count == 0 {
            return
        }
        
        let commonFaces = allFaces.reduce(allFaces[0]) { result, faces in
            result.intersection(faces)
        }
        
        // Expect a single common face to work with
        if commonFaces.count != 1 {
            return
        }
        
        let faceId = commonFaces.first!
        
        applyToFace(faceId, vertex: vertexIndex)
    }
    
    func applyToFace(_ faceId: Face.Id, vertex: Int) {
        let face = field.faceWithId(faceId)
        
        // Requires hint!
        guard let hint = face.hint else {
            return
        }
        
        let allEdges = face
            .localToGlobalEdges
            .edges(in: field)
        
        let edges = allEdges.filter { $0.sharesVertex(vertex) }
        
        let normalEdges = edges.filter { $0.state == .normal }
        
        if normalEdges.isEmpty {
            return
        }
        
        var leastCount = Int.max
        
        for edge in normalEdges {
            let edgesPath =
                GraphUtils
                    .singlePathEdges(in: field, fromEdge: edge)
                    .filter { field.faceContainsEdge(face: face, edge: $0) }
            
            let edgeCount = edgesPath.count
            leastCount = min(edgeCount, leastCount)
            
            // If we follow this path, we'll end up with more edges marked than
            // the face requirement; disable this path, then
            if edgeCount > hint {
                controller.setEdges(state: .disabled, forEdges: edgesPath)
            }
        }
        
        if leastCount >= hint {
            // Disable all edges not sharing the common vertex
            let toDisable = allEdges.filter { !$0.sharesVertex(vertex) }
            
            controller.setEdges(state: .disabled, forEdges: toDisable)
        }
    }
}
