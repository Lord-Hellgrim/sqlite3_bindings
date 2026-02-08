package tests

import "core:testing"
import "core:fmt"
import "core:time"

import sqlite3 "../../sqlite3_bindings"
import raw "../raw_bindings"


@(test)
test_binding_values :: proc(t: ^testing.T) {
    using sqlite3

	fmt.println("TEST BINDING -----------------------------------------------------")
	
	db, open_status := open_database("test_db/tests_database_binding.db")
    
    
	if open_status != .OK {
        panic("Couldn't open database")
	}
    execute_one_shot(db, "PRAGMA journal_mode=WAL;")

    error_message := execute_one_shot(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);")

	sql_text := "INSERT INTO expenses (texts, ints, floats) VALUES (?,?,?), (?,?,?);"

	stmt, prepare_status := prepare_statement(db, sql_text)

	if prepare_status != .OK {
		fmt.println(prepare_status)
		return
	}

	Expense :: struct {
		text: string,
		integer: i32,
		real: f32,
	}

	bind_status : SqliteStatus

	bind_status = bind_text(stmt, "test1", 1)
	bind_status = bind_int(stmt, 1, 2)
	bind_status = bind_float(stmt, 1.0, 3)

	bind_status = bind_text(stmt, "test2", 4)
	bind_status = bind_int(stmt, 2, 5)
	bind_status = bind_float(stmt, 2.0, 6)


	for i in 0..<10{
		step_status := step_statement(db, stmt)

		fmt.println(step_status)

		if step_status == .DONE {
			break
		}
	}

	select, select_status := prepare_statement(db, "select * from expenses")

	fmt.println("Got results:\n")
	rows := 0
	for (step_statement(db, select) != .DONE) {
		i: i32
		num_cols: i32 = get_column_count(select)
		for i = 0; i < num_cols; i += 1 {
			#partial switch (get_column_type(select, i))
			{
				case (.TEXT):
					fmt.println(get_column_text(select, i))
				case (.INTEGER):
					fmt.println(get_column_int(select, i))
				case (.FLOAT):
					fmt.println(get_column_double(select, i))
				case:
					panic("not supposed to happen")
            }
		}
		rows += 1
	}

	fmt.println(rows)

    execute_one_shot(db, "DROP TABLE expenses;")


	fmt.println("***************************************************************")

}


@(test)
test_one_shot :: proc(t: ^testing.T) {
    using sqlite3

	fmt.println("TEST ONESHOT -----------------------------------------------------")

	stmt: ^raw.sqlite3_stmt
	
	db, status := open_database("test_db/tests_database_oneshot.db")

    execute_one_shot(db, "PRAGMA journal_mode=WAL;")

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

    execute_one_shot(db, "DROP TABLE expenses;")


	fmt.println("***************************************************************")

}


@(test)
test_raw :: proc(t: ^testing.T) {
    using sqlite3

    fmt.println("TEST_BASIC ------------------------------------------------------")

	db: ^raw.sqlite3
	stmt: ^raw.sqlite3_stmt
	
	raw.sqlite3_open("test_db/tests_database_raw.db", &db)

	if db == nil {
		fmt.println("Failed to open DB\n")
		return
	}

	fmt.println("Performing query...\n")

    raw.sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)

    raw.sqlite3_exec(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"a\", 0, 0.0)", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"b\", 1, 1.0)", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"c\", 2, 2.0)", nil, nil, nil)

	raw.sqlite3_prepare_v2(db, "select * from expenses", -1, &stmt, nil)
	
	fmt.println("Got results:\n")
    
	for (raw.sqlite3_step(stmt) != raw.SQLITE_DONE) {
        status := raw.sqlite3_step(stmt)

        fmt.println(status)

        if status == raw.SQLITE_DONE {
            break
        }
        
        time.sleep(time.Second)

		i: i32
		num_cols: i32 = raw.sqlite3_column_count(stmt)
		for i = 0; i < num_cols; i += 1 {
			switch (raw.sqlite3_column_type(stmt, i))
			{
			case (raw.SQLITE3_TEXT):
				fmt.println(raw.sqlite3_column_text(stmt, i))
			case (raw.SQLITE_INTEGER):
				fmt.println(raw.sqlite3_column_int(stmt, i))
			case (raw.SQLITE_FLOAT):
				fmt.println(raw.sqlite3_column_double(stmt, i))
			case:
                panic("not suppsed")
            }
		}
		fmt.println("\n")

	}

	raw.sqlite3_finalize(stmt)

    raw.sqlite3_exec(db, "DROP TABLE expenses;", nil, nil, nil)

	raw.sqlite3_close(db)

	fmt.println("***************************************************************")

	return

}
