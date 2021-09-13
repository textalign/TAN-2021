// script below adapted from https://www.w3schools.com/howto/tryit.asp?filename=tryhow_js_sort_table_desc
function sortTable(n, t) {
   var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
   table = document.getElementById(t);
   switching = true;
   dir = "asc";
   while (switching) {
      switching = false;
      rows = table.querySelectorAll("tbody tr:not(.score)");
      for (i = 0; i < (rows.length - 1);
      i++) {
         shouldSwitch = false;
         x = rows[i].getElementsByTagName("TD")[n];
         y = rows[i + 1].getElementsByTagName("TD")[n];
         xLc = x.innerText.toLowerCase();
         yLc = y.innerText.toLowerCase();
         if (dir == "asc") {
            if (xLc > yLc) {
               shouldSwitch = true;
               break;
            }
         } else if (dir == "desc") {
            if (xLc < yLc) {
               shouldSwitch = true;
               break;
            }
         }
      }
      if (shouldSwitch) {
         rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
         switching = true;
         switchcount++;
      } else {
         if (switchcount == 0 && dir == "asc") {
            dir = "desc";
            switching = true;
         }
      }
   }
}
function sortTableByNumber(n, t) {
   var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
   table = document.getElementById(t);
   switching = true;
   dir = "asc";
   while (switching) {
      switching = false;
      rows = table.querySelectorAll("tbody tr:not(.score)");
      for (i = 0; i < (rows.length - 1);
      i++) {
         shouldSwitch = false;
         x = rows[i].getElementsByTagName("TD")[n];
         y = rows[i + 1].getElementsByTagName("TD")[n];
         xLc = x.innerText;
         yLc = y.innerText;
         if (dir == "asc") {
            if (Number(xLc) > Number(yLc)) {
               shouldSwitch = true;
               break;
            }
         } else if (dir == "desc") {
            if (Number(xLc) < Number(yLc)) {
               shouldSwitch = true;
               break;
            }
         }
      }
      if (shouldSwitch) {
         rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
         switching = true;
         switchcount++;
      } else {
         if (switchcount == 0 && dir == "asc") {
            dir = "desc";
            switching = true;
         }
      }
   }
}

function toggleNext(elem) {
   elem.nextElementSibling.classList.toggle("hide");
}