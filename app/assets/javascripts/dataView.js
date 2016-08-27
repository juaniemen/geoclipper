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

    // Crea el balloon a raíz del atributo title del elemento html
    $("#epsg-help").balloon( {css: {
        fontSize: "1.2rem",
        minWidth: ".7rem",
        padding: ".2rem .5rem",
        border: "1px solid rgba(212, 212, 212, .4)",
        borderRadius: "3px",
        boxShadow: "2px 2px 4px #555",
        color: "#eee",
        backgroundColor: "#111",
        opacity: "0.85",
        zIndex: "32767",
        textAlign: "left"
    }});


});
