package sqlite

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:time"
import "core:mem"

import raw "raw_sqlite3_bindings"

SqliteStatus :: enum {

	OK         =    0,   /* Successful result */
	/* beginning-of-error-codes */
	ERROR      =    1,   /* Generic error */
	INTERNAL   =    2,   /* Internal logic error in SQLite */
	PERM       =    3,   /* Access permission denied */
	ABORT      =    4,   /* Callback routine requested an abort */
	BUSY       =    5,   /* The database file is locked */
	LOCKED     =    6,   /* A table in the database is locked */
	NOMEM      =    7,   /* A malloc() failed */
	READONLY   =    8,   /* Attempt to write a readonly database */
	INTERRUPT  =    9,   /* Operation terminated by sqlite3_interrupt()*/
	IOERR      =   10,   /* Some kind of disk I/O error occurred */
	CORRUPT    =   11,   /* The database disk image is malformed */
	NOTFOUND   =   12,   /* Unknown opcode in sqlite3_file_control() */
	FULL       =   13,   /* Insertion failed because database is full */
	CANTOPEN   =   14,   /* Unable to open the database file */
	PROTOCOL   =   15,   /* Database lock protocol error */
	EMPTY      =   16,   /* Internal use only */
	SCHEMA     =   17,   /* The database schema changed */
	TOOBIG     =   18,   /* String or BLOB exceeds size limit */
	CONSTRAINT =   19,   /* Abort due to constraint violation */
	MISMATCH   =   20,   /* Data type mismatch */
	MISUSE     =   21,   /* Library used incorrectly */
	NOLFS      =   22,   /* Uses OS features not supported on host */
	AUTH       =   23,   /* Authorization denied */
	FORMAT     =   24,   /* Not used */
	RANGE      =   25,   /* 2nd parameter to sqlite3_bind out of range */
	NOTADB     =   26,   /* File opened that is not a database file */
	NOTICE     =   27,   /* Notifications from sqlite3_log() */
	WARNING    =   28,   /* Warnings from sqlite3_log() */
	ROW        =   100,  /* sqlite3_step() has another row ready */
	DONE       =   101,  /* sqlite3_step() has finished executing */
}

status_from_int :: proc(#any_int i: int) -> SqliteStatus {
	switch i {
		case 0:   {return .OK}
		case 1:   {return .ERROR      } 
		case 2:   {return .INTERNAL   } 
		case 3:   {return .PERM       } 
		case 4:   {return .ABORT      } 
		case 5:   {return .BUSY       } 
		case 6:   {return .LOCKED     } 
		case 7:   {return .NOMEM      } 
		case 8:   {return .READONLY   } 
		case 9:   {return .INTERRUPT  } 
		case 10:  {return .IOERR      } 
		case 11:  {return .CORRUPT    } 
		case 12:  {return .NOTFOUND   } 
		case 13:  {return .FULL       } 
		case 14:  {return .CANTOPEN   } 
		case 15:  {return .PROTOCOL   } 
		case 16:  {return .EMPTY      } 
		case 17:  {return .SCHEMA     } 
		case 18:  {return .TOOBIG     } 
		case 19:  {return .CONSTRAINT } 
		case 20:  {return .MISMATCH   } 
		case 21:  {return .MISUSE     } 
		case 22:  {return .NOLFS      } 
		case 23:  {return .AUTH       } 
		case 24:  {return .FORMAT     } 
		case 25:  {return .RANGE      } 
		case 26:  {return .NOTADB     } 
		case 27:  {return .NOTICE     } 
		case 28:  {return .WARNING    } 
		case 100: {return .ROW        }
		case 101: {return .DONE       }
		case: {panic("Received invalid status code from alleged sqlite function")}
	}
}

Statement :: distinct raw.sqlite3_stmt

Database :: distinct raw.sqlite3

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


execute_one_shot :: proc(db_pointer: ^Database, sql_string: cstring) -> string {
	errmsg: ^cstring = new(cstring)

	raw.sqlite3_exec(cast(^raw.sqlite3)db_pointer, sql_string, nil, nil, errmsg)

	error_message: string = strings.clone_from_cstring(errmsg^)

	return error_message

}

prepare_statement :: proc(db_pointer: ^Database, initial_sql: string) -> (^Statement, SqliteStatus) {
	stmt : ^raw.sqlite3_stmt

	error := raw.sqlite3_prepare_v2(cast(^raw.sqlite3)db_pointer, cstring(raw_data(initial_sql)), i32(len(initial_sql)), &stmt, nil)
	
	statement := cast(^Statement)stmt

	return statement, .OK
}

step_statement :: proc(db_pointer: ^Database, statement: ^Statement) -> SqliteStatus {
	status := raw.sqlite3_step(cast(^raw.sqlite3_stmt)statement)

	return status_from_int(status)
}

finalize_statement :: proc(statement: ^Statement) -> SqliteStatus {
	status := raw.sqlite3_finalize(cast(^raw.sqlite3_stmt)statement)

	return status_from_int(status)
}

close_database :: proc(database_pointer: ^Database) -> SqliteStatus {
	status := raw.sqlite3_close(cast(^raw.sqlite3)database_pointer)

	return status_from_int(status)
}

open_database :: proc(path: cstring) -> (^Database, SqliteStatus) {
	db: ^raw.sqlite3

	status := raw.sqlite3_open(path, &db)

	return cast(^Database)db, status_from_int(status)
}

bind_null :: proc(statement: ^Statement, index: i32) -> SqliteStatus {
	status := raw.sqlite3_bind_null(cast(^raw.sqlite3_stmt)statement, index)

	return status_from_int(status)
}

bind_int :: proc(statement: ^Statement, value: i32, index: i32) -> SqliteStatus {
	status := raw.sqlite3_bind_int(cast(^raw.sqlite3_stmt)statement, index, value)

	return status_from_int(status)
}

bind_float :: proc(statement: ^Statement, value: f64, index: i32) -> SqliteStatus {
	status := raw.sqlite3_bind_double(cast(^raw.sqlite3_stmt)statement, index, value)

	return status_from_int(status)
}

bind_text :: proc(statement: ^Statement, value: string, index: i32) -> SqliteStatus {
	status := raw.sqlite3_bind_text(cast(^raw.sqlite3_stmt)statement, index, cstring(raw_data(value)), i32(len(value)), nil)

	return status_from_int(status)
}

bind_blob :: proc(statement: ^Statement, value: []u8, index: i32) -> SqliteStatus {
	status := raw.sqlite3_bind_blob(cast(^raw.sqlite3_stmt)statement, index, raw_data(value), i32(len(value)), nil)

	return status_from_int(status)
}

SqliteType :: enum {
	INTEGER  =  raw.SQLITE_INTEGER,
	FLOAT    =  raw.SQLITE_FLOAT,
	TEXT     =  raw.SQLITE_TEXT,
	BLOB     =  raw.SQLITE_BLOB,
	NULL     =  raw.SQLITE_NULL,
}

SqliteValue :: union {
	int,
	f64,
	string,
	[]u8,
}

get_column_count :: proc(statement: ^Statement) -> i32 {
	return raw.sqlite3_column_count(cast(^raw.sqlite3_stmt)statement)
}

get_column_type :: proc(statement: ^Statement, column_number: i32) -> SqliteType {

	col_index := min(column_number, get_column_count(statement))

	col_type := raw.sqlite3_column_type(cast(^raw.sqlite3_stmt)statement, column_number)

	switch col_type {
		case raw.SQLITE_INTEGER: {return .INTEGER}
		case raw.SQLITE_FLOAT:   {return .FLOAT  }
		case raw.SQLITE_TEXT:    {return .TEXT   }
		case raw.SQLITE_BLOB:    {return .BLOB   }
		case raw.SQLITE_NULL:    {return .NULL   }
		case: panic("Unsupported col type returned")
	}
}

get_column_int :: proc(statement: ^Statement, column_number: i32) -> (i32, SqliteStatus) {
	
	col_index := min(column_number, get_column_count(statement))
	
	col_type := get_column_type(statement, col_index)

	if col_type != .INTEGER {
		return 0, .ERROR
	}

	return raw.sqlite3_column_int(cast(^raw.sqlite3_stmt)statement, col_index), .OK
}

get_column_double :: proc(statement: ^Statement, column_number: i32) -> (f64, SqliteStatus) {
	
	col_index := min(column_number, get_column_count(statement))
	
	col_type := get_column_type(statement, col_index)

	if col_type != .FLOAT {
		return 0, .ERROR
	}

	return raw.sqlite3_column_double(cast(^raw.sqlite3_stmt)statement, col_index), .OK
}


get_column_text :: proc(statement: ^Statement, column_number: i32) -> string {
	
	col_index := min(column_number, get_column_count(statement))
	
	col_type := get_column_type(statement, col_index)

	if col_type != .TEXT {
		return ""
	}

	temp_string := raw.sqlite3_column_text(cast(^raw.sqlite3_stmt)statement, col_index)

	str := strings.clone_from_cstring(temp_string)
	
	return str

}

get_column_blob :: proc(statement: ^Statement, column_number: i32) -> []u8 {
	
	col_index := min(column_number, get_column_count(statement))
	
	col_type := get_column_type(statement, col_index)

	if col_type != .BLOB {
		return {}
	}

	temp_blob := raw.sqlite3_column_blob(cast(^raw.sqlite3_stmt)statement, col_index)
	temp_blob_len := raw.sqlite3_column_bytes(cast(^raw.sqlite3_stmt)statement, col_index)

	blob: []u8 = make([]u8, temp_blob_len)
	mem.copy(raw_data(blob), temp_blob, int(temp_blob_len))
	
	return blob

}


test_binding_values :: proc() {

	fmt.println("TEST BINDING -----------------------------------------------------")
	
	db, status := open_database("tests_database.db")

	if status != .OK {
		panic("Couldn't open database")
	}

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

		fmt.println(status)

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

test_one_shot :: proc() {
	fmt.println("TEST ONESHOT -----------------------------------------------------")

	stmt: ^raw.sqlite3_stmt
	
	db, status := open_database("tests_database.db")

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


test_basic :: proc() {
    fmt.println("TEST_BASIC ------------------------------------------------------")

	db: ^raw.sqlite3
	stmt: ^raw.sqlite3_stmt
	
	raw.sqlite3_open("tests_database.db", &db)

	if db == nil {
		fmt.println("Failed to open DB\n")
		return
	}

	fmt.println("Performing query...\n")

    raw.sqlite3_exec(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"a\", 0, 0.0)", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"b\", 1, 1.0)", nil, nil, nil)
    raw.sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"c\", 2, 2.0)", nil, nil, nil)

	raw.sqlite3_prepare_v2(db, "select * from expenses", -1, &stmt, nil)
	
	fmt.println("Got results:\n")
	for (raw.sqlite3_step(stmt) != raw.SQLITE_DONE) {
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


main :: proc() {
	
	// test_basic()

	test_binding_values()

}

