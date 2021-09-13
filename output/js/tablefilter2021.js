/* Written August 2021 by Joel Kalvesmaki 
   Adds Javascript functionality connecting a filter input to its table.
  
   Expected setup is one or more pairs of <input> and <table> items as below:
   <input type="text" id="filter_tableX" class="tableFilter" placeholder="filter..." />
   
  <table id="tableX">
  	 <thead>
  		<tr>
  		   <th>col</th>
  		   <th>col</th>
  		</tr>
  	 </thead>
  	 <tbody>
  		<tr>
  		   <td>...</td>
  		   <td>...</td>
  		</tr>
  		<!-- . . . -->
  	 </tbody>
  </table> */
  
  
document.querySelectorAll("input.tableFilter").forEach(filter => filter.addEventListener("keyup", filterFunction));

// Do the work...
function filterFunction(evt) {
	// Input: an event, presumed to be bound to an input element with an @id that
	// is "filter_" followed by the id of the table that it filters.
	// Output: the target table, with rows that do not match the text suppressed. 
	// The count of rows is bound to a div element placed after the input element,
	// specifying how many rows have been found. That note has the class filterNote
	// and the same id as the input element with "_note" appended. The table is 
	// presumed to be fully qualified, i.e., it has tbody and thead as a buffer between
	// table and the tr elements.

	value = this.value.toLowerCase();
	targetID = this.id.replace(/filter_/, "");
	noteID = this.id + "_note";
	targetTable = document.getElementById(targetID);
	targetTableRows = targetTable.querySelectorAll("tbody > tr");
	matchCount = 0;
	currentNote = document.getElementById(noteID);
	
	for(i = 0; i < targetTableRows.length; i++){
		thisTr = targetTableRows[i];
		thisTrVal = thisTr.textContent.toLowerCase();
		if (thisTrVal.indexOf(value) > -1) {
			thisTr.style.display = "";
			matchCount++;
		} else {
			thisTr.style.display = "none";
		}
	};
	newNote = document.createElement("div");
	newNote.id = noteID;
	newNote.classList.add("filterNote");
	newNote.innerText = "(" + matchCount + " of " + targetTableRows.length + ")";
	if (currentNote && currentNote !== "null") {
		currentNote.replaceWith(newNote);
	} else {
		this.insertAdjacentElement("afterend", newNote);
	};
}