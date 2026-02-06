package sqlite

import "core:fmt"
import "core:strings"

import "raw_sqlite3_bindings"

SqliteError :: enum {
	Success,
	Error,
}

SqliteRow :: distinct [dynamic]any

SqliteTable :: struct {
	header: [dynamic]typeid,
	rows: [dynamic]SqliteRow,
}


execute_one_shot :: proc(db_pointer: ^raw_sqlite3_bindings.sqlite3, sql_string: string) -> string {
	errmsg: ^cstring = new(cstring)

	raw_sqlite3_bindings.sqlite3_exec(db_pointer, strings.clone_to_cstring(sql_string), nil, nil, errmsg)

	error_message: string = strings.clone_from_cstring(errmsg^)

	return error_message

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
	
	test_one_shot()

}

