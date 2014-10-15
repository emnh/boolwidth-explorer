console_main = () ->
  $("#console_input").keypress (e) ->
    if (e.keyCode == 13)
      statement = $("#console_input")
      console.log(statement)
      result = CoffeeScript.compile(statement)
      $('#console_output').append(result)
$(console_main)