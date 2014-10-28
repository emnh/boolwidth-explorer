window.consoleMain = () ->
  $("#console_input").keypress (e) ->
    if (e.keyCode == 13)
      statement = $("#console_input").val()
      console.log(statement)
      code = CoffeeScript.compile(statement)
      code = code[14...-17]
      console.log("code", code)
      result = eval.call(window, code)
      console.log("result", result)
      #if not result?
      #  result = "undefined"
      dresult = $("<div/>")
      dresult.append(result)
      $("#console_output").append(dresult)