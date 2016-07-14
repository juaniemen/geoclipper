/**
 * Created by juanfran on 29/06/16.
 */

$(document).ready(function(){

    $("#datepickerMonth").datepicker( {
        format: "mm-yyyy",
        startView: "months",
        minViewMode: "months"
    });

    $(".fileInput").filestyle({
        input: true,
        placeholder: "No se ha cargado ningún archivo",
        buttonText: "Cargar archivo"
    })

    


});
