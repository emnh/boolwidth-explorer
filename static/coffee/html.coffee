makeH = () ->
  html = {}
  tags =
    ["script", "div", "span", "p", "ol", "ul", "li", "a", "dl", "dt", "dd",
    "table", "th", "tr", "td", "colgroup", "col", "thead", "tbody",
    "h1", "h2", "h3", "h4", "h5",
    "label", "input", "button", "select", "option"]
  makeTagDef = (tag) ->
    html[tag] = (content, attrs = {}) ->
      attrs.html = content
      $("<" + tag + "/>", attrs)
  makeTagDef(tag) for tag in tags
  return html

window.emhHTML = makeH()
    
emhHTML.mat2table = (mat) ->
  tdf = (x, i, j) ->
    td = H.td(x)
    td.data('index', [i, j])
    td
  rowf = (row, i) -> H.tr([H.th(i + 1)].concat(tdf(x, i, j) for x, j in row))
  rows = (rowf(row, i) for row, i in mat)
  headers = H.tr([H.th()].concat((H.th(i) for i in [1..mat.cols])))
  rows = [headers].concat(rows)
  H.table(rows)

emhHTML.show = (h...) ->
  i.appendTo('#compute_results') for i in h

emhHTML.section = (title, h...) ->
  contentdiv = (H.div(h, {'class': 'content'}))
  atitle = H.a(title, {href: '#', 'class': 'title'})
  title.click () ->
    $(".section .content").css("visibility", "hidden")
    $(".title h1").css("font-size", "small")
    contentdiv.css("visibility", "visible")
    title.css("font-size", "large")
  H.show(H.div([atitle, contentdiv], { 'class': 'section' }))
  title.click
  #title.click()

emhHTML.u2table = (mat) ->
  trow = (row) ->
    r = (H.td(x) for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(H.td("[ from: [#{a}] [#{b}] ]"))
    r
  H.table(H.tr(trow(row)) for row in mat)

emhHTML.u2list = (mat) ->
  trow = (row) ->
    r = (x for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(" [ from: [#{a}] [#{b}] ]")
    r
  H.ul(H.li(trow(row)) for row in mat)

