package sqlite3_bindings

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:time"
import "core:mem"
import "core:reflect"
import "core:prof/spall"

import raw "raw_bindings"

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


get_column_text :: proc(statement: ^Statement, column_number: i32) -> (string, SqliteStatus) {

	col_index := min(column_number, get_column_count(statement))

	col_type := get_column_type(statement, col_index)

	if col_type != .TEXT {
		return "", .ERROR
	}

	temp_string := raw.sqlite3_column_text(cast(^raw.sqlite3_stmt)statement, col_index)

	str := strings.clone_from_cstring(temp_string)

	return str, .OK

}

get_column_blob :: proc(statement: ^Statement, column_number: i32) -> ([]u8, SqliteStatus) {

	col_index := min(column_number, get_column_count(statement))

	col_type := get_column_type(statement, col_index)

	if col_type != .BLOB {
		return {}, .ERROR
	}

	temp_blob := raw.sqlite3_column_blob(cast(^raw.sqlite3_stmt)statement, col_index)
	temp_blob_len := raw.sqlite3_column_bytes(cast(^raw.sqlite3_stmt)statement, col_index)

	blob: []u8 = make([]u8, temp_blob_len)
	mem.copy(raw_data(blob), temp_blob, int(temp_blob_len))

	return blob, .OK

}

Result :: struct($T: typeid) {
	value: T,
	status: SqliteStatus,
}

// Struct fields must match table fields in the order they were declared in CREATE TABLE
map_to_struct :: proc(db_pointer: ^Database, statement: ^Statement, $T: typeid) -> Result(T) {
	value : T
	value_rawptr := cast([^]u8)&value

	struct_fields_num := i32(reflect.struct_field_count(T))
	alignment := i32(align_of(T))

	if struct_fields_num != get_column_count(statement) {
		return Result(T){value = value, status = .ERROR}
	}

	offsets := make([dynamic]i32)
	defer delete(offsets)

	current_offset: i32 = 0

	struct_fields := reflect.struct_fields_zipped(T)
	for r in i32(0)..<struct_fields_num {
		if struct_fields[r].type.id == i32 {
			int_rawptr := cast(^i32)&value_rawptr[struct_fields[r].offset]
			integer, int_status := get_column_int(statement, r)
			if int_status == .ERROR {
				result := Result(T){status = .ERROR}
				return result
			}
			int_rawptr^ = integer
		} else if struct_fields[r].type.id == f64 {
			double_rawptr := cast(^f64)&value_rawptr[struct_fields[r].offset]
			double, double_status := get_column_double(statement, r)
			if double_status == .ERROR {
				result := Result(T){status = .ERROR}
				return result
			}
			double_rawptr^ = double
		} else if struct_fields[r].type.id == string {
			text_rawptr := cast(^string)&value_rawptr[struct_fields[r].offset]
			text, text_status := get_column_text(statement, r)
			if text_status == .ERROR {
				result := Result(T){status = .ERROR}
				return result
			}
			text_rawptr^ = text
		} else if struct_fields[r].type.id == []u8 {
			blob_rawptr := cast(^[]u8)&value_rawptr[struct_fields[r].offset]
			blob, blob_status := get_column_blob(statement, r)
			if blob_status == .ERROR {
				result := Result(T){status = .ERROR}
				return result
			}
			blob_rawptr^ = blob
		}
	}

	return Result(T){value = value, status = .OK}
}



main :: proc() {

	db, db_status := open_database("temp.db")

	// execute_one_shot(db, "DROP TABLE temp_table")

	execute_one_shot(db, "CREATE TABLE temp_table (name TEXT, size FLOAT, price INTEGER, picture BLOB);")

	statement, status := prepare_statement(db, "INSERT INTO temp_table (name, size, price, picture) VALUES (\"PI\", 3.14, 1000, ?), (\"TAU\", 6.28, 2000, ?);")	
	fmt.println(status)

	bind_blob(statement, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, 1)
	bind_blob(statement, {11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}, 2)

	step_statement(db, statement)
	step_statement(db, statement)
	finalize_statement(statement)

	select, select_status := prepare_statement(db, "SELECT * FROM temp_table;")
	step_statement(db, select)

	fmt.println(size_of(string))
	fmt.println(align_of(string))

	struct_types := reflect.struct_field_types(Product)
	for i in 0..<len(struct_types) {
		fmt.println(struct_types[i])
	}

	Product :: struct {
		name: string,
		size: f64,
		price: i32,
		picture: []u8
	}

	result := map_to_struct(db, select, Product)

	fmt.println(result.value)

}

