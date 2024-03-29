%{
#include <bits/stdc++.h>
#include "../symbol_table/symbol_table.h"
#include "../util/util.h"
#include "../assembly/assembly.h"
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int line_count;
extern int error_count;
int temp_count = 0;
int label_count = 0;


vector<pair<string, int>> global_vars;

FILE *fp;
FILE *log_out;
FILE *error_out;
FILE *asm_out;

string current_function_ret_type = "UNDEFINED";
string current_function_name = "UNDEFINED";


// asm variables
int func_var_count = 0;

symbol_table table(7);


void yyerror(char *s)
{
	//write your code
	error_count++;
	fprintf(log_out, "Error at line %d: %s\n\n", line_count, s);
	fprintf(error_out, "Error at line no:%d  %s\n\n", line_count, s);
}


%}

%union {
	symbol_info* info;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token COMMA SEMICOLON LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD NOT ASSIGNOP INCOP DECOP
%token <info> ADDOP MULOP RELOP LOGICOP CONST_INT CONST_CHAR CONST_FLOAT ID STRING

%type <info> arguments logic_expression argument_list factor variable expression unary_expression 
%type <info> program unit term simple_expression rel_expression expression_statement statement statements
%type <info> var_declaration compound_statement declaration_list type_specifier parameter_list func_definition func_declaration
%type <info> if_block_marker

%nonassoc LOWER_THAN_ELSE LOWER_THAN_ERROR
%nonassoc ELSE error

%%

start : program {
		fprintf(log_out, "start : program\n\n");
	}
	;

program : program unit {
		string argument_name = $1->get_name() + "\n" + $2->get_name();
		string argument_identifier = "program";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - program : program unit\n\n%s\n\n", line_count, $$->get_name().c_str());

	}
	| unit {
		// cout<<"unit found"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - program : unit\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	;
	
unit : var_declaration {
		// cout<<"var_declaration found"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - unit : var_declaration\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
    | func_declaration {
		// cout<<"func_declaration found"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - unit : func_declaration\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
    | func_definition {
		// cout<<"func_definition found"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - unit : func_definition\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
		// cout<<"type_specifier id lparen parameter_list rparen semicolon found"<<endl;
		string func_ret_type = $1->get_identifier();
		string func_name = $2->get_name();

		vector<param> func_param_list = get_param_type_list($4->get_name());
		symbol_info* temp_func = table.search(func_name);
		if(temp_func != NULL) {
			// ! function already declared and cannot be redeclared
			error_count++;
			fprintf(log_out, "Error at line no:%d Function %s already declared\n\n", line_count, func_name.c_str());
			fprintf(error_out, "Error at line no:%d Function %s already declared\n\n", line_count, func_name.c_str());
		}
		else {
			// okay function not declared and can be declared
			symbol_info *temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
			// set the definition flag to false
			temp_func->set_defined(false);
			table.insert(temp_func);
		}

		string argument_name = $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ");";
		string argument_identifier = "func_declaration";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON {
		// cout<<"type_specifier id lparen rparen semicolon found"<<endl;
		string func_ret_type = $1->get_identifier();
		string func_name = $2->get_name();

		vector<param> func_param_list;
		symbol_info* temp_func = table.search(func_name);
		if(temp_func != NULL) {
			// ! function already declared and cannot be redeclared
			error_count++;
			fprintf(log_out, "Error at line no:%d Function %s already declared\n\n", line_count, func_name.c_str());
			fprintf(error_out, "Error at line no:%d Function %s already declared\n\n", line_count, func_name.c_str());
		}
		else {
			// okay function not declared and can be declared
			symbol_info *temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
			// set the definition flag to false
			temp_func->set_defined(false);
			table.insert(temp_func);
		}

		string argument_name = $1->get_name() + " " + $2->get_name() + "();";
		string argument_identifier = "func_declaration";
		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
	// this is called after finding the ) in the function declaration and before the {
		string func_ret_type = $1->get_identifier();
		string func_name = $2->get_name();
		vector<param> func_param_list = get_param_list($4->get_name());
		current_function_ret_type = func_ret_type;
		current_function_name = func_name;

		symbol_info* temp_func = table.search(func_name);
		if(temp_func != NULL){
			// function already declared
			if(temp_func->is_function()){
				// function is declared as a function
				if(temp_func->is_defined()){
					// ! function alredy defined cannot be defined again
					error_count++;
					fprintf(log_out, "Error at line no:%d Function \'%s\' already defined\n\n", line_count, func_name.c_str());
					fprintf(error_out, "Error at line no:%d Function \'%s\' already defined\n\n", line_count, func_name.c_str());
				} else {
					// okay function is declared as a function but not defined 
					bool definition_matched = true;
					int declared_param_count = temp_func->get_param_count();
					int definition_param_count = func_param_list.size();
					// check if the function definition has the same number of parameters
					if(declared_param_count != definition_param_count){
						// ! function definition has different number of parameters
						error_count++;
						fprintf(log_out, "Error at line no:%d Function \'%s\' has different number of parameters\n\n", line_count, func_name.c_str());
						fprintf(error_out, "Error at line no:%d Function \'%s\' has different number of parameters\n\n", line_count, func_name.c_str());
						definition_matched = false;
					} else {
						vector<param> declared_param_list = temp_func->get_params();
						for(int i = 0; i < declared_param_count; i++){
							if(declared_param_list[i].get_type() != func_param_list[i].get_type()){
								// ! function definition has different parameter types
								error_count++;
								fprintf(log_out, "Error at line no:%d Function \'%s\' has different parameter types\n\n", line_count, func_name.c_str());
								fprintf(error_out, "Error at line no:%d Function \'%s\' has different parameter types\n\n", line_count, func_name.c_str());
								definition_matched = false;
							}
							if(func_param_list[i].get_name()==""){
								// ! function definition has no parameter names
								error_count++;
								fprintf(log_out, "Error at line no:%d Function \'%s\' has no parameter names\n\n", line_count, func_name.c_str());
								fprintf(error_out, "Error at line no:%d Function \'%s\' has no parameter names\n\n", line_count, func_name.c_str());
							}
							
						}
					}
					if(func_ret_type != temp_func->get_identifier()){
						// ! function definition has different return type
						error_count++;
						fprintf(log_out, "Error at line no:%d Function \'%s\' has different return type\n\n", line_count, func_name.c_str());
						fprintf(error_out, "Error at line no:%d Function \'%s\' has different return type\n\n", line_count, func_name.c_str());
						definition_matched = false;
					}
					// if the function definition matches the declaration then 
					// remove the function from the symbol table and add it again with the definition
					if(definition_matched){
						table.remove(func_name);
						temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
						table.insert(temp_func);
					}
					// set the function as defined
					temp_func->set_defined(true);

					// enter to the function scope
					table.create_scope();
					// add the parameters to the symbol table
					for(int i = 0; i < func_param_list.size(); i++){
						string param_name = func_param_list[i].get_name();
						string param_type = func_param_list[i].get_type();
						symbol_info* temp_param = new symbol_info(param_name, param_type);
						int offset = func_param_list.size() - i + 1;
						temp_param->set_offset(offset*2);
						bool result = table.insert(temp_param);

						if(!result){
							// ! function parameter already declared
							error_count++;
							fprintf(log_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
							fprintf(error_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
						}
					}

					// declare the function
					declare_procedure(asm_out, current_function_name);
				}
			} else {
				// ! function is not declared as a function but is already declared
				// we will enter scope no matter what and treat this as a function
				table.create_scope();
				// add the parameters to the symbol table
				for(int i = 0; i < func_param_list.size(); i++){
					string param_name = func_param_list[i].get_name();
					string param_type = func_param_list[i].get_type();
					if(param_name==""){
						// ! function parameter has no name
						error_count++;
						fprintf(log_out, "Error at line no:%d Function parameter has no name\n\n", line_count);
						fprintf(error_out, "Error at line no:%d Function parameter has no name\n\n", line_count);
					}
					bool result = table.insert(new symbol_info(param_name, param_type));

					if(!result){
						// ! function parameter already declared
						error_count++;
						fprintf(log_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
						fprintf(error_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
					}
				}
				error_count++;
				fprintf(log_out, "Error at line no:%d Function \'%s\' already declared but not as Function\n\n", line_count, func_name.c_str());
				fprintf(error_out, "Error at line no:%d Function \'%s\' already declared but not as Function\n\n", line_count, func_name.c_str());
			}
		} else {
			// okay function is not declared
			symbol_info* temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
			temp_func->set_defined(true);
			table.insert(temp_func);
			// enter to the function scope
			table.create_scope();
			// add the parameters to the symbol table
			for(int i = 0; i < func_param_list.size(); i++){
				string param_name = func_param_list[i].get_name();
				string param_type = func_param_list[i].get_type();
				if(param_name==""){
					// ! function parameter has no name
					error_count++;
					fprintf(log_out, "Error at line no:%d Function parameter has no name\n\n", line_count);
					fprintf(error_out, "Error at line no:%d Function parameter has no name\n\n", line_count);
				}
				symbol_info* temp_param = new symbol_info(param_name, param_type);
				int offset = func_param_list.size() - i + 1;
				temp_param->set_offset(offset*2);
				bool result = table.insert(temp_param);

				if(!result){
					// ! function parameter already declared
					error_count++;
					fprintf(log_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
					fprintf(error_out, "Error at line no:%d Function parameter \'%s\' already declared\n\n", line_count, param_name.c_str());
				}
			}

			// declare the function
			declare_procedure(asm_out, current_function_name);
		}

	} compound_statement {
		string argument_name = $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")" + $7->get_name();
		string argument_identifier = "function_definition";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - function definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n%s\n\n", line_count, argument_name.c_str());

		func_var_count = 0;
		// asm code for function definition
		// call finish proc
		symbol_info* temp_func = table.search(current_function_name);
		terminate_proc(asm_out, current_function_name, current_function_ret_type, temp_func->get_param_count());

		string code = "\t" + current_function_name + " ENDP";
		print_asm_to_file(asm_out, code);

	}
	| type_specifier ID LPAREN RPAREN {
		string func_ret_type = $1->get_identifier();
		string func_name = $2->get_name();
		vector<param> func_param_list;
		current_function_ret_type = func_ret_type;
		current_function_name = func_name;

		symbol_info* temp_func = table.search(func_name);
		if(temp_func != NULL){
			// function is already declared
			if(temp_func->is_function()){
				// function is already declared as a function
				if(temp_func->is_defined()){
					// ! function is already defined and cannot be redefined
					error_count++;
					fprintf(log_out, "Error at line no:%d Function \'%s\' already defined\n\n", line_count, func_name.c_str());
					fprintf(error_out, "Error at line no:%d Function \'%s\' already defined\n\n", line_count, func_name.c_str());
				} else {
					// function is declared as a function but not defined
					bool definition_matched = true;
					int declared_param_count = temp_func->get_param_count();
					int definition_param_count = func_param_list.size();
					// check if the function definition has the same number of parameters
					if(declared_param_count != definition_param_count){
						// ! function definition has different number of parameters
						error_count++;
						fprintf(log_out, "Error at line no:%d Function \'%s\' has different number of parameters\n\n", line_count, func_name.c_str());
						fprintf(error_out, "Error at line no:%d Function \'%s\' has different number of parameters\n\n", line_count, func_name.c_str());
						definition_matched = false;
					}
					if(func_ret_type != temp_func->get_identifier()){
						// ! function definition has different return type
						error_count++;
						fprintf(log_out, "Error at line no:%d Function \'%s\' has different return type\n\n", line_count, func_name.c_str());
						fprintf(error_out, "Error at line no:%d Function \'%s\' has different return type\n\n", line_count, func_name.c_str());
						definition_matched = false;
					}
					// if the function definition matches the declaration then 
					// remove the function from the symbol table and add it again with the definition
					if(definition_matched){
						table.remove(func_name);
						temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
						table.insert(temp_func);
					}
					// set the fundtion as defined
					temp_func->set_defined(true);

					// enter to the function scope
					table.create_scope();

					// declare the function
					declare_procedure(asm_out, func_name);
				}
			}
		} else {
			// function is not declared
			symbol_info* temp_func = new symbol_info(func_name, func_ret_type, func_param_list);
			temp_func->set_defined(true);
			table.insert(temp_func);
			// enter to the function scope
			table.create_scope();

			// declare the function
			declare_procedure(asm_out, func_name);
		}
		
	} compound_statement {
		// cout<<"type_specifier id lparen rparen compound_statement found"<<endl;
		string argument_name = $1->get_name() + " " + $2->get_name() + "()" + $6->get_name();
		string argument_identifier = "function_definition";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line no:%d - function definition : type_specifier ID LPAREN RPAREN compound_statement\n\n%s\n\n", line_count, argument_name.c_str());

		// asm code for function definition
		// call finish proc
		func_var_count = 0;
		symbol_info* temp_func = table.search(current_function_name);
		terminate_proc(asm_out, current_function_name, current_function_ret_type, temp_func->get_param_count());

		string code = "\t" + current_function_name + " ENDP";
		print_asm_to_file(asm_out, code);
	}
 	;				


parameter_list  : parameter_list COMMA type_specifier ID {
		// cout<<"parameter_list comma type_specifier id found"<<endl;
		string argument_name = $1->get_name() + "," + $3->get_name() + " " + $4->get_name();
		string argument_identifier = "parameter_list";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - parameter_list : parameter_list COMMA type_specifier ID\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| parameter_list COMMA type_specifier {
		// cout<<"parameter_list comma type_specifier found"<<endl;
		string argument_name = $1->get_name() + "," + $3->get_name();
		string argument_identifier = "parameter_list";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - parameter_list : parameter_list COMMA type_specifier ID\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	| type_specifier ID {
		// cout<<"type_specifier id found"<<endl;
		string argument_name = $1->get_name() + " " + $2->get_name();
		string argument_identifier = "parameter_list";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - parameter_list : type_specifier ID\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| type_specifier {
		// cout<<"type_specifier found"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - parameter_list : type_specifier\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| parameter_list error {
		// cout<<"parameter_list error found"<<endl;
		string argument_name = $1->get_name();
		string argument_identifier = "parameter_list";

		$$ = new symbol_info(argument_name, argument_identifier);

		/* error_count++;
		fprintf(log_out, "Error at line no:%d - Parameter not properly defined\n\n", line_count);
		fprintf(error_out, "Error at line no:%d - Parameter not properly defined\n\n", line_count); */
	}
 	;

 		
compound_statement : LCURL statements RCURL {
		// cout<<"lcurl statements rcurl found"<<endl;
		string argument_name = "{\n" + $2->get_name() + "\n}";
		string argument_identifier = "compound_statement";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - compound_statement : LCURL statements RCURL\n\n%s\n\n", line_count, $$->get_name().c_str());

		table.print_all(log_out);
		table.delete_scope();
	}
 	| LCURL RCURL {
		// cout<<"lcurl rcurl found"<<endl;
		string argument_name = "{\n}";
		string argument_identifier = "compound_statement";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - compound_statement : LCURL RCURL\n\n%s\n\n", line_count, $$->get_name().c_str());
		
		table.print_all(log_out);
		table.delete_scope();
	}
 	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
		// cout<<"type_specifier declaration_list semicolon found"<<endl;
		string variable_type = $1->get_identifier();

		if(variable_type == "VOID"){
			error_count++;
			fprintf(error_out, "Error at line no:%d void is not a valid type for variable declaration\n\n", line_count);
		} else {
			vector<string> declaration_list_names = split($2->get_name(), ',');
			for(int i = 0; i < declaration_list_names.size(); i++){
				string argument_name = declaration_list_names[i];
				symbol_info* temp;
				if (is_array_declaration(argument_name)){
					// okay need to differentiate between global and local array
					int array_size = get_array_size(argument_name);
					string array_name = get_array_name(argument_name);
					temp = new symbol_info(array_name, variable_type, array_size);
					// check if the current scope is global scope or not
					if(regex_match(table.get_top()->get_id(), regex("\\d+"))){
						print_global_variable_name(asm_out, array_name, line_count, array_size);
					}else{
						func_var_count += array_size;

						temp->set_offset(func_var_count*-2);

						string asm_code = "\t\tSUB SP, " + to_string(array_size*2) + "\t\t\t;line no: "
							+ to_string(line_count) + " " + array_name + " declared\n";
						print_asm_to_file(asm_out, asm_code);
					}

				} else {
					temp = new symbol_info(argument_name, variable_type);
					if(regex_match(table.get_top()->get_id(), regex("\\d+"))){
						print_global_variable_name(asm_out, argument_name, line_count);
					}else{
						func_var_count++;
						temp->set_offset(func_var_count*(-2));
						cout<<"offset: "<<temp->get_offset()<<endl;
						string asm_code = "\t\tSUB SP, 2\t\t\t;line no: " 
							+ to_string(line_count) + " " + argument_name + " declared.\n";
						print_asm_to_file(asm_out, asm_code);
					}
				}
				if(!table.insert(temp)){
					// ! multiple declaration error
					// ! the symbol is already present in the symbol table
					error_count++;
					fprintf(log_out, "Error at line no:%d Multiple declaration of %s\n\n", line_count, temp->get_name().c_str());
					fprintf(error_out, "Error at line no:%d Multiple declaration of %s\n\n", line_count, temp->get_name().c_str());
				}
			}
		}
		string argument_name = $1->get_name() + " " + $2->get_name() + ";";
		string argument_identifier = "var_declaration";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - var_declaration : type_specifier declaration_list semicolon\n\n%s\n\n", line_count, $$->get_name().c_str());		
	}
 	;
 		 
type_specifier	: INT {
		$$ = new symbol_info("int", "CONST_INT");
		fprintf(log_out, "Line %d - type_specifier : INT\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	| FLOAT {
		$$ = new symbol_info("float", "CONST_FLOAT");
		fprintf(log_out, "Line %d - type_specifier : FLOAT\n\n%s\n\n", line_count, $$->get_name().c_str());
		
	}
 	| VOID {
		// cout<<"void detected"<<endl;
		$$ = new symbol_info("void", "VOID");
		fprintf(log_out, "Line %d - type_specifier : VOID\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	;
 		
declaration_list : declaration_list COMMA ID {
		// cout<<"declaration list detected"<<endl;
		string argument_name = $1->get_name() + "," + $3->get_name();
		string argument_identifier = "declaration_list";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - declaration_list : declaration_list COMMA ID\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
		// cout<<"array detected"<<endl;
		string argument_name = $1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]";
		string argument_identifier = "declaration_list";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	| ID {
		// cout<<"id detected"<<endl;
		$$ = $1;
		fprintf(log_out, "Line %d - declaration_list : ID\n\n%s\n\n", line_count, $$->get_name().c_str());

	}
 	| ID LTHIRD CONST_INT RTHIRD {
		// cout<<"array detected"<<endl;
		string argument_name = $1->get_name() + "[" + $3->get_name() + "]";
		string argument_identifier = "declaration_list";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| declaration_list error {
		string argument_name = $1->get_name();
		string argument_identifier = "declaration_list";

		$$ = new symbol_info(argument_name, argument_identifier);

		
		/* error_count++;
		fprintf(error_out, "Error at line no:%d Declaration error detected.\n\n", line_count);
		fprintf(log_out, "Error at line no:%d Declaration error detected.\n\n", line_count); */

		fprintf(log_out, "Line %d - declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	;
 		  
statements : statement {
		// cout<<"statement found"<<endl;
		$$ = $1;

		fprintf(log_out, "Line %d - statements : statement\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
 	| statements statement {
		// cout<<"statements statement found"<<endl;
		string argument_name = $1->get_name() + "\n" + $2->get_name();
		string argument_identifier = "statements";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - statements : statements statement\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| statements error {
		// cout<<"statements error state found"<<endl;
		string argument_name = $1->get_name();
		string argument_identifier = "statements";

		$$ = new symbol_info(argument_name, argument_identifier);

		/* error_count++;
		fprintf(log_out, "Error at line no:%d Statement not properly defined.\n\n", line_count);
		fprintf(error_out, "Error at line no:%d Statement not properly defined.\n\n", line_count); */
	}
	;
	   
statement : var_declaration {
		$$ = $1;
		fprintf(log_out, "Line %d - statement : var_declaration\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| expression_statement {
		$$ = $1;
		fprintf(log_out, "Line %d - statement : expression_statement\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| { table.create_scope(); } compound_statement {
		$$ = $2;
		fprintf(log_out, "Line %d - statement : compound_statement\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| FOR LPAREN expression_statement {
		string for_start_label = get_new_label(&label_count);
		string for_end_label = get_new_label(&label_count);
		string code = "\t\t;line no : " + to_string(line_count) + ";for loop evaluatoin\n";
		code += "\t\t" + for_start_label + ":\t\t;for loop start label\n";

		print_asm_to_file(asm_out, code);

		$<info>$ = new symbol_info(for_start_label, for_end_label);
	} expression_statement {
		string for_end_label = $<info>4->get_identifier();
		string update_label = get_new_label(&label_count);
		string for_true_label = get_new_label(&label_count);

		string code = "\t\tCMP AX, 0\t\t;compare the value with 0\n";
		code += "\t\tJNE " + for_true_label + "\t\t;if true jump to loop label\n";
		code += "\t\tJMP " + for_end_label + "\t\t;if false jump to end label\n";
		code += "\t\t" + update_label + ":\t\t;for loop true label\n";

		print_asm_to_file(asm_out, code);

		$<info>$ = new symbol_info(update_label, for_true_label);
	} expression {
		string for_start_label = $<info>4->get_name();
		string for_true_label = $<info>6->get_identifier();


		string code = "\t\tPOP AX\t\t;pop the value from stack\n";
		code += "\t\tJMP " + for_start_label + "\t\t;jump to start label\n";
		code += "\t\t" + for_true_label + ":\t\t;loop iteration label\n";

		print_asm_to_file(asm_out, code);

	} RPAREN statement {
		// cout<<"for loop detected"<<endl;
		string argument_name = "for (" + $3->get_name() + $5->get_name() + $7->get_name() + ")" + $10->get_name();
		string argument_identifier = "statement";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n%s\n\n", line_count, $$->get_name().c_str());

		// add the for loop end label
		string for_end = $<info>4->get_identifier();
		string update_label = $<info>6->get_name();
		string code = "\t\tJMP " + update_label + "\t\t;update of the loop label\n";
		code += "\t\t" + for_end + ":\t\t;for loop end label\n";

		print_asm_to_file(asm_out, code);
	}
	| IF LPAREN expression RPAREN if_block_marker statement %prec LOWER_THAN_ELSE {
		// cout<<"if statement detected"<<endl;
		string argument_name = "if (" + $3->get_name() + ")" + $6->get_name();
		string argument_identifier = "statement";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - statement : IF LPAREN expression RPAREN statement\n\n%s\n\n", line_count, $$->get_name().c_str());

		// asm code
		string if_false = $<info>5->get_name();
		string code = "\t\t" + if_false + ":\t\t\t;if false label\n";

		print_asm_to_file(asm_out, code);
	}
	| IF LPAREN expression RPAREN if_block_marker statement ELSE {
		// asm code
		string if_false = $<info>5->get_name();
		string else_end = get_new_label(&label_count);

		string code = "\t\tJMP " + else_end + "\t\t\t;jump to the end of the else statement\n";
		code += "\t\t" + if_false + ":\t\t\t;if false label\n";

		$<info>$ = new symbol_info(else_end, "LABEL");

		print_asm_to_file(asm_out, code);
	} statement {
		// cout<<"if else statement detected"<<endl;
		string argument_name = "if (" + $3->get_name() + ")" + $6->get_name() + "else" + $9->get_name();
		string argument_identifier = "statement";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - statement : IF LPAREN expression RPAREN statement ELSE statement\n\n%s\n\n", line_count, $$->get_name().c_str());

		// asm code
		string end_label = $<info>8->get_name();

		string code = "\t\t" + end_label + ":\t\t\t;end label of else\n";

		print_asm_to_file(asm_out, code);
		
	}
	| WHILE {
		// create a start label for while
		string while_start = get_new_label(&label_count);
		string code = "\t\t" + while_start + ": \t\t;while loop start";
		print_asm_to_file(asm_out, code);
		$<info>$ = new symbol_info(while_start, "LABEL");
	} LPAREN expression {


		string while_end = get_new_label(&label_count);
		string code = "\t\tPOP AX\t\t;pop expression value\n";
		code += "\t\tCMP AX, 0\t\t;check if expression is true\n";
		code += "\t\tJE " + while_end + "\t\t;if false, jump to end of loop\n";
		code += "\t\t;continue while loop";
		print_asm_to_file(asm_out, code);
		$<info>$ = new symbol_info(while_end, "LABEL");
	} RPAREN statement {
		// cout<<"while loop detected"<<endl;

		string argument_name = "while (" + $4->get_name() + ")" + $7->get_name();
		string argument_identifier = "statement";

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - statement : WHILE LPAREN expression RPAREN statement\n\n%s\n\n", line_count, $$->get_name().c_str());

		// asm code
		string while_start = $<info>2->get_name();
		string while_end = $<info>5->get_name();

		string code = "\t\tJMP " + while_start + "\t\t;jump back to start of loop\n";
		code += "\t\t" + while_end + ": \t\t;while loop end";
		print_asm_to_file(asm_out, code);
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		// cout<<"println detected"<<endl;
		string argument_name = "printf(" + $3->get_name() + ")";
		string argument_identifier = "statement";

		symbol_info* temp = table.search($3->get_name());

		if(temp == NULL){
			// ! the variable is not declared
			error_count++;
			fprintf(log_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $3->get_name().c_str());
			fprintf(error_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $3->get_name().c_str());
		} else {
			if (!temp->is_variable()){
				// ! the variable is not a variable
				error_count++;
				fprintf(log_out, "Error at line no:%d Variable - %s is not a variable\n\n", line_count, $3->get_name().c_str());
				fprintf(error_out, "Error at line no:%d Variable - %s is not a variable\n\n", line_count, $3->get_name().c_str());
			} else {
				// okay temp is a variable
				string code = "\t\t;line no : "+ to_string(line_count) + " " + argument_name + "\n";
				if(temp->get_offset() == 0){
					// global variable
					code += "\t\tPUSH " + temp->get_name() + ";passing the value of " + temp->get_name() + " \n";
				} else {
					// local variable
					code += "\t\tPUSH [BP + " + to_string(temp->get_offset()) + "];passing the value of " + temp->get_name() + " \n";
				}
				code += "\t\tCALL PRINT_DECIMAL_INTEGER\n";
				print_asm_to_file(asm_out, code);	
			}
		}

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n%s\n\n", line_count, $$->get_name().c_str());

	}
	| RETURN expression SEMICOLON {
		// cout<<"return detected"<<endl;
		string argument_name = "return " + $2->get_name() + ";";
		string argument_identifier = "statement";

		if(current_function_ret_type == "VOID"){
			error_count++;
			fprintf(log_out, "Error at line no:%d Function \'%s\' does not have a return type\n\n", line_count, current_function_name.c_str());
			fprintf(error_out, "Error at line no:%d Function \'%s\' does not have a return type\n\n", line_count, current_function_name.c_str());
			current_function_ret_type = "ERROR";
		} else {
			// generate asm code
			string code = "\t\t;returning to caller\n";
			code += "\t\tPOP AX\t\t;storing the return value of the function to the variable AX\n";
			if(current_function_name == "main"){
				// main function
				return_to_dos(asm_out);
			} else {
				symbol_info* temp_func = table.search(current_function_name);
				code += "\t\tMOV SP, BP\t\t;restoring the stack pointer\n";
				code += "\t\tPOP BP\t\t\t;restoring the caller function's BP\n";
				int num_param_count = temp_func->get_param_count();
				code += "\t\tRET " + to_string(num_param_count * 2) + "\t\t;returning to the caller";
				print_asm_to_file(asm_out, code);
			}
		}

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - statement : RETURN expression SEMICOLON\n\n%s\n\n", line_count, $$->get_name().c_str());


	}
	;
	  
expression_statement : SEMICOLON {
		$$ = new symbol_info(";", "SEMICOLON");

		// no need to generate any code only single semicolon is present
	}		
	| expression SEMICOLON {
		string argument_name = $1->get_name() + ";";
		string argument_identifier = "EXPRESSION_STATEMENT";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - expression_statement : expression SEMICOLON\n\n%s\n\n", line_count, $$->get_name().c_str());
		// generate code for asm file
		string code = "\t\tPOP AX\t\t\t\t;Popped the expression " + argument_name + "'s value' ";
		print_asm_to_file(asm_out, code);

	}
	;

variable : ID {
		symbol_info* temp = table.search($1->get_name());

		if(temp == NULL){
			// ! current symbol is not in the table
			error_count++;
			fprintf(log_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $1->get_name().c_str());
			fprintf(error_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $1->get_name().c_str());

			$$ = new symbol_info($1->get_name(), "ERROR");
		} else {
			if(temp->is_array()) {
				// ! current symbol is found in the table but it is an array so error
				$$ = new symbol_info(temp->get_name(), "ERROR", temp->get_size());
			} else {
				// current symbol is found in the table and it is not an array so all okay
				$$ = new symbol_info(temp->get_name(), temp->get_identifier());


				//write to assembly file
				// check if the variable is global or local
				if (temp->get_offset() == 0){
					// global variable
					string code = "\t\tPUSH " + temp->get_name() 
					+ "\t\t\t\t;line no: " + to_string(line_count) + " - " + temp->get_name() + " global variable\n";
					print_asm_to_file(asm_out, code);
				} else {
					// local variable
					string code = "\t\tPUSH [BP + " + to_string(temp->get_offset()) 
						+ "]\t\t\t\t;line no: " + to_string(line_count) + " - " + temp->get_name() + " local variable\n";

					print_asm_to_file(asm_out, code);
				}
			}
		}
		fprintf(log_out, "Line %d - variable : ID\n\n%s\n\n",line_count, $$->get_name().c_str());
	}
	| ID LTHIRD expression RTHIRD {
		//cout<<$1->get_name()<<endl;
		symbol_info* temp = table.search($1->get_name());
		if(temp == NULL){
			// ! current symbol is not in the table
			error_count++;
			fprintf(log_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $1->get_name().c_str());
			fprintf(error_out, "Error at line no:%d Variable - %s not declared\n\n", line_count, $1->get_name().c_str());
			string argument_name = $1->get_name() + "[" + $3->get_name() + "]";
			$$ = new symbol_info(argument_name, "ERROR");
		} else {
			if(temp->is_array()) {
				// okay current symbol is found in the table and it is an array
				if ($3->get_identifier() != "CONST_INT"){
					// ! index is not an integer error
					error_count++;
					fprintf(log_out, "Error at line no:%d Array index is not an integer\n\n", line_count);
					fprintf(error_out, "Error at line no:%d Array index is not an integer\n\n", line_count);
				} else {
					// okay index is an integer and variable is an array 
					// write to assembly file

					string code = "\t\t;line no: " + to_string(line_count) + " - " + temp->get_name() + " array\n";
					code += "\t\t;getting index: " + $3->get_name() + " from stack.\n";
					code += "\t\tPOP BX\t\t\t\t;getting index from stack.\n";
					code += "\t\tSHL BX, 1\t\t\t;multiplying index by 2.\n";

					// check if the variable is global or local
					if(temp->get_offset() == 0){
						// global variable
						code += "\t\tMOV AX, "+ temp->get_name()+"[BX]\t\t;getting the value of the array at index BX\n";
					} else {
						// local variable
						code += "\t\tADD BX, " + to_string(temp->get_offset()) + "\t\t\t;adding offset to BX.\n";
						code += "\t\tADD BX, BP\t\t\t;adding index to local variable.\n";
						code += "\t\tPUSH BP\t\t\t;push bp to stack.\n";
						code += "\t\tMOV BP, BX\t\t\t;setting bp to bx.\n";
						code += "\t\tMOV AX, [BP]\t\t;getting the value of the array at index BX\n";
						code += "\t\tPOP BP\t\t\t\t;pop bp from stack.\n";
					}

					code += "\t\tPUSH AX\t\t\t\t;pushing the value of the array at index "+ $3->get_name()+" \n";
					code += "\t\tPUSH BX\t\t\t\t;pushing the address of the array element\n";
					print_asm_to_file(asm_out, code);
				}
				string argument_name = $1->get_name() + "[" + $3->get_name() + "]";
				$$ = new symbol_info(argument_name, temp->get_identifier());
			} else {
				// ! current symbol is found in the table and it is not an array so error
				string argument_name = $1->get_name() + "[" + $3->get_name() + "]";
				$$ = new symbol_info(argument_name, "ERROR");
				fprintf(log_out, "Error at line no:%d Variable - %s is not an array\n\n", line_count, $1->get_name().c_str());
				fprintf(error_out, "Error at line no:%d Variable - %s is not an array\n\n", line_count, $1->get_name().c_str());
			}
		}
		fprintf(log_out, "Line %d - variable : ID LTHIRD expression RTHIRD\n\n%s\n\n",line_count, $$->get_name().c_str());
	}
	;

expression : logic_expression {
		$$ = $1;
		fprintf(log_out, "Line %d - expression : logic_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
 	}
	| variable ASSIGNOP logic_expression {
		symbol_info* left = $1;
		symbol_info* right = $3;

		if (left->get_identifier() != right->get_identifier()) {
			// error
			if (left->get_identifier() == "ERROR" || right->get_identifier() == "ERROR") {
				if (left->is_array() || right->is_array()) {
					// error
					error_count++;
					if(left->is_array()){
						fprintf(log_out, "Error at line no:%d Type mismatch, %s is an array\n\n", line_count, left->get_name().c_str());
						fprintf(error_out, "Error at line no:%d Type mismatch, %s is an array\n\n", line_count, left->get_name().c_str());
					}else{
						fprintf(log_out, "Error at line no:%d Type mismatch, %s is an array\n\n", line_count, right->get_name().c_str());
						fprintf(error_out, "Error at line no:%d Type mismatch, %s is an array\n\n", line_count, right->get_name().c_str());
					}
				} 
			} else if (left->get_identifier() == "CONST_FLOAT" && right->get_identifier() == "CONST_INT") {
				// okay do nothing
			} else if (right->get_identifier() == "UNDEFINED") {
				// do nothing (error already printed)
			} else {
				// error
				error_count++;
				fprintf(log_out, "Error at line no:%d Type mismatch, %s is not of type %s\n\n", line_count, left->get_name().c_str(), right->get_identifier().c_str());
				fprintf(error_out, "Error at line no:%d Type mismatch, %s is not of type %s\n\n", line_count, left->get_name().c_str(), right->get_identifier().c_str());
			}
		}

		string argument_name = left->get_name() + " = " + right->get_name();
		string argument_identifier = "EXPRESSION";

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - expression : variable ASSIGNOP logic_expression\n\n%s\n\n", line_count, $$->get_name().c_str());


		// generate assembly code
		// pop the right value from the stack
		string code = "\t\t;line no : " + to_string(line_count) + 
					" - variable assignment: " + left->get_name() + " = " + right->get_name() + "\n";
		code += "\t\tPOP AX\t\t\t\t;poping right side's value: " + right->get_name()  +"\n";
		// first check if the variable is valid or not
		if(left->get_identifier() == "ERROR"){
			// ! variable is not valid
		} else {
			// check if the variable is an array
			symbol_info* temp;
			string var_name = get_array_name(left->get_name());
			if(is_array_declaration(left->get_name())){
				code += "\t\tPOP BX\t\t\t\t;popped array index from stack\n";
				// get the name of the array
				temp = table.search(var_name);
			}else{
				temp = table.search(left->get_name());
			}

			//if the variable is global or local
			if(temp->get_offset() == 0){
				// variable is global
				if(temp->is_array()){
					// array
					code += "\t\tMOV "+ var_name +"[BX], AX\t\t;assigning value to array element\n";
				} else {
					// scalar
					code += "\t\tMOV "+ var_name +", AX\t\t\t;assigning value to variable\n";
				}
			} else {
				// variable is local
				if(temp->is_array()){
					// array
					code += "\t\tPUSH BP\t\t;pushing the bp value in stack\n";
					code += "\t\tMOV BP, BX\t;setting bp to bx\n";
					code += "\t\tMOV [BP], AX\t;assigning value to variable\n";
					code += "\t\tPOP BP\t\t;popping the bp value from stack\n";
				} else {
					// scalar
					code += "\t\tMOV [BP + " + to_string(temp->get_offset()) + "], AX\t;assigning value to variable\n";
				}
			}
			code += "\t\tPUSH AX\t\t\t\t;pushing the value of the variable\n";

			// print the variable assignment code
			print_asm_to_file(asm_out, code);

		}
	} 	
	;

logic_expression : rel_expression {
		$$ = $1;
		fprintf(log_out, "Line %d - logic_expression : rel_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| rel_expression LOGICOP rel_expression {
		string return_identifier = "CONST_INT";
		string left_identifier = $1->get_identifier();
		string right_identifier = $3->get_identifier();
		string operator_name = $2->get_name();
		if(left_identifier != "CONST_INT" || right_identifier != "CONST_INT"){
			error_count++;
			fprintf(log_out, "Error at line no:%d Relational operator can only be used with two integers\n\n", line_count);
			fprintf(error_out, "Error at line no:%d Relational operator can only be used with two integers\n\n", line_count);
			return_identifier = "ERROR";
		}
		string argument_name = $1->get_name() + $2->get_name() + $3->get_name();
		$$ = new symbol_info(argument_name, return_identifier);
		fprintf(log_out, "Line %d - logic_expression : rel_expression LOGICOP rel_expression\n\n%s\n\n", line_count, $$->get_name().c_str());


		// generate assembly code for the relational operator
		string left_name = $1->get_name();
		string right_name = $3->get_name();
		string code = "\t\t;line no: " + to_string(line_count) + "relational operator for\n";
		code += "\t\t;left: " + left_name + "\n";
		code += "\t\t;operator: " + operator_name + "\n";
		code += "\t\t;right: " + right_name + "\n";

		if (operator_name == "&&"){
			string label_left_true = get_new_label(&label_count);
			string label_whole_true = get_new_label(&label_count);
			string label_end = get_new_label(&label_count);

			code += "\t\t;left true label: " + label_left_true + "\n";
			code += "\t\t;whole true label: " + label_whole_true + "\n";
			code += "\t\t;end label: " + label_end + "\n";

			code += "\t\tPOP BX\t\t;pop the right value : " + right_name + "\n";
			code += "\t\tPOP AX\t\t;pop the left value : " + left_name + "\n";

			code += "\t\tCMP AX, 0\t\t;compare the left value with false\n";
			code += "\t\tJNE " + label_left_true + "\t\t;if not false, jump to left true label\n";
			code += "\t\t\t;if left value is false, jump to whole false label\n";
			code += "\t\t\tPUSH 0\t\t;push false\n";
			code += "\t\t\tJMP " + label_end + "\t\t;jump to end label\n";
			code += "\t\t" + label_left_true + ":\t\t;left true label\n";
			code += "\t\t\tCMP BX, 0\t\t;compare the right value with false\n";
			code += "\t\t\tJNE " + label_whole_true + "\t\t;if not false, jump to whole true label\n";
			code += "\t\t\t\t;if right value is false, jump to whole false label\n";
			code += "\t\t\t\tPUSH 0\t\t;push false\n";
			code += "\t\t\t\tJMP " + label_end + "\t\t;jump to end label\n";
			code += "\t\t" + label_whole_true + ":\t\t;whole true label\n";
			code += "\t\t\tPUSH 1\t\t;push true\n";
			code += "\t\t" + label_end + ":\t\t;end label\n";
		} else {
			string label_left_false = get_new_label(&label_count);
			string label_whole_false = get_new_label(&label_count);
			string label_end = get_new_label(&label_count);

			code += "\t\t;left false label: " + label_left_false + "\n";
			code += "\t\t;whole false label: " + label_whole_false + "\n";
			code += "\t\t;end label: " + label_end + "\n";

			code += "\t\tPOP BX\t\t;pop the right value : " + right_name + "\n";
			code += "\t\tPOP AX\t\t;pop the left value : " + left_name + "\n";
			code += "\t\tCMP AX, 0\t\t;compare the left value with false\n";
			code += "\t\tJE " + label_left_false + "\t\t;if false, jump to left false label\n";
			code += "\t\t\t;if left value is not false, jump to whole true label\n";
			code += "\t\t\tPUSH 1\t\t;push true\n";
			code += "\t\t\tJMP " + label_end + "\t\t;jump to end label\n";
			code += "\t\t" + label_left_false + ":\t\t;left false label\n";
			code += "\t\t\tCMP BX, 0\t\t;compare the right value with false\n";
			code += "\t\t\tJE " + label_whole_false + "\t\t;if false, jump to whole false label\n";
			code += "\t\t\t\t;if right value is not false, jump to whole true label\n";
			code += "\t\t\t\tPUSH 1\t\t;push true\n";
			code += "\t\t\t\tJMP " + label_end + "\t\t;jump to end label\n";
			code += "\t\t" + label_whole_false + ":\t\t;whole false label\n";
			code += "\t\t\tPUSH 0\t\t;push false\n";
			code += "\t\t" + label_end + ":\t\t;end label\n";
		}

		print_asm_to_file(asm_out, code);

	}
	;
			
rel_expression	: simple_expression {
		$$ = $1;
		fprintf(log_out, "Line %d - rel_expression : simple_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| simple_expression RELOP simple_expression	{
		string argument_name = $1->get_name() + $2->get_name() + $3->get_name();
		string argument_identifier = "CONST_INT";
		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - rel_expression : simple_expression relop simple_expression\n\n%s\n\n", line_count, $$->get_name().c_str());


		string label_if_true = get_new_label(&label_count);
		string label_if_false = get_new_label(&label_count);

		string left_name = $1->get_name();
		string right_name = $3->get_name();

		string code = "\t\t; Relational operator for " + left_name + " " + right_name + "\n";
		code += "\t\tPOP BX\t\t; BX = " + right_name + "\n";
		code += "\t\tPOP AX\t\t; AX = " + left_name + "\n";
		code += "\t\tCMP AX, BX\t; Compare AX and BX\n";
		code += "\t\t" + get_relop_equivalent_code($2->get_name()) + " " + label_if_true + "\n";
		code += "\t\tPUSH 0\t\t; Push false to stack\n";
		code += "\t\tJMP " + label_if_false + "\n";
		code += "\t\t" +label_if_true + ":\n";
		code += "\t\t\tPUSH 1\t\t; Push true to stack\n";
		code += "\t\t" + label_if_false + ":\n";

		print_asm_to_file(asm_out, code);



	}
	;
				
simple_expression : term {
		$$ = $1;
		fprintf(log_out, "Lind %d - simple_expression : term \n\n%s\n\n", line_count, $$->get_name().c_str());
	} 
	| simple_expression ADDOP term {
		string argument_name = $1->get_name() + $2->get_name() + $3->get_name();
		string argument_identifier = "CONST_INT";
		if($1->get_identifier() == "CONST_FLOAT"){
			argument_identifier = "CONST_FLOAT";
		} else if($3->get_identifier() == "CONST_FLOAT"){
			argument_identifier = "CONST_FLOAT";
		}

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Lind %d - simple_expression : simple_expression ADDOP term \n\n%s\n\n", line_count, $$->get_name().c_str());



		//generate code for add operation
		string operation_name = "";
		if($2->get_name() == "+"){
			operation_name = "ADD";
		} else {
			operation_name = "SUB";
		}

		string code = "\t\t;line no: " + to_string(line_count) + " " + operation_name + " " + $1->get_name() + " " + $3->get_name() + "\n";
		code += "\t\tPOP BX\t\t;load the right operand\n";
		code += "\t\tPOP AX\t\t;load the left operand\n";

		code += "\t\t" + operation_name + " AX, BX\t;perform the operation\n";
		code += "\t\tPUSH AX\t\t;push the result into the stack\n";

		print_asm_to_file(asm_out, code);

	}
	| simple_expression error {
		string argument_name = $1->get_name();
		string argument_identifier = $1->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
	}
	;
					
term :	unary_expression {
		$$ = $1;
		fprintf(log_out, "Line %d - term : unary_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
    |  term MULOP unary_expression {
		string left_identifier = $1->get_identifier();
		string right_identifier = $3->get_identifier();
		string left_name = $1->get_name().c_str();
		string right_name = $3->get_name().c_str();

		string return_identifier = "ERROR";
		string operator_name = $2->get_name();
		switch(operator_name[0]){
			case '*':
				if(left_identifier == "CONST_FLOAT" || right_identifier == "CONST_FLOAT"){
					return_identifier = "CONST_FLOAT";
				} else {
					return_identifier = "CONST_INT";
				}
				break;
			case '/':
				if(left_identifier == "CONST_FLOAT" || right_identifier == "CONST_FLOAT"){
					return_identifier = "CONST_FLOAT";
				} else {
					return_identifier = "CONST_INT";
				}
				if(right_name == "0"){
					error_count++;
					fprintf(log_out, "Error at line no:%d  Division by zero\n\n", line_count);
					fprintf(error_out, "Error at line no:%d  Division by zero\n\n", line_count);
					return_identifier = "ERROR";
				}
				break;
			case '%':
				if(left_identifier != "CONST_INT" || right_identifier != "CONST_INT"){
					error_count++;
					fprintf(log_out, "Error at line no:%d %c operator can only be used with integers\n\n", line_count, '%');
					fprintf(error_out, "Error at line no:%d %c operator can only be used with integers\n\n", line_count, '%');
					return_identifier = "ERROR";
				} else {
					if(right_name == "0"){
						error_count++;
						fprintf(log_out, "Error at line no:%d %c operator can not be used with 0\n\n", line_count, '%');
						fprintf(error_out, "Error at line no:%d %c operator can not be used with 0\n\n", line_count, '%');
						return_identifier = "ERROR";
					} else {
						return_identifier = "CONST_INT";
					}
				}
				break;
			default:
				return_identifier = "ERROR";
				break;
		}

		string argument_name = left_name + operator_name + right_name;
		$$ = new symbol_info(argument_name, return_identifier);
		fprintf(log_out, "Line %d - term : term MULOP unary_expression\n\n%s\n\n", line_count, $$->get_name().c_str());


		// generate code for the operator
		string operation_name = "";
		switch(operator_name[0]){
			case '*':
				operation_name = "IMUL";
				break;
			case '/':
				operation_name = "IDIV";
				break;
			case '%':
				operation_name = "MOD";
				break;
			default:
				break;
		}

		string code = "\t\t;line no: " + to_string(line_count) + " " + operation_name + "\n";
		code += "\t\t;" + left_name + " " + operator_name[0] + " " + right_name + "\n";
		code += "\t\tPOP BX\t\t;pop the value of " + right_name + " from stack\n";
		code += "\t\tPOP AX\t\t;pop the value of " + left_name + " from stack\n";

		if(operation_name == "IMUL"){
			code += "\t\tIMUL BX\t\t;multiply the values\n";
		} else {
			code += "\t\tXOR DX, DX\t\t;making the DX register 0 for div operation\n";
			code += "\t\tIDIV BX\t\t;divide the values\n";
			if(operation_name == "MOD"){
				code += "\t\tMOV AX,DX\t\t;move the remainder to AX\n";
			}
		}
		code += "\t\tPUSH AX\t\t;push the result to stack\n";

		print_asm_to_file(asm_out, code);

	}
    ;

unary_expression : ADDOP unary_expression {
		string argument_name = $1->get_name() + $2->get_name();
		string argument_identifier = $2->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
		
		fprintf(log_out, "Line %d - unary_expression : ADDOP unary_expression\n\n%s\n\n", line_count, $$->get_name().c_str());

		// generate asm code for addop unary_expression
		// only - need to negate the value
		// for + no need to do anything

		string exp_name = $2->get_name();

		if($1->get_name() == "-"){
			string code = "\t\t;line no: " + to_string(line_count) + " Negating the value\n";
			code += "\t\tPOP AX\t\t; pop the value of " + exp_name + "\n";
			code += "\t\tNEG AX\t\t; negate the value\n";
			code += "\t\tPUSH AX\t\t; push the value of " + exp_name + "\n";

			print_asm_to_file(asm_out, code);
		} 
	} 
	| NOT unary_expression {
		string argument_name = "!" + $2->get_name();
		string argument_identifier = $2->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - unary_expression : NOT unary_expression\n\n%s\n\n", line_count, $$->get_name().c_str());

		string exp_name = $2->get_name();
		string label_if_true =  get_new_label(&label_count);
		string label_end =  get_new_label(&label_count);

		// generate asm code for not expression
		string code = "\t\t;line no " + to_string(line_count) + ": Logical NOT of " + exp_name + "\n";
		code += "\t\tPOP \tAX\t\t\t;pop the value of the "+ exp_name +"\n";
		code += "\t\tCMP \tAX, 0\t\t;compare the value of the "+ exp_name +" with 0\n";
		code += "\t\tJE \t" + label_if_true + "\t\t\t;if equal jump to true label: " + label_if_true + "\n";
		code += "\t\t\tPUSH \t0\t\t;else move 0 to AX\n";
		code += "\t\t\tJMP \t" + label_end + "\t;jump to false label: " + label_end + "\n";
		code += "\t\t" + label_if_true + ":\n";
		code += "\t\t\tPUSH \t1\t\t;move 1 to AX\n";
		code += "\t\t" + label_end + ":\n";

		print_asm_to_file(asm_out, code);
	} 
	| factor {
		$$ = $1;
		fprintf(log_out, "Line %d - unary_expression : factor\n\n%s\n\n", line_count, $$->get_name().c_str());
		if($$->get_identifier() == "VOID"){
			// ! function is declared as void but called with arguments
			error_count++;
			fprintf(log_out, "Error at line no:%d  Function %s is declared as void but called with arguments\n\n", line_count, $1->get_name().c_str());
			fprintf(error_out, "Error at line no:%d  Function %s is declared as void but called with arguments\n\n", line_count, $1->get_name().c_str());
		}
	} 
	;
	
factor	: variable {
		$$ = $1;
		fprintf(log_out, "Line %d - factor : variable\n\n%s\n\n", line_count, $$->get_name().c_str());
		if ($$->get_identifier() == "ERROR"){
			// ! error in variable
		} else {
			// generate asm code for variable only if the variable is array
			symbol_info* temp;
			string var_name = get_array_name($1->get_name());
			if(is_array_declaration($1->get_name())){
				string code = "\t\t;line no: " + to_string(line_count) + " " + $$->get_name() + "\n";
				code += "\t\tPOP \tBX\t\t\t;popped array index from stack\n";
				// get the name of the array
				temp = table.search(var_name);
				// temp is guaranteed to be not null

				if(temp->get_offset() == 0){
					// array is global
					code += "\t\tMOV "+ var_name +"[BX], AX\t\t;assigning value to array element\n";
				} else {
					code += "\t\tPUSH BP\t\t\t;push base pointer\n";
					code += "\t\tMOV BP,BX\t\t\t;set base pointer to BX\n";
					code += "\t\tMOV [BP], AX\t;assigning value to variable\n";
					code += "\t\tPOP BP\t\t\t;pop base pointer\n";	
				}
				print_asm_to_file(asm_out, code);
			}
		}
	}
	| ID LPAREN argument_list RPAREN {
		string func_ret_type = "UNDEFINED";
		symbol_info* temp_func = table.search($1->get_name());

		if(temp_func == NULL){
			// ! function is not declared but called
			error_count++;
			fprintf(log_out, "Error at line no:%d Function %s is not defined\n\n", line_count, $1->get_name().c_str());
			fprintf(error_out, "Error at line no:%d Function %s is not defined\n\n", line_count, $1->get_name().c_str());
		} else {
			// okay id is declared
			if(!(temp_func->is_function())){
				// ! function is not declared as function but called
				error_count++;
				fprintf(log_out, "Error at line no:%d  %s is not a function\n\n", line_count, $1->get_name().c_str());
				fprintf(error_out, "Error at line no:%d  %s is not a function\n\n", line_count, $1->get_name().c_str());
			} else {
				// okay id is declared as function
				func_ret_type = temp_func->get_identifier();
				
				// extract the argument list from the argument list
				string argument_name_str = $3->get_name();
				string argument_identifier_str = $3->get_identifier();
				vector<string> argument_name_list = split(argument_name_str, ',');
				vector<string> argument_identifier_list = split(argument_identifier_str, ',');
				
				//get the function argument list
				vector<param> func_param_list = temp_func->get_params();
				int func_argument_count = temp_func->get_param_count();
				// check if the return type of the declared function is void or not
				if(argument_name_list.size() != func_argument_count) {
					// ! function is declared with different number of arguments than called
					error_count++;
					fprintf(log_out, "Error at line no:%d  Function \'%s\' is declared with %d arguments but called with %d arguments\n\n", line_count, $1->get_name().c_str(), func_argument_count, argument_name_list.size());
					fprintf(error_out, "Error at line no:%d  Function \'%s\' is declared with %d arguments but called with %d arguments\n\n", line_count, $1->get_name().c_str(), func_argument_count, argument_name_list.size());
				} else {
					// okay function is declared with same number of arguments as called
					// check if the argument types are same as the declared function
					bool flag = true;
					for(int i = 0; i < func_argument_count; i++){
						if(func_param_list[i].get_type() != argument_identifier_list[i]){
							// ! function is declared with different argument types than called
							error_count++;
							flag = false;
							fprintf(log_out, "Error at line no:%d Type Mismatch. %d\'th argument of function \'%s\' is declared as %s\n\n", line_count,i+1, $1->get_name().c_str(), func_param_list[i].get_type().c_str());
							fprintf(error_out, "Error at line no:%d Type Mismatch. %d\'th argument of function \'%s\' is declared as %s\n\n", line_count,i+1, $1->get_name().c_str(), func_param_list[i].get_type().c_str());
						}
					}

				}

				// okay function is declared with same argument types as called
				// call the function
				// generate asm code
				string code = "\t\tCALL " + temp_func->get_name() + "\t\t\t;calling the function\n";
				code += "\t\tPUSH AX\t\t\t\t;push the return value of " + temp_func->get_name() + " onto the stack\n";

				//write code to the file
				print_asm_to_file(asm_out, code);

			}
		}

		string argument_name = $1->get_name() + "(" + $3->get_name() + ")";
		string argument_identifier = func_ret_type;

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - factor : ID LPAREN argument_list RPAREN\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| LPAREN expression RPAREN {
		string argument_name = "(" + $2->get_name() + ")";
		string argument_identifier = $2->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
		fprintf(log_out, "Line %d - factor : lparen expression rparen\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| CONST_INT {
		$$ = yylval.info;
		fprintf(log_out, "Line %d - factor : CONST_INT\n\n%s\n\n", line_count, $$->get_name().c_str());

		// generate asm code
		string code = "\t\tPUSH " + $$->get_name() + "\t\t\t;push the constant value onto the stack\n";
		print_asm_to_file(asm_out, code);
	} 
	| CONST_FLOAT {
		$$ = yylval.info;
		fprintf(log_out, "Line %d - factor : CONST_FLOAT\n\n%s\n\n", line_count, $$->get_name().c_str());

		// ! our program don't support float values for now
	}
	| INCOP variable {
		string argument_name = "++" + $2->get_name();
		string argument_identifier = $2->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
		symbol_info *temp_var = $2;

		fprintf(log_out, "Line %d - factor : variable INCOP\n\n%s\n\n", line_count, $$->get_name().c_str());

		// generate asm code
		// first check if the the variable is valid
		if(temp_var->get_identifier() == "ERROR"){
			// ! variable is not valid
		} else {
			string code = "\t\t;line no: "+ to_string(line_count) +" variable increment\n";

			// load the value of the variable into the AX register
			// check if the variable is an array
			if(is_array_declaration(temp_var->get_name())){
				code += "\t\tPOP \tBX\t\t\t;popped array index from stack\n";
				code += "\t\tPUSH BP\t\t\t;push the base pointer onto the stack\n";
				code += "\t\tMOV BP, BX\t\t\t;set the base pointer to the array index\n";
            	code += "\t\tMOV AX, [BP]\t\t;setting AX to the value of " + temp_var->get_name() + "\n";
				code += "\t\tPOP BP\t\t\t;pop the base pointer from the stack\n";
			} else {
				code += "\t\tPOP \tAX\t\t\t;popped variable " + temp_var->get_name() + " from stack\n";
			}

			// increment the value of the variable
			code += "\t\tINC \tAX\t\t\t;incrementing the value of " + temp_var->get_name() + "\n";
			
			// store the value of the variable back in the stack

	
			// first check if the variable is an array
			if (is_array_declaration(temp_var->get_name())){
				// get the array name
				string array_name = get_array_name(temp_var->get_name());
				// find the array in the symbol table
				symbol_info *temp_array = table.search(array_name);
				// check if array global or not
				if(temp_array->get_offset() == 0){
					// array is global
					code += "\t\tMOV [BX], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// array is local
					code += "\t\tMOV [BP+" + to_string(temp_array->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			} else {
				// variable is not an array
				string var_name = temp_var->get_name();
				// find the variable in the symbol table
				symbol_info *temp_var = table.search(var_name);
				// check if variable global or not
				if(temp_var->get_offset() == 0){
					// variable is global
					code += "\t\tMOV "+ var_name +", AX\t\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// variable is local
					code += "\t\tMOV [BP+" + to_string(temp_var->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			}

			code += "\t\tPUSH AX\t\t\t;pushing the value of " + temp_var->get_name() + " back onto the stack\n";

			print_asm_to_file(asm_out, code);
			

		}
	}
	| variable INCOP {
		string argument_name = $1->get_name() + "++";
		string argument_identifier = $1->get_identifier();

		$$ = new symbol_info(argument_name, argument_identifier);
		symbol_info *temp_var = $1;

		fprintf(log_out, "Line %d - factor : variable INCOP\n\n%s\n\n", line_count, $$->get_name().c_str());

		// generate asm code
		// first check if the the variable is valid
		if(temp_var->get_identifier() == "ERROR"){
			// ! variable is not valid
		} else {
			string code = "\t\t;line no: "+ to_string(line_count) +" variable increment\n";

			// load the value of the variable into the AX register
			// check if the variable is an array
			if(is_array_declaration(temp_var->get_name())){
				code += "\t\tPOP \tBX\t\t\t;popped array index from stack\n";
				code += "\t\tPUSH BP\t\t\t;push the base pointer onto the stack\n";
				code += "\t\tMOV BP, BX\t\t\t;set the base pointer to the array index\n";
            	code += "\t\tMOV AX, [BP]\t\t;setting AX to the value of " + temp_var->get_name() + "\n";
				code += "\t\tPOP BP\t\t\t;pop the base pointer from the stack\n";
			} else {
				code += "\t\tPOP \tAX\t\t\t;popped variable " + temp_var->get_name() + " from stack\n";
			}

			// store the value of the variable back in the stack
			code += "\t\tPUSH AX\t\t\t;pushing the value of " + temp_var->get_name() + " back onto the stack\n";


			// increment the value of the variable
			code += "\t\tINC \tAX\t\t\t;incrementing the value of " + temp_var->get_name() + "\n";
			

	
			// first check if the variable is an array
			if (is_array_declaration(temp_var->get_name())){
				// get the array name
				string array_name = get_array_name(temp_var->get_name());
				// find the array in the symbol table
				symbol_info *temp_array = table.search(array_name);
				// check if array global or not
				if(temp_array->get_offset() == 0){
					// array is global
					code += "\t\tMOV [BX], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// array is local
					code += "\t\tMOV [BP+" + to_string(temp_array->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			} else {
				// variable is not an array
				string var_name = temp_var->get_name();
				// find the variable in the symbol table
				symbol_info *temp_var = table.search(var_name);
				// check if variable global or not
				if(temp_var->get_offset() == 0){
					// variable is global
					code += "\t\tMOV "+ var_name +", AX\t\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// variable is local
					code += "\t\tMOV [BP+" + to_string(temp_var->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			}


			print_asm_to_file(asm_out, code);
			

		}
	}
	| DECOP variable {
		string argument_name = "--" + $2->get_name();
		string argument_identifier = $2->get_identifier();

		symbol_info *temp_var = $2;

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - factor : variable DECOP\n\n%s\n\n", line_count, $$->get_name().c_str());


		// generate asm code
		// first check if the the variable is valid
		if(temp_var->get_identifier() == "ERROR"){
			// ! variable is not valid
		} else {
			string code = "\t\t;line no: "+ to_string(line_count) +" variable decrement\n";

			// load the value of the variable into the AX register
			// check if the variable is an array
			if(is_array_declaration(temp_var->get_name())){
				code += "\t\tPOP \tBX\t\t\t;popped array index from stack\n";
				code += "\t\tPUSH BP\t\t;push the value of BP";
				code += "\t\tMOV BP, BX\t\t;move the value of bx for array access";
            	code += "\t\tMOV AX, [BP]\t\t;setting AX to the value of " + temp_var->get_name() + "\n";
				code += "\t\tPOP BP\t\t; the value of bp restored";
			} else {
				code += "\t\tPOP \tAX\t\t\t;popped variable " + temp_var->get_name() + " from stack\n";
			}

			// decrement the value of the variable
			code += "\t\tDEC \tAX\t\t\t;decrementing the value of " + temp_var->get_name() + "\n";



	
			// first check if the variable is an array
			if (is_array_declaration(temp_var->get_name())){
				// get the array name
				string array_name = get_array_name(temp_var->get_name());
				// find the array in the symbol table
				symbol_info *temp_array = table.search(array_name);
				// check if array global or not
				if(temp_array->get_offset() == 0){
					// array is global
					code += "\t\tMOV [BX], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// array is local
					code += "\t\tMOV [BP+" + to_string(temp_array->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			} else {
				// variable is not an array
				string var_name = temp_var->get_name();
				// find the variable in the symbol table
				symbol_info *temp_var = table.search(var_name);
				// check if variable global or not
				if(temp_var->get_offset() == 0){
					// variable is global
					code += "\t\tMOV "+ var_name +", AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// variable is local
					code += "\t\tMOV [BP+" + to_string(temp_var->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			}

			// store the value of the variable back in the stack
			code += "\t\tPUSH AX\t\t\t;pushing the value of " + temp_var->get_name() + " back onto the stack\n";
			print_asm_to_file(asm_out, code);
		}
	}
	| variable DECOP {
		
		string argument_name = $1->get_name() + "--";
		string argument_identifier = $1->get_identifier();

		symbol_info *temp_var = $1;

		$$ = new symbol_info(argument_name, argument_identifier);

		fprintf(log_out, "Line %d - factor : variable DECOP\n\n%s\n\n", line_count, $$->get_name().c_str());


		// generate asm code
		// first check if the the variable is valid
		if(temp_var->get_identifier() == "ERROR"){
			// ! variable is not valid
		} else {
			string code = "\t\t;line no: "+ to_string(line_count) +" variable decrement\n";

			// load the value of the variable into the AX register
			// check if the variable is an array
			if(is_array_declaration(temp_var->get_name())){
				code += "\t\tPOP \tBX\t\t\t;popped array index from stack\n";
				code += "\t\tPUSH BP\t\t;push the value of BP";
				code += "\t\tMOV BP, BX\t\t;move the value of bx for array access";
            	code += "\t\tMOV AX, [BP]\t\t;setting AX to the value of " + temp_var->get_name() + "\n";
				code += "\t\tPOP BP\t\t; the value of bp restored";
			} else {
				code += "\t\tPOP \tAX\t\t\t;popped variable " + temp_var->get_name() + " from stack\n";
			}

			// store the value of the variable back in the stack
			code += "\t\tPUSH AX\t\t\t;pushing the value of " + temp_var->get_name() + " back onto the stack\n";


			// decrement the value of the variable
			code += "\t\tDEC \tAX\t\t\t;decrementing the value of " + temp_var->get_name() + "\n";



	
			// first check if the variable is an array
			if (is_array_declaration(temp_var->get_name())){
				// get the array name
				string array_name = get_array_name(temp_var->get_name());
				// find the array in the symbol table
				symbol_info *temp_array = table.search(array_name);
				// check if array global or not
				if(temp_array->get_offset() == 0){
					// array is global
					code += "\t\tMOV [BX], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// array is local
					code += "\t\tMOV [BP+" + to_string(temp_array->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			} else {
				// variable is not an array
				string var_name = temp_var->get_name();
				// find the variable in the symbol table
				symbol_info *temp_var = table.search(var_name);
				// check if variable global or not
				if(temp_var->get_offset() == 0){
					// variable is global
					code += "\t\tMOV "+ var_name +", AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				} else {
					// variable is local
					code += "\t\tMOV [BP+" + to_string(temp_var->get_offset()) + "], AX\t\t;storing the value of " + temp_var->get_name() + " back in the stack\n";
				}
			}
			print_asm_to_file(asm_out, code);
		}

		
	};
	
argument_list : arguments {
		$$ = $1;
		fprintf(log_out, "Line %d - argument_list : arguments\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| {
		// no arguments
		$$ = new symbol_info("", "void");
		fprintf(log_out, "Line %d - argument_list : \n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	;
	
arguments : arguments COMMA logic_expression {
		//preparing the new symbol_info for the argument
		string argument_name = $1->get_name() + "," + $3->get_name();
		string argument_identifier = $1->get_identifier() + "," + $3->get_identifier();

		//creating the new symbol_info
		$$ = new symbol_info(argument_name, argument_identifier);
		//log file output
		fprintf(log_out, "Line %d - arguments : arguments COMMA logic_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	| logic_expression {
		$$ = $1;
		fprintf(log_out, "Line: %d - arguments : logic_expression\n\n%s\n\n", line_count, $$->get_name().c_str());
	}
	;
if_block_marker: {
	string if_false = get_new_label(&label_count);
	string code = "\t\t;line no " + to_string(line_count) + " - if statement\n";
	code += "\t\tPOP AX\t\t\t;pop the value of the expression\n";
	code += "\t\tCMP AX, 0\t\t\t;compare the value with 0\n";
	code += "\t\tJE " + if_false + "\t\t\t;if value is false, jump to the false label\n";
	print_asm_to_file(asm_out, code);

	$$ = new symbol_info(if_false, "LABEL");
}
%%
int main(int argc,char *argv[]) {

	if((fp=fopen(argv[1],"r"))==NULL) {
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	log_out= fopen(argv[2],"w");
	fclose(log_out);
	error_out= fopen(argv[3],"w");
	fclose(error_out);
	asm_out= fopen(argv[4],"w");
	fclose(asm_out);
	
	log_out= fopen(argv[2],"a");
	error_out= fopen(argv[3],"a");
	asm_out= fopen(argv[4],"a");

	// initializing the asm file
	init_assembly_file(asm_out);
	

	yyin=fp;
	yyparse();
	table.print_all(log_out);
	print_predefined_proc(asm_out);
	
	optimize_asm_code_push(asm_out, "assembly.asm", "temp.asm", 0);
	// while(!optimize_asm_code_push(asm_out, "temp.asm", "optimized.asm", 1));
	
	fprintf(log_out, "Total Lines: %d\n", line_count);
	fprintf(log_out, "Total Errors: %d\n", error_count);
	fclose(log_out);
	fclose(error_out);
	fclose(asm_out);

	return 0;
}