#if os(macOS)
    import Foundation
#else
    import Glibc
#endif

import TowersSolver

do {
    print("See solving steps interactively? (y/n)")
    let interactive = (readLine()?.lowercased().first?.description ?? "n") == "y"
    var descriptive = false
    
    if interactive {
        print("Use descriptive solving steps (i.e. show internal logic of solver)? (y/n)")
        descriptive = (readLine()?.lowercased().first?.description ?? "n") == "y"
    }
    
    var grid = Grid(size: 6)

    /* // 1
    grid.visibilities.top = [2, 2, 3, 2, 4, 1]
    grid.visibilities.left = [4, 1, 2, 3, 2, 2]
    grid.visibilities.right = [1, 4, 3, 2, 2, 2]
    grid.visibilities.bottom = [3, 4, 1, 2, 2, 2]
    grid.markSolved(x: 4, y: 0, height: 1)
    grid.markSolved(x: 3, y: 1, height: 1)
    grid.markSolved(x: 0, y: 2, height: 2)
    grid.markSolved(x: 2, y: 3, height: 3)
    grid.markSolved(x: 3, y: 4, height: 6)
    */

    /* // 2
    grid.visibilities.top = [2, 1, 3, 3, 2, 4]
    grid.visibilities.left = [2, 1, 3, 3, 3, 2]
    grid.visibilities.right = [3, 3, 2, 1, 3, 2]
    grid.visibilities.bottom = [2, 3, 2, 2, 1, 2]
    grid.markSolved(x: 0, y: 0, height: 2)
    grid.markSolved(x: 3, y: 1, height: 3)
    grid.markSolved(x: 4, y: 3, height: 1)
    grid.markSolved(x: 3, y: 4, height: 6)
    grid.markSolved(x: 5, y: 4, height: 1)
    */

    /* // 3
    grid.visibilities.top = [4, 2, 4, 3, 2, 1]
    grid.visibilities.left = [4, 2, 2, 1, 3, 2]
    grid.visibilities.right = [1, 2, 2, 3, 2, 4]
    grid.visibilities.bottom = [3, 3, 1, 2, 2, 5]
    grid.markSolved(x: 1, y: 0, height: 4)
    grid.markSolved(x: 3, y: 2, height: 6)
    grid.markSolved(x: 5, y: 2, height: 2)
    grid.markSolved(x: 3, y: 3, height: 3)
    grid.markSolved(x: 0, y: 4, height: 4)
    */

    // 4
    grid.visibilities.top = [3, 2, 4, 1, 2, 2]
    grid.visibilities.left = [3, 2, 6, 1, 2, 3]
    grid.visibilities.right = [2, 2, 1, 3, 4, 2]
    grid.visibilities.bottom = [3, 2, 1, 4, 4, 2]
    grid.markSolved(x: 0, y: 0, height: 4)
    grid.markSolved(x: 4, y: 0, height: 1)
    
    let solver = Solver(grid: grid)
    solver.interactive = interactive
    solver.descriptive = descriptive
    
    solver.gridPrinter.printGrid(grid: solver.grid)
    
    let start = clock()
    
    solver.solve()

    let duration = clock() - start
    
    print("")
    print("After solve:")
    print("")
    
    GridPrinter.printGrid(grid: solver.grid)
    
    let msec = Float(duration) / Float(CLOCKS_PER_SEC)
    
    print("Total time: \(String(format: "%.2f", msec))s")
    print("Total backtracked guess(es): \(solver.totalGuesses)")
}
