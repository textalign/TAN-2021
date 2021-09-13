/* JavaScript routines for diff files */

$(".last-picker").click(function () {
   /*thisWitId = $(this).parent().children(".label").text();*/
   thisWitId = $(this).parents("tr").first().attr("class").match(/a-w-\S+|e-[ab]/g)[0];
   thisLocalRoot = $(this).parents("table.e-stats").parents("td, body").first();
   thisLocalRoot.find(".a-last").removeClass("a-last");
   console.log("Witness id: ", thisWitId);
   $(this).addClass("a-last");
   thisLocalRoot.find(".e-u." + thisWitId).addClass("a-last");
   thisLocalRoot.find("div.e-diff div." + thisWitId).addClass("a-last");
});
$(".other-picker").click(function () {
   thisWitId = $(this).parents("tr").first().attr("class").match(/a-w-\S+|e-[ab]/g)[0];
   thisLocalRoot = $(this).parents("table.e-stats").parents("td, body").first();
   thisLocalRoot.find(".a-other").removeClass("a-other");
   console.log("Witness id: ", thisWitId);
   $(this).addClass("a-other");
   thisLocalRoot.find(".e-u." + thisWitId).addClass("a-other");
   thisLocalRoot.find("div.e-diff div." + thisWitId).addClass("a-other");
});
$("table.e-stats .switch").click(function () {
   /* This function turns witnesses/readings on and off */
   $(this).children().toggle();
   $(this).parents("tr").first().toggleClass('suppressed');
   var arOn =[];
   $(this).parents("table.e-stats").find("tbody > tr:not(.suppressed):not(.averages):not(.a-diff):not(.a-collation)").each(function () {
      thisAttrClass = $(this).attr("class").match(/a-w-\S+|e-[ab]/g)[0];
      console.log("this attr class:", thisAttrClass);
      arOn.push(thisAttrClass);
   });
   console.log("Witnesses to show: ", arOn, arOn.length);
   /* ("div.e-u, div.e-a, div.e-b") */
   $(this).parents("table.e-stats").parents("td, body").first().find("div.e-u, div.e-a, div.e-b, div.siglum").each(function () {
      thisAttrClass = $(this).attr("class");
      theseClasses = thisAttrClass.match(/a-w-\S+|e-[ab]/g);
      commonWitnesses = arOn.filter(value => theseClasses.includes(value));
      console.log("These witnesses: ", theseClasses, theseClasses.length);
      console.log("Witnesses that must be shown: ", commonWitnesses);
      if (commonWitnesses.length > 0) {
         $(this).removeClass("hide");
      } else {
         $(this).addClass("hide");
      };
      
   });
});
/*$(".label").click(function() {
   $(this).nextAll("div, table").toggle("fast");
});*/