package sqlite

import "core:fmt"
import "core:strings"
import "core:time"

import "raw_sqlite3_bindings"

sql_string :: distinct string

SqliteError :: enum {
	Success,
	Error,
	INVALID_TYPES,

}

SqliteRow :: distinct [dynamic]any

SqliteTable :: struct {
	header: [dynamic]typeid,
	rows: [dynamic]SqliteRow,
}

QueryType :: enum {
	SELECT,
	INSERT,
	UPDATE,
	DELETE,
	DROP,
	CREATE,
}

QueryStatus :: enum {
	uninitialized,
	in_progress,
	valid,
}


SqlQueryBuilder :: struct {
	type: QueryType,
	text: strings.Builder,
	status: QueryStatus,
	type_of_tuple: typeid,
}


query_add_inserts :: proc(query: ^SqlQueryBuilder, inserts: []$T) -> SqliteError {
	if query.query_type != QueryType.INSERT {
		return SqliteError.Error
	}

}


execute_one_shot :: proc(db_pointer: ^raw_sqlite3_bindings.sqlite3, sql_string: string) -> string {
	errmsg: ^cstring = new(cstring)

	raw_sqlite3_bindings.sqlite3_exec(db_pointer, strings.clone_to_cstring(sql_string), nil, nil, errmsg)

	error_message: string = strings.clone_from_cstring(errmsg^)

	return error_message

}

prepare_query :: proc(db_pointer: ^raw_sqlite3_bindings.sqlite3, initial_sql: string) -> ^raw_sqlite3_bindings.sqlite3_stmt, SqliteError {
	stmt : ^raw_sqlite3_bindings.sqlite3_stmt

	

}

test_binding_values :: proc() {

	fmt.println("TEST BINDING -----------------------------------------------------")

	db: ^raw_sqlite3_bindings.sqlite3
	stmt: ^raw_sqlite3_bindings.sqlite3_stmt
	
	raw_sqlite3_bindings.sqlite3_open("tests_database.db", &db)

    error_message := execute_one_shot(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);")

	statement : ^raw_sqlite3_bindings.sqlite3_stmt

	sql_text := "INSERT INTO expenses (texts, ints, floats) VALUES (?,?,?), (?,?,?);"

	errc := raw_sqlite3_bindings.sqlite3_prepare_v2(db, strings.clone_to_cstring(sql_text), i32(len(sql_text)), &statement, nil)

	if errc != raw_sqlite3_bindings.SQLITE_OK {
		fmt.println(errc)
		return
	}

	Expense :: struct {
		text: string,
		integer: i32,
		real: f32,
	}

	raw_sqlite3_bindings.sqlite3_bind_text(statement, 1, cstring("test1"), 5, nil)
	raw_sqlite3_bindings.sqlite3_bind_int(statement, 2, 1)
	raw_sqlite3_bindings.sqlite3_bind_double(statement, 3, 1.0)

	raw_sqlite3_bindings.sqlite3_bind_text(statement, 4, cstring("test2"), 5, nil)
	raw_sqlite3_bindings.sqlite3_bind_int(statement, 5, 2)
	raw_sqlite3_bindings.sqlite3_bind_double(statement, 6, 2.0)

	for i in 0..<10{
		time.sleep(time.Second)
		status := raw_sqlite3_bindings.sqlite3_step(statement)

		fmt.println(status)

		if status == raw_sqlite3_bindings.SQLITE_DONE || status == raw_sqlite3_bindings.SQLITE_ERROR || status == raw_sqlite3_bindings.SQLITE_MISUSE {
			time.sleep(time.Second)
			break
		}
	}

	select : ^raw_sqlite3_bindings.sqlite3_stmt

	raw_sqlite3_bindings.sqlite3_prepare_v2(db, "select * from expenses", -1, &select, nil)

	fmt.println("Got results:\n")
	for (raw_sqlite3_bindings.sqlite3_step(select) != raw_sqlite3_bindings.SQLITE_DONE) {
		i: i32
		num_cols: i32 = raw_sqlite3_bindings.sqlite3_column_count(select)
		for i = 0; i < num_cols; i += 1 {
			switch (raw_sqlite3_bindings.sqlite3_column_type(select, i))
			{
			case (raw_sqlite3_bindings.SQLITE3_TEXT):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_text(select, i))
			case (raw_sqlite3_bindings.SQLITE_INTEGER):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_int(select, i))
			case (raw_sqlite3_bindings.SQLITE_FLOAT):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_double(select, i))
			case:
                panic("not suppsed")
            }
		}
		fmt.println("\n")

	}

    raw_sqlite3_bindings.sqlite3_exec(db, "DROP TABLE expenses;", nil, nil, nil)


	fmt.println("***************************************************************")

}

test_one_shot :: proc() {
	fmt.println("TEST ONESHOT -----------------------------------------------------")

	db: ^raw_sqlite3_bindings.sqlite3
	stmt: ^raw_sqlite3_bindings.sqlite3_stmt
	
	raw_sqlite3_bindings.sqlite3_open("tests_database.db", &db)

	if db == nil {
		fmt.println("Failed to open DB\n")
		return
	}

	fmt.println("Performing query...\n")

    error_message := execute_one_shot(db, "CREATE TALE expenses (texts TEXT, ints INTEGER, floats FLOAT);")

	
	fmt.println(error_message)
	
	if error_message == "near \"TALE\": syntax error" {
		fmt.println("PASSED!!!")
	}

    raw_sqlite3_bindings.sqlite3_exec(db, "DROP TABLE expenses;", nil, nil, nil)


	fmt.println("***************************************************************")

}


test_basic :: proc() {
    fmt.println("TEST_BASIC ------------------------------------------------------")

	db: ^raw_sqlite3_bindings.sqlite3
	stmt: ^raw_sqlite3_bindings.sqlite3_stmt
	
	raw_sqlite3_bindings.sqlite3_open("tests_database.db", &db)

	if db == nil {
		fmt.println("Failed to open DB\n")
		return
	}

	fmt.println("Performing query...\n")

    raw_sqlite3_bindings.sqlite3_exec(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);", nil, nil, nil)
    raw_sqlite3_bindings.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"a\", 0, 0.0)", nil, nil, nil)
    raw_sqlite3_bindings.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"b\", 1, 1.0)", nil, nil, nil)
    raw_sqlite3_bindings.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"c\", 2, 2.0)", nil, nil, nil)

	raw_sqlite3_bindings.sqlite3_prepare_v2(db, "select * from expenses", -1, &stmt, nil)
	
	fmt.println("Got results:\n")
	for (raw_sqlite3_bindings.sqlite3_step(stmt) != raw_sqlite3_bindings.SQLITE_DONE) {
		i: i32
		num_cols: i32 = raw_sqlite3_bindings.sqlite3_column_count(stmt)
		for i = 0; i < num_cols; i += 1 {
			switch (raw_sqlite3_bindings.sqlite3_column_type(stmt, i))
			{
			case (raw_sqlite3_bindings.SQLITE3_TEXT):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_text(stmt, i))
			case (raw_sqlite3_bindings.SQLITE_INTEGER):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_int(stmt, i))
			case (raw_sqlite3_bindings.SQLITE_FLOAT):
				fmt.println(raw_sqlite3_bindings.sqlite3_column_double(stmt, i))
			case:
                panic("not suppsed")
            }
		}
		fmt.println("\n")

	}

	raw_sqlite3_bindings.sqlite3_finalize(stmt)

    raw_sqlite3_bindings.sqlite3_exec(db, "DROP TABLE expenses;", nil, nil, nil)

	raw_sqlite3_bindings.sqlite3_close(db)

	fmt.println("***************************************************************")

	return

}


main :: proc() {
	
	test_binding_values()

}

