#include "symbol_info.h"
/** constructor
 * @param name name of the symbol
 * @param identifier the type of symbol 
 * @param value the current value of the symbol (it is applicable to only variables)
*/
symbol_info::symbol_info(string name, string identifier) {
    this->name = name;
    this->identifier = identifier;
    next = NULL;
}

// copy constructor
symbol_info::symbol_info(const symbol_info& that) {
    this->name = new char;
    this->name = that.name;
    this->identifier = that.identifier;
    this->next = that.next;
}

// destructor
symbol_info::~symbol_info() {
    // patience
    // don't do anything stupid
 }

// dictionary getter setter

/** function to set the next node of this node
 * @param next the node that is next to this node
 */
void symbol_info::set_next(symbol_info* next) { this->next = next; }

symbol_info* symbol_info::get_next() { return this->next; }

string symbol_info::get_name() { return this->name; }

string symbol_info::get_identifier() { return this->identifier; }


// function to print the node
void symbol_info::print_node() {
    cout<<"<" << (this->name) << " : " << this->identifier << ">";
}

// finction to print the node in a file passed to the function
void symbol_info::print_node(FILE *file) {
    fprintf(file, "<%s : %s>", this->name.c_str(), this->identifier.c_str());
}