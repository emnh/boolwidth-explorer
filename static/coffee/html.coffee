# TODO: deprecate this file and use
# https://github.com/emnh/test/blob/master/static/coffee/html.coffee instead

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

emhHTML = makeH()
window.emhHTML = emhHTML
    
emhHTML.mat2table = (mat) ->
  tdf = (x, i, j) ->
    td = emhHTML.td(x)
    td.data('index', [i, j])
    td
  rowf = (row, i) -> emhHTML.tr([emhHTML.th(i + 1)].concat(tdf(x, i, j) for x, j in row))
  if not mat.cols?
    throw "not valid matrix, missing cols"
  if not mat.rows?
    throw "not valid matrix, missing rows"
  rows = (rowf(row, i) for row, i in mat)
  headers = emhHTML.tr([emhHTML.th()].concat((emhHTML.th(i) for i in [1..mat.cols])))
  rows = [headers].concat(rows)
  emhHTML.table(rows)

emhHTML.show = (h...) ->
  i.appendTo('#compute_results') for i in h

emhHTML.section = (title, h...) ->
  contentdiv = (emhHTML.div(h, {'class': 'content'}))
  atitle = emhHTML.a(title, {href: '#', 'class': 'title'})
  title.click () ->
    $(".section .content").css("visibility", "hidden")
    $(".title h1").css("font-size", "small")
    contentdiv.css("visibility", "visible")
    title.css("font-size", "large")
  emhHTML.show(emhHTML.div([atitle, contentdiv], { 'class': 'section' }))
  title.click
  #title.click()

emhHTML.u2table = (mat) ->
  trow = (row) ->
    r = (emhHTML.td(x) for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(emhHTML.td("[ from: [#{a}] [#{b}] ]"))
    r
  emhHTML.table(emhHTML.tr(trow(row)) for row in mat)

emhHTML.u2list = (mat) ->
  trow = (row) ->
    r = (x for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(" [ from: [#{a}] [#{b}] ]")
    r
  emhHTML.ul(emhHTML.li(trow(row)) for row in mat)

