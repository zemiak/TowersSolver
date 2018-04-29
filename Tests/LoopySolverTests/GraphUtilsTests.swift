import XCTest
import Geometry
import LoopySolver

class GraphUtilsTests: XCTestCase {
    func testSinglePathEdgesInGraphFromEdge() {
        // Create a graph that looks roughly like this:
        //  .__.
        //  !__!__.
        //  !
        //
        var graph = LoopyGrid()
        graph.addVertex(Vertex(x: 0, y: 0)) // 0
        graph.addVertex(Vertex(x: 1, y: 0)) // 1
        graph.addVertex(Vertex(x: 1, y: 1)) // 2
        graph.addVertex(Vertex(x: 1, y: 0)) // 3
        graph.addVertex(Vertex(x: 2, y: 1)) // 4
        graph.addVertex(Vertex(x: 0, y: 2)) // 5
        graph.createEdge(from: 0, to: 1)
        graph.createEdge(from: 1, to: 2)
        graph.createEdge(from: 2, to: 3)
        graph.createEdge(from: 3, to: 0)
        graph.createEdge(from: 2, to: 4)
        graph.createEdge(from: 3, to: 5)
        
        // Test the top-most horizontal edge
        let result1 = GraphUtils.singlePathEdges(in: graph, fromEdge: Edge(start: 0, end: 1))
        XCTAssertEqual(result1.count, 3)
        XCTAssert(result1.contains(Edge(start: 0, end: 1)))
        XCTAssert(result1.contains(Edge(start: 1, end: 2)))
        XCTAssert(result1.contains(Edge(start: 3, end: 0)))
        
        // Test the central horizontal edge
        let result2 = GraphUtils.singlePathEdges(in: graph, fromEdge: Edge(start: 2, end: 3))
        XCTAssertEqual(result2.count, 1)
        XCTAssert(result2.contains(Edge(start: 2, end: 3)))
    }
    
    func testSinglePathEdgesInGraphFromEdgeExcludingDisabledEdges() {
        // Create a graph that looks roughly like this:
        //  .__.
        //  !__!__.
        //  !  ^ this vertical edge is disabled.
        //
        var graph = LoopyGrid()
        graph.addVertex(Vertex(x: 0, y: 0)) // 0
        graph.addVertex(Vertex(x: 1, y: 0)) // 1
        graph.addVertex(Vertex(x: 1, y: 1)) // 2
        graph.addVertex(Vertex(x: 1, y: 0)) // 3
        graph.addVertex(Vertex(x: 2, y: 1)) // 4
        graph.addVertex(Vertex(x: 0, y: 2)) // 5
        graph.createEdge(from: 0, to: 1)
        graph.createEdge(from: 1, to: 2)
        graph.createEdge(from: 2, to: 3)
        graph.createEdge(from: 3, to: 0)
        graph.createEdge(from: 2, to: 4)
        graph.createEdge(from: 3, to: 5)
        graph.edges[1].state = .disabled
        
        // Test top-most vertical edge
        let result1 = GraphUtils.singlePathEdges(in: graph,
                                                 fromEdge: Edge(start: 0, end: 1),
                                                 excludeDisabled: true)
        XCTAssertEqual(result1.count, 2)
        XCTAssert(result1.contains(Edge(start: 0, end: 1)))
        XCTAssert(result1.contains(Edge(start: 3, end: 0)))
        
        let result2 = GraphUtils.singlePathEdges(in: graph,
                                                 fromEdge: Edge(start: 0, end: 1),
                                                 excludeDisabled: false)
        XCTAssertEqual(result2.count, 3)
        XCTAssert(result2.contains(Edge(start: 0, end: 1)))
        XCTAssert(result2.contains(Edge(start: 1, end: 2, state: .disabled)))
        XCTAssert(result2.contains(Edge(start: 3, end: 0)))
        
        // Test right-most horizontal edge
        let result3 = GraphUtils.singlePathEdges(in: graph,
                                                 fromEdge: Edge(start: 2, end: 4),
                                                 excludeDisabled: true)
        XCTAssertEqual(result3.count, 2)
        XCTAssert(result3.contains(Edge(start: 2, end: 4)))
        XCTAssert(result3.contains(Edge(start: 2, end: 3)))
        
        let result4 = GraphUtils.singlePathEdges(in: graph,
                                                 fromEdge: Edge(start: 2, end: 4),
                                                 excludeDisabled: false)
        XCTAssertEqual(result4.count, 1)
        XCTAssert(result3.contains(Edge(start: 2, end: 4)))
    }
    
    func testBugWithDuplicatedEdgeReporting() {
        // Tests a case where the algorithm would report the same edge twice:
        //
        // •══•  •   •
        // ║  Y
        // •  •XX•   •
        // ║     ║
        // •══•  •═══•
        //    ║      ║
        // •  •══•═══•
        //
        // Querying for the single path edges of the (marked) edge signaled with
        // 'XX' results in edge 'Y' (marked as well) being reported twice in the
        // results array.
        let gridGen = LoopySquareGrid(width: 3, height: 3)
        let controller = LoopyGridController(grid: gridGen.generate())
        controller.setAllEdges(state: .disabled)
        controller.setEdges(state: .marked, forFace: 0)
        controller.setEdges(state: .marked, forFace: 3)
        controller.setEdges(state: .marked, forFace: 4)
        controller.setEdges(state: .marked, forFace: 7)
        controller.setEdges(state: .marked, forFace: 8)
        controller.setEdge(state: .disabled, forFace: 0, edgeIndex: 2)
        controller.setEdge(state: .disabled, forFace: 3, edgeIndex: 1)
        controller.setEdge(state: .disabled, forFace: 4, edgeIndex: 2)
        controller.setEdge(state: .disabled, forFace: 7, edgeIndex: 1)
        let grid = controller.grid
        
        let result = GraphUtils.singlePathEdges(in: grid, fromEdge: grid.edges[6])
        let resultIds = result.map { grid.edgeId(forEdge: $0)! }.map { $0.value }.sorted()
        XCTAssertEqual(resultIds, [0, 1, 3, 6, 11, 12, 13, 16, 17, 21, 22, 23])
    }
}