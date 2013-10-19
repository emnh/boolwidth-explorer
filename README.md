A project to explore boolean width using a graphical user interface.

<div id="todo">
    <ul>
        <li>TODO</li>
        <ul>
        <li>clean separation of graph/tree data objects with change notifications</li>
        <li>tag or display max cutbool for tree</li>
        <li>drag to rearrange tree</li>
            <ul>
                <li>fix bugs (not possible to exchange child with parent)</li>
            </ul>
        <li>graph changes preserve tree as much as possible</li>
        <li>graph and tree simple print literals</li>
        <li>click to fix cutbool view and enable node swaps</li>
        <li>add help text for keys and mouse actions</li>
        <li>switch between circle pack and regular tree</li>
        <li>editable graph text</li>
        <li>all selectors in css and code target parent svg in case of multiple graphs</li>
        </ul>
    </ul>
</div>

- visualize cutbool algorithm
  - Make debugger to step over Data, not over Code. Data centric view and control at least.
  - JS Parser in JS: htps://github.com/ariya/esprima
  - JS debugger in JS: https://github.com/int3/metajs, http://int3.github.io/metajs/#
  - JS Interactive learning tool, Choc: https://github.com/fullstackio/choc
  - Inspiration from JS webgl tracer, but it's not free: https://trace.gl/

- bugfix drag n drop in tree
  - replace with simple tree like
    - http://www.jstree.com/documentation/dnd#
    - https://github.com/mar10/fancytree
    - http://mbraak.github.io/jqTree/
  - lazy tree with async computation of cutbool

- upload graph text files to separate (for speed) github repository
 - enumerate using github API
   - https://api.github.com/repos/emnh/boolwidth/git/refs for sha
   - https://api.github.com/repos/emnh/boolwidth/git/trees/f4778315107f4b69ec9866233dedfbe97604ea68 for tree and so on

- store graphs and output in neo4j
  - load/import standard graph from github in tree view
  - neo4j makes it easy to query and have multiple decompositions on same graph
  - makes it easy to query graphs and decompositions using cypher

- dump boolwidth java algorithm runs to json and create d3 visualization with time slider or port/compile to JavaScript and use choc
  - cutbool with choc will be simplest
  - full heuristic will require more work to port, better json it as first step
  - rewrite algorithm or modularize Java code with an AJAX interface to control/step run from JS
