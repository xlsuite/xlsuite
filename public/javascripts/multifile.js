/**
 * Convert a single file-input element into a 'multiple' input list
 *
 * Usage:
 *
 *   1. Create a file input element (no name)
 *      eg. <input type="file" id="first_file_element">
 *
 *   2. Create a DIV for the output to be written to
 *      eg. <div id="files_list"></div>
 *
 *   3. Instantiate a MultiSelector object, passing in the DIV and an (optional) maximum number of files
 *      eg. var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 3 );
 *
 *   4. Add the first element
 *      eg. multi_selector.addElement( document.getElementById( 'first_file_element' ) );
 *
 *   5. That's it.
 *
 *   You might (will) want to play around with the addListRow() method to make the output prettier.
 *
 *   You might also want to change the line 
 *       element.name = 'file_' + this.count;
 *   ...to a naming convention that makes more sense to you.
 * 
 * Licence:
 *   Use this however/wherever you like, just don't blame me if it breaks anything.
 *
 * Credit:
 *   If you're nice, you'll leave this bit:
 *  
 *   Class by Stickman -- http://www.the-stickman.com
 *      with thanks to:
 *      [for Safari fixes]
 *         Luis Torrefranca -- http://www.law.pitt.edu
 *         and
 *         Shawn Parker & John Pennypacker -- http://www.fuzzycoconut.com
 *      [for duplicate name bug]
 *         'neal'
 *
 * XLsuite additions (2007-11):
 *   - added options parameter to constructor
 *   - defaults follow Rails convention
 *
 * Available options:
 *   max:   The maximum number of items to allow
 *   name:  The name to set on the generated file elements
 *   id:    A function that generates the next id.  Must
 *          accept a numeric argument and return a String.
 */
function MultiSelector( list_target, options ){
  this.options = options || {};
  if (!this.options.name) this.options.name = "file[]";
  if (!this.options.id) {
    this.options.id = function(id) {return "file_" + id;}
  }

  // Where to write the list
  this.list_target = list_target;

  // How many elements?
  this.count = 0;

  // How many elements?
  this.id = 0;

  // Is there a maximum?
  if( !this.options.max ){
    this.options.max = -1;
  };

  /**
   * Add a new file input element
   */
  this.addElement = function( element ){
    // Make sure it's a file input element
    if( !(element.tagName == 'INPUT' && element.type == 'file') ) {
      throw "Not a INPUT[type=file] element";
    }

    element.id = this.options.id(this.id++);
    element.name = this.options.name;
    element.multi_selector = this;
    element.observe("change", this.addNext);

    // If we've reached maximum number, disable input element
    if( this.options.max != -1 && this.count >= this.options.max ){
      element.disabled = true;
    };

    // File element counter
    this.count++;

    // Most recent element
    this.current_element = element;
  };

  this.addNext = function() {
    // New file input
    var new_element = document.createElement( 'input' );
    new_element.type = 'file';

    // Add new element
    this.parentNode.insertBefore( new_element, this );

    // Apply 'update' to element
    this.multi_selector.addElement( new_element );

    // Update list
    this.multi_selector.addListRow( this );

    // Hide this: we can't use display:none because Safari doesn't like it
    this.style.position = 'absolute';
    this.style.left = '-1000px';

  }

  /**
   * The template object
   */
  this.template = new Template(this.options.templateText);

  /**
   * Add a new row to the list of files
   */
  this.addListRow = function( element ){
    var html = this.template.evaluate({id: element.id + "_row", title: $F(element)});
    new Insertion.Bottom(this.list_target, html);
    new Effect.Highlight(element.id + "_row");
  };
};
